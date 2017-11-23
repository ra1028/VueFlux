<H1 align="center">VueFlux</H1>
<H4 align="center">
Unidirectional Data Flow State Management Architecture for Swift - Inspired by <a href="https://github.com/vuejs/vuex">Vuex</a> and <a href="https://github.com/facebook/flux">Flux</a>
</H4>
</br>

<p align="center">
<a href="https://developer.apple.com/swift"><img alt="Swift4" src="https://img.shields.io/badge/language-swift4-orange.svg?style=flat"/></a>
<a href="https://travis-ci.org/ra1028/VueFlux"><img alt="Build Status" src="https://travis-ci.org/ra1028/VueFlux.svg?branch=master"/></a>
<a href="https://codebeat.co/projects/github-com-ra1028-vueflux-master"><img alt="CodeBeat" src="https://codebeat.co/badges/5f422c2e-40b9-4900-a9e9-9c776757b976" /></a>
<a href="https://cocoapods.org/pods/VueFlux"><img alt="CocoaPods" src="https://img.shields.io/cocoapods/v/VueFlux.svg"/></a>
<a href="https://github.com/Carthage/Carthage"><img alt="Carthage" src="https://img.shields.io/badge/Carthage-compatible-yellow.svg?style=flat"/></a>
<a href="https://developer.apple.com/swift/"><img alt="Platform" src="https://img.shields.io/badge/platform-iOS%20%7C%20OSX%20%7C%20tvOS%20%7C%20watchOS-green.svg"/></a>
<a href="https://github.com/ra1028/VueFlux/blob/master/LICENSE"><img alt="Lincense" src="http://img.shields.io/badge/license-MIT-000000.svg?style=flat"/></a>
</p>

---

## About VueFlux
VueFlux is the architecture to manage state with unidirectional data flow for Swift, inspired by [Vuex](https://github.com/vuejs/vuex) and [Flux](https://github.com/facebook/flux).  

It serves multi store, so that all ViewControllers have designated stores, with rules ensuring that the states can only be mutated in a predictable fashion.  

The stores also can receives an action dispatched globally. That makes ViewControllers be freed from dependencies among them. And, a shared state in an application is also supported by making a shared instance of the store.  

Although VueFlux makes your projects more productive and codes more readable, it also comes with the cost of more concepts and boilerplates.  
If your project is small-scale, you will most likely be fine without VueFlux.  
However, as the scale of your project becomes larger, VueFlux will be the best choice to handle the complicated data flow.  

VueFlux is recommended to be used with arbitrary reactive programming libraries(e.g. [RxSwift](https://github.com/ReactiveX/RxSwift), [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) and [ReactiveKit](https://github.com/ReactiveKit/ReactiveKit)), but even VueFlux alone works awesome.  

![](./Assets/VueFlux.png)

---

## Core Concepts
VueFlux is constituted of following core concepts.  
You can see actual implementation [here](./Examples).  

- [State](#state)
- [Actions](#actions)
- [Mutations](#mutations)
- [Computed](#computed)
- [Store](#store)

### State
This is the protocol that only just for constraining the type of Action and Mutations, represents the state managed by the Store.  

Implement some properties of the state, and keeps them readonly by fileprivate access control, like below.   

Will be mutated only by Mutations, and the properties will be published only by Computed.  

```swift
final class CounterState: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations

    fileprivate var count = 0
}
```

### Actions
This is the proxy for functions of dispatching Action.  

They can have arbitrary operations asynchronous such as request to backend API.  

The type of Action dispatched from Actions' proxied functions is determined by State.  

```swift
enum CounterAction {
    case increment, decrement
}
```
```swift
extension Actions where State == CounterState {
    func increment() {
        dispatch(action: .increment)
    }

    func decrement() {
        dispatch(action: .decrement)
    }
}

```

### Mutations
This is the protocol that represents `commit` function that mutate the state.  

Be able to change the fileprivate properties of the state by implementing it in the same file.  

The only way to actually change State in a Store is committing an Action via Mutations.  

Changes of State must be done `synchronously`.  

```swift
struct CounterMutations: Mutations {
    func commit(action: CounterAction, state: CounterState) {
        switch action {
        case .increment:
            state.count += 1

        case .decrement:
            state.count -= 1
        }
    }
}
```

### Computed
This is the proxy for publishing read-only properties of State.  

Be able to access and publish the fileprivate properties of state by implementing it in the same file.  

Properties of State in the Store can only be accessed via this.  

```swift
extension Computed where State == CounterState {
    var count: Int {
        return state.count
    }
}
```

### Store
The Store manages the state, and also can be manage shared state in an application by shared store instance.  

Computed and Actions can only be accessed via this. Changing the state is the same as well.  

An Action dispatched from the `actions` of the instance member is mutates only the designated store's state. On the other hand, an Action dispatched from the `actions` of the static member will mutates all the states managed in the stores which have same generic type of State in common.  

Store implementation in a ViewController is like as follows:  

```swift
final class CounterViewController: UIViewController {
    @IBOutlet private weak var counterLabel: UILabel!

    private let store = Store<CounterState>(state: .init(), mutations: .init(), executor: .queue(.global()))
    // This is the type erased code of following.
    // private let store = Store<CounterState>(state: CounterState(), mutations: CounterMutations(), executor: Executor.queue(DispatchQueue.global()))

    override func viewDidLoad() {
        super.viewDidLoad()

        store.subscribe(scope: self) { [unowned self] action, store in
            switch action {
                case .increment, .decrement:
                    self.counterLabel.text = String(store.computed.count)
            }
        }
    }

    @IBAction func incrementButtonTapped(sender: UIButton) {
        store.actions.increment()  // Store<CounterState>.actions.increment()
    }

    @IBAction func decrementButtonTapped(sender: UIButton) {
        store.actions.decrement()  // Store<CounterState>.actions.decrement()
    }
}
```

---

## Advanced concepts

### Executor
Executor determines the execution behavior of function such as execute on main-thread, on a global queue and so on.  

It has some behavior by default.  
- immediate  
  Executes function immediately and synchronously.  

- mainThread  
  Executes immediately and synchronously if execution thread is main-thread. Otherwise enqueue to main-queue.  

- queue(_ dispatchQueue: DispatchQueue)  
  All functions are enqueued to given dispatch queue.  

In the following case, the store commits actions to mutations through the global queue.  
```swift
let store = Store<CounterState>(state: .init(), mutations: .init(), executor: .queue(.global()))
```

If you subscribe like below, the observer function is executed on the main thread.  
The argument default is `mainThread`.  
```swift
store.subscribe(executor: .mainThread) { action, store in
    // Executed on the main thread
}
```

### Subscription
Subscribing to the store returns Subscription.  

Subscription has `unsubscribe` function which can remove an observer function that is subscribing to the store.  

```swift
let subscription = store.subscribe { action, store in
    // NOT executed after unsubscribed.
}

subscription.unsubscribe()
```

### SubscriptionScope
SubscriptionScope serves as resource manager of subscription.  

This will terminate all added subscriptions on deinitialization.  

For example, when the ViewController which has a property of SubscriptionScope is dismissed, all subscriptions are terminated.  

```swift
var subscriptionsScope: SubscriptionScope? = SubscriptionScope()

subscriptionScope += store.subscribe { action, store in
    // NOT executed after subscriptionsScope had deinitialized.
}

subscriptionsScope = nil  // Be unsubscribed
```

### Scoped Subscribe
In subscribing, you can pass `AnyObject` as the parameter of `scope`.  
An observer function which is subscribed to the store will be unsubscribe when deinitializes its object.  

```swift
store.subscribe(scope: self) { action, store in
    // NOT executed after `self` had deinitialized.
}
```

### Shared Store
You should make a shared instance of Store in order to manages a state shared in application.  

Although you may define it as a global variable, an elegant way is overriding the Store and defining a static member `shared`.  

```swift
final class CounterStore: Store<CounterState> {
    static let shared = CounterStore()

    private init() {
        super.init(state: .init(), mutations: .init())
    }
}
```

### Global Event Bus
VueFlux can also serve as a global event bus.  

If you call a function from `actions` that is a static member of Store, all the states managed in the stores which have same generic type of State in common are affected.  

```swift
let store = Store<CounterState>(state: .init(), mutations: .init(), executor: .immediate)

print(store.computed.count)  // 0

Store<CounterState>.actions.increment()

print(store.computed.count)  // 1
```
---

## Requirements
- Swift4.0 or later
- OS X 10.9 or later
- iOS 9.0 or later
- watchOS 2.0 or later
- tvOS 9.0 or later

---

## Installation

### [CocoaPods](https://cocoapods.org/)  
Add the following to your Podfile:  
```ruby
use_frameworks!

target 'TargetName' do
  pod 'VueFlux'
end
```
And run
```sh
pod install
```

### [Carthage](https://github.com/Carthage/Carthage)  
Add the following to your Cartfile:  
```ruby
github "ra1028/VueFlux"
```
And run
```sh
carthage update
```

---

## Contribution
Welcome to fork and submit pull requests.  

Before submitting pull request, please ensure you have passed the included tests.  
If your pull request including new function, please write test cases for it.  

---

## License
VueFlux is released under the MIT License.  

---