import XCTest
@testable import VueFlux

final class StorageTests: XCTestCase {
    func testStorage() {
        var value = 0
        var storage = Storage<() -> Void>()
        
        let f1 = {
            value += 1
        }
        
        let f2 = {
            value += 10
        }
        
        let key1 = storage.add(f1)
        let key2 = storage.add(f2)
        
        for f in storage { f() }
        
        XCTAssertEqual(value, 11)
        
        storage.remove(for: key1)
        
        for f in storage { f() }
        
        XCTAssertEqual(value, 21)
        
        storage.remove(for: key2)
        
        for f in storage { f() }
        
        XCTAssertEqual(value, 21)
    }
}
