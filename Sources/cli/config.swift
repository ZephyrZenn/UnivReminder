import ArgumentParser
/// This file contains the implementation of the config subcommand
import Foundation

struct ConfigCommand: ParsableCommand {
  static let configuration: CommandConfiguration = CommandConfiguration(
    commandName: "config",
    abstract: "Set the configuration for UnivReminder",
    subcommands: [Set.self, Get.self]
  )

}

struct Set: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "set",
    abstract: "Set a configuration value."
  )

  @Argument(help: "The configuration key to set.")
  var key: String

  @Argument(help: "The value to set for the key.")
  var value: String

  func run() throws {
    ConfigManager.shared.set(key: key, value: value)
  }
}

struct Get: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "get",
    abstract: "Get a configuration value."
  )

  @Argument(help: "The configuration key to get.")
  var key: String

  func run() throws {
    guard let value = ConfigManager.shared.get(key: key) else {
      print("No value found for key \(key)")
      return
    }
    print(value)
  }
}

class ConfigManager {
  static let shared = ConfigManager()
  private var config: [String: String] = [:]

  private init() {
    let path = CLIConstant.CONFIG_PATH
    if FileManager.default.fileExists(atPath: path.path) {
      do {

        let data = try Data(contentsOf: path)
        config = try JSONDecoder().decode([String: String].self, from: data)
      } catch {
        print(error)
      }
    } else {
      print("Didn't find config file. Try to initialize a new one")
      let parent = path.deletingLastPathComponent()
      if !FileManager.default.fileExists(atPath: parent.path) {
        try! FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
      }
      try! "{}".write(to: path, atomically: true, encoding: String.Encoding.utf8)
    }
  }

  func save() {
    let data = try! JSONEncoder().encode(config)
    try! data.write(to: CLIConstant.CONFIG_PATH)
  }

  func get(key: String) -> String? {
    return config[key]
  }

  func set(key: String, value: String) {
    config[key] = value
    // The deinit may not be called when the program is terminated. So I invoke save here explicitly
    save()
  }
}
