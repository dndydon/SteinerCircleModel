# SteinerCircleModel

Pure geometry for [Steiner chains](https://en.wikipedia.org/wiki/Steiner_chain) —
rings of circles packed between an outer and inner bounding circle — and for
[Soddy's hexlet](https://en.wikipedia.org/wiki/Soddy%27s_hexlet), its 3D analog with spheres.

## Products

| Library | Purpose | Dependencies |
|---------|---------|--------------|
| `SteinerCircleModel` | Geometry only | `Foundation`, `CoreGraphics` |
| `SteinerCircleUI` | SwiftUI drawing helpers and an interactive demo | `SteinerCircleModel`, `SwiftUI` |
| `SoddyHexletModel` | 3D hexlet geometry (see [Soddy's Hexlet](#soddys-hexlet)) | `SteinerCircleModel`, `simd` |
| `SoddyHexletUI` | A `RealityView` hexlet demo | `SoddyHexletModel`, `RealityKit`, `SwiftUI` |

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

Pass `gap: 0` for exactly tangent neighbors.

### Multiple Windings

`windings` wraps the chain around the center more than once, forming a star.
Each circle stays tangent to its neighbors (index *i* and *i* + 1) and to both
boundaries; non-neighbors overlap.

```swift
// 7 circles over 2 turns
let star = SteinerCircle(outerRadius: 10, circleCount: 7, windings: 2)
```

`windings` is clamped to 1...(*n* − 1)/2. Choose a count and winding number
with no common factor; otherwise the chain retraces a smaller one and circles coincide.

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

### Focus, Fitting, and Hit Testing

Focus a circle by index instead of placing the inversion center by hand.
`magnification` is the ratio of the largest to the smallest chain circle.

```swift
let chain = SteinerCircle(outerRadius: 10, circleCount: 8)

if let focused = chain.focused(on: 3, magnification: 4) {
  focused.largestIndex   // 3
  focused.smallestIndex  // 7 — the circle opposite

  // Scale and center the result so its bounding circle fills a view.
  // The bounding circle stays fixed as the focus changes; only the
  // inner circle and chain move.
  let fitted = focused.fitted(in: CGRect(x: 0, y: 0, width: 360, height: 360))

  // Hit-test a tap in the same (view) coordinates.
  let tapped = fitted.chainIndex(containing: tapLocation)  // Int?
}

// Or get the inversion itself, e.g. to animate toward it.
let inversion = chain.inversion(focusingOn: 3, magnification: 4)
```

`fittingTransform(in:)` returns the `CGAffineTransform` that `fitted(in:)` applies,
for mapping other points into view coordinates (or back, with `.inverted()`).

When the inversion center is inside the inner circle, inversion swaps the
boundaries: `innerCircle` becomes the enclosing circle. `boundingCircle`
always returns whichever one encloses the chain.

### Moving, Scaling, and Nesting

`fitted(in:)` also takes a `Circle2D`, and `placed(in:)` puts a concentric chain
inside one. Together they nest chains inside the circles of other chains.

```swift
let outer = SteinerCircle(outerRadius: 10, circleCount: 6)
let host = outer.chainCircles[2]

// A concentric chain whose outer circle is `host`
let nested = SteinerCircle(outerRadius: 1, circleCount: 5).placed(in: host)

// An inverted chain whose bounding circle is `host`
let nestedInverted = SteinerCircle(outerRadius: 1, circleCount: 5)
  .focused(on: 0, magnification: 3)?
  .fitted(in: host)

// Move and scale single circles
let moved = host.offsetBy(dx: 2, dy: 0)
let half = host.scaled(by: 0.5, about: host.center)
```

`placed(in:)` returns an `InvertedSteinerChain`, the type for a chain at a
position; its circles stay concentric and equal.

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

![Steiner circle demo](Steiner%20Circle%20Demo.png)

- **Circles** / **Gap** sliders adjust the chain geometry in real time
- **Windings** stepper wraps the chain into a star (up to (*n* − 1)/2 turns)
- **Circle Inversion** toggle switches to the inverted (non-concentric) view
- **Rotate Chain** toggle animates `phase`
- **Drag** on the canvas to move the inversion center and see the cascade effect;
  the outer boundary stays fixed while the inner circle and chain move
- **Tap** a chain circle to focus it
- **Double-click** to re-center the inversion view

Open the file in Xcode and choose **Editor > Canvas** to use it.
The demo isn't available on tvOS, which lacks `Slider` and `DragGesture`.

## Soddy's Hexlet

A hexlet is a ring of six spheres, each tangent to its two neighbors and to
three mutually tangent spheres A, B, and C. However the ring is rolled, it
closes — the 3D version of Steiner's porism.

| Type | Purpose |
|------|---------|
| `SoddyHexlet` | Standard form: planes A and B at z = ±*r*, nucleus C of radius *r*, six ring spheres of radius *r* |
| `InvertedSoddyHexlet` | A general hexlet: spheres `a`, `b`, `c` and the six-sphere ring `spheres` |
| `Sphere3D` | Sphere value type (`SIMD3<Double>` center + radius), with `Float` accessors for RealityKit |
| `Plane3D` | Plane value type; its normal points into the side it bounds |
| `SphereInversion` | Inversion through a sphere — maps points, spheres, and planes, with signed curvature of each image |
| `HexletError` | Why three spheres can't hold a hexlet |

### Standard Form and Inversion

The standard form is built by composition: its z = 0 slice is a six-circle
`SteinerCircle` with outer radius 3*r* and no gap, lifted into 3D.

```swift
import SoddyHexletModel

let hexlet = SoddyHexlet(radius: 1, phase: 0.3)
hexlet.ringSpheres  // [Sphere3D], centers 2r from the origin, 60° apart
hexlet.nucleus      // Sphere3D at the origin
hexlet.planeA       // Plane3D, z = r
hexlet.slice        // the SteinerCircle cross-section

// Invert it into a general hexlet; nil if the center lies on any sphere or plane
let inversion = SphereInversion(center: [0.3, 0, 0.2], radius: 1)
if let general = hexlet.inverted(through: inversion) {
  general.a                // image of plane A (likewise b and c)
  general.spheres          // [Sphere3D] — the ring, now in varying sizes
  general.enclosingSphere  // the sphere containing all others, if any
}
```

As in 2D, the model is a pure function of `phase`. When the inversion center
lies inside one of the original regions (the nucleus, a ring sphere, or beyond
a plane), that sphere's image encloses all the others.

### From Three Tangent Spheres

`init(tangentTo:_:_:phase:)` builds the hexlet around any three mutually
tangent spheres. Any pair may touch internally, so `a` can enclose the others.

```swift
let outer = Sphere3D(center: .zero, radius: 3)
let inner = Sphere3D(center: [0, 0, 1], radius: 2)
let nucleus = Sphere3D(center: [0, 0, -2], radius: 1)

do {
  let hexlet = try InvertedSoddyHexlet(tangentTo: outer, inner, nucleus, phase: 0)
  hexlet.spheres  // six spheres, each tangent to all three and to its neighbors
} catch {
  // .notMutuallyTangent or .degenerate
}
```

It inverts at the point where `a` and `b` touch, which turns them into parallel
planes, builds the standard form between them, and inverts the ring back.
Its `phase` 0 is a fixed but arbitrary starting position, not the same one
as `SoddyHexlet`'s.

### Hexlet Preview

`SoddyHexletPlayground.swift` in `SoddyHexletUI` has a `#Preview` that renders
an inverted hexlet in a `RealityView`, scaled so the enclosing sphere fills the view.

![Soddy hexlet demo](Soddy%20Hexlet%20Demo.png)

- **Phase** slider and **Rotate Ring** toggle roll the ring
- **Inversion X / Y / Z** sliders move the inversion center inside the nucleus
- **Show Enclosing Sphere** toggles the translucent outer sphere
- **Drag** to orbit the camera (not on visionOS)

The demo needs iOS 18, macOS 15, or visionOS 1, and isn't available on tvOS or watchOS.

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, tvOS 17+, watchOS 10+, visionOS 1+
- `SoddyHexletUI` demo: macOS 15+, iOS 18+, visionOS 1+

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
| visionOS | Soddy's hexlet — the 3D analog with spheres in a `RealityView` | Done: `SoddyHexletModel` and `SoddyHexletUI` |

Not a good fit: data where circle size must stand for a quantity
("this color is 40% of the image"). Use a pie chart or circle packing for that.

### API gaps, by how many apps need them

Done in 1.2.0:

1. ~~**Hit-testing**~~ — `Circle2D.contains(_:)`, `chainIndex(containing:)`.
2. ~~**Fit to a rectangle**~~ — `boundingCircle`, `fittingTransform(in:)`, `fitted(in:)`.
3. ~~**Focus by index**~~ — `inversion(focusingOn:magnification:)`, `focused(on:magnification:)`.
4. ~~**Largest and smallest index**~~ — `largestIndex`, `smallestIndex`.

Planned for 1.3.0:

- ~~**Exact tangency**~~ — `gap` is now clamped to at least 0 (was 0.001), so `gap: 0`
  makes neighboring chain circles touch. The default stays 0.001.
- ~~**9. Multiple windings**~~ — `windings`: *n* circles over *m* turns, with θ = *m*π/*n*.
- ~~**5. `Codable` and `Hashable`**~~ on `SteinerCircle`, `Circle2D`, `CircleInversion`,
  and `InvertedSteinerChain`. Decoding a `SteinerCircle` applies the same clamping as `init`,
  and missing `windings`, `gap`, or `phase` take their defaults.
- ~~**6. Move and scale `Circle2D`**~~ (`offsetBy(dx:dy:)`, `scaled(by:about:)`), and build a
  chain inside a given circle (for nesting): `InvertedSteinerChain.fitted(in: Circle2D)` and
  `SteinerCircle.placed(in: Circle2D)`.
- **10. Number types beyond `CGFloat`** — `Float`/SIMD conversions for RealityKit.
  `Double` already works through Swift's implicit `CGFloat` conversion.

Planned for 1.4.0:

- **8. Tangent points and per-circle spin angle** for games and connector lines —
  `spinAngle(at:rollingOn:)` with `.outer` or `.inner` as the fixed boundary.
- **7. Friendlier inversion failures** — `inverted(through:)` returns `nil` if any one circle
  passes through the inversion center, which can blank a frame mid-drag. Add a
  typed-throws variant that reports which circle failed; the optional API stays.
  Returning a line in its place is deferred.

## License

MIT
