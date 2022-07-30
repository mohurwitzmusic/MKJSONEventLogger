import Foundation
import os


open class MKJSONEventLogger {
        
    public struct EventLog: Codable, CustomDebugStringConvertible {
        public let identifier: LogIdentifier
        public let directoryURL: URL
        public fileprivate(set) var loggedEvents = [LoggedEvent]()
        fileprivate init(id: LogIdentifier, url: URL) {
            self.identifier = id
            self.directoryURL = url
        }
        public var debugDescription: String {
            return "EventLog: identifier: \(identifier), url: \(directoryURL), events: \(loggedEvents.count)"
        }
    }
    
    public struct LoggedEvent: Codable {
        let message: String
        let timestamp: String
    }
    
    public struct LogIdentifier: Codable {
        let subsystem: String
        let loggingCategory: String
    }
    
    private let osLog: Logger
    private var eventLog: EventLog
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .short
        return df
    }()
    
    /// Initializes a new logger instance.
    ///
    /// - Parameters:
    ///    - identifier: The unique identifer for the logger. Used to generate the file name. Use reverse DNS notation to ensure uniqueness.
    ///    - directoryURL: The directory in which the logger will be written to disk.
    ///
    
    public init(identifier: LogIdentifier, directoryURL: URL) {
        self.eventLog = .init(id: identifier, url: directoryURL)
        self.osLog = Logger(subsystem: identifier.subsystem, category: identifier.loggingCategory)
    }
    
    public enum LogLevel: Equatable {
        case `default`
        case error
        case warning
        
        fileprivate var osLogType: OSLogType {
            switch self {
            case .default:
                return .default
            case .error:
                return .error
            case .warning:
                return .fault
            }
        }
    }
    
    public func retrieveLog() throws -> EventLog {
        do {
            let data = try Data(contentsOf: fileURL())
            return try JSONDecoder().decode(EventLog.self, from: data)
        } catch {
            throw error
        }
    }

    public func log(_ level: LogLevel, _ msg: String) {
        Task {
            var exists = ObjCBool(false)
            FileManager.default.fileExists(atPath: eventLog.directoryURL.path, isDirectory: &exists)
            guard exists.boolValue else {
                osLog.log("Logging failed to write event to disk: the directory did not exist. Did you create one? \(self.eventLog.debugDescription)")
                return
            }
            osLog.log(level: level.osLogType, "\(msg)")
            if eventLog.loggedEvents.count > 100 {
                eventLog.loggedEvents.removeSubrange(0...50)
            }
            let event = LoggedEvent(message: msg, timestamp: dateFormatter.string(from: Date()))
            eventLog.loggedEvents.append(event)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try? encoder.encode(eventLog)
            let url = fileURL()
            try? data?.write(to: url)
        }

    }
    
    private func fileURL() -> URL {
        let fileName = eventLog.identifier.loggingCategory + "-" + eventLog.identifier.subsystem
        return eventLog.directoryURL.appendingPathComponent(fileName).appendingPathExtension("json")
    }
}

