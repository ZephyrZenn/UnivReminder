/// Some extension of EventKit
import EventKit

struct EventKitConstants {
  static let reminderAppURL = "x-apple-reminderkit://"
  static let isoDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  static let dateOnlyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  static let monthSymbols = DateFormatter().monthSymbols

  static let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter
  }()

}

extension EKReminderPriority {
  var displayString: String {
    switch self {
    case .low:
      return "low"
    case .medium:
      return "medium"
    case .high:
      return "high"
    default:
      return ""
    }
  }
}

extension EKReminder {
  func toStruct() -> Reminder {
    var dueDateString: String = ""
    if let dueDateComponents,
      let dueDate = Calendar.current.date(from: dueDateComponents)
    {
      let hasTime = (dueDateComponents.hour != nil && dueDateComponents.minute != nil)
      if hasTime {
        dueDateString = EventKitConstants.isoDateFormatter.string(for: dueDate) ?? ""
      } else {
        dueDateString = EventKitConstants.dateOnlyFormatter.string(for: dueDate) ?? ""
      }
    }

    let reminderPriority = EKReminderPriority(rawValue: UInt(self.priority)) ?? .none

    return Reminder(
      id: self.calendarItemIdentifier,
      title: self.title,
      notes: self.notes ?? "",
      dueDate: dueDateString,
      completed: self.isCompleted,
      priority: reminderPriority.displayString,
      url: "x-apple-reminderkit://REMCDReminder/\(self.calendarItemIdentifier)"
    )
  }
}

extension EKEventStore {
  func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder]? {
    await withCheckedContinuation { continuation in
      fetchReminders(matching: predicate) { reminders in
        continuation.resume(returning: reminders)
      }
    }
  }
}
