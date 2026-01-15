//
//  ContentView.swift
//  MedicationReminder
//
//  Created by Yuangang Sheng on 15.01.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                MedicationListView()
            }
            .tabItem {
                Label("要吃的药", systemImage: "list.bullet.clipboard")
            }

            NavigationStack {
                MedicationsView()
            }
            .tabItem {
                Label("药物", systemImage: "pills")
            }

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("更多", systemImage: "ellipsis")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
