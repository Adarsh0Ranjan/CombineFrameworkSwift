//
//  Timer.swift
//  CombineSwift
//
//  Created by Adarsh Ranjan on 15/09/25.
//

import SwiftUI

struct TimerBootcamp: View {
    // Publisher that emits a value every 1 second
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    @State var currentDate: Date = Date()

    // Formatter to display the time as a readable string
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }

    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [Color.purple, Color.black]),
                center: .center,
                startRadius: 5,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Display formatted current time
            Text(dateFormatter.string(from: currentDate))
                .font(.system(size: 100, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.1)
        }
        // Update currentDate every second
        .onReceive(timer) { value in
            currentDate = value
        }
    }
}

//📘 Learnings (Interview Style Notes)
//
//Timer.publish(every:on:in:) creates a Combine publisher that emits values at regular intervals.
//
//    .autoconnect() automatically starts the timer without needing manual connection.
//
//    .onReceive(timer) lets you subscribe to the publisher and update your state.
//
//DateFormatter converts Date → user-friendly string.
//


