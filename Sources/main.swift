import Foundation
import SwiftDotenv

func run() async {
  try! Dotenv.configure()
  guard let token = Dotenv["canvas_token"] else {
    print("Can't find canvas token")
    return
  }
  let canvasManager = CanvasManager(
    token: token.stringValue)
  let reminderManager = ReminderManager()
  do {
    try await reminderManager.requestAccess()
    let todos = try await canvasManager.getToDo()
    let todo = todos[0]
    try await reminderManager.createReminder(newReminder: todo.toStruct())
  } catch {
    print(error)
  }
}

await run()
