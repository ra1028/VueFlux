import XCTest
@testable import VueFluxReactive

final class BinderTests: XCTestCase {
    final class Object {
        var value: Int = 0
    }
    
    func testBindOnMainThreadExectuor() {
        let object = Object()
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        let binder = Binder<Int>(target: object) { object, value in
            XCTAssertTrue(Thread.isMainThread)
            object.value = value
        }
        
        _ = binder.bind(signal: signal, on: .mainThread)
        
        sink.send(value: 1)
        
        XCTAssertEqual(object.value, 1)
    }
    
    func testBindOnImmediateExectuor() {
        let object = Object()
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        let expectation = self.expectation(description: "send value on global queue")
        
        let binder = Binder<Int>(target: object) { object, value in
            XCTAssertFalse(Thread.isMainThread)
            object.value = value
            expectation.fulfill()
        }
        
        _ = binder.bind(signal: signal, on: .immediate)
        
        DispatchQueue.globalDefault().async {
            sink.send(value: 1)
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(object.value, 1)
        }
    }
    
    func testImmediatelyDisposeBinding() {
        let object = Object()
        
        let queue = DispatchQueue(label: "testImmediatelyDisposeObserveOn")
        
        let sink = Sink<Int>()
        let signal = sink.signal
        
        let expectation = self.expectation(description: "bind on global queue")
        
        let binder = Binder<Int>(target: object) { object, value in
            object.value = value
            expectation.fulfill()
        }
        
        let disposable = binder.bind(signal: signal, on: .queue(queue))
        queue.suspend()
        
        sink.send(value: 1)
        disposable.dispose()
        
        queue.resume()
        
        queue.async(execute: expectation.fulfill)
        
        waitForExpectations(timeout: 2) { _ in
            XCTAssertEqual(object.value, 0)
        }
    }
    
    func testUnbindOnTargetDeinit() {
        let sink = Sink<Int>()
        let signal = sink.signal
        
        var object: Object? = .init()
        var value: Int = 0
        
        let binder = Binder<Int>(target: object!) { _, int in
            value = int
        }
        
        let disposable = binder.bind(signal: signal, on: .immediate)
        
        sink.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        sink.send(value: 2)
        
        XCTAssertEqual(value, 1)
        
        XCTAssertTrue(disposable.isDisposed)
    }
}
