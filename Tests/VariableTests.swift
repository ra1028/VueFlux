import XCTest
import VueFlux
@testable import VueFluxReactive

final class VariableTests: XCTestCase {
    func testObserve() {
        let variable = Variable(0)
        
        var value: Int? = nil
        
        variable.signal.observe { int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        XCTAssertEqual(variable.value, 0)
        XCTAssertEqual(value, 0)
        
        variable.value = 1

        XCTAssertEqual(variable.value, 1)
        XCTAssertEqual(value, 1)
    }
    
    func testDispose() {
        let variable = Variable(0)
        
        var value: Int? = nil
        
        let disposable = variable.signal.observe { int in
            value = int
        }

        XCTAssertEqual(variable.value, 0)
        XCTAssertEqual(value, 0)
        
        variable.value = 1
        
        XCTAssertEqual(variable.value, 1)
        XCTAssertEqual(value, 1)
        
        disposable.dispose()
        
        variable.value = 2
        
        XCTAssertEqual(variable.value, 2)
        XCTAssertEqual(value, 1)
        
        variable.signal.observe { int in
            value = int
        }
        
        XCTAssertEqual(variable.value, 2)
        XCTAssertEqual(value, 2)
    }
    
    func testDisposeOnObserving() {
        let variable = Variable(())
        let signal = variable.signal
        
        let disposable = signal.observe {}
        signal.observe {
            disposable.dispose()
        }
        
        variable.value = ()
        
        XCTAssertEqual(disposable.isDisposed, true)
    }
    
    func testConcurrentQueueValueChanged() {
        let variable = Variable(())
        let signal = variable.signal
        
        let queue = DispatchQueue(label: "testConcurrentQueueValueChanged", attributes: .concurrent)
        let group = DispatchGroup()
        
        var value = 0
        signal.observe {
            value += 1
            value -= 1
            value += 2
            value -= 2
        }
        
        for _ in (1...100) {
            queue.async(group: group) {
                variable.value = ()
            }
        }
        
        _ = group.wait(timeout: .now() + 10)
        XCTAssertEqual(value, 0)
    }
    
    func testUnbindOnTargetDeinit() {
        final class Object {}
        
        let variable = Variable(0)
        
        var value = 0
        var object: Object? = .init()
        
        let binder = Binder(target: object!) { _, int in value = int }
        
        variable.signal.bind(to: binder)
        
        variable.value = 1
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        variable.value = 2
        
        XCTAssertEqual(value, 1)
        
        let disposable = variable.signal.bind(to: binder)
        
        XCTAssertTrue(disposable.isDisposed)
    }
    
    func testMapValues() {
        let variable = Variable(0)
        
        var value: String?
        
        let disposable = variable.signal
            .map(String.init)
            .observe { string in
                value = string
        }
        
        XCTAssertEqual(value, "0")
        
        variable.value = 1
        
        XCTAssertEqual(value, "1")
        
        disposable.dispose()
        
        variable.value = 2
        
        XCTAssertEqual(value, "1")
    }
    
    func testObserveOn() {
        let variable = Variable(0)
        let signal = variable.signal
        
        var value: Int?
        
        let expectation = self.expectation(description: "testObserveOn")
        
        signal
            .observe(on: .queue(.globalDefault()))
            .observe { int in
                XCTAssertFalse(Thread.isMainThread)
                value = int
                expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(value, 0)
        }
    }
}
