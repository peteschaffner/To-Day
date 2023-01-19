//
//  DataStore.swift
//  Today
//
//  Created by Sarah Reichelt on 17/1/2023.
//

import Foundation

struct DataStore {
  func saveTodos(todos: [Todo]) {
    let fileURL = URL.documentsDirectory.appending(component: "todos.json")
    do {
      let data = try JSONEncoder().encode(todos)
      try data.write(to: fileURL)
    } catch {
      print(error)
    }
  }

  func loadTodos() -> [Todo] {
    let fileURL = URL.documentsDirectory.appending(component: "todos.json")

    do {
      let data = try Data(contentsOf: fileURL)
      let todos = try JSONDecoder().decode([Todo].self, from: data)
        .sorted(using: KeyPathComparator(\.id))
      return todos
    } catch {
      print(error)
    }

    return Todo.sampleToDos
  }
}