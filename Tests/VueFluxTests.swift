import XCTest
@testable import VueFlux

final class VueFluxTests: XCTestCase {
    func testMutations() {
        let state = TestState()
        let mutations = TestMutations()
        
        XCTAssertEqual(state.value, 0)
        
        mutations.commit(action: (), state: state)
        
        XCTAssertEqual(state.value, 1)
    }
    
    func testDispatch() {
        let store = Store<TestState>(state: .init(), mutations: .init(), executor: .immediate)
        
        XCTAssertEqual(store.computed.value, 0)
        
        store.actions.check()
        
        XCTAssertEqual(store.computed.value, 1)
    }
    
    func testDispatchOnTargetThread() {
        let state1 = TestState { _ in
            XCTAssertTrue(Thread.isMainThread)
        }
        let store1 = Store<TestState>(state: state1, mutations: .init(), executor: .mainThread)
        
        store1.actions.check()
        
        XCTAssertEqual(store1.computed.value, 1)
        
        let expectation = self.expectation(description: "dispatch on global queue")
        
        let state2 = TestState { _ in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }
        let store2 = Store<TestState>(state: state2, mutations: .init(), executor: .queue(.globalQueue()))
        
        store2.actions.check()
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(store2.computed.value, 1)
        }
    }
    
    func testGlobalDispatch() {
        let store1 = Store<TestState>(state: .init(), mutations: .init(), executor: .immediate)
        let store2 = Store<TestState>(state: .init(), mutations: .init(), executor: .immediate)
        
        store1.actions.check()
        
        XCTAssertEqual(store1.computed.value, 1)
        XCTAssertEqual(store2.computed.value, 0)
        
        Store<TestState>.actions.check()
        
        XCTAssertEqual(store1.computed.value, 2)
        XCTAssertEqual(store2.computed.value, 1)
    }
    
    func testUnsubscribeStoreOnDeinit() {
        var store: Store<TestState>? = .init(state: .init(), mutations: .init(), executor: .immediate)
        let computed = store!.computed
        
        store?.actions.check()
        
        XCTAssertEqual(computed.value, 1)
        
        Store<TestState>.actions.check()
        
        XCTAssertEqual(computed.value, 2)
        
        store = nil
        
        XCTAssertEqual(computed.value, 2)
        
        Store<TestState>.actions.check()
        
        XCTAssertEqual(computed.value, 2)
    }
    
    func testSubscribe() {
        var value = 0
        let store = Store<TestState>(state: .init(), mutations: .init(), executor: .immediate)
        
        let subscription = store.subscribe { store, _ in
            value = store.computed.value
        }
        
        store.actions.check()
        
        XCTAssertEqual(value, 1)
        
        subscription.unsubscribe()
        store.actions.check()
        
        XCTAssertEqual(value, 1)
    }
    
    func testUnsubscribeAtDeinitObject() {
        final class Object {}
        
        var value1 = 0
        var value2 = 0
        var object: Object? = .init()
        let store = Store<TestState>(state: .init(), mutations: .init(), executor: .immediate)
        
        store
            .subscribe { store, _ in
                value1 = store.computed.value
            }
            .unsubscribed(byScopeOf: object!)
        
        store
            .subscribe { store, _ in
                value2 = store.computed.value * 10
            }
            .unsubscribed(byScopeOf: object!)
        
        store.actions.check()
        
        XCTAssertEqual(value1, 1)
        XCTAssertEqual(value2, 10)
        
        object = nil
        
        XCTAssertEqual(value1, 1)
        XCTAssertEqual(value2, 10)
    }
}

final class TestState: State {
    typealias Action = Void
    typealias Mutations = TestMutations
    
    let didSetValue: (Int) -> Void
    private var innerValue = 0
    var value: Int {
        get { return innerValue }
        set {
            innerValue = newValue
            didSetValue(newValue)
        }
    }
    
    init(didSetValue: @escaping (Int) -> Void = { _ in }) {
        self.didSetValue = didSetValue
    }
}

struct TestMutations: Mutations {
    typealias State = TestState
    
    func commit(action: Void, state: TestState) {
        state.value += 1
    }
}

extension Computed where State == TestState {
    var value: Int {
        return state.value
    }
}

extension Actions where State == TestState {
    func check() {
        dispatch(action: ())
    }
}

extension DispatchQueue {
    static func globalQueue() -> DispatchQueue {
        if #available(OSX 10.10, *) {
            return .global()
        } else {
            return .global(priority: .default)
        }
    }
}
