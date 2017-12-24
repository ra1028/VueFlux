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
    
    func testObserveOn_sink() {
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
    
    func testObserveOn_variable() {
        let variable = Variable(0)
        let signal = variable.signal
        
        var value: Int?
        
        let expectation = self.expectation(description: "subscribe to signal on global queue")
        
        signal
            .observe(on: .queue(.globalDefault()))
            .subscribe { int in
                XCTAssertFalse(Thread.isMainThread)
                value = int
                expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, 0)
        }
    }
    
    func testObserveOn_constant() {
        let variable = Variable(0)
        let constant = Constant(variable: variable)
        let signal = constant.signal
        
        var value: Int?
        
        let expectation = self.expectation(description: "subscribe to signal on global queue")
        
        signal
            .observe(on: .queue(.globalDefault()))
            .subscribe { int in
                XCTAssertFalse(Thread.isMainThread)
                value = int
                expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, 0)
        }
    }
}
