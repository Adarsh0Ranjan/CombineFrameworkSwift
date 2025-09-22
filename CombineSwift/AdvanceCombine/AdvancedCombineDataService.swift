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
