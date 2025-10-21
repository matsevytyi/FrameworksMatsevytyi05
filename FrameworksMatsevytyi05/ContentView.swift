//
//  ContentView.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 07.10.2025.
//


import SwiftUI
import CoreData

// MARK: - Preview
#Preview {
//    ContentView()
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    LoginView()
}



struct LoginView: View {
    
    @State private var posta = ""
    @State private var password = ""
    
    @EnvironmentObject var authService: AuthService
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Схоже ви не авторизовані. Введіть номер і пароль банківської картки і не надокучатиму вам наступного разу :)")
                .font(.title)
                .bold()

            TextField("Пошта", text: $posta)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .typesettingLanguage(Locale.Language.init(identifier: "uk"))
                .padding(.horizontal)

            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Login") {
                print("Лог with \(posta), \(password)")
                Task {
                    let success = await authService.login(poshta: posta, password: password)
                    if !success {
                        errorMessage = "Invalid credentials"
                    } else {
                        authService.isAuthenticated = true
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .padding()
    }
}

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var context
    @StateObject private var databaseService: CoreDataTodoService
    
    @State private var observer: NSObjectProtocol?
    
    @State private var showingAddTask = false
    @State private var showingNotificationsList = false

    init() {
        _databaseService = StateObject(wrappedValue: CoreDataTodoService(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(databaseService.tasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task, service: databaseService)
                    ) {
                        TodoTaskRowView(task: task, service: databaseService)
                    }
                }
                .onDelete(perform: deleteTask)
                .id(databaseService.refreshID)
            }
            .navigationTitle("Список справ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Label("Додати", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNotificationsList = true }) {
                        Label("Оновлення", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear() {
                observer = NotificationCenter.default.addObserver(forName: Notification.Name("didAcceptInboxTodo"), object: nil, queue: .main) { notification in
                        guard let info = notification.userInfo,
                              let name = info["name"] as? String,
                              let due = info["due"] as? Date else { return }
                        print("passed data: \(name), \(due)")
                        try? databaseService.createTask(name: name, dueDate: due, isNotify: true)
                        }

            }
            .onDisappear(){
            if let observer = observer {
                            NotificationCenter.default.removeObserver(observer)
                        }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(service: databaseService)
            }
            .sheet(isPresented: $showingNotificationsList) {
                InboxView(notificationService: NotificationService.shared)
            }
        }
    }

    private func deleteTask(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let task = databaseService.tasks[index]
                do {
                    try databaseService.deleteTask(task)
                } catch {
                    print("Error deleting task: \(error)")
                }
            }
        }
    }
}

// MARK: - Todo Task Row View
struct TodoTaskRowView: View {
    let task: TodoTask
    let service: CoreDataTodoService

    var body: some View {
        HStack {
            // Toggle button
            Button(action: toggleTask) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isDone ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name ?? "Без назви")
                    .font(.headline)
                    .strikethrough(task.isDone)
                    .foregroundColor(task.isDone ? .secondary : .primary)

                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Subtasks count
                let subtasksSet = task.subtasks as? Set<TodoSubtask> ?? Set()
                if !subtasksSet.isEmpty {
                    let completedCount = subtasksSet.filter { $0.isDone }.count
                    Text("\(completedCount)/\(subtasksSet.count) підзавдань")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Status indicator
            if task.isDone {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            } else if let dueDate = task.dueDate, dueDate < Date() {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 2)
    }

    private func toggleTask() {
        withAnimation(.easeInOut(duration: 0.2)) {
            do {
                try service.updateTask(task, name: nil, isDone: !task.isDone, dueDate: nil, isNotify: !task.isNotify)
            } catch {
                print("Error updating task: \(error)")
            }
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    let service: CoreDataTodoService
    @Environment(\.dismiss) private var dismiss

    @State private var taskName = ""
    @State private var dueDate = Date().addingTimeInterval(24*60*60) // Tomorrow by default
    @State private var isNotify = false
    

    var body: some View {
        NavigationView {
            Form {
                Section("Нове завдання") {
                    TextField("Назва завдання", text: $taskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    DatePicker("Термін виконання",
                             selection: $dueDate,
                               displayedComponents: [.date, .hourAndMinute])
                    Toggle("Сповістити", isOn: $isNotify)
                }

                Section {
                    Button("Створити завдання") {
                        createTask()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(taskName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .disabled(taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Нове завдання")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }
                }
            }
        }
    }

    private func createTask() {
        let trimmedName = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            try service.createTask(name: trimmedName, dueDate: dueDate, isNotify: isNotify)
            updateNotification()
            dismiss()
        } catch {
            print("Error creating task: \(error)")
        }
    }
    private func updateNotification() {
        if NotificationService.shared.permissionPending { NotificationService.shared.requestAuthorization() }
        if isNotify, dueDate > .now {
            NotificationService.shared.scheduleNotification(id: taskName, title: taskName, dueDate: dueDate)
            print("task scheduled")
        } else {
            NotificationService.shared.cancelNotification(id: taskName)
            print("schedule canceled")
        }

    }
}

// MARK: - Task Detail View
struct TaskDetailView: View {
    let task: TodoTask
    let service: CoreDataTodoService
    @State private var showingAddSubtask = false
    @State private var showingEditTask = false

    var body: some View {
        List {
            Section("Завдання") {
                HStack {
                    Text("Статус:")
                    Spacer()
                    Text(task.isDone ? "Виконано" : "В процесі")
                        .foregroundColor(task.isDone ? .green : .orange)
                        .fontWeight(.semibold)
                }

                if let dueDate = task.dueDate {
                    HStack {
                        Text("Термін:")
                        Spacer()
                        Text(dueDate, style: .date)
                            .foregroundColor(dueDate < Date() && !task.isDone ? .red : .secondary)
                    }
                }
                
                HStack {
                    Text("Сповістити:")
                    Spacer()
                    Text(task.isNotify ? "Так" : "Ні")
                }
                
            }

            Section("Підзавдання") {
                let subtasksArray = (task.subtasks as? Set<TodoSubtask>)?.sorted {
                    ($0.name ?? "") < ($1.name ?? "")
                } ?? []

                if subtasksArray.isEmpty {
                    Text("Немає підзавдань")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(subtasksArray, id: \.id) { subtask in
                        SubtaskRowView(subtask: subtask, service: service)
                    }
                    .onDelete(perform: deleteSubtask)
                }

                Button(action: { showingAddSubtask = true }) {
                    Label("Додати підзавдання", systemImage: "plus.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle(task.name ?? "Завдання")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Редагувати") {
                    showingEditTask = true
                }
            }
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task, service: service)
        }
        .sheet(isPresented: $showingAddSubtask) {
            AddSubtaskView(task: task, service: service)
        }
    }

    private func deleteSubtask(offsets: IndexSet) {
        let subtasksArray = (task.subtasks as? Set<TodoSubtask>)?.sorted {
            ($0.name ?? "") < ($1.name ?? "")
        } ?? []

        for index in offsets {
            let subtask = subtasksArray[index]
            do {
                try service.deleteSubtask(subtask, from: task)
            } catch {
                print("Error deleting subtask: \(error)")
            }
        }
    }
}

// MARK: - Subtask Row View
struct SubtaskRowView: View {
    let subtask: TodoSubtask
    let service: CoreDataTodoService

    var body: some View {
        HStack {
            Button(action: toggleSubtask) {
                Image(systemName: subtask.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.isDone ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            Text(subtask.name ?? "")
                .strikethrough(subtask.isDone)
                .foregroundColor(subtask.isDone ? .secondary : .primary)

            Spacer()
        }
    }

    private func toggleSubtask() {
        do {
            try service.updateSubtask(subtask, name: nil, isDone: !subtask.isDone)
        } catch {
            print("Error updating subtask: \(error)")
        }
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    let task: TodoTask
    let service: CoreDataTodoService
    @Environment(\.dismiss) private var dismiss

    @State private var taskName: String
    @State private var dueDate: Date
    @State private var isDone: Bool
    @State private var isNotify: Bool

    init(task: TodoTask, service: CoreDataTodoService) {
        self.task = task
        self.service = service
        self._taskName = State(initialValue: task.name ?? "")
        self._dueDate = State(initialValue: task.dueDate ?? Date())
        self._isDone = State(initialValue: task.isDone)
        self._isNotify = State(initialValue: task.isNotify)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Редагувати завдання") {
                    TextField("Назва", text: $taskName)
                    DatePicker("Термін", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Виконано", isOn: $isDone)
                    Toggle("Сповістити:", isOn: $isNotify)
                }
            }
            .navigationTitle("Редагувати")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Зберегти") {
                        updateNotification()
                        saveTask()
                    }
                }
            }
        }
    }
    
    private func updateNotification() {
        if NotificationService.shared.permissionPending { NotificationService.shared.requestAuthorization() }
        if isNotify, dueDate > .now, isDone == false {
            NotificationService.shared.scheduleNotification(id: taskName, title: taskName, dueDate: dueDate)
            print("task scheduled")
        } else {
            NotificationService.shared.cancelNotification(id: taskName)
            print("schedule canceled")
        }

    }


    private func saveTask() {
        do {
            try service.updateTask(task, name: taskName, isDone: isDone, dueDate: dueDate, isNotify: isNotify)
            dismiss()
        } catch {
            print("Error updating task: \(error)")
        }
    }
}

// MARK: - Add Subtask View
struct AddSubtaskView: View {
    let task: TodoTask
    let service: CoreDataTodoService
    @Environment(\.dismiss) private var dismiss

    @State private var subtaskName = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Нове підзавдання") {
                    TextField("Назва підзавдання", text: $subtaskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle("Підзавдання")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Додати") {
                        createSubtask()
                    }
                    .disabled(subtaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func createSubtask() {
        let trimmedName = subtaskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            try service.createSubtask(name: trimmedName, for: task)
            dismiss()
        } catch {
            print("Error creating subtask: \(error)")
        }
    }
}
