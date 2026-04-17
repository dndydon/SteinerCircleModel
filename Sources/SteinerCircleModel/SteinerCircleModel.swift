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

  public init(outerRadius: CGFloat, circleCount: Int, gap: CGFloat = 0.001) {
    self.outerRadius = outerRadius
    self.circleCount = max(1, circleCount)
    self.gap = max(gap, 0.001)
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
  /// Circle 0 is at the top (12 o'clock / -π/2).
  public func centerAngle(at index: Int) -> CGFloat {
    let step = 2 * CGFloat.pi / CGFloat(circleCount)
    return -.pi / 2 + step * CGFloat(index)
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
