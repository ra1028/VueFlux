import XCTest
import VueFlux
@testable import VueFluxReactive

final class SinkSignalTests: XCTestCase {
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
