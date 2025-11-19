import SwiftUI
import PhotosUI

struct CameraView: View {
    @State private var selectedImage: UIImage?
    @State private var takePicture = false
    @State private var uploadImage = false
    @State private var loading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var imageResponse: AnalyzeImageResponse?
    @State private var results: EstimateCaloriesResponse?
    @State private var showQuestions: Bool = false
    @State private var showResults: Bool = false
    private let storage = MealStorage()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("FoodLens")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
                    .padding()
                    .multilineTextAlignment(.center)
                Text("Scan a photo of your food and view the nutritional information")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                
                HStack {
                    Button("Take Picture") {
                        takePicture = true
                    }
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .bold()
                    
                    Button("Upload Image") {
                        uploadImage = true
                    }
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .bold()
                }.padding()
            }
            .overlay {
                if loading {
                    LoadingView()
                }
            }
            .sheet(isPresented: $takePicture) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $uploadImage) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showError) {
                ErrorView(error: errorMessage, isPresented: $showError)
            }
            .sheet(isPresented: $showQuestions) {
                if let response = imageResponse {
                    QuestionsView(
                        analysis: response,
                        isPresented: $showQuestions,
                        onComplete: { answers in
                            handleQuestionsComplete(answers: answers)
                        }
                    )
                }
            }
            .sheet(isPresented: $showResults) {
                if let results = results {
                    ResultsView(
                        results: results,
                        isPresented: $showResults,
                        storage: storage
                    )
                }
            }
            .onChange(of: selectedImage, initial: false) { oldImage, newImage in
                guard let newImage else { return }
                loading = true
                
                Task {
                    do {
                        let response = try await APIService().analyzeImage(uiImage: newImage)
                        print("Response:", response)
                        imageResponse = response
                        showQuestions = true
                    } catch {
                        print("API error:", error)
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                    
                    loading = false
                }
            }
        }
    }
    
    private func handleQuestionsComplete(answers: [String]) {
        guard let analysis = imageResponse else { return }
        
        loading = true
        showQuestions = false
        
        Task {
            do {
                let calorieResults = try await APIService().estimateCalories(
                    foodName: analysis.food_name,
                    details: analysis.details,
                    questions: analysis.questions,
                    answers: answers
                )
                
                results = calorieResults
                showResults = true
            } catch {
                print("Calorie estimation error:", error)
                errorMessage = error.localizedDescription
                showError = true
            }
            
            loading = false
        }
    }
}


struct ErrorView: View {
    let error: String
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("An unexpected error occurred while analyzing your food.")
                    .font(Font.largeTitle.bold())
                    .foregroundColor(.red)
                    .padding()
                    .multilineTextAlignment(.center)
                
                Text("We are sorry for the inconvenience. Please try again later.")
                    .font(Font.title3)
                    .foregroundColor(.white)
                    .padding()
                    .multilineTextAlignment(.center)
                
                if !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                Button("Close") {
                    isPresented = false
                }
                .foregroundColor(.black)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .bold()
                .padding(.top, 10)
            }
            .padding()
        }
    }
}


struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                
                Text("Analyzing your food...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

struct QuestionsView: View {
    let analysis: AnalyzeImageResponse
    @Binding var isPresented: Bool
    let onComplete: ([String]) -> Void
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [String] = []
    @State private var currentAnswer = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Food Analysis")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                
                VStack(spacing: 20) {
                    Text("Question \(currentQuestionIndex + 1) of \(analysis.questions.count)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(analysis.questions[currentQuestionIndex])
                        .font(.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    TextField("Your answer", text: $currentAnswer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(currentQuestionIndex < analysis.questions.count - 1 ? "Next" : "Finish") {
                        submitAnswer()
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(currentAnswer.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .bold()
                    .padding(.horizontal)
                    .disabled(currentAnswer.isEmpty)
                }
                .padding()
            }
        }
    }
    
    private func submitAnswer() {
        answers.append(currentAnswer)
        currentAnswer = ""
        
        if currentQuestionIndex < analysis.questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            onComplete(answers)
            isPresented = false
        }
    }
}

struct ResultsView: View {
    let results: EstimateCaloriesResponse
    @Binding var isPresented: Bool
    let storage: MealStorage  
    
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    VStack(spacing: 10) {
                        Text("Nutritional Analysis")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text("\(Int(results.calories)) Calories")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Health Score")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        HStack {
                            Text("\(results.health_score)/100")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("Confidence: \(results.confidence_level)%")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        ProgressView(value: Double(results.health_score), total: 100)
                            .tint(healthScoreColor(results.health_score))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Portion Size")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(results.portion_size)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Macronutrients")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        NutrientRow(name: "Protein", value: results.macronutrients.protein_g, unit: "g", color: .blue)
                        NutrientRow(name: "Carbs", value: results.macronutrients.carbs_g, unit: "g", color: .green)
                        NutrientRow(name: "Fat", value: results.macronutrients.fat_g, unit: "g", color: .yellow)
                        NutrientRow(name: "Fiber", value: results.macronutrients.fiber_g, unit: "g", color: .brown)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Micronutrients")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        NutrientRow(name: "Sodium", value: results.micronutrients.sodium_mg, unit: "mg", color: .red)
                        NutrientRow(name: "Sugar", value: results.micronutrients.sugar_g, unit: "g", color: .pink)
                        NutrientRow(name: "Saturated Fat", value: results.micronutrients.saturated_fat_g, unit: "g", color: .blue)
                        NutrientRow(name: "Cholesterol", value: results.micronutrients.cholesterol_mg, unit: "mg", color: .purple)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    
                    if !results.health_insights.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Health Insights")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            ForEach(results.health_insights, id: \.self) { insight in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                        .foregroundColor(.blue)
                                    Text(insight)
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    
                    Button("Save") {
                        storage.save(results)
                        isPresented = false
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .bold()
                    .padding(.top, 10)
                    
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .bold()
                    .padding(.top, 10)
                }
                .padding()
            }
        }
    }
    
    private func healthScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100:
            return .green
        case 50...79:
            return .yellow
        default:
            return .red
        }
    }
}

struct NutrientRow: View {
    let name: String
    let value: Float
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .foregroundColor(.white)
                .font(.body)
            
            Spacer()
            
            Text(String(format: "%.1f %@", value, unit))
                .foregroundColor(.white)
                .font(.body)
                .bold()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    CameraView()
}
