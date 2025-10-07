//
//  CoreDataService.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 07.10.2025.
//

import Foundation
import CoreData
import Combine

class CoreDataTodoService: DBServiceProtocol, ObservableObject {

    @Published var tasks: [TodoTask] = []
    var tasksPublisher: Published<[TodoTask]>.Publisher { $tasks }
    
    @Published var refreshID = UUID()

    //var context = PersistenceController.shared.container.viewContext
    private let context: NSManagedObjectContext

    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTasks()
    }

    // MARK: - TodoTask CRUD Operations
    func createTask(name: String, dueDate: Date) throws {
        
        let task = TodoTask(context: context)
        task.name = name
        task.isDone = false
        task.dueDate = dueDate

        try saveContext()
        fetchTasks()
    }

    func updateTask(_ task: TodoTask, name: String?, isDone: Bool?, dueDate: Date?) throws {
        print("🔄 === DEBUG START ===")
        print("BEFORE: task.isDone = \(task.isDone)")
        print("Context hasChanges BEFORE: \(context.hasChanges)")
        
        if let isDone = isDone { task.isDone = isDone }
        
        print("AFTER: task.isDone = \(task.isDone)")
        print("Context hasChanges AFTER: \(context.hasChanges)")
        
        try saveContext()
        print("Save completed")
        
        print("Calling fetchTasks...")
        fetchTasks()
        print("Tasks after fetch: \(tasks.count)")
        print("=== DEBUG END ===")
    }


    func deleteTask(_ task: TodoTask) throws {
        
        context.delete(task)
        try saveContext()
        fetchTasks()
    }

    func fetchTasks() {
        let request: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        
        do {
            let fetchedTasks = try context.fetch(request)
            
            DispatchQueue.main.async {
                print("BEFORE: tasks[0].isDone = \(self.tasks.first?.isDone ?? false)")
                
                self.objectWillChange.send()
                self.tasks.removeAll()
                self.tasks.append(contentsOf: fetchedTasks)
                
                self.refreshID = UUID()
                
                print(" AFTER: tasks[0].isDone = \(self.tasks.first?.isDone ?? false)")
            }
        } catch {
            print("Failed to fetch tasks: \(error)")
            DispatchQueue.main.async {
                self.tasks = []
            }
        }
    }


    // MARK: - TodoSubtask CRUD Operations
    func createSubtask(name: String, for task: TodoTask) throws {
        
        let subtask = TodoSubtask(context: context)
        subtask.name = name
        subtask.isDone = false
        //task.addToSubtasks(subtask)// зв'язок
        subtask.task = task

        try saveContext()
        fetchTasks()
    }

    func updateSubtask(_ subtask: TodoSubtask, name: String?, isDone: Bool?) throws {
        
        if let name = name { subtask.name = name }
        if let isDone = isDone { subtask.isDone = isDone }

        try saveContext()
        fetchTasks()
    }

    func deleteSubtask(_ subtask: TodoSubtask, from task: TodoTask) throws {
        
        context.delete(subtask)
        try saveContext()
        fetchTasks()
    }

    // MARK: - Helper Methods
    private func saveContext() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
            throw error
        }
    }
}
