from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from pydantic import BaseModel
from typing import Dict, List, Optional
from services.openai_service import analyze_image, estimate_calories, chat
import json
import base64

router = APIRouter()


class EstimateCaloriesRequest(BaseModel):
    food_name: str
    details: str
    answers: Dict[str, str]


class ChatRequest(BaseModel):
    message: str
    conversation_history: Optional[List[Dict[str, str]]] = None


@router.post("/analyze-image")
async def analyze_image_endpoint(file: UploadFile = File(...)):

    try:

        if not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")

        image_bytes = await file.read()

        result = analyze_image(image_bytes)
        print(result["output"][0]["content"][0]["parsed"])
        return result["output"][0]["content"][0]["parsed"]

    except Exception as e:
        print(str(e))
        raise HTTPException(status_code=500, detail=f"Error analyzing image: {str(e)}")


@router.post("/estimate-calories")
async def estimate_calories_endpoint(request: EstimateCaloriesRequest):
    try:
        result = estimate_calories(request.food_name, request.details, request.answers)
        print(result)
        return result["output"][0]["content"][0]["parsed"]
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        print(str(e))
        raise HTTPException(
            status_code=500, detail=f"Error estimating calories: {str(e)}"
        )


@router.post("/chat")
async def chat_endpoint(request: ChatRequest):
    try:

        result = chat(request.message, request.conversation_history)

        return result

    except Exception as e:
        print(str(e))
        raise HTTPException(status_code=500, detail=f"Error in chat: {str(e)}")
