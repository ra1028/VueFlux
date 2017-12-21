import XCTest
import VueFlux
@testable import VueFluxReactive

final class SignalTests: XCTestCase {
    func testSubscribe() {
        let sink = Sink<Int>()
        let stream = sink.stream
        
        var value = 0
        
        stream.subscribe { int in
            value += int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        stream.subscribe { int in
            XCTAssertTrue(Thread.isMainThread)
            value += int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 3)
    }
    
    func testSubscribeWithExercutor() {
        let sink = Sink<Int>()
        let stream = sink.stream
        
        var value = 0
        
        let expectation = self.expectation(description: "subscribe to signal on global queue")
        
        stream.subscribe(executor: .queue(.globalDefault())) { int in
            XCTAssertFalse(Thread.isMainThread)
            value = int
            expectation.fulfill()
        }
        
        sink.send(value: 1)
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, 1)
        }
    }
    
    func testUnsubscribe() {
        let sink = Sink<Int>()
        let stream = sink.stream
        
        var value = 0
        
        let subscription = stream.subscribe { int in
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
        let stream = sink.stream
        
        var value = 0
        var object: Object? = .init()
        
        let binder = Binder(target: object!) { _, int in value = int }
        
        stream.bind(to: binder)
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, 1)
    }
    
    func testMapValues() {
        let sink = Sink<Int>()
        let stream = sink.stream
        
        var value: String?
        
        let subscription = stream.map(String.init(_:)).subscribe { string in
            value = string
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, "1")
        
        subscription.unsubscribe()
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, "1")
    }
}
