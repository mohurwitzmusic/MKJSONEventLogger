import XCTest
@testable import MKJSONEventLogger

final class MKJSONEventLoggerTests: XCTestCase {
    
    func test_writeMessageToDisk() {
        let url = FileManager.default.temporaryDirectory
        let logger = MKJSONEventLogger(identifier: .init(subsystem: "com.mkeventlogger", loggingCategory: "unit-test"), directoryURL: url)
        logger.log(.default, "This is a test message")
        logger.log(.default, "This is another test message")
        do {
            let log = try logger.retrieveLog()
            XCTAssertEqual(log.loggedEvents.count, 2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
