import XCTest
import VueFlux
@testable import VueFluxReactive

final class StreamTests: XCTestCase {
    func testAddObserver() {
        let stream = VueFluxReactive.Stream<Int>()
        
        var value = 0
        
        stream.add { int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        stream.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        stream.send(value: 2)
        
        XCTAssertEqual(value, 2)
    }
    
    func testDispose() {
        let stream = VueFluxReactive.Stream<Int>()
        
        var value = 0
        
        let disposable = stream.add { int in
            value = int
        }
        
        stream.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        disposable.dispose()
        
        stream.send(value: 2)
        
        XCTAssertEqual(value, 1)
    }
}
