//
//  GameViewModel.swift
//  GlassCrush
//
//  Created by fisher on 2026/3/27.
//

import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    let size = 8
    
    @Published var board: [[Tile]] = []
    @Published var selected: (row: Int, col: Int)?
    @Published var score = 0
    @Published var moves = 0
    @Published var combo = 0
    @Published var lastMatchCount = 0
    @Published var matchPulse = 0
    
    init() {
        resetGame()
    }
    
    func generateBoard() {
        board = (0..<size).map { _ in
            (0..<size).map { _ in
                Tile(type: TileType.allCases.randomElement()!)
            }
        }
    }
    
    func resetGame() {
        score = 0
        moves = 0
        combo = 0
        lastMatchCount = 0
        generateBoard()
    }
    
    func select(row: Int, col: Int) {
        if let prev = selected {
            swap(prev, (row, col))
            selected = nil
            moves += 1
            
            if !checkMatches() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.swap(prev, (row, col))
                    self.combo = 0
                }
            }
        } else {
            selected = (row, col)
        }
    }
    
    func swap(_ a: (Int, Int), _ b: (Int, Int)) {
        withAnimation(.spring()) {
            let temp = board[a.0][a.1]
            board[a.0][a.1] = board[b.0][b.1]
            board[b.0][b.1] = temp
        }
    }
    
    func checkMatches() -> Bool {
        var matched = Set<UUID>()
        
        // horizontal
        for row in 0..<size {
            for col in 0..<(size - 2) {
                let t1 = board[row][col]
                let t2 = board[row][col+1]
                let t3 = board[row][col+2]
                
                if t1.type == t2.type && t2.type == t3.type {
                    matched.insert(t1.id)
                    matched.insert(t2.id)
                    matched.insert(t3.id)
                }
            }
        }
        
        // vertical
        for col in 0..<size {
            for row in 0..<(size - 2) {
                let t1 = board[row][col]
                let t2 = board[row+1][col]
                let t3 = board[row+2][col]
                
                if t1.type == t2.type && t2.type == t3.type {
                    matched.insert(t1.id)
                    matched.insert(t2.id)
                    matched.insert(t3.id)
                }
            }
        }
        
        if !matched.isEmpty {
            lastMatchCount = matched.count
            combo += 1
            score += matched.count * 10 * combo
            matchPulse += 1
            remove(matches: matched)
            return true
        }
        combo = 0
        return false
    }
    
    func remove(matches: Set<UUID>) {
        for col in 0..<size {
            var column = board.map { $0[col] }
            column.removeAll { matches.contains($0.id) }
            
            let newTiles = (0..<(size - column.count)).map { _ in
                Tile(type: TileType.allCases.randomElement()!)
            }
            
            column = newTiles + column
            
            for row in 0..<size {
                board[row][col] = column[row]
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            _ = self.checkMatches()
        }
    }
}

struct Tile: Identifiable, Equatable {
    let id = UUID()
    var type: TileType
}

enum TileType: Int, CaseIterable {
    case red, blue, green, yellow, purple
    
    var color: Color {
        switch self {
        case .red:    return .red
        case .blue:   return .blue
        case .green:  return .green
        case .yellow: return .yellow
        case .purple: return .purple
        }
    }
}
