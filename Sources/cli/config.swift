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
    var path: URL
    if #available(macOS 13.0, *) {
      path = FileManager.default.homeDirectoryForCurrentUser.appending(
        component: ".univreminder", directoryHint: URL.DirectoryHint.isDirectory
      ).appending(component: "config.json", directoryHint: URL.DirectoryHint.notDirectory)
    } else {
      // Fallback on earlier versions
      path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
        ".univreminder"
      ).appendingPathComponent("config.json")
    }
    if FileManager.default.fileExists(atPath: path.path) {
      do {

        let data = try Data(contentsOf: path)
        config = try JSONDecoder().decode([String: String].self, from: data)
      } catch {
        print(error)
      }
    } else {
      let parent = path.deletingLastPathComponent()
      if !FileManager.default.fileExists(atPath: parent.path) {
        try! FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
      }
      print("Creating config file")
      try! "{}".write(to: path, atomically: true, encoding: String.Encoding.utf8)
    }
  }

  deinit {
    save()
  }

  func save() {
    var path: URL
    if #available(macOS 13.0, *) {
      path = FileManager.default.homeDirectoryForCurrentUser.appending(
        component: ".univreminder", directoryHint: URL.DirectoryHint.isDirectory
      ).appending(component: "config.json", directoryHint: URL.DirectoryHint.notDirectory)
    } else {
      // Fallback on earlier versions
      path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
        ".univreminder"
      ).appendingPathComponent("config.json")
    }
    let data = try! JSONEncoder().encode(config)
    try! data.write(to: path)
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
