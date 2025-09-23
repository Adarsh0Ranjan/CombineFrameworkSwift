//
//  FuturesAndPromise.swift
//  CombineSwift
//
//  Created by Adarsh Ranjan on 23/09/25.
//

import SwiftUI
import Combine

// This view demonstrates the use of the ViewModel.
struct FuturesAndPromise: View {
    @StateObject var viewModel = FuturesAndPromiseViewModel()

    var body: some View {
        // Display the title which will be updated by the async operation.
        Text(viewModel.title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .padding()
    }
}

class FuturesAndPromiseViewModel: ObservableObject {

    // The property that will be updated and published to the View.
    @Published var title: String = "Starting Title"

    // A set to store subscriptions to prevent them from being deallocated.
    var cancellables: Set<AnyCancellable> = []

    let url = URL(string: "https://www.apple.com/")!

    init () {
        download()
    }

    // This function orchestrates the download, allowing you to switch between
    // different asynchronous patterns by uncommenting the desired one.
    func download() {
        // --- Option 1: Using a standard Combine Publisher ---
        //        getCombinePublisher()
        //            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
        //                self?.title = value
        //            })
        //            .store(in: &cancellables)

        // --- Option 2: Using a traditional escaping closure (the "old way") ---
        //        getEscapingClosure(completion: { [weak self] value, error in
        //            // Note: This requires manual dispatching to the main thread for UI updates.
        //            DispatchQueue.main.async {
        //                self?.title = value
        //            }
        //        })

        // --- Option 3: Using a Future to wrap the escaping closure ---
        // This is the main focus: bridging the old way with the new Combine way.
        getFuturePublisher()
            .receive(on: DispatchQueue.main) // Ensure UI updates are on the main thread.
            .sink(receiveCompletion: { _ in
                print("Future finished.")
            }, receiveValue: { [weak self] value in
                self?.title = value
            })
            .store(in: &cancellables)
    }

    // This function demonstrates how to wrap an escaping closure-based async operation
    // into a Combine Future.
    // A Future is a publisher that eventually produces a single value and then finishes, or fails.
    func getFuturePublisher() -> Future<String, Error> {
        // The Future initializer takes a closure. This closure is executed immediately.
        // It gives you a `promise`, which is a function you call exactly once to signal the result.
        return Future { promise in
            print("Future is starting its work.")
            // We call our existing closure-based function.
            self.getEscapingClosure(completion: { value, error in
                // Inside the completion handler, we fulfill the promise.
                if let error = error {
                    // If there's an error, we signal failure.
                    promise(.failure(error))
                } else {
                    // If it's successful, we signal success with the value.
                    promise(.success(value))
                }
            })
        }
    }

    // This is a standard Combine pipeline for a network request.
    // It returns a publisher that can be subscribed to.
    func getCombinePublisher() -> AnyPublisher<String, URLError> {
        URLSession.shared.dataTaskPublisher(for: url)
            .timeout(1, scheduler: DispatchQueue.main) // Example operator
            .map({ _ in
                // Transform the output (Data, URLResponse) into a simple String.
                return "New Value from Combine Publisher"
            })
            .eraseToAnyPublisher() // Type-erase to hide implementation details.
    }

    // This is a classic asynchronous function using an escaping closure (completion handler).
    // This pattern is common in older Apple APIs (like UIKit).
    func getEscapingClosure(
        completion: @escaping (_ value: String, _ error: Error? ) -> ()
    ) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            // When the network request finishes, this completion handler is called.
            completion("New Value from Escaping Closure", error)
        }
        .resume() // Don't forget to start the task!
    }
}


// MARK: - COMBINE INTERVIEW QUESTIONS & ANSWERS (Future & Promise)

// MARK: - BEGINNER / FOUNDATIONAL

// Q: What is a `Future` in Combine?
// A: A `Future` is a special type of publisher that eventually produces a single value and then finishes, or it fails. It's designed to wrap asynchronous operations that produce a single result, such as a network request or a complex calculation that runs in the background.

// Q: What is a `Promise` and how does it relate to a `Future`?
// A: A `Promise` is a closure that is passed into the `Future`'s initializer. It's a mechanism to fulfill or reject the `Future`. You call the promise exactly once with either a `.success(Value)` or a `.failure(Error)`. The `Future` holds the eventual result, and the `Promise` is how you provide that result.

// Q: What is the primary use case for a `Future`?
// A: The primary use case is to **bridge** existing asynchronous code that uses completion handlers (escaping closures) into the world of Combine. It allows you to take an old-style async function and make it return a modern Combine publisher, which you can then use with operators like `map`, `filter`, `sink`, etc.

// Q: How is a `Future` different from a `PassthroughSubject`?
// A:
// -   **Values:** A `Future` emits exactly one value (or an error) and then finishes. A `PassthroughSubject` can emit a continuous stream of zero or more values and may never finish.
// -   **State:** A `Future` stores its result. If a new subscriber attaches after the `Future` has completed, it will immediately receive the stored result. A `PassthroughSubject` has no state and new subscribers will only receive values emitted *after* they subscribe.

// MARK: - INTERMEDIATE

// Q: When does the work inside a `Future` begin?
// A: The work inside a `Future`'s closure begins **immediately** upon initialization, not when a subscriber attaches. This is a critical difference from most other publishers, which are "lazy" and only start their work when they receive a subscription. This is known as "eager" execution.

// Q: What happens if you have multiple subscribers for the same `Future` instance?
// A: The asynchronous operation inside the `Future` is only executed once. The `Future` caches its result. All subsequent subscribers will immediately receive the same cached result (either the success value or the failure) without re-running the operation.

// Q: How can you make a `Future` execute its work lazily (i.e., only when a subscriber attaches)?
// A: You can wrap the `Future`'s initialization in a `Deferred` publisher. The `Deferred` publisher takes a closure that creates a publisher. This closure is only executed when a subscriber attaches, effectively delaying the creation (and thus the execution) of the `Future`.
// ```swift
// let lazyFuture = Deferred {
//     Future { promise in
//         // This work now starts on subscription
//     }
// }
// ```

// Q: Can a `Future`'s `Failure` type be `Never`?
// A: Yes. If the asynchronous operation you are wrapping can never fail, you can define the `Future` with a `Failure` type of `Never`. In this case, the promise will only ever be called with `.success(Value)`.

// MARK: - ADVANCED

// Q: Compare and contrast `Future` with `URLSession.dataTaskPublisher`. When would you choose one over the other?
// A:
// -   **`Future`:**
//     -   **Execution:** Eager (starts immediately).
//     -   **Result:** Single-shot. Emits one value/error and finishes. The result is cached.
//     -   **Retries:** Cannot be retried on its own. Since the work is already done and the result is cached, applying a `.retry()` operator will just replay the cached failure.
//     -   **Use Case:** Best for wrapping existing closure-based APIs or for one-off async operations where you want to share the result among multiple subscribers.
// -   **`URLSession.dataTaskPublisher`:**
//     -   **Execution:** Lazy (starts on subscription).
//     -   **Result:** Can emit multiple values (e.g., data chunks, though typically treated as one `(Data, URLResponse)` tuple).
//     -   **Retries:** Can be easily retried with the `.retry()` operator, as each retry will create a new subscription and re-execute the network request.
//     -   **Use Case:** The preferred, idiomatic Combine way to perform network requests. Use it for all new networking code.

// Q: How does `Future` fit into the world of Swift's modern concurrency (`async/await`)?
// A: `Future` acts as an excellent bridge between the callback-based world and the structured concurrency world.
// 1.  **Wrapping `async` code for Combine:** You can wrap an `async` function call inside a `Future` to make its result available to a Combine pipeline.
// 2.  **Legacy Code:** It remains the best tool for converting old APIs to Combine publishers, which can then be consumed by `async/await` using the `.values` property (an `AsyncSequence`).
// However, for new code, if your entire stack supports `async/await`, it's often simpler to use `async` functions directly rather than creating a `Future`.

// Q: You have a delegate-based API that can call a "did receive data" method multiple times. Is `Future` a good choice to wrap this? Why or why not?
// A: No, `Future` is a poor choice for this scenario. A `Future`'s promise can only be fulfilled **once**. If the delegate method is called a second time and you try to call the promise again, it will have no effect (and may trigger a runtime warning). This API is a stream of values, not a single result. A better choice would be to use a `PassthroughSubject` or create a custom `Publisher` that can handle multiple delegate callbacks and forward them as a stream of values to its subscribers.
