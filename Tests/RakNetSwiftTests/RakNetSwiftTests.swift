import XCTest
@testable import RakNetSwift

final class RakNetSwiftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        do {
            let info = ServerInfo("RakNetSwift Test", "RakNetSwift", 409, "1.16.40", 0, 5, "Creative", 0)
            try Listener().listen(info)!.wait()
        } catch {
            
            //ignore
        }

    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
