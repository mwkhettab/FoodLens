import SwiftUI

struct MealDetailView: View {
    let meal: EstimateCaloriesResponse
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(spacing: 10) {
                    Text("Nutritional Analysis")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("\(Int(meal.calories)) Calories")
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
                        Text("\(meal.health_score)/100")
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Confidence: \(meal.confidence_level)%")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    ProgressView(value: Double(meal.health_score), total: 100)
                        .tint(healthScoreColor(meal.health_score))
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)


                VStack(alignment: .leading, spacing: 10) {
                    Text("Portion Size")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text(meal.portion_size)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                

                VStack(alignment: .leading, spacing: 10) {
                    Text("Macronutrients")
                        .font(.headline)
                        .foregroundColor(.blue)

                    NutrientRow(name: "Protein", value: meal.macronutrients.protein_g, unit: "g", color: .blue)
                    NutrientRow(name: "Carbs", value: meal.macronutrients.carbs_g, unit: "g", color: .green)
                    NutrientRow(name: "Fat", value: meal.macronutrients.fat_g, unit: "g", color: .yellow)
                    NutrientRow(name: "Fiber", value: meal.macronutrients.fiber_g, unit: "g", color: .brown)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Micronutrients")
                        .font(.headline)
                        .foregroundColor(.blue)

                    NutrientRow(name: "Sodium", value: meal.micronutrients.sodium_mg, unit: "mg", color: .red)
                    NutrientRow(name: "Sugar", value: meal.micronutrients.sugar_g, unit: "g", color: .pink)
                    NutrientRow(name: "Saturated Fat", value: meal.micronutrients.saturated_fat_g, unit: "g", color: .orange)
                    NutrientRow(name: "Cholesterol", value: meal.micronutrients.cholesterol_mg, unit: "mg", color: .purple)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                if !meal.health_insights.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Health Insights")
                            .font(.headline)
                            .foregroundColor(.blue)

                        ForEach(meal.health_insights, id: \.self) { insight in
                            HStack(alignment: .top, spacing: 10) {
                                Text("•").foregroundColor(.blue)
                                Text(insight)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
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

struct SavedView: View {
    @Environment(\.presentationMode) private var presentationMode
    private let storage = MealStorage()

    @State private var savedMeals: [EstimateCaloriesResponse] = []

    private let grid = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {

                    Text("Saved Meals")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top)

                    if savedMeals.isEmpty {
                        Text("No saved meals found.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: grid, spacing: 20) {
                                ForEach(Array(savedMeals.enumerated()), id: \.offset) { index, meal in
                                    NavigationLink(destination: MealDetailView(meal: meal)) {
                                        mealThumbnail(meal)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                  
                }
            }
            .onAppear {
                savedMeals = storage.loadAll() ?? []
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func mealThumbnail(_ meal: EstimateCaloriesResponse) -> some View {
        VStack(spacing: 8) {
            Text("\(Int(meal.calories)) kcal")
                .font(.headline)
                .foregroundColor(.blue)

            Text("Score: \(meal.health_score)")
                .font(.subheadline)
                .foregroundColor(.white)

            Text(meal.portion_size)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
