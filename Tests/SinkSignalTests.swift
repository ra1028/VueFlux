import XCTest
import VueFlux
@testable import VueFluxReactive

final class SinkSignalTests: XCTestCase {
    private final class Object {
        var value = 0
    }
    
    func testSubscribe() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        
        signal.subscribe { int in
            value += int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        signal.subscribe { int in
            XCTAssertTrue(Thread.isMainThread)
            value += int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 3)
    }
    
    func testUnsubscribe() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        
        let subscription = signal.subscribe { int in
            value = int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        subscription.unsubscribe()
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, 1)
    }
    
    func testScopedSubscribe() {
        var value1 = 0
        var value2 = 0
        var object: Object? = .init()
        
        let sink1 = Sink<Int>()
        let sink2 = Sink<Int>()
        let signal1 = sink1.signal
        let signal2 = sink2.signal
        
        signal1.subscribe(duringScopeOf: object!) { int in
            value1 = int
        }
        
        signal2.subscribe(duringScopeOf: object!) { int in
            value2 = int
        }
        
        sink1.send(value: 1)
        sink2.send(value: 10)
        
        XCTAssertEqual(value1, 1)
        XCTAssertEqual(value2, 10)
        
        object = nil
        
        sink1.send(value: 2)
        sink2.send(value: 20)
        
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
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        let binder = Binder<Int>(target: object) { object, value in
            object.value = value
        }
        
        signal.bind(to: binder)
        
        sink.send(value: 3)
        
        XCTAssertEqual(object.value, 3)
    }
    
    func testBindWithTargetAndBinding() {
        let object = Object()
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        signal.bind(to: object) { $0.value = $1 }
        
        sink.send(value: 3)
        
        XCTAssertEqual(object.value, 3)
    }
    
    func testBindWithTargetAndKeyPath() {
        let object = Object()
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        signal.bind(to: object, \.value)
        
        sink.send(value: 3)
        
        XCTAssertEqual(object.value, 3)
    }
    
    func testUnbindOnTargetDeinit() {
        final class Object {}
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        var object: Object? = .init()
        
        let binder = Binder(target: object!) { _, int in value = int }
        
        signal.bind(to: binder)
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, 1)
        
        let subscription = signal.bind(to: binder)
        
        XCTAssertTrue(subscription.isUnsubscribed)
    }
    
    func testMap() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value: String?
        
        let subscription = signal.map(String.init(_:)).subscribe { string in
            value = string
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, "1")
        
        subscription.unsubscribe()
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, "1")
    }
    
    func testObserveOn() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        
        let expectation = self.expectation(description: "subscribe to signal on global queue")
        
        signal
            .observe(on: .queue(.globalDefault()))
            .subscribe { int in
                XCTAssertFalse(Thread.isMainThread)
                value = int
                expectation.fulfill()
        }
        
        sink.send(value: 1)
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, 1)
        }
    }
    
    func testImmediatelyUnsubscribeObserveOn() {
        let queue = DispatchQueue(label: "testImmediatelyUnsubscribeObserveOn")
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        
        let expectation = self.expectation(description: "subscribe to signal on queue")
        
        let subscription = signal
            .observe(on: .queue(queue))
            .subscribe { int in
                value = int
        }
        
        queue.suspend()
        
        sink.send(value: 1)
        subscription.unsubscribe()
        
        queue.resume()
        
        queue.async(execute: expectation.fulfill)
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertEqual(value, 0)
        }
    }
}
