import XCTest
@testable import VueFluxReactive

final class SubscribableTests: XCTestCase {
    private final class Object {
        var value = 0
    }
    
    func testScopedSubscribe() {
        var value1 = 0
        var value2 = 0
        var object: Object? = .init()
        
        let subject1 = Subject<Int>()
        let subject2 = Subject<Int>()
        
        subject1.subscribe(duringScopeOf: object!) { int in
            value1 = int
        }
        
        subject2.subscribe(duringScopeOf: object!) { int in
            value2 = int
        }
        
        subject1.send(value: 1)
        subject2.send(value: 10)
        
        XCTAssertEqual(value1, 1)
        XCTAssertEqual(value2, 10)
        
        object = nil
        
        subject1.send(value: 2)
        subject2.send(value: 20)
        
        XCTAssertEqual(value1, 1)
        XCTAssertEqual(value2, 10)
    }
    
    func testScopedSubscribeConcurrentAsync() {
        var value = 0
        let queue = DispatchQueue(label: "scoped subscribe loop queue")
        let group = DispatchGroup()
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        for _ in (1...100) {
            queue.async(group: group) {
                var object: Object? = .init()
                
                signal.subscribe(duringScopeOf: object!) { int in
                    value += int
                }
                
                object = nil
                sink.send(value: 1)
            }
        }
        
        _ = group.wait(timeout: .now() + 10)
        
        XCTAssertEqual(value, 0)
        
        var object: Object? = .init()
        
        signal.subscribe(duringScopeOf: object!) { int in
            value += int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
    }
    
    func testBindWithBinder() {
        let object = Object()
        
        let subject = Subject<Int>()
        
        subject.bind(to: .init(target: object, \.value))
        
        subject.send(value: 3)
        
        XCTAssertEqual(object.value, 3)
    }
    
    func testBindWithTargetAndBinding() {
        let object = Object()
        
        let subject = Subject<Int>()

        subject.bind(to: object) { $0.value = $1 }
        
        subject.send(value: 3)
        
        XCTAssertEqual(object.value, 3)
    }
    
    func testBindWithTargetAndKeyPath() {
        let object = Object()
        
        let subject = Subject<Int>()
        
        subject.bind(to: object, \.value)
        
        subject.send(value: 3)
        
        XCTAssertEqual(object.value, 3)
    }
}
