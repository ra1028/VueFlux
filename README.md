<H1 align="center">VueFlux</H1>
<H4 align="center">Unidirectional Data Flow State Management Architecture for Swift - Inspired by [Vuex](https://github.com/vuejs/vuex) and [Flux](https://github.com/facebook/flux)</H4>
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

VueFlux is recommended to be used with arbitrary Reactive programming libraries(e.g. [RxSwift](https://github.com/ReactiveX/RxSwift), [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) and [ReactiveKit](https://github.com/ReactiveKit/ReactiveKit)), but even VueFlux alone works awesome.  

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
This is the protocol that only just for constraining the type of `Action` and `Mutations`, represents the state managed by the `Store`.  

Implement some properties of the state, and keeps them readonly by fileprivate access control, like below.   

Will be mutated only by Mutations, and the properties will be published only by `Computed`.  

```swift
final class CounterState: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations

    fileprivate var count = 0
}
```

### Actions
This is the proxy for functions of dispatching `Action`.  

They can have arbitrary operations asynchronous such as request to backend API.  

The type of `Action` dispatched from `Actions`' proxied functions is determined by `State`.  

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

The only way to actually change `State` in a `Store` is committing an `Action` via `Mutations`.  

Changes of `State` must be done `synchronously`.  

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
This is the proxy for publishing read-only properties of `State`.  

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
The `Store` manages the state, and also can be manage shared state in an application by shared store instance.  

`Computed` and `Actions` can only be accessed via this. Changing the state is the same as well.  

An `Action` dispatched from the `actions` of the instance member changes only the designated store's state. On the other hand, an `Action` dispatched from the `actions` of the static member will affects all stores' states that constrained by same `State`.  

`Store` implementation in a ViewController is like as follows:  

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
        store.actions.increment()
    }

    @IBAction func decrementButtonTapped(sender: UIButton) {
        store.actions.decrement()
    }
}
```

---

## Advanced concepts

### Executor
Executor determines the execution behavior of function such as execute on main-thread, on a global queue and so on.  

It has implements some behavior by default.  
- immediate  
  Executes function immediately and synchronously.  

- mainThread  
  Executes immediately and synchronously if execution thread is main-thread. Otherwise enqueue to main-queue.  

- queue(_ dispatchQueue: DispatchQueue)  
  All the functions are enqueue to given dispatch queue.  

In the cases of below, the store commits actions to mutations through the global queue.  
```swift
let store = Store<CounterState>(state: .init(), mutations: .init(), executor: .queue(.global()))
```

Also, if you subscribe like this, the observer function is executed on the main thread.  
The argument default is `mainThread`  
```swift
store.subscribe(executor: .mainThread) { action, store in
    // Executed on the main thread
}
```

### Subscription
Subscribing to the store, returns `Subscription`.  

`Subscription` has a function `unsubscribe`. Can removing an observer function that subscribe to the store by executing `unsubscribe.  

```swift
let subscription = store.subscribe { action, store in
    // NOT executed after unsubscribed.
}

subscription.unsubscribe()
```

### SubscriptionScope
`SubscriptionScope` serves as resource manager of subscription.  

This will be unsubscribe all the added subscriptions on `deinit`.  

Unsubscribe when the ViewController is closed by retaining this as a property of ViewController.  

```swift
var subscriptionsScope: SubscriptionScope? = SubscriptionScope()

subscriptionScope += store.subscribe { action, store in
    // NOT executed after subscriptionsScope had deinitialized.
}

subscriptionsScope = nil // Be unsubscribed
```

### Scoped Subscribe
When subscribing, you can pass `AnyObject` as the parameter `scope`.  
An observer function subscribed to the store will be unsubscribe when deinitializes its object.  

```swift
store.subscribe(scope: self) { [unowned self] action, store in
    // NOT executed after `self` had deinitialized.
}
```

## Shared Store
Should make a shared instance of `Store` in order to manages a state shared in application.  

Although you may as well defined as a global variable, an elegant way is override the `Store` and define a static member `shared`.  

```
final class CounterStore: Store<CounterState> {
    static let shared = CounterStore()

    private init() {
        super.init(state: .init(), mutations: .init())
    }
}
```

## Global Event Bus
VueFlux is also serves as a global event bus.  

If you call a function from `actions' that a static member of the Store, it affects all the states managed by the instances of that Store type.  

```Swift
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
- Linux

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