//
//  Post.swift
//  CombineSwift
//
//  Created by Adarsh Ranjan on 15/09/25.
//


import Foundation

struct Post: Codable, Identifiable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
