import SwiftUI

// MARK: - Stub CategoryViews
struct CategoryGridView: View {
    let categories: [Category]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
            ForEach(categories, id: \.id) { category in
                CategoryCardView(category: category)
            }
        }
        .padding()
    }
}

struct CategoryCardView: View {
    let category: Category
    
    var body: some View {
        VStack {
            Image(systemName: category.icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text(category.name)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Add Category View")
                .navigationTitle("Add Category")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    CategoryGridView(categories: [])
}