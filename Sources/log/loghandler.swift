import Foundation
import Logging

class FileLogHandler: LogHandler {

  var metadata: Logging.Logger.Metadata

  var logLevel: Logging.Logger.Level

  let fileHandle: FileHandle?

  private let queue = DispatchQueue(label: "FileLogHandlerQueue")

  init(logPath: URL) {
    self.metadata = [:]
    self.logLevel = .info
    let parent = logPath.deletingLastPathComponent()
    do {
      if !FileManager.default.fileExists(atPath: parent.path) {
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
      }
      if !FileManager.default.fileExists(atPath: logPath.path) {
        try "".write(to: logPath, atomically: true, encoding: String.Encoding.utf8)
      }
    } catch {
      print("Failed to create log file: \(error)")
    }

    self.fileHandle = try? FileHandle(forWritingTo: logPath)
    try! self.fileHandle?.seekToEnd()
  }

  deinit {
    self.fileHandle?.closeFile()
  }

  public func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata?,
    source: String,
    file: String,
    function: String,
    line: UInt
  ) {
    let combinedMetadata = self.metadata.merging(metadata ?? [:]) { (_, new) in new }

    let logMessage =
      "\(ISO8601DateFormatter().string(from: Date())) [\(level)] \(message) \(combinedMetadata)\n"

    if let data = logMessage.data(using: .utf8) {
      queue.async { [weak self] in
        self?.fileHandle?.write(data)
      }
    }
  }

  subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
    get {
      return metadata[key]
    }
    set(newValue) {
      metadata[key] = newValue
    }
  }

}
