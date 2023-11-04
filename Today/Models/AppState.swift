//
//  AppState.swift
//  To-Day
//
//  Created by Sarah Reichelt on 20/1/2023.
//

import SwiftUI

// MARK: - Properties

class AppState: ObservableObject {
  @Published var todos: [Todo] = DataStore().loadTodos() {
    didSet {
      debouncedSave()
    }
  }

  @AppStorage("sortCompletedToEnd") var sortCompletedToEnd = true

  var dataStore = DataStore()
  var saveTask: DispatchWorkItem?

  func debouncedSave() {
    self.saveTask?.cancel()

    let task = DispatchWorkItem { [todos, weak self] in
      DispatchQueue.global(qos: .background).async { [weak self] in
        if let self {
          self.dataStore.saveTodos(todos: todos)
        }
      }
    }

    self.saveTask = task
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)
  }
}

// MARK: - Computed Properties

extension AppState {
  var sortedTodos: [Todo] {
    if sortCompletedToEnd {
      return todos.sorted(using: KeyPathComparator(\.sortProperty))
    } else {
      return todos.sorted(using: KeyPathComparator(\.order))
    }
  }

  var allComplete: Bool {
    let totalTodos = todos.count
    let completedTodos = todos.filter { $0.isComplete }.count
    return totalTodos == completedTodos
  }

  var allIncomplete: Bool {
    let completedTodos = todos.filter { $0.isComplete }.count
    return completedTodos == 0
  }

  var todoButtons: some View {
    ForEach(sortedTodos) { todo in
      Button {
        self.toggleComplete(todo.id)
      } label: {
        Text(todo.wrappedTitle)
          .foregroundColor(todo.isComplete ? .secondary : .primary)
          .strikethrough(todo.isComplete ? true : false)
      }
    }
  }

  var menuTitle: some View {
    let title: String
    let totalTodos = todos.count
    let completedTodos = todos.filter { $0.isComplete }.count

    if totalTodos == 0 {
      title = "To-Day"
    } else if completedTodos == totalTodos {
      title = "All Done"
    } else {
      title = "\(completedTodos) of \(totalTodos) done"
    }

    return HStack {
      Text(title).monospacedDigit()
    }
  }
}

// MARK: - Methods

extension AppState {
  func createNewTodo(title: String) {
    let maxOrder = todos.reduce(0) { partialResult, todo in
      max(partialResult, todo.order)
    }
    let newTodo = Todo(order: maxOrder + 1, title: title)
    todos.append(newTodo)
  }

  func deleteTodo(_ todo: Todo) {
    todos.removeAll {
      $0.id == todo.id
    }
  }

  func deleteAll() {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "Really delete all the todos?"
    alert.addButton(withTitle: "Delete")
    alert.addButton(withTitle: "Cancel")

    NSApp.activate(ignoringOtherApps: true)

    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
      todos = []
    }
  }

  func toggleComplete(_ id: UUID) {
    let todoIndex = todos.firstIndex {
      $0.id == id
    }
    if let todoIndex {
      todos[todoIndex].isComplete.toggle()
    }
  }

  func markAll(complete: Bool) {
    for index in 0 ..< todos.count {
      todos[index].isComplete = complete
    }
  }
}
