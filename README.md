<H1 align="center">VueFlux</H1>
<H4 align="center">Unidirectional Data Flow State Management Architecture for Swift - Inspired by Vuex and Flux</H4>
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

It serves as a multi store so that all ViewControllers have designated stores, with rules ensuring that the state can only be mutated in a predictable fashion.  

The Store also can receives an action dispatched globally, it helps to resolve dependencies between ViewControllers. And, can be manage a shared state in application by making a shared instance of store.  

Although VueFlux keeps your project's good productivity and readable codes, it also comes with the cost of more concepts and boilerplate.  
If your project is small-scale, you will most likely be fine without VueFlux.  
However, as the scale of your project gets larger, VueFlux will be the best choice to handle the complicated data flow.  

VueFlux is recommended to be used with arbitrary Reactive programming libraries(e.g. [RxSwift](https://github.com/ReactiveX/RxSwift), [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) and [ReactiveKit](https://github.com/ReactiveKit/ReactiveKit)), but even VueFlux alone works awesome.  

---

## Core Concepts
VueFlux is Constituted by following core concepts.  
For actual implementation please see [Examples](./Examples).  

- [State](#state)
- [Actions](#actions)
- [Mutations](#mutations)
- [Computed](#computed)
- [Store](#store)

### State
This is the protocol that only just constrain the type of `Action` and `Mutations`, represents the state managed by the `Store`.

Implement some detailed state property to the state, and keeps as readonly by `fileprivate` access level.   

Will be mutated only by Mutations, and property will be publish only by `Computed`.  

```swift
final class CounterState: State {
    typealias Action = CounterAction
    typealias Mutations = CounterMutations

    fileprivate var count = 0
}
```

### Actions
This is the proxy for functions of dispatching `Action`.  

Proxied functions can contain arbitrary asynchronous operations such as request to backend API.  

The type of `Action` dispatched from `Actions` proxied functions is constrained by `State`.  

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
This is the protocol that represents proxy for `commit` function that to be mutate the state.  

Be able to change the fileprivate property of State by implementing it in the same file.  

The only way to actually change `State` in a `Store` is by committing a `Action` through `Mutations`.  

Changes of `State` are must be `synchronous`.  

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
Proxy for publishing properties of `State` to read-only.  

Be able to read and publish the fileprivate property of State by implementing it in the same file.  

Properties of State in the Store can only be read through this.  

```swift
extension Computed where State == CounterState {
    var count: Int {
        return state.count
    }
}
```

### Store
The `Store` is manages the state, and also can be manage a shared state in application by making a shared instance.  

`Computed` and `Actions` are only be access through this, also the same of change the state.  

An `action` dispatched from the `store.actions` of the instance member changes only the designated store's state. On the other hand, an `action` dispatched from the `Store<State>.actions` of the static member will affect all store that constrained by same `State`  
So this is also serves as __global event bus__.  

`Store` implement on a ViewController like so follows:  

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