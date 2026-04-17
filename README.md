# SteinerCircleModel

Pure geometry for [Steiner chains](https://en.wikipedia.org/wiki/Steiner_chain) —
rings of circles packed between an outer and inner bounding circle.

No UI dependencies. Uses only `Foundation` and `CoreGraphics` types (`CGFloat`, `CGPoint`).
All types are `Sendable`.

## Types

| Type | Purpose |
|------|---------|
| `SteinerCircle` | Compute geometry for N equal circles in a concentric chain |
| `Circle2D` | Simple circle value type (center + radius) |
| `CircleInversion` | Möbius circle inversion — maps circles to circles |
| `InvertedSteinerChain` | Result of inverting a concentric chain into a non-concentric one |

## Usage

### Basic Steiner Chain

```swift
import SteinerCircleModel

// 6 circles inside a unit circle, with a small gap
let chain = SteinerCircle(outerRadius: 1, circleCount: 6, gap: 0.05)

chain.rho          // radius of each chain circle
chain.innerRadius  // radius of the inner bounding circle
chain.theta        // half-angle between adjacent centers

// Get individual circle positions (0-based, starts at 12 o'clock)
let angle = chain.centerAngle(at: 0)  // radians
let point = chain.centerPoint(at: 0)  // CGPoint

// Get all chain circles as Circle2D values
let circles = chain.chainCircles  // [Circle2D]
```

### Circle Inversion

Inversion transforms a concentric Steiner chain (equal circles) into a
non-concentric chain (varying sizes) — the classic "cascading circles" effect.

```swift
// Start with a concentric chain
let chain = SteinerCircle(outerRadius: 10, circleCount: 8)

// Define an inversion circle (off-center for the cascade effect)
let inversion = CircleInversion(center: CGPoint(x: 3, y: 0), radius: 8)

// Invert the entire chain
if let inverted = chain.inverted(through: inversion) {
  inverted.outerCircle   // Circle2D — the new outer boundary
  inverted.innerCircle   // Circle2D — the new inner boundary
  inverted.chainCircles  // [Circle2D] — varying-radius chain circles
}
```

Moving the inversion center smoothly animates the chain — drive it with
a gesture or slider for an interactive visualization.

### SwiftUI Example

```swift
struct SteinerChainView: View {
  let chain = SteinerCircle(outerRadius: 150, circleCount: 8)

  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)

      // Draw outer circle
      let outerRect = CGRect(
        x: center.x - chain.outerRadius,
        y: center.y - chain.outerRadius,
        width: chain.outerRadius * 2,
        height: chain.outerRadius * 2
      )
      context.stroke(Path(ellipseIn: outerRect), with: .color(.gray))

      // Draw chain circles
      for circle in chain.chainCircles {
        let rect = CGRect(
          x: center.x + circle.center.x - circle.radius,
          y: center.y + circle.center.y - circle.radius,
          width: circle.radius * 2,
          height: circle.radius * 2
        )
        context.stroke(Path(ellipseIn: rect), with: .color(.blue))
      }
    }
  }
}
```

## Interactive Preview

The package includes a `#Preview` in `SteinerCirclePlayground.swift` for visualizing
both the concentric chain and the circle-inversion transform directly in Xcode's canvas.

- **Circles** / **Gap** sliders adjust the chain geometry in real time
- **Circle Inversion** toggle switches to the inverted (non-concentric) view
- **Drag** on the canvas to move the inversion center and see the cascade effect

Open the file in Xcode and choose **Editor > Canvas** to use it.

## Requirements

- Swift 5.9+
- macOS 14+

## License

MIT
