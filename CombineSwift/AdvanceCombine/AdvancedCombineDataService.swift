//
//  AdvancedCombineDataService.swift
//  CombineSwift
//
//  Created by Adarsh Ranjan on 16/09/25.
//


import Foundation
import Combine

class AdvancedCombineDataService {

    @Published var publishedProperty: Int = 0
    let currentValuePublisher = CurrentValueSubject<Int, Never>(0)
    let passthroughPublisher = PassthroughSubject<Int, Never>()

    init() {
        //        publishWithPublishedProperty()
        //        publishWithCurrentValueSubject()
        publishWithPassthroughSubject()
    }

    private func publishWithPublishedProperty() {
        for i in 0...10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                self.publishedProperty = i
            }
        }
    }

    private func publishWithCurrentValueSubject() {
        for i in 0...10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) + 12) {
                self.currentValuePublisher.send(i)
            }
        }
    }

    private func publishWithPassthroughSubject() {
        let items = Array(0..<11) // [0, 1, 2, ... 10]

        for x in items.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(x)) {
                self.passthroughPublisher.send(items[x])

                // When the loop is finished, send a completion event.
                // This is crucial for operators like .last()
                if x == items.indices.last {
                    self.passthroughPublisher.send(completion: .finished)
                }
            }
        }
    }
}

// MARK: - COMBINE INTERVIEW QUESTIONS & ANSWERS

// MARK: - BEGINNER / FOUNDATIONAL

// Q: What is Combine?
// A: Combine is Apple's framework for processing values over time. It provides a declarative Swift API for handling asynchronous events. It's Apple's native implementation of Functional Reactive Programming (FRP).

// Q: What are the three main components of Combine?
// A:
// 1.  **Publisher:** Emits a sequence of values over time. A publisher can emit zero or more values, and can terminate with either a successful completion or an error.
// 2.  **Operator:** A method on a publisher that transforms, filters, or combines values from an upstream publisher and returns a new, downstream publisher. Operators are chained together to form a pipeline.
// 3.  **Subscriber:** Receives values from a publisher. It acts on the received input and completion events.

// Q: What is the difference between a PassthroughSubject and a CurrentValueSubject?
// A:
// -   **PassthroughSubject:** A "stateless" subject. It broadcasts values to all current subscribers but doesn't have an initial value or hold onto the last emitted value. New subscribers will only receive values sent *after* they have subscribed.
// -   **CurrentValueSubject:** A "stateful" subject. It is initialized with a value and always stores the most recent value. When a new subscriber connects, it immediately receives the current value.

// Q: What does the `@Published` property wrapper do?
// A: `@Published` is a property wrapper that turns any property into a publisher. Whenever the property's value changes, it automatically publishes the new value. It's a convenient way to expose a publisher from a property, commonly used in SwiftUI `ObservableObject`s to trigger view updates. Under the hood, it creates a `Published<Value>.Publisher`.

// Q: What is `AnyCancellable` and why is it important for memory management?
// A: `AnyCancellable` is a type-erased class that manages the lifecycle of a subscription. When you subscribe to a publisher (e.g., using `.sink` or `.assign`), it returns a cancellable object. You *must* store this object. If the `AnyCancellable` is deallocated, the subscription is automatically cancelled and torn down. This prevents memory leaks by ensuring the subscription doesn't live forever. Typically, you store them in a `Set<AnyCancellable>`.

// MARK: - INTERMEDIATE

// Q: Explain the publisher lifecycle.
// A:
// 1.  **Subscription:** A subscriber attaches to a publisher.
// 2.  **Request:** The subscriber requests a number of values from the publisher (this is part of the backpressure mechanism).
// 3.  **Value Emission:** The publisher sends zero or more values to the subscriber.
// 4.  **Completion:** The publisher sends a single completion event. This can be either `.finished` (a normal termination) or `.failure(Error)` (an abnormal termination). Once a completion event is sent, the stream is closed and no more values will be emitted.

// Q: What is backpressure and how does Combine handle it?
// A: Backpressure is a mechanism that allows a subscriber to control the rate at which it receives values from a publisher. This prevents a fast publisher from overwhelming a slow subscriber. Combine handles this through the `Subscribers.Demand` enum. When a subscriber first connects, it can specify an initial demand (e.g., `.max(10)` or `.unlimited`). The publisher will only send up to that many values. The subscriber can then adjust its demand as it processes values.

// Q: What is the difference between `map` and `flatMap`?
// A:
// -   **`map`:** Transforms each value from an upstream publisher into a new value of a potentially different type. It's a 1-to-1 transformation (e.g., `Int` -> `String`).
// -   **`flatMap`:** Transforms each value from an upstream publisher into a *new publisher*. It then "flattens" the emissions from all these inner publishers into a single stream of values. It's essential for chaining asynchronous operations, like making a network request for each value received from a previous publisher.

// Q: When would you use `debounce` vs. `throttle`?
// A:
// -   **`debounce`:** Use when you only care about the final value after a series of rapid events has stopped. The classic example is a search bar: you wait for the user to stop typing for a moment before firing a network request.
// -   **`throttle`:** Use when you want to limit the rate of events being processed. For example, if a user is rapidly tapping a button or scrolling, you might throttle the events to ensure you only process one event every second, either the first one or the latest one in that interval.

// Q: What is the difference between `.sink` and `.assign`?
// A: Both are subscribers, but they have different purposes.
// -   **`.sink`:** A generic subscriber that takes closures as parameters. You provide a closure for receiving values (`receiveValue`) and an optional closure for handling completion (`receiveCompletion`). It's highly flexible.
// -   **`.assign(to:on:)`:** A specialized subscriber that binds the output of a publisher directly to a property on an object using a KeyPath. It's less flexible but more concise for directly updating properties. It requires the publisher's `Failure` type to be `Never`.

// MARK: - ADVANCED

// Q: What is a `Scheduler` in Combine? Explain the difference between `receive(on:)` and `subscribe(on:)`.
// A: A `Scheduler` defines an execution context where work can be performed, essentially abstracting away concepts like threads and dispatch queues.
// -   **`receive(on:)`:** This operator changes the execution context for all *downstream* operators. It affects where the subscriber receives values. The most common use case is `receive(on: DispatchQueue.main)` to ensure that UI updates happen on the main thread.
// -   **`subscribe(on:)`:** This operator changes the execution context for the *upstream* work, including the subscription itself and any work the publisher does to produce values. For example, you would use `subscribe(on: DispatchQueue.global())` to make a network request on a background thread. The position of these operators in the chain is critical.

// Q: What is the purpose of `eraseToAnyPublisher()`?
// A: `eraseToAnyPublisher()` is a form of type erasure. It hides the complex, specific type of a publisher chain and wraps it in a simple `AnyPublisher<Output, Failure>` type. This is useful for:
// 1.  **API Design:** When returning a publisher from a function, you can hide the implementation details of your operator chain. This makes your API cleaner and allows you to change the internal implementation without breaking the public contract.
// 2.  **Simplifying Types:** Storing publishers with long, complex types (e.g., `Publishers.Map<Publishers.Filter<...>>`) can be cumbersome. Erasing the type makes it much easier to manage.

// Q: Explain the difference between `combineLatest`, `merge`, and `zip`.
// A:
// -   **`combineLatest`:** Takes two or more publishers. It waits for all publishers to emit at least one value. After that, it emits a new tuple of the latest values whenever *any* of the input publishers emits a new value. It's great for combining multiple states that contribute to a single view (e.g., form validation).
// -   **`merge`:** Takes two or more publishers of the *same type*. It interleaves the values from all publishers into a single stream as they are emitted. The order depends on the timing of the emissions.
// -   **`zip`:** Takes two or more publishers. It waits for each publisher to emit a value at a corresponding "index" and then emits a tuple of those values. It pairs the 1st value from each, then the 2nd from each, and so on. It will only emit as many tuples as the publisher with the fewest emissions.

// MARK: - EXPERT / VERY ADVANCED

// Q: How would you create a custom Publisher?
// A: To create a custom publisher, you must conform to the `Publisher` protocol. This involves:
// 1.  Defining the associated types `Output` and `Failure`.
// 2.  Implementing the `receive<S: Subscriber>(subscriber: S)` method.
// 3.  Inside `receive(subscriber:)`, you typically create a custom `Subscription` object. This subscription object is responsible for handling the subscriber's demand and sending values.
// 4.  You pass this custom subscription to the subscriber's `receive(subscription:)` method. The subscription object is the link that manages the flow of data according to the subscriber's requests (backpressure).

// Q: What are `ConnectablePublisher`s and when are they useful?
// A: A `ConnectablePublisher` is a special type of publisher that does not start emitting values as soon as a subscriber attaches. Instead, it waits until its `connect()` method is called. This is known as "cold" behavior until connected.
// It is useful for **multicasting**, where you want multiple subscribers to receive the exact same sequence of values from a single subscription. You can attach all your subscribers first, and then call `connect()` once to start the underlying work (e.g., a single network request). Operators like `share()` and `multicast()` create `ConnectablePublisher`s.

// Q: How do you manage memory and avoid retain cycles in Combine, especially with `.sink`?
// A: The most common retain cycle occurs when an object (e.g., a ViewModel) stores a cancellable for a subscription, and the subscription's closure (e.g., in `.sink`) captures a strong reference back to the object.
// `self` -> `cancellables` (property) -> `subscription` -> `sink closure` -> `self`
// The solution is to use a weak capture list in the closure:
// ```swift
// .sink { [weak self] value in
//     guard let self = self else { return }
//     self.myProperty = value
// }
// .store(in: &cancellables)
// ```
// By capturing `[weak self]`, the closure holds a weak reference to the object, breaking the strong reference cycle.

// Q: How does Combine integrate with Swift's modern concurrency (`async/await`)?
// A: Combine and `async/await` are highly interoperable.
// 1.  **Consuming a Publisher with `async/await`:** Any `Publisher` has a `.values` property, which is an `AsyncSequence`. You can iterate over it using a `for await...in` loop. This provides a natural, imperative way to handle a stream of values.
// 2.  **Getting a single value:** You can `await` the `publisher.firstValue` property to suspend execution until the publisher emits its first value or finishes.
// 3.  **Creating a Publisher from an `async` operation:** You can use a `Future` publisher or create a custom publisher to wrap an `async` function call, bridging the `async/await` world back into a declarative Combine pipeline.

class AdvancedCombineBootcampViewModel: ObservableObject {
    @Published var dataFromPublished: [String] = []
    @Published var dataFromCurrentValue: [String] = []
    @Published var dataFromPassthrough: [String] = []
    @Published var error: String? = nil

    let dataService = AdvancedCombineDataService()
    var cancellables = Set<AnyCancellable>()

    init() {
        addSubscribers()
    }

    private func addSubscribers() {
        dataService.$publishedProperty
            .map { "Published: \($0)" }
            .sink { [weak self] in self?.dataFromPublished.append($0) }
            .store(in: &cancellables)

        dataService.currentValuePublisher
            .map { "CurrentValue: \($0)" }
            .sink { [weak self] in self?.dataFromCurrentValue.append($0) }
            .store(in: &cancellables)

        dataService.passthroughPublisher

        // MARK: - SEQUENCE OPERATORS (Uncomment one at a time to test)
        // Assumes input sequence: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

        // .first()                       // Outputs: 0
        // .first(where: { $0 > 4 })       // Outputs: 5
        // .tryFirst(where: { int in
        //     if int == 3 { throw URLError(.badURL) }
        //     return int > 1
        // })                             // Outputs: 2

        // .last()                         // **REQUIRES COMPLETION**. Outputs: 10
        // .last(where: { $0 < 4 })         // **REQUIRES COMPLETION**. Outputs: 3
        // .tryLast(where: { int in
        //     if int == 3 { throw URLError(.badURL) }
        //     return int < 5
        // })                             // **REQUIRES COMPLETION**. Outputs: Error

        // .dropFirst(3)                    // Outputs: 3, 4, 5, 6, 7, 8, 9, 10
        // .drop(while: { $0 < 5 })         // Outputs: 5, 6, 7, 8, 9, 10
        // .prefix(3)                       // Outputs: 0, 1, 2
        // .prefix(while: { $0 < 5 })       // Outputs: 0, 1, 2, 3, 4

        // .output(at: 5)                   // Outputs: 5
        // .output(in: 2...4)               // Outputs: 2, 3, 4

        // MARK: - MATHEMATIC OPERATIONS

        // .max()                           // **REQUIRES COMPLETION**. Outputs: 10
        // .min()                           // **REQUIRES COMPLETION**. Outputs: 0

        // MARK: - MAPPING & FILTERING
        // NOTE: These are "streaming" operators. They process values as they arrive
        // and DO NOT need to wait for the publisher to send a .finished completion event.

        // .compactMap({ int in
        //     if int == 5 { return nil }
        //     return "\(int)"
        // })                               // Outputs: "0", "1", "2", "3", "4", "6", "7", "8", "9", "10"
        // .filter({ ($0 > 3) && ($0 < 7) }) // Outputs: 4, 5, 6
        // .removeDuplicates()              // Assumes input: 1, 2, 2, 3 -> Outputs: 1, 2, 3
        // .replaceEmpty(with: 5)           // **REQUIRES COMPLETION**. Assumes input: Empty() -> Outputs: 5

        // MARK: - ACCUMULATION & ERROR HANDLING
        // Assumes input sequence: 1, 2, 3, 4, 5

        // .replaceError(with: "DEFAULT VALUE") // If an error occurs, stream stops and outputs this value.
        // .scan(0, +)                      // Outputs each intermediate sum: 1, 3, 6, 10, 15
        // .reduce(0, +)                    // **REQUIRES COMPLETION**. Outputs one final value: 15

        // MARK: - COLLECTION & VALIDATION
        /*
         BEGINNER / INTERVIEW DETAILS:
         - `collect` is a "buffering" operator. It waits for values and groups them, unlike `map` or `filter` which process items one-by-one.
         - `collect()` waits for the `.finished` completion event, then emits a single array of all items.
         - `collect(count)` emits an array every time it gathers `count` items. It's great for batching.
         - `allSatisfy` is a validation operator. It outputs a single `Bool`. It will output `false` immediately if a value fails the condition, but must wait for completion to output `true`.
         */
        // Assumes input sequence: 1, 2, 3, 4, 5, 6, 7

        // .collect()                      // **REQUIRES COMPLETION**. Outputs one array: [1, 2, 3, 4, 5, 6, 7]
        // .collect(3)                     // Outputs arrays in batches: [1, 2, 3], then [4, 5, 6], then [7] on completion.
        // .allSatisfy({ $0 < 50 })        // **REQUIRES COMPLETION** (to be true). Outputs: true
        // .tryAllSatisfy()

        // MARK: - TIMING OPERATIONS
        /*
         BEGINNER / INTERVIEW DETAILS:
         - `debounce` is great for search bars. It waits for the user to stop typing before sending a network request.
         - `throttle` is great for limiting events that fire rapidly, like button taps or scroll events. It ensures an event is only processed once per interval.
         - `delay` simply shifts all events forward in time.
         */

        // .debounce(for: 0.75, scheduler: DispatchQueue.main) // Waits for a 0.75s pause, then publishes the latest value.
        // .delay(for: 2, scheduler: DispatchQueue.main)      // Delays every value by 2 seconds.
        // .measureInterval(using: DispatchQueue.main)        // Outputs the time elapsed between each published value.
        // .map({ stride in
        //     return "\(stride.timeInterval)"
        // })
        // .throttle(for: 5, scheduler: DispatchQueue.main, latest: true) // Publishes the *last* value received during the 5-second interval.
        // .throttle(for: 5, scheduler: DispatchQueue.main, latest: false) // Publishes the *first* value received, then ignores others for 5 seconds.
        // .retry(3)                                          // If the publisher fails, it will try again up to 3 times.
        // .timeout(0.75, scheduler: DispatchQueue.main)      // If no value is received in 0.75s, the publisher fails.

        // MARK: - Combining Publishres

        // .combineLatest(dataService.boolPublisher, dataService.intPublisher)
        //     .map({ (int1, bool, int2) in
        //         return "Int1: \(int1), Bool: \(bool), Int2: \(int2)"
        //     })
        //     // Waits for ALL publishers to emit at least one value.
        //     // Then, it emits a new tuple whenever ANY of the publishers emits a new value.
        //     // Outputs:
        //     // "Int1: 1, Bool: true, Int2: 100"  (after all three have emitted once)
        //     // "Int1: 2, Bool: true, Int2: 100"  (when passthroughPublisher emits 2)
        //     // "Int1: 2, Bool: false, Int2: 100" (when boolPublisher emits false)
        //     // "Int1: 2, Bool: false, Int2: 200" (when intPublisher emits 200)

        // .merge(with: dataService.intPublisher)
        //     // Merges two publishers of the SAME TYPE into one stream.
        //     // It simply interleaves the values as they are emitted.
        //     // Outputs (order depends on timing): 1, 100, 2, 200

        // .zip(dataService.boolPublisher, dataService.intPublisher)
        //     .map({ (int1, bool, int2) in
        //         return "Int1: \(int1), Bool: \(bool), Int2: \(int2)"
        //     })
        //     // Waits for each publisher to emit a value at a matching "index".
        //     // It pairs up emissions: the 1st from each, then the 2nd from each, etc.
        //     // Outputs:
        //     // "Int1: 1, Bool: true, Int2: 100" (waits for the first value from all three)
        //     // "Int1: 2, Bool: false, Int2: 200" (waits for the second value from all three)
        //     // Note: It will not emit again until a 3rd value is sent from all three publishers.


        // MARK: - ERROR HANDLING
        /*
         BEGINNER / INTERVIEW DETAILS:
         - `tryMap` is identical to `map`, but its closure can throw an error. If an error is thrown, the publisher immediately fails and terminates.
         - `catch` is a powerful operator that intercepts a failure from an upstream publisher. It must return a *new publisher* of the same Output type. The subscription then switches to this new publisher. This is great for providing a fallback data source.
         - `replaceError` is simpler: it just replaces a failure with a single default value and then finishes.
         */
        // Assumes input sequence: 1, 2, 3, 4, 5, 6, 7
        // Assumes dataService.intPublisher will emit: 100, 200

        // .tryMap({ int in
        //     if int == 5 {
        //         throw URLError(.badServerResponse)
        //     }
        //     return int
        // })
        // .catch({ error in
        //     // When tryMap throws an error, this block is executed.
        //     // It must return a new publisher to take over the stream.
        //     return self.dataService.intPublisher
        // })
        // // Outputs: 1, 2, 3, 4 (from original publisher)
        // // Then, when 5 causes an error, it switches to the new publisher.
        // // Outputs: 100, 200 (from intPublisher)
        // // Final combined output: 1, 2, 3, 4, 100, 200
        // // Note: 6 and 7 from the original publisher are never received because it terminated.



            .map { "Passthrough: \($0)" }
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.error = "ERROR: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] returnedValue in
                    self?.dataFromPassthrough.append(returnedValue)
                }
            )
            .store(in: &cancellables)

    }
}

import SwiftUI

struct AdvancedCombineBootcamp: View {
    
    @StateObject private var vm = AdvancedCombineBootcampViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                if let error = vm.error {
                    Text(error).foregroundColor(.red)
                }

                Text("Data from @Published").font(.title.bold())
                ForEach(vm.dataFromPublished, id: \.self) { Text($0) }

                Divider().padding()

                Text("Data from CurrentValueSubject").font(.title.bold())
                ForEach(vm.dataFromCurrentValue, id: \.self) { Text($0) }

                Divider().padding()

                Text("Data from PassthroughSubject").font(.title.bold())
                ForEach(vm.dataFromPassthrough, id: \.self) { Text($0) }
            }
            .padding()
        }
    }
}


// rmekove duplciates nee dto ahjbev bnack tlo backmn opublsuefgrt
