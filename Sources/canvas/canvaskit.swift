// Get ToDo list from Canvas

import Foundation

struct CanvasConstants {
  static let TODO_URL = "https://canvas.nus.edu.sg/api/v1/planner/items"
  static let TODO_INTERVAL = 60 * 60 * 24 * 30
  static let PER_PAGE = 100
}

struct CanvasToDo: Codable {
  var plannableType: String
  var submissions: SubmissionsUnion
  var plannableDate: String
  var plannable: Plannable
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

struct SubmissionRecord: Codable {
  let submitted, excused, graded: Bool
  let postedAt: Date
  let late, missing, needsGrading, hasFeedback: Bool
  let redoRequest: Bool
}

enum CanvasError: Error {
  case errorResponse(statusCode: Int)
  case decodingError
}

class CanvasManager {

  var token: String

  init(token: String) {
    self.token = "Bearer \(token)"
  }

  func getToDo() async throws -> [CanvasToDo] {
    let startDate = Date(timeIntervalSinceNow: -Double(CanvasConstants.TODO_INTERVAL))
    let url_param = "\(CanvasConstants.TODO_URL)?start_date=\(startDate.ISO8601Format())&per_page=\(CanvasConstants.PER_PAGE)"
    let url = URL(string: url_param)!
    var req = URLRequest(url: url)
    req.allHTTPHeaderFields = ["Authorization": self.token]
    req.httpMethod = "GET"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let (data, resp) = try await URLSession.shared.data(for: req)
    if let httpResponse = resp as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
      throw CanvasError.errorResponse(statusCode: httpResponse.statusCode)
    }
    do {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      decoder.dateDecodingStrategy = .iso8601
      let todos = try decoder.decode([CanvasToDo].self, from: data)
      return todos.filter { todo in
        todo.plannableType == "assignment"
      }
    } catch {
      print(error)
      throw CanvasError.decodingError
    }
  }
}
