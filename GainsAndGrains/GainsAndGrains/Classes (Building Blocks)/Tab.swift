//
//  Tab.swift
//  GainsAndGrains
//
//  Created by Vishane Stubbs on 29/05/2025.
//


import Combine

enum Tab {
    case home, exercise, profile
}

class TabRouter: ObservableObject {
    @Published var selectedTab: Tab = .home
    let tabTapped = PassthroughSubject<Tab, Never>()
}