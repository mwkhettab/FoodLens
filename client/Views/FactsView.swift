import SwiftUI

struct FactsView: View {
    let articles = [
        Article(
            title: "Understanding Macronutrients",
            description: "Learn about proteins, carbohydrates, and fats",
            url: "https://www.healthline.com/nutrition/macronutrients"
        ),
        Article(
            title: "The Mediterranean Diet Guide",
            description: "Benefits and basics of Mediterranean eating",
            url: "https://www.mayoclinic.org/healthy-lifestyle/nutrition-and-healthy-eating/in-depth/mediterranean-diet/art-20047801"
        ),
        Article(
            title: "Reading Nutrition Labels",
            description: "How to understand food labels and serving sizes",
            url: "https://www.fda.gov/food/nutrition-education-resources-materials/how-understand-and-use-nutrition-facts-label"
        ),
        Article(
            title: "Meal Planning Basics",
            description: "Tips for planning healthy, balanced meals",
            url: "https://www.eatright.org/food/planning-and-prep/meal-planning-made-easy"
        ),
        Article(
            title: "Food Safety Guidelines",
            description: "Proper food storage and handling practices",
            url: "https://www.foodsafety.gov/keep-food-safe/foodkeeper-app"
        ),
        Article(
            title: "Plant-Based Eating",
            description: "Introduction to vegetarian and vegan diets",
            url: "https://www.hsph.harvard.edu/nutritionsource/healthy-eating-plate/"
        ),
        Article(
            title: "Hydration and Health",
            description: "Why water matters and how much you need",
            url: "https://www.mayoclinic.org/healthy-lifestyle/nutrition-and-healthy-eating/in-depth/water/art-20044256"
        ),
        Article(
            title: "Understanding Food Allergies",
            description: "Common allergens and how to manage them",
            url: "https://www.foodallergy.org/living-food-allergies/food-allergy-essentials"
        )
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(articles) { article in
                    ArticleCard(article: article)
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle("Food Articles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Article: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let url: String
}

struct ArticleCard: View {
    let article: Article
    
    var body: some View {
        Link(destination: URL(string: article.url)!) {
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(article.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationView {
        FactsView()
    }
}
