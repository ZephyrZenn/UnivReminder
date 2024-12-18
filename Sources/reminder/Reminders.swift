/// This file is used for managing apple reminders

import EventKit
import Logging

enum ReminderError: Error {
  case accessDenied
  case noRemindersFound
  case saveFailed
  case unknownSource
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

extension CanvasToDo {
  func toStruct() -> CreateReminderReq {
    let title = self.plannable.title
    let notes = self.contextName
    let dueDate = self.plannable.dueAt?.description
    return CreateReminderReq(title: title, notes: notes, dueDate: dueDate)
  }
}

class ReminderManager {

  let store = EKEventStore()
  let calendarName: String
  let calendar: EKCalendar?
  var logger = Logger(label: "ReminderManager")

  init(calendarName: String = "UnivReminder") {
    self.calendarName = calendarName
    self.calendar = nil
  }

  func requestAccess() async throws {
    let granted: Bool
    if #available(macOS 14.0, *) {
      granted = try await store.requestFullAccessToReminders()
    } else {
      granted = try await store.requestAccess(to: .reminder)
    }
    guard granted else {
      logger.error("Access to reminders is denied")
      throw ReminderError.accessDenied
    }
  }

  /// Get or create a calendar for reminders. Use lazy init to avoid unnecessary creation
  /// - Throws: ReminderError
  /// - Returns: The calendar
  func getOrCreateCalendar() throws -> EKCalendar {
    // Lazy init. CLI tool don't need concurrent access to the store
    if let cal = self.calendar {
      return cal
    }
    let calendars = store.calendars(for: .reminder)
    if let calendar = calendars.first(where: { $0.title == calendarName }) {
      return calendar
    }
    let newCalendar = EKCalendar(for: .reminder, eventStore: store)
    newCalendar.title = calendarName
    // Assign the calendar to the default source
    if let defaultSource = store.defaultCalendarForNewReminders()?.source {
      newCalendar.source = defaultSource
    } else {
      // Fallback to a local source if default source is unavailable
      if let localSource = store.sources.first(where: { $0.sourceType == .local }) {
        newCalendar.source = localSource
      } else {
        logger.error("Failed to find a source for the calendar")
        throw ReminderError.unknownSource
      }
    }
    // Save the calendar
    try store.saveCalendar(newCalendar, commit: true)
    return newCalendar
  }

  func getReminders() async throws -> [Reminder] {
    let predict_ = store.predicateForIncompleteReminders(
      withDueDateStarting: nil, ending: nil, calendars: nil)

    guard let reminders = await store.fetchReminders(matching: predict_) else {
      logger.error("Fetch reminders failed")
      throw ReminderError.noRemindersFound
    }

    return reminders.map { $0.toStruct() }
  }

  /// Create a new reminder in apple reminders
  /// - Parameters:
  ///   - newReminder: The reminder to be created
  ///   - commit: Whether to commit the change to the store immediately
  /// - Throws: ReminderError
  func createReminder(newReminder: CreateReminderReq, commit: Bool) async throws {
    let reminder = EKReminder(eventStore: store)
    reminder.title = newReminder.title
    if let notes = newReminder.notes {
      reminder.notes = notes
    }
    if let dueDateString = newReminder.dueDate {
      if dueDateString.contains("T"),
        let dueDate = EventKitConstants.isoDateFormatter.date(from: dueDateString)
      {
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
    do {
      reminder.priority = Int(EKReminderPriority.medium.rawValue)
      reminder.calendar = try getOrCreateCalendar()
      try store.save(reminder, commit: commit)
    } catch {
      logger.error("Failed to save reminder: \(error)")
      throw ReminderError.saveFailed
    }
  }

  func commit() throws {
    try store.commit()
  }
}
