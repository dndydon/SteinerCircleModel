/// Pure geometry for a Steiner chain of N equal circles packed
/// between an outer circle and an inner circle.
///
/// Given:
///   - `outerRadius` R — radius of the bounding circle
///   - `circleCount` N — number of chain circles
///   - `gap` — spacing factor (0 = tangent, approaching 1 = maximally spaced)
///
/// Derived:
///   - θ = π/N  (half the angular spacing between adjacent centers)
///   - ρ_t = R·sinθ/(1+sinθ) — tangent-case chain circle radius
///   - ρ = ρ_t·(1−gap) — chain circle radius adjusted for gap
///   - d = R − ρ — center ring distance (chain circles tangent to outer)
///   - r = R − 2ρ — inner circle radius (chain circles tangent to inner)
///
/// All properties are computed from the immutable inputs.

import Foundation

public struct SteinerCircle: Sendable {

  public let outerRadius: CGFloat
  public let circleCount: Int
  public let gap: CGFloat
  /// Rotation (radians) applied to every chain circle center.
  /// By Steiner's porism, the chain stays tangent at any phase.
  public let phase: CGFloat

  public init(outerRadius: CGFloat, circleCount: Int, gap: CGFloat = 0.001,
              phase: CGFloat = 0) {
    self.outerRadius = outerRadius
    self.circleCount = max(1, circleCount)
    self.gap = max(gap, 0.001)
    self.phase = phase
  }

  // MARK: - Computed Geometry

  /// Half the angular spacing between adjacent chain circle centers.
  public var theta: CGFloat {
    CGFloat.pi / CGFloat(circleCount)
  }

  /// Chain circle radius in the tangent (no-gap) case.
  private var rhoTangent: CGFloat {
    guard circleCount != 1 else { return outerRadius }
    let sinTheta = sin(theta)
    let r = outerRadius * sinTheta / (1 + sinTheta)
    guard r > .zero else { return .zero }
    return r
  }

  /// Radius of each chain circle, adjusted for gap.
  public var rho: CGFloat {
    guard circleCount != 1 else { return outerRadius }
    return rhoTangent * (1 - gap)
  }

  /// Distance from the center to each chain circle's center.
  /// Chain circles remain tangent to the outer circle: d + ρ = R.
  public var chainCenterDistance: CGFloat {
    outerRadius - rho
  }

  /// Radius of the inner circle.
  /// Chain circles remain tangent to the inner circle: d − ρ = r.
  public var innerRadius: CGFloat {
    outerRadius - 2 * rho
  }

  /// Angular position (radians) of the i-th chain circle center (0-based).
  /// Circle 0 is at the top (12 o'clock / -π/2) when `phase` is 0.
  public func centerAngle(at index: Int) -> CGFloat {
    let step = 2 * CGFloat.pi / CGFloat(circleCount)
    return -.pi / 2 + phase + step * CGFloat(index)
  }

  /// Center point of the i-th chain circle (0-based), in a coordinate
  /// system where the outer circle is centered at the origin.
  public func centerPoint(at index: Int) -> CGPoint {
    let angle = centerAngle(at: index)
    let d = chainCenterDistance
    return CGPoint(x: d * cos(angle), y: d * sin(angle))
  }

  // MARK: - Chain Circles

  /// All chain circles as `Circle2D` values.
  public var chainCircles: [Circle2D] {
    (0..<circleCount).map { i in
      Circle2D(center: centerPoint(at: i), radius: rho)
    }
  }

  /// The outer bounding circle as a `Circle2D`.
  public var outerCircle: Circle2D {
    Circle2D(center: .zero, radius: outerRadius)
  }

  /// The inner circle as a `Circle2D`.
  public var innerCircle: Circle2D {
    Circle2D(center: .zero, radius: innerRadius)
  }

  // MARK: - Inversion

  /// Invert this concentric Steiner chain through a `CircleInversion`,
  /// producing a non-concentric chain with varying circle sizes.
  ///
  /// Moving the inversion center smoothly animates the chain.
  /// Returns nil if any circle degenerates during inversion.
  public func inverted(through inversion: CircleInversion) -> InvertedSteinerChain? {
    guard let invertedOuter = inversion.invert(outerCircle),
          let invertedInner = inversion.invert(innerCircle) else {
      return nil
    }

    var invertedChain: [Circle2D] = []
    for circle in chainCircles {
      guard let inverted = inversion.invert(circle) else { return nil }
      invertedChain.append(inverted)
    }

    return InvertedSteinerChain(
      outerCircle: invertedOuter,
      innerCircle: invertedInner,
      chainCircles: invertedChain
    )
  }

  // MARK: - Hit Testing

  /// Index of the chain circle containing `point`, or nil.
  /// `point` is in chain coordinates (outer circle centered at the origin).
  public func chainIndex(containing point: CGPoint) -> Int? {
    chainCircles.firstIndex { $0.contains(point) }
  }

  // MARK: - Focus

  /// An inversion that makes chain circle `index` the largest, with
  /// `magnification` as the ratio of the largest to the smallest circle.
  ///
  /// The inversion center moves from the origin toward circle `index`;
  /// the farther it moves, the larger the ratio. `index` wraps around the
  /// ring. A magnification of 1 or less returns a centered inversion,
  /// which leaves all circles equal.
  public func inversion(focusingOn index: Int, magnification: CGFloat) -> CircleInversion {
    let k = ((index % circleCount) + circleCount) % circleCount
    let angle = centerAngle(at: k)
    func inversion(at distance: CGFloat) -> CircleInversion {
      CircleInversion(center: CGPoint(x: distance * cos(angle), y: distance * sin(angle)),
                      radius: outerRadius)
    }
    guard circleCount > 1, magnification > 1, innerRadius > 0 else {
      return inversion(at: 0)
    }

    // The size ratio rises monotonically from 1 at the origin toward
    // infinity as the center approaches the inner circle, so bisect.
    var low: CGFloat = 0
    var high = innerRadius
    for _ in 0..<60 {
      let mid = (low + high) / 2
      if sizeRatio(through: inversion(at: mid)) < magnification {
        low = mid
      } else {
        high = mid
      }
    }
    return inversion(at: low)
  }

  /// This chain inverted so circle `index` is the largest, with
  /// `magnification` as the ratio of the largest to the smallest circle.
  public func focused(on index: Int, magnification: CGFloat) -> InvertedSteinerChain? {
    inverted(through: inversion(focusingOn: index, magnification: magnification))
  }

  /// Ratio of the largest to the smallest inverted chain circle.
  private func sizeRatio(through inversion: CircleInversion) -> CGFloat {
    guard let chain = inverted(through: inversion) else { return .infinity }
    let radii = chain.chainCircles.map(\.radius)
    guard let largest = radii.max(), let smallest = radii.min(), smallest > 0 else {
      return .infinity
    }
    return largest / smallest
  }
}

// MARK: - CustomStringConvertible

extension SteinerCircle: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    """
    SteinerCircle(count: \(circleCount), R: \(outerRadius), gap: \(gap))
      theta: \(theta) rad, rho: \(rho), innerRadius: \(innerRadius)
    """
  }
  public var debugDescription: String { description }
}
