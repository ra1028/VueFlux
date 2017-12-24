import XCTest
import VueFlux
@testable import VueFluxReactive

final class SubjectTests: XCTestCase {
    func testSubscribe() {
        let subject = Subject<Int>()
        
        var value = 0
        
        subject.subscribe { int in
            XCTAssertTrue(Thread.isMainThread)
            value = int
        }
        
        subject.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        subject.send(value: 2)
        
        XCTAssertEqual(value, 2)
    }
    
    func testUnsubscribe() {
        let subject = Subject<Int>()
        
        var value = 0
        
        let subscription = subject.subscribe { int in
            value = int
        }
        
        subject.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        subscription.unsubscribe()
        
        subject.send(value: 2)
        
        XCTAssertEqual(value, 1)
    }
    
    
    func testUnbindOnTargetDeinit() {
        final class Object {}
        
        let subject = Subject<Int>()
        
        var value = 0
        var object: Object? = .init()
        
        let binder = Binder(target: object!) { _, int in value = int }
        
        subject.bind(to: binder)
        
        subject.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        subject.send(value: 2)
        
        XCTAssertEqual(value, 1)
        
        let subscription = subject.bind(to: binder)
        
        XCTAssertTrue(subscription.isUnsubscribed)
    }
}
