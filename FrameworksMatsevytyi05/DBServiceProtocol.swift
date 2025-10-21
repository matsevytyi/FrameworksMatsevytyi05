//
//  DBServiceProtocol.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 07.10.2025.
//

import Foundation
import Combine

// MARK: - Database Service Protocol
protocol DBServiceProtocol: ObservableObject {
    var tasks: [TodoTask] { get }
    var tasksPublisher: Published<[TodoTask]>.Publisher { get }

    // TodoTask CRUD
    func createTask(name: String, dueDate: Date, isNotify: Bool?, isPrivate: Bool?) throws
    func updateTask(_ task: TodoTask, name: String?, isDone: Bool?, dueDate: Date?, isNotify: Bool?, isPrivate: Bool?) throws
    func deleteTask(_ task: TodoTask) throws
    func fetchTasks()

    // TodoSubtask CRUD
    func createSubtask(name: String, for task: TodoTask) throws
    func updateSubtask(_ subtask: TodoSubtask, name: String?, isDone: Bool?) throws
    func deleteSubtask(_ subtask: TodoSubtask, from task: TodoTask) throws
}
