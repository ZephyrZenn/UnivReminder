import Foundation
import SwiftDotenv

func run() async {
  // let manager = ReminderManager()
  // do {
  //     print("Trying to get permission")
  //     try await manager.requestAccess()
  //     print("Going to fetch reminders")
  //     let reminders = try await manager.getReminders()
  //     print(reminders)
  // } catch {
  //     print(error)
  // }
  // print("Done")
  try! Dotenv.configure()
  guard let token = Dotenv["canvas_token"] else {
    print("Can't find canvas token")
    return
  }
  let canvasManager = CanvasManager(
    token: token.stringValue)
  do {
    let todos = try await canvasManager.getToDo()
    print(todos.count)
  } catch {
    print(error)
  }
}

Task {
  await run()
}

sleep(10)
