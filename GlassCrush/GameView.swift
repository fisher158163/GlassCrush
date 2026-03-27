//
//  GameView.swift
//  GlassCrush
//
//  Created by fisher on 2026/3/27.
//

import SwiftUI

struct GameView: View {
    @StateObject var vm = GameViewModel()
    
    let grid = Array(repeating: GridItem(.flexible()), count: 8)
    
    var body: some View {
        GeometryReader { proxy in
            let canvasSize = min(proxy.size.width, proxy.size.height)
            let gridPadding: CGFloat = 20
            let tileSpacing: CGFloat = 10
            let tileSize = (canvasSize - (gridPadding * 2) - (tileSpacing * CGFloat(vm.size - 1))) / CGFloat(vm.size)
            
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.18),
                        Color(red: 0.06, green: 0.07, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: canvasSize * 0.75, height: canvasSize * 0.75)
                    .offset(x: -canvasSize * 0.25, y: -canvasSize * 0.2)
                    .blur(radius: 20)
                
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: canvasSize * 0.6, height: canvasSize * 0.6)
                    .offset(x: canvasSize * 0.3, y: canvasSize * 0.35)
                    .blur(radius: 24)
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Glass Crush")
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            Text("Swap to match 3+ tiles")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                        Button("New Board") {
                            vm.resetGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white.opacity(0.15))
                    }
                    .padding(.horizontal, 20)
                    .foregroundStyle(.white)
                    
                    HStack(spacing: 10) {
                        StatPill(title: "Score", value: "\(vm.score)")
                        StatPill(title: "Moves", value: "\(vm.moves)")
                        StatPill(title: "Combo", value: vm.combo > 0 ? "x\(vm.combo)" : "—")
                        if vm.lastMatchCount > 0 {
                            StatPill(title: "Match", value: "\(vm.lastMatchCount)")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 12)
                        
                        LazyVGrid(columns: grid, spacing: tileSpacing) {
                            ForEach(0..<vm.size, id: \.self) { row in
                                ForEach(0..<vm.size, id: \.self) { col in
                                    let tile = vm.board[row][col]
                                    tileView(tile: tile, row: row, col: col, tileSize: tileSize)
                                }
                            }
                        }
                        .padding(gridPadding)
                    }
                    .padding(.horizontal, 20)
                    .overlay {
                        SparkleBurst(trigger: vm.matchPulse)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func tileView(tile: Tile, row: Int, col: Int, tileSize: CGFloat) -> some View {
        let isSelected = vm.selected?.row == row && vm.selected?.col == col
        
        Circle()
            .fill(tile.type.color.gradient)
            .frame(width: tileSize, height: tileSize)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isSelected ? 0.9 : 0.0), lineWidth: 3)
                    .blur(radius: isSelected ? 0 : 4)
            )
            .shadow(color: tile.type.color.opacity(0.4), radius: 8, x: 0, y: 6)
            .scaleEffect(isSelected ? 1.12 : 1.0)
            .rotationEffect(.degrees(isSelected ? 4 : 0))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
            .onTapGesture {
                vm.select(row: row, col: col)
            }
            .glassBackgroundEffect()
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

private struct SparkleBurst: View {
    let trigger: Int
    
    @State private var animate = false
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                guard animate else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                var rng = SeededRandomNumberGenerator(seed: UInt64(trigger * 9973))
                
                for _ in 0..<26 {
                    let angle = Double.random(in: 0...(2 * .pi), using: &rng)
                    let distance = Double.random(in: 40...140, using: &rng)
                    let radius = Double.random(in: 2...5, using: &rng)
                    
                    let point = CGPoint(
                        x: center.x + CGFloat(cos(angle) * distance),
                        y: center.y + CGFloat(sin(angle) * distance)
                    )
                    
                    let rect = CGRect(
                        x: point.x - CGFloat(radius),
                        y: point.y - CGFloat(radius),
                        width: CGFloat(radius * 2),
                        height: CGFloat(radius * 2)
                    )
                    
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.6)))
                }
            }
        }
        .opacity(animate ? 1 : 0)
        .scaleEffect(animate ? 1.0 : 0.7)
        .animation(.easeOut(duration: 0.5), value: animate)
        .onChange(of: trigger) { _, _ in
            animate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                animate = false
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed == 0 ? 0x1234567890ABCDEF : seed
    }
    
    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1
        return state
    }
}
