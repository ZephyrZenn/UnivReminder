/// The main entry point for the CLI
import ArgumentParser
import EventKit
import Foundation

struct CLIConstant {
  static let TOKEN_KEY = "token"
  static let ROOT_DIR = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
    ".univreminder")
  static let CONFIG_PATH = ROOT_DIR.appendingPathComponent("config.json")
  static let KNOWN_TODO_IDS_PATH = ROOT_DIR.appendingPathComponent("known_todo_ids")
}

enum CLIError: Error {
  case missingConfig(String)
}

@main
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct UnivReminderCLI: AsyncParsableCommand {
  static let configuration: CommandConfiguration = CommandConfiguration(
    commandName: "univcli",
    abstract: "A CLI for synchronizing Canvas todos to Apple reminders",
    subcommands: [ConfigCommand.self, RunCommand.self]
  )
}
