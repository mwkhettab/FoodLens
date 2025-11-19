from openai import OpenAI
from typing import Dict, Any, List, Optional
from core.config import settings
import json
from pydantic import BaseModel, Field
import base64

client = OpenAI(api_key=settings.openai_api_key)


class ImageAnalysisResponse(BaseModel):
    food_name: str
    details: str
    questions: List[str]


def analyze_image(image_bytes: bytes) -> Dict[str, Any]:
    response = client.responses.parse(
        model="gpt-4.1",
        input=[
            {
                "role": "system",
                "content": """You identify foods in images. Your response must always follow the schema:

food_name: the exact name of the food item as visibly identifiable in the image.
details: an extremely specific description of what you can visually confirm, including portion size (visually estimated), preparation/cooking method, visible ingredients, visible seasonings, visible sauces, packaging/brand markings (if any), and any other concrete visual details. Focus on the main photographed item only and ignore any background items or context.
questions: ask exactly 3 clarifying questions that would help estimate calories more accurately. Focus on portion size confirmation, cooking method, added fats/oils, dressing/sauces, brand, or anything not clearly visible.

Important:
- Only describe details you can visually confirm.
- Do not guess hidden ingredients or internal contents.
- Be explicit and concrete about what you see (color, texture, cut, visible oil sheen, browning, toppings, shape, approximate volume).
- "food_name" must be the simple item name (e.g., "grilled chicken breast", "pepperoni pizza slice", "blueberry muffin").
- "details" is where you provide the full descriptive breakdown.
""",
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": "Identify this food and provide 3 clarification questions in JSON format.",
                    },
                    {
                        "type": "input_image",
                        "image_url": f"data:image/png;base64,{base64.b64encode(image_bytes).decode('utf-8')}",
                    },
                ],
            },
        ],
        text_format=ImageAnalysisResponse,
    )

    return response.model_dump()


class Macronutrients(BaseModel):
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: float


class Micronutrients(BaseModel):
    sodium_mg: float
    sugar_g: float
    saturated_fat_g: float
    cholesterol_mg: float


class EstimateCaloriesResponse(BaseModel):
    calories: float
    macronutrients: Macronutrients
    micronutrients: Micronutrients
    health_score: int = Field(..., ge=0, le=100)
    health_insights: List[str]
    portion_size: str
    confidence_level: int = Field(..., ge=0, le=100)


def estimate_calories(
    food_name: str, details: str, answers: Dict[str, str]
) -> Dict[str, Any]:
    prompt = {"food_name": food_name, "details": details, "answers": answers}

    response = client.responses.parse(
        model="gpt-4.1",
        input=[
            {
                "role": "system",
                "content": """You are a nutrition expert with access to USDA FoodData Central and comprehensive nutrition databases.

Provide MAXIMUM ACCURACY estimates using:
- USDA FoodData Central values
- Restaurant/brand nutrition facts when applicable
- Standard portion sizes from nutrition databases
- Peer-reviewed nutritional research

Be as accurate as possible. Use decimal precision for nutrients. Health score should be a number from 0-100 based on overall nutritional quality. Confidence level should reflect how certain you are about the estimates based on provided info, also 1-100.""",
            },
            {
                "role": "user",
                "content": f"Generate accurate nutritional estimates for: {json.dumps(prompt)}",
            },
        ],
        text_format=EstimateCaloriesResponse,
    )

    return response.model_dump()


class ChatResponse(BaseModel):
    response: str


def chat(
    message: str, conversation_history: Optional[List[Dict[str, str]]] = None
) -> Dict[str, Any]:
    if conversation_history is None:
        conversation_history = []

    input_messages = [
        {
            "role": "system",
            "content": """You are a knowledgeable nutrition assistant. Answer questions about:
- Nutrition and calorie information
- Meal planning and dietary advice
- Food preparation and cooking methods
- Health and wellness related to diet

Be concise, accurate, and helpful. Reference previous context when relevant.

CRITICAL SAFETY RULE: If a question could be dangerous if answered incorrectly, you MUST respond with ONLY:
"I cannot help you with that. Please consult a healthcare professional or registered dietitian for personalized medical advice."

Refuse to answer questions about:
- Medical conditions, diseases, or health disorders (diabetes, kidney disease, heart conditions, allergies, etc.)
- Medication interactions with food or supplements
- Therapeutic diets for medical conditions
- Weight loss or gain for specific health conditions
- Pregnancy, breastfeeding, or infant nutrition advice
- Eating disorders or disordered eating patterns
- Supplement dosing or medical claims
- Food safety for immunocompromised individuals
- Diagnosis or treatment of any condition
- Any question where incorrect information could cause harm

You can provide general, educational nutrition information, but never personalized medical advice.""",
        }
    ]

    input_messages.extend(conversation_history)

    input_messages.append({"role": "user", "content": message})

    response = client.responses.parse(
        model="gpt-4.1",
        input=input_messages,
        text_format=ChatResponse,
    )

    result = response.model_dump()
    print(result)
    assistant_message = result["output"][0]["content"][0]["parsed"]["response"]

    updated_history = conversation_history + [
        {"role": "user", "content": message},
        {"role": "assistant", "content": assistant_message},
    ]

    return {"response": assistant_message, "conversation_history": updated_history}
