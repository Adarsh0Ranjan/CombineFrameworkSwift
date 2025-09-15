//
//  DownloadWithCombine.swift
//  CombineSwift
//
//  Created by Adarsh Ranjan on 15/09/25.
//

import SwiftUI
import Combine

import SwiftUI
import Combine

struct DownloadWithCombine: View {
    @StateObject var viewModel = DownloadWithCombineViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.posts) { post in
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title.capitalized)
                        .font(.headline)
                    Text(post.body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Posts")
        }
    }
}



class DownloadWithCombineViewModel: ObservableObject {
    @Published var posts: [Post] = []
    var cancellables: Set<AnyCancellable> = []

    init () {
        getPost()
    }


    func getPost() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }

        // 1. sign up for monthly subscription for package to be delivered
        // 2. the company would make the package behind the scene
        // 3. receive the package at your front door
        // 4. make sure the box isn't damaged
        // 5. open and make sure the item is correct
        // 6. use the item!!!!
        // 7. cancellable at any time!!

        // 1. create the publisher
        // 2. subscribe publisher on background thread
        // 3. receive on main thread
        // 4. tryMap (check that the data is good)
        // 5. decode (decode data into PostModels)
        // 6. sink (put the item into our app)
        // 7. store (cancel subscription if needed)

        URLSession.shared.dataTaskPublisher(for: url)
            .subscribe(on: DispatchQueue.global(qos: .background))   // background thread
            .receive(on: DispatchQueue.main)                        // main thread
            .tryMap { (data, response) -> Data in                   // check response
                guard let response = response as? HTTPURLResponse,
                      response.statusCode >= 200 && response.statusCode < 300 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: [Post].self, decoder: JSONDecoder()) // decode JSON
            .replaceError(with: [])
            .sink { (completion) in
                print("COMPLETION: \(completion)")
            } receiveValue: { [weak self] returnedPosts in
                self?.posts = returnedPosts                         // assign to posts
            }
            .store(in: &cancellables)                               // keep subscription
    }
}

/// 📘 Learnings (Interview Style Notes)
/// - Combine was launched in **iOS 13**.
/// - `dataTaskPublisher` from `URLSession` is **always on a background thread** by default.
/// - Key Combine steps:
///   1. Create a publisher (URLSession).
///   2. `subscribe(on:)` → perform work on background thread.
///   3. `receive(on:)` → deliver results on main thread for UI updates.
///   4. `tryMap` → validate response.
///   5. `decode` → map JSON to Swift model.
///   6. `sink` → receive values and completion.
///   7. `store(in:)` → retain cancellable for subscription lifecycle.
///   ✅ If you use .replaceError(with: []), you can ignore the completion closure in sink and only keep the receiveValue.

