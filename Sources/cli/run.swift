/// Subcommand run for synchronizing Canvas todos to Reminders
import ArgumentParser

struct RunCommand: AsyncParsableCommand {

  static var configuration = CommandConfiguration(
    commandName: "run",
    abstract: "Synchronize Canvas todos to Apple reminders"
  )

  func validate() throws {
    // check if the user has set the canvas token and apple account
    guard ConfigManager.shared.get(key: CLIConstant.TOKEN_KEY) != nil else {
      throw CLIError.missingConfig(
        "Please set your canvas token using `univcli config set token <token>`")
    }
  }

  func run() async throws {

    let canvasManager = CanvasManager(
      token: ConfigManager.shared.get(key: CLIConstant.TOKEN_KEY)!,
      known_todo_ids_path: CLIConstant.KNOWN_TODO_IDS_PATH)

    let reminderManager = ReminderManager()
    do {
      print("Requesting access to reminders")
      try await reminderManager.requestAccess()
      print("Getting todos from Canvas")
      let todos = try await canvasManager.getToDo()
      if todos.isEmpty {
        print("No todo needs to be synced")
        return
      }
      print("Find \(todos.count) new reminders. Preparing to create reminders")
      for todo in todos {
        try await reminderManager.createReminder(newReminder: todo.toStruct())
      }
    } catch {
      print(error)
    }
  }

}
