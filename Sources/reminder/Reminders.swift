/// This file is used for managing apple reminders

import EventKit

enum ReminderError: Error {
  case accessDenied
  case noRemindersFound
  case saveFailed
}

// Customized Reminder struct for antiseptic
struct Reminder: Codable {
  var id: String
  var title: String
  var notes: String?
  var dueDate: String?
  var completed: Bool
  var priority: String
  var url: String
}

struct CreateReminderReq {
  var title: String
  var notes: String?
  var dueDate: String?
}

class ReminderManager {

  let store = EKEventStore()

  init() {

  }

  func requestAccess() async throws {
    let granted: Bool
    if #available(macOS 14.0, *) {
      granted = try await store.requestFullAccessToReminders()
    } else {
      granted = try await store.requestAccess(to: .reminder)
    }
    guard granted else {
      throw ReminderError.accessDenied
    }
  }

  func getReminders() async throws -> [Reminder] {
    let predict_ = store.predicateForIncompleteReminders(
      withDueDateStarting: nil, ending: nil, calendars: nil)

    guard let reminders = await store.fetchReminders(matching: predict_) else {
      throw ReminderError.noRemindersFound
    }

    return reminders.map { $0.toStruct() }
  }

  func createReminder(newReminder: CreateReminderReq) async throws {
    let reminder = EKReminder(eventStore: store)
    reminder.title = newReminder.title
    if let notes = newReminder.notes {
      reminder.notes = notes
    }
    if let dueDateString = newReminder.dueDate {
      if dueDateString.contains("T"), let dueDate = EventKitConstants.isoDateFormatter.date(from: dueDateString) {
        reminder.dueDateComponents = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute, .second],
          from: dueDate
        )
        reminder.addAlarm(EKAlarm(absoluteDate: dueDate))
      } else if let dueDate = EventKitConstants.dateOnlyFormatter.date(from: dueDateString) {
        reminder.dueDateComponents = Calendar.current.dateComponents(
          [.year, .month, .day],
          from: dueDate
        )
      }
    }
    reminder.priority = Int(EKReminderPriority.medium.rawValue)
    do {
      try store.save(reminder, commit: true)
    } catch {
      throw ReminderError.saveFailed
    }
  }
}
