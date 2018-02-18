import XCTest
@testable import VueFlux

final class StorageTests: XCTestCase {
    func testStorage() {
        var storage = Storage<Int>()
        
        let additionValue1 = 1
        let additionValue2 = 2
        
        let key1 = storage.add(additionValue1)
        let key2 = storage.add(additionValue2)
        
        XCTAssertEqual(storage[0], additionValue1)
        XCTAssertEqual(storage[1], additionValue2)
        
        var targetValue1 = 0
        for additionValue in storage {
            targetValue1 += additionValue
        }
        
        XCTAssertEqual(targetValue1, additionValue1 + additionValue2)
        
        let removed1 = storage.remove(for: key1)
        XCTAssertEqual(removed1, additionValue1)
        
        var targetValue2 = 0
        for additionValue in storage {
            targetValue2 += additionValue
        }
        
        XCTAssertEqual(targetValue2, additionValue2)
        
        let removed2 = storage.remove(for: key2)
        XCTAssertEqual(removed2, additionValue2)
        
        var targetValue3 = 0
        for additionValue in storage {
            targetValue3 += additionValue
        }
        
        let removed3 = storage.remove(for: key2)
        XCTAssertNil(removed3)
        
        XCTAssertEqual(targetValue3, 0)
    }
}
