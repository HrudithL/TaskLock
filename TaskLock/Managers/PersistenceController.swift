import Foundation
import CoreData

// MARK: - Persistence Controller
public class PersistenceController {
    public static let shared = PersistenceController()
    
    public static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleCategory = Category(context: viewContext)
        sampleCategory.id = UUID()
        sampleCategory.name = "Personal"
        sampleCategory.color = "blue"
        sampleCategory.icon = "person"
        sampleCategory.createdAt = Date()
        
        let sampleTask = Task(context: viewContext)
        sampleTask.id = UUID()
        sampleTask.title = "Sample Task"
        sampleTask.notes = "This is a sample task for preview"
        sampleTask.dueDate = Date()
        sampleTask.category = sampleCategory
        sampleTask.priority = .medium
        sampleTask.estimateMinutes = 30
        sampleTask.isCompleted = false
        sampleTask.createdAt = Date()
        sampleTask.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    public let container: NSPersistentContainer
    
    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TaskLockModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    public func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    public func saveContext() {
        save()
    }
}
