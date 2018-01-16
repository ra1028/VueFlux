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

## Introduction
VueFlux is the architecture to manage state with unidirectional data flow for Swift, inspired by [Vuex](https://github.com/vuejs/vuex) and [Flux](https://github.com/facebook/flux).  

It serves multi store, so that all ViewControllers have designated stores, with rules ensuring that the states can only be mutated in a predictable fashion.  

The stores also can receives an action dispatched globally.  
That makes ViewControllers be freed from dependencies among them.
And, a shared state in an application is also supported by a shared instance of the store.  

Although VueFlux makes your projects more productive and codes more readable, it also comes with the cost of more concepts and boilerplates.  
If your project is small-scale, you will most likely be fine without VueFlux.  
However, as the scale of your project becomes larger, VueFlux will be the best choice to handle the complicated data flow.  

VueFlux is receives state changes by efficient reactive system. [VueFluxReactive](./VueFluxReactive) is µ reactive framework(not functional) compatible with this architecture.  
Arbitrary third party reactive frameworks (e.g. [RxSwift](https://github.com/ReactiveX/RxSwift), [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) and [ReactiveKit](https://github.com/ReactiveKit/ReactiveKit)) can also be used with VueFlux.  

![VueFlux Architecture](./assets/VueFlux.png)

---

## About VueFlux
VueFlux makes a unidirectional and predictable flow by explicitly dividing the roles making up the ViewController.
It's constituted of following core concepts.  
State changes are observed by the ViewController using the reactive system.  
Sample code uses VueFluxReactive which will be described later.  
You can see example implementation [here](./Examples/Example).  

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

    fileprivate let count = Variable(0)
}
```

### Actions
This is the proxy for functions of dispatching Action.  
They can have arbitrary operations asynchronous such as request to backend API.  
The type of Action dispatched from Actions' function is determined by State.  

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
            state.count.value += 1

        case .decrement:
            state.count.value -= 1
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
    var count: Constant<Int> {
        return state.count.constant
    }
}
```

### Store
The Store manages the state, and also can be manage shared state in an application by shared store instance.  
Computed and Actions can only be accessed via this. Changing the state is the same as well.  
An Action dispatched from the `actions` of the instance member is mutates only the designated store's state.  
On the other hand, an Action dispatched from the `actions` of the static member will mutates all the states managed in the stores which have same generic type of State in common.  
Store implementation in a ViewController is like as follows:  

```swift
final class CounterViewController: UIViewController {
    @IBOutlet private weak var counterLabel: UILabel!

    private let store = Store<CounterState>(state: .init(), mutations: .init(), executor: .queue(.global()))

    override func viewDidLoad() {
        super.viewDidLoad()

        store.computed.count.signal
            .map { String($0) }
            .observe(on: .mainThread)
            .bind(to: counterLabel, \.text)
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

## About VueFluxReactive
VueFluxReactive is a μ reactive system for observing state changes.  
It was made for replacing the existing reactive framework that takes high learning and introduction costs though high-powered such as RxSwift and ReactiveSwift.  
But, of course, VueFlux can be used with those framework because VueFluxReactive is separated.  
VueFluxReactive is constituted of following primitives.  

- [Variable](#variable)
- [Constant](#constant)
- [Sink](#sink)
- [Signal](#signal)

### Sink
This type has a way of generating Signal.  
One can send values into a sink and receives it by observing generated signal.  
Signals generated from Sink does not hold the latest value.  
Practically, it's used to send commands (such as presents another ViewController) from State to ViewController.

```swift
let sink = Sink<Int>()
let signal = sink.signal

signal.subscribe { print($0) }

sink.send(value: 100)

// prints "100"
```

### Signal
A push-driven stream that sends value changes over time.  
Can be subscribe values stream, and values will be sent to all observers at the same time.  
All of values changes are made via this primitive.  

```swift
let sink = Sink<Int>()
let signal = sink.signal

signal.subscribe { print("1: \($0)") }
signal.subscribe { print($2: \($0)") }

sink.send(value: 100)
sink.send(value: 200)

// prints "1: 100"
// prints "2: 100"
// prints "1: 200"
// prints "2: 200"
```

### Variable
Variable represents a thread-safe mutable value that allows observation of its changes via signal generated from it.  
The signal forwards the latest value when observing starts. All value changes are delivers on after that.  

```swift
let variable = Variable(0)

variable.signal.subscribe { print($0) }

variable.value = 1

print(variable.value)

variable.signal.subscribe { print($0) }

/// prints "0"
/// prints "1"
/// prints "1"
/// prints "1"
```

### Constant
This is a kind of wrapper to making Variable read-only.  
Constant generated from Variable reflects the changes of its Variable.  
Just like Variable, the latest value and value changes are forwarded via signal. But Constant is not allowed to be changed directly.  

```swift
let variable = Variable(0)
let constant = variable.constant

constant.signal.subscribe { print($0) }

variable.value = 1

print(constant.value)

constant.signal.subscribe { print($0) }

/// prints "0"
/// prints "1"
/// prints "1"
/// prints "1"
```

---

## Advanced Usage

### Executor
Executor determines the execution context of function such as execute on main-thread, on a global queue and so on.  
Some contexts are built in default.  

- immediate  
  Executes function immediately and synchronously.  

- mainThread  
  Executes immediately and synchronously if execution thread is main-thread. Otherwise enqueue to main-queue.  

- queue(_ dispatchQueue: DispatchQueue)  
  All functions are enqueued to given dispatch queue.  

In the following case, the store commits actions to mutations on global queue.  

```swift
let store = Store<CounterState>(state: .init(), mutations: .init(), executor: .queue(.global()))
```

If you subscribe like below, the observer function is executed on global background queue.  

```swift
store.computed.valueSignal
    .observe(on: .queue(.global(qos: .background)))
    .subscribe { value in
        // Executed on global background queue
}
```

**Executor.WorkItem**  
Executor can also be executed with WorkItem.  
The WorkItem can call `cancel` to prevent it from execute in future.  
Cancellation does not affect any execution of the function that is already in progress.  

```swift
let executor = Executor.immediate
let workItem = Executor.WorkItem<Int> { value in
    print("Value is \(value)")
}

executor.execute(workItem: workItem, with: 100)

workItem.cancel()

executor.execute(workItem: workItem, with: 200)

// prints "Value is 100"
```

### Signal Operators
VueFluxReactive restricts functional approach AMAP.  
However, includes minimum operators for convenience.  
These operators transform a signal into a new sinal generated in the operators, which means the invariance of Signal holds.  

**map**  
The map operator is used to transform the values in a signal.  

```swift
let sink = Sink<Int>()
let signal = sink.signal

signal
    .map { "Value is \($0)" }
    .subscribe { print($0) }

sink.send(value: 100)
sink.send(value: 200)

// prints "Value is 100"
// prints "Value is 200"
```

**observe(on:)**  
Forwards all values ​​on context of a given Executor.  

```swift
let sink = Sink<Int>()
let signal = sink.signal

signal
    .observe(on: .mainThread)
    .subscribe { print("Value: \($0), isMainThread: \(Thread.isMainThread)") }

DispatchQueue.global().async {
    sink.send(value: 100)    
    sink.send(value: 200)
}

// prints "Value: 100, isMainThread: true"
// prints "Value: 200, isMainThread: true"
```

### Subscription
Subscribing to the store returns this type.  
Subscription has `unsubscribe` function which can remove an observer function that is subscribing to the store.  

```swift
let subscription = signal.subscribe { value in
    // Not executed after unsubscribed.
}

subscription.unsubscribe()
```

### SubscriptionScope
SubscriptionScope serves as resource manager of subscription.  
This will terminate all added subscriptions on deinitialization.  
For example, when the ViewController which has a property of SubscriptionScope is dismissed, all subscriptions are terminated.  

```swift
var subscriptionsScope: SubscriptionScope? = SubscriptionScope()

subscriptionScope += signal.subscribe { value in
    // Not executed after subscriptionsScope had deinitialized.
}

subscriptionsScope = nil  // Be unsubscribed
```

### Scoped Subscribe
In subscribing, you can pass `AnyObject` as the parameter of `duringScopeOf`.  
An observer function which is subscribing to the store will be unsubscribed when the object is deinitialized.  

```swift
signal.subscribe(duringScopeOf: self) { value in
    // Not executed after `self` had deinitialized.
}
```

### Bind
Binding makes target object's value be updated to the latest value sent by the Signal.  
The binding is no longer valid after the target object is deinitialized.  

Closure binding.
```swift
text.signal
    .observe(on: .mainThread)
    .bind(to: label) { label, text in label.text = text }
```

Smart KeyPath binding.
```swift
text.signal
    .observe(on: .mainThread)
    .bind(to: label, \.text)
```

Binder
```swift
extension UIView {
    func setHiddenBinder(duration: TimeInterval) -> Binder<Bool> {
        return Binder(target: self) { view, isHidden in
            UIView.transition(
              with: view,
              duration: duration,
              options: .transitionCrossDissolve,
              animations: { view.isHidden = isHidden }
            )
        }
    }
}

isViewHidden.signal
    .observe(on: .mainThread)
    .bind(to: view.setHiddenBinder(duration: 0.3))
```

### Shared Store
You should make a shared instance of Store in order to manages a state shared in application.  
Although you may define it as a global variable, an elegant way is overriding the Store and defining a static member `shared`.  

```swift
final class CounterStore: Store<CounterState> {
    static let shared = CounterStore()

    private init() {
        super.init(state: .init(), mutations: .init(), executor: .queue(.global()))
    }
}
```

### Global Event Bus
VueFlux can also serve as a global event bus.  
If you call a function from `actions` that is a static member of Store, all the states managed in the stores which have same generic type of State in common are affected.  

```swift
let store = Store<CounterState>(state: .init(), mutations: .init(), executor: .immediate)

print(store.computed.count.value)

Store<CounterState>.actions.increment()

print(store.computed.count.value)

// prints "0"
// prints "1"
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
If use VueFlux with VueFluxReactive, add the following to your Podfile:  
```ruby
use_frameworks!

target 'TargetName' do
  pod 'VueFluxReactive'
end
```
Or if, use with third-party Reactive framework:  
```ruby
use_frameworks!

target 'TargetName' do
  pod 'VueFlux'
  # and reactive framework you like
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
VueFlux and VueFluxReactive is released under the MIT License.  

---