import SwiftUI

class MealStorage {
    private let key = "savedMeals"
    
    func save(_ response: EstimateCaloriesResponse) {
        var meals = loadAll() ?? []
        meals.append(response)
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(meals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func loadAll() -> [EstimateCaloriesResponse]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([EstimateCaloriesResponse].self, from: data)
    }
}
