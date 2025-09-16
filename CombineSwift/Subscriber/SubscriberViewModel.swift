//
//  SubscriberViewModel.swift
//  CombineSwift
//
//  Created by Adarsh Ranjan on 16/09/25.
//

import Combine
import Foundation
import SwiftUI

class SubscriberViewModel: ObservableObject {

    @Published var count: Int = 0
    var cancellables = Set<AnyCancellable>()

    @Published var textFieldText: String = ""
    @Published var textIsValid: Bool = false
    @Published var showButton: Bool = false

    init() {
        setUpTimer()
        addTextFieldSubscriber()
        addButtonSubscriber()
    }

    func setUpTimer() {
        Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.count += 1
            }
            .store(in: &cancellables)
    }

    func addTextFieldSubscriber() {
        $textFieldText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map { (text) -> Bool in
                if text.count > 3 {
                    return true
                }
                return false
            }
            .assign(to: \.textIsValid, on: self) // we can also use sink instead of this
            .store(in: &cancellables)
    }

    func addButtonSubscriber() {
        $textIsValid
            .combineLatest($count)
            .sink { [weak self] (isValid, count) in
                guard let self = self else { return }
                if isValid && count >= 10 {
                    self.showButton = true
                } else {
                    self.showButton = false
                }
            }
            .store(in: &cancellables)
    }

}

import SwiftUI

struct SubscriberView: View {

    @StateObject private var vm = SubscriberViewModel()

    var body: some View {
        VStack(spacing: 20) {

            Text("Timer: \(vm.count)")
                .font(.largeTitle)

            Text(vm.textIsValid ? "Text is valid" : "Text is not valid")
                .font(.headline)
                .foregroundColor(vm.textIsValid ? .green : .red)

            TextField("Type more than 3 characters...", text: $vm.textFieldText)
                .padding(.horizontal)
                .frame(height: 55)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)

            // This is the key change.
            // The button will only be added to the view hierarchy
            // when vm.showButton is true.
            if vm.showButton {
                Button(action: {}) {
                    Text("Submit".uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .animation(.easeInOut, value: vm.showButton) // Animate the button's appearance
    }
}

//Interview Questions & Answers for the Provided Code
//  Question 1: In addTextFieldSubscriber, you use .assign(to:on:). The comment says you could also use .sink. Can you explain the difference between the two and when you would choose one over the other?
//
// Answer:
// Yes. Both .assign(to:on:) and .sink() are subscribers that complete a Combine pipeline, but they serve different purposes.
//
//  .assign(to: \.property, on: object) is a highly specialized subscriber. Its only job is to take the value received from the publisher and assign it directly to a KVO-compliant property on a given object.
//
//  Pros: It's very declarative and concise. The code .assign(to: \.textIsValid, on: self) clearly states its intent: "assign the output to the textIsValid property." It also handles memory management automatically by holding a weak reference to the object, preventing retain cycles.
//
//  Use Case: Use it when your only goal is to update a property with the value from the publisher.
//
//  .sink(receiveValue:) is a more general-purpose subscriber. It takes a closure that is executed every time the publisher emits a new value.
//
//  Pros: It's much more flexible. Inside the closure, you can perform any logic you want—you can assign the value to a property, but you could also print it for debugging, call another function, perform calculations, or trigger other side effects.
//
//  Memory Management: You are responsible for managing memory. If you reference self inside the .sink closure, you must capture it weakly (i.e., [weak self]) to prevent a strong reference cycle, as the subscription is stored in cancellables, which is owned by self.
//
// Use Case: Use it when you need to do more than just a simple property assignment.
//
// In summary: For the code in this example, where the only goal is to update textIsValid, .assign is the cleaner and safer choice. If we needed to, for example, log the validation change to an analytics service, we would have to use .sink.

//Question 2: What is the purpose of the .debounce() operator in the addTextFieldSubscriber function? What would happen if you removed it?
//
// Answer:
//
// The .debounce() operator is used to improve performance and user experience by controlling the rate of events.
//
// What it does: It waits for a specified pause in the stream of published events before passing the latest value downstream. In this code, .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) tells the publisher to wait until the user has stopped typing for half a second before sending the current text from the TextField to the .map operator for validation.
// Why it's important: Without .debounce(), the validation logic inside .map would run on every single keystroke. If a user types "hello", the pipeline would execute 5 times (for "h", "he", "hel", "hell", "hello"). This is inefficient. By debouncing, we only perform the validation once, 0.5 seconds after the user finishes typing "hello". This is especially critical if the validation logic were more complex, like making a network call to check if a username is available.
//The scheduler parameter: Specifying scheduler: DispatchQueue.main is important because the result of this pipeline will eventually update a @Published property, which in turn updates the UI. All UI updates must occur on the main thread.
//
//Question 3: Explain the logic in addButtonSubscriber. What does .combineLatest() do and why is it the correct choice here?
//
//Answer:
//
// The addButtonSubscriber function implements the logic to determine if the "Submit" button should be visible. It depends on two conditions: the text must be valid, AND the timer must have reached at least 10.
//
//What .combineLatest() does: This operator combines two or more publishers into one. It emits a new value (as a tuple) whenever any of its upstream publishers emit a value. The tuple contains the most recent value from all of the publishers it is combining.
//
//Why it's used here: We need to re-evaluate our condition (isValid && count >= 10) whenever either the validation status changes OR the timer count changes.
//
//When the user types valid text, $textIsValid emits true. combineLatest immediately fires with (true, current_count).
//
//While the text is valid, every second the timer ticks, $count emits a new value. combineLatest fires again with (true, new_count).
//
//As soon as count reaches 10 (and isValid is still true), the condition isValid && count >= 10 becomes true, and showButton is set to true.
//
//If we used another operator like .zip, it would wait for both publishers to emit a new value before it would fire. That wouldn't work, because the user might type valid text and then wait several seconds for the timer to tick before the condition is checked. .combineLatest ensures the logic runs immediately on any relevant state change.

//  Question 4: What is the role of the cancellables property and the .store(in: &cancellables) method? What would happen if you removed them?
//
// Answer:
//
//The cancellables property and .store(in:) method are fundamental to managing the lifecycle of a Combine subscription.
//
//Role: When you create a subscription (e.g., with .sink or .assign), it returns a value of type AnyCancellable. This object represents the active subscription. If this AnyCancellable object is deallocated, the subscription is automatically cancelled and stops receiving events.
//
//cancellables Set: The var cancellables = Set<AnyCancellable>() is a property that holds on to all of our active subscriptions. By storing the AnyCancellable instances in this set, we keep them in memory, ensuring our subscriptions stay alive and continue to receive values.
//
//.store(in: &cancellables): This is a convenience method that adds the AnyCancellable to the provided set.
//
//                                                                                                         What happens if you remove them?
//If you removed .store(in: &cancellables), the AnyCancellable returned by .sink or .assign would not be stored anywhere. It would be created and then immediately deallocated at the end of the function's scope (init in this case). As a result, the subscription would be cancelled instantly, and your publishers would never actually send any values to your UI. The timer wouldn't run, and the text validation would never happen.
//
//This mechanism also provides automatic cleanup. When the SubscriberViewModel instance is deallocated, its cancellables property is also deallocated. This deallocation process cancels all stored subscriptions, preventing memory leaks or attempts to update a non-existent object.
