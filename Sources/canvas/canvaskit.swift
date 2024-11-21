// Get ToDo list from Canvas

import Foundation

struct CanvasConstants {
  static let TODO_URL = "https://canvas.nus.edu.sg/api/v1/planner/items"
  static let TODO_INTERVAL = 60 * 60 * 24 * 30
  static let PER_PAGE = 100
  static let ASSIGNMENT_TYPE_STR = "assignment"
}

struct CanvasToDo: Codable {
  var plannableType: String
  var submissions: SubmissionsUnion
  var plannableDate: String
  var plannable: Plannable
  var contextName: String
}

struct Plannable: Codable {
  var id: Int
  var title: String
  var dueAt: Date?
}

enum SubmissionsUnion: Codable {
  case bool(Bool)
  case submissionsClass(SubmissionRecord)

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let boolValue = try? container.decode(Bool.self) {
      self = .bool(boolValue)
      return
    }
    if let submission = try? container.decode(SubmissionRecord.self) {
      self = .submissionsClass(submission)
      return
    }
    self = .bool(false)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .bool(let boolValue):
      try container.encode(boolValue)
    case .submissionsClass(let submission):
      try container.encode(submission)
    }
  }
}

extension SubmissionsUnion: Equatable {
  static func == (lhs: SubmissionsUnion, rhs: SubmissionsUnion) -> Bool {
    switch (lhs, rhs) {
    case let (.bool(lhsFlag), .bool(rhsFlag)):
      return lhsFlag == rhsFlag
    case let (.submissionsClass(lhsSubmission), .submissionsClass(rhsSubmission)):
      return lhsSubmission == rhsSubmission
    default:
      return false
    }
  }
}

struct SubmissionRecord: Codable, Equatable {
  let submitted, excused, graded: Bool
  let postedAt: Date
  let late, missing, needsGrading, hasFeedback: Bool
  let redoRequest: Bool
}

enum CanvasError: Error {
  case initError(Error)
  case errorResponse(statusCode: Int)
  case decodingError
}

class CanvasManager {

  let token: String
  // id of todos that are already known
  var known_todo_ids: [Int]
  let known_todo_ids_path: String
  // a flag to indicate if the manager has got the known todo ids
  var init_flag: Bool

  init(token: String, known_todo_ids_path: String = "known_todo_ids.txt") {
    self.token = "Bearer \(token)"
    self.known_todo_ids_path = known_todo_ids_path
    self.known_todo_ids = []
    self.init_flag = false
  }

  /// write new todo ids to the file when program exits
  // TODO: don't store known_todo_ids if save to apple reminders failed
  deinit {
    let text = self.known_todo_ids.map { id in
      String(id)
    }.joined(separator: ",")
    do {
      try text.write(toFile: self.known_todo_ids_path, atomically: true, encoding: .utf8)
    } catch {
      print("failed to write known_todo_ids to file")
    }
  }

  /// Initialize known_todo_ids from the file. Lazy init
  /// - Throws: initError
  func init_known_todo_ids() async throws {
    // check if the file exists
    if !FileManager.default.fileExists(atPath: self.known_todo_ids_path) {
      let t = FileManager.default.createFile(
        atPath: self.known_todo_ids_path, contents: nil, attributes: nil)
      if !t {
        throw CanvasError.initError(
          NSError(
            domain: "CreateFileError", code: 1,
            userInfo: ["msg": "failed to create known_todo_ids file"]))
      }
      init_flag = true
      return
    }
    do {
      let text = try String(contentsOfFile: self.known_todo_ids_path)
      text.split(separator: ",").forEach { id in
        self.known_todo_ids.append(Int(id)!)
      }
      self.init_flag = true
    } catch {
      throw CanvasError.initError(error)
    }
  }

  /// Get ToDo list from Canvas
  /// - Throws: CanvasError
  /// - Returns: CanvasToDo array
  func getToDo() async throws -> [CanvasToDo] {
    let startDate = Date(timeIntervalSinceNow: -Double(CanvasConstants.TODO_INTERVAL))
    let url_param =
      "\(CanvasConstants.TODO_URL)?start_date=\(startDate.ISO8601Format())&per_page=\(CanvasConstants.PER_PAGE)"
    let url = URL(string: url_param)!
    var req = URLRequest(url: url)
    req.allHTTPHeaderFields = ["Authorization": self.token]
    req.httpMethod = "GET"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let (data, resp) = try await URLSession.shared.data(for: req)
    if let httpResponse = resp as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
      throw CanvasError.errorResponse(statusCode: httpResponse.statusCode)
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    var todos: [CanvasToDo]
    do {
      todos = try decoder.decode([CanvasToDo].self, from: data).filter { todo in
        todo.plannableType == CanvasConstants.ASSIGNMENT_TYPE_STR
          && todo.submissions == .bool(false)
      }
    } catch {
      print(error)
      throw CanvasError.decodingError
    }
    // initialize known_todo_ids if not done
    if !self.init_flag {
      try await self.init_known_todo_ids()
    }
    // filter out todos that are already known
    todos = todos.filter { todo in
      !self.known_todo_ids.contains(todo.plannable.id)
    }
    // write the new todo ids to the file
    self.known_todo_ids.append(
      contentsOf: todos.map { todo in
        todo.plannable.id
      })
    return todos
  }
}
