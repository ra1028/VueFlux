import XCTest
import VueFlux
@testable import VueFluxReactive

final class SinkSignalTests: XCTestCase {
    private final class Object {
        var value = 0
    }
    
    func testObserve() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        
        signal.observe { int in
            value += int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        signal.observe { int in
            XCTAssertTrue(Thread.isMainThread)
            value += int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 3)
    }
    
    func testDispose() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        
        let disposable = signal.observe { int in
            value = int
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        disposable.dispose()
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, 1)
    }
    
    func testScopedObserving() {
        var value1 = 0
        var value2 = 0
        var object: Object? = .init()
        
        let sink1 = Sink<Int>()
        let sink2 = Sink<Int>()
        let signal1 = sink1.signal
        let signal2 = sink2.signal
        
        signal1.observe(duringScopeOf: object!) { int in
            value1 = int
        }
        
        signal2.observe(duringScopeOf: object!) { int in
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
    
    func testConcurrentAsyncScopedObserving() {
        var value = 0
        let queue = DispatchQueue(label: "testConcurrentAsyncScopedObserving")
        let group = DispatchGroup()
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        for _ in (1...100) {
            queue.async(group: group) {
                var object: Object? = .init()
                
                signal.observe(duringScopeOf: object!) { int in
                    value += int
                }
                
                object = nil
                sink.send(value: 1)
            }
        }
        
        _ = group.wait(timeout: .now() + 10)
        
        XCTAssertEqual(value, 0)
        
        var object: Object? = .init()
        
        signal.observe(duringScopeOf: object!) { int in
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
            XCTAssertTrue(Thread.isMainThread)
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
        
        signal.bind(to: object) {
            XCTAssertTrue(Thread.isMainThread)
            $0.value = $1
        }
        
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
        
        let binder = Binder<Int>(target: object!) { _, int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        signal.bind(to: binder)
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, 1)
        
        let disposable = signal.bind(to: binder)
        
        XCTAssertTrue(disposable.isDisposed)
    }
    
    func testMap() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value: String?
        
        let disposable = signal.map(String.init).observe { string in
            value = string
        }
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, "1")
        
        disposable.dispose()
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, "1")
    }
    
    func testObserveOn() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        
        let expectation = self.expectation(description: "testObserveOn")
        
        signal
            .observe(on: .queue(.globalDefault()))
            .observe { int in
                XCTAssertFalse(Thread.isMainThread)
                value = int
                expectation.fulfill()
        }
        
        sink.send(value: 1)
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, 1)
        }
    }
    
    func testImmediatelyDisposeObserveOn() {
        let queue = DispatchQueue(label: "testImmediatelyDisposeObserveOn")
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var value = 0
        
        let expectation = self.expectation(description: "testImmediatelyDisposeObserveOn")
        
        let disposable = signal
            .observe(on: .queue(queue))
            .observe { int in
                value = int
        }
        
        queue.suspend()
        
        sink.send(value: 1)
        disposable.dispose()
        
        queue.resume()
        
        queue.async(execute: expectation.fulfill)
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertEqual(value, 0)
        }
    }
}
