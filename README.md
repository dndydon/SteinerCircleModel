# SteinerCircleModel

Pure geometry for [Steiner chains](https://en.wikipedia.org/wiki/Steiner_chain) —
rings of circles packed between an outer and inner bounding circle.

## Products

| Library | Purpose | Dependencies |
|---------|---------|--------------|
| `SteinerCircleModel` | Geometry only | `Foundation`, `CoreGraphics` |
| `SteinerCircleUI` | SwiftUI drawing helpers and an interactive demo | `SteinerCircleModel`, `SwiftUI` |

Depend on `SteinerCircleModel` alone when you don't need SwiftUI.
All model types are `Sendable`, and the package builds in Swift 6 language mode.

## Types

| Type | Purpose |
|------|---------|
| `SteinerCircle` | Compute geometry for N equal circles in a concentric chain |
| `Circle2D` | Simple circle value type (center + radius) |
| `CircleInversion` | Möbius circle inversion — maps circles to circles |
| `InvertedSteinerChain` | Result of inverting a concentric chain into a non-concentric one |
| `Path.init(_:scale:offset:)` | (`SteinerCircleUI`) A SwiftUI `Path` for a `Circle2D` |

## Usage

### Basic Steiner Chain

```swift
import SteinerCircleModel

// 6 circles inside a unit circle, with a small gap between each circle
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

### Rotating the Chain

`phase` rotates every chain circle around the center. By Steiner's porism,
the inverted chain stays tangent to both bounding circles at any phase, so
animating `phase` makes the inverted chain roll around itself.

```swift
let chain = SteinerCircle(outerRadius: 10, circleCount: 8, phase: .pi / 8)
```

The model is a pure function of `phase` — it holds no time or animation state.
Your app owns timing: pausing, resuming, easing, or snapping back to zero.

### SwiftUI Example

```swift
import SteinerCircleModel
import SteinerCircleUI
import SwiftUI

struct SteinerChainView: View {
  let chain = SteinerCircle(outerRadius: 150, circleCount: 8)

  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)

      context.stroke(Path(chain.outerCircle, offset: center), with: .color(.gray))
      for circle in chain.chainCircles {
        context.stroke(Path(circle, offset: center), with: .color(.blue))
      }
    }
  }
}
```

## Interactive Preview

`SteinerCircleUI` includes a `#Preview` in `SteinerCirclePlayground.swift` for visualizing
both the concentric chain and the circle-inversion transform directly in Xcode's canvas.

- **Circles** / **Gap** sliders adjust the chain geometry in real time
- **Circle Inversion** toggle switches to the inverted (non-concentric) view
- **Rotate Chain** toggle animates `phase`
- **Drag** on the canvas to move the inversion center and see the cascade effect
- **Double-click** to re-center the inversion view

Open the file in Xcode and choose **Editor > Canvas** to use it.
The demo isn't available on tvOS, which lacks `Slider` and `DragGesture`.

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, tvOS 17+, watchOS 10+, visionOS 1+

## Roadmap

Ideas for the next version, found by working through how apps might use the library.

### Degrees of freedom

A Steiner chain has few free parameters:

- **Concentric layout:** circle count, gap, and phase.
- **Inversion center:** a 2D offset that picks which circle is largest and how lopsided the chain is.
  The chain circle nearest the inversion center becomes the largest.
- **Inversion radius:** only scales the whole result uniformly, so it cancels out once an app fits the result to a frame.

Circle sizes therefore **can't encode arbitrary data** — they always follow one
smooth curve from largest to smallest around the ring. The library's strength is
a **smooth fisheye around a ring**: one item large, its neighbors tapering, and
the whole ring able to roll.

### Application ideas

| Application | How it uses the chain | Gaps it reveals |
|---|---|---|
| Photo screensaver (macOS ScreenSaver, tvOS, iPad standby) | Photos rotate through the chain; swap a photo while it's smallest | Largest/smallest index; fit to a rectangle |
| Focus picker for cyclic items (hours, months, hues, contacts, playlists) | Selected item large, neighbors taper | Focus by index and magnification |
| Color palettes and photo color analysis | Swatches in the ring, photo or selected color in the inner circle | `Codable`/`Hashable`/`Transferable` for saving and sharing |
| Photo library or email threads | Nested chains: albums → photos, thread → replies or participants | Build a chain inside an existing `Circle2D`; move/scale helpers |
| Games (porism puzzle, rolling marbles, gears) | Rotate and invert to align targets; chain rolls between boundaries | Hit-testing; per-circle spin angle; tangent points |
| Data visualization of cyclic data (week, year, 24-hour clock) | Focus plus context, with "now" enlarged | Focus by index |
| Generative art | Multi-winding star chains; nested chains approaching Apollonian-like fractals | Multiple windings |
| visionOS | Soddy's hexlet — the 3D analog with spheres in a `RealityView` | `Sphere3D`, 3D inversion, `Float`/SIMD types |

Not a good fit: data where circle size must stand for a quantity
("this color is 40% of the image"). Use a pie chart or circle packing for that.

### API gaps, by how many apps need them

1. **Hit-testing** — `Circle2D.contains(_:)` and "which chain circle contains this point".
2. **Fit to a rectangle** — bounding box and scale-to-fit transform. The demo does this by hand today.
3. **Focus by index** — `focused(on:magnification:)`: point the inversion offset at item *k*'s angle and solve for its distance.
4. **Largest and smallest index** of an inverted chain.
5. **`Codable` and `Hashable`** on `SteinerCircle` and `Circle2D`.
6. **Move and scale `Circle2D`**, and build a chain inside a given circle (for nesting).
7. **Friendlier inversion failures** — `inverted(through:)` returns `nil` if any one circle passes through the inversion center, which can blank a frame mid-drag. Report which circle failed, or return a line in its place.
8. **Tangent points and per-circle spin angle** for games and connector lines.
9. **Multiple windings** — *n* circles over *m* turns, a small change to the `theta` formula.
10. **Number types beyond `CGFloat`** — `Float`/SIMD for RealityKit, `Double` for Charts.

Also: `gap` is clamped to at least 0.001, so neighboring chain circles never
exactly touch. Games and connector lines want exact tangency.

## License

MIT
