/// The result of inverting a concentric Steiner chain through
/// a `CircleInversion`. The outer and inner circles become
/// non-concentric, and the chain circles have varying radii.
///
/// `outerCircle` and `innerCircle` are the images of the original
/// boundaries. When the inversion center lies inside the inner circle,
/// inversion swaps their roles: `innerCircle` becomes the enclosing
/// boundary. Use `boundingCircle` for whichever one encloses the chain.

import CoreGraphics
import Foundation

public struct InvertedSteinerChain: Sendable {
  public let outerCircle: Circle2D
  public let innerCircle: Circle2D
  public let chainCircles: [Circle2D]

  /// The larger of `outerCircle` and `innerCircle` — the boundary that
  /// encloses the chain when the inversion center lies inside the inner
  /// circle or outside the outer circle.
  public var boundingCircle: Circle2D {
    outerCircle.radius >= innerCircle.radius ? outerCircle : innerCircle
  }

  // MARK: - Hit Testing

  /// Index of the chain circle containing `point`, or nil.
  public func chainIndex(containing point: CGPoint) -> Int? {
    chainCircles.firstIndex { $0.contains(point) }
  }

  // MARK: - Largest and Smallest

  /// Index of the largest chain circle — the one nearest the inversion center.
  public var largestIndex: Int {
    chainCircles.indices.max { chainCircles[$0].radius < chainCircles[$1].radius } ?? 0
  }

  /// Index of the smallest chain circle — the one farthest from the inversion center.
  public var smallestIndex: Int {
    chainCircles.indices.min { chainCircles[$0].radius < chainCircles[$1].radius } ?? 0
  }

  // MARK: - Fitting

  /// A uniform scale and translation that inscribes `boundingCircle`
  /// in `rect`, centered. Apply it to points such as the inversion center;
  /// apply its inverse to map view points back into chain coordinates.
  public func fittingTransform(in rect: CGRect) -> CGAffineTransform {
    let bound = boundingCircle
    let scale = min(rect.width, rect.height) / 2 / bound.radius
    return CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                             tx: rect.midX - bound.center.x * scale,
                             ty: rect.midY - bound.center.y * scale)
  }

  /// This chain scaled and moved so `boundingCircle` is inscribed in `rect`.
  ///
  /// The bounding circle stays fixed as the inversion center moves, so only
  /// the inner circle and chain appear to move. Scaling and translating
  /// preserve tangency.
  public func fitted(in rect: CGRect) -> InvertedSteinerChain {
    let transform = fittingTransform(in: rect)
    return InvertedSteinerChain(
      outerCircle: outerCircle.applying(transform),
      innerCircle: innerCircle.applying(transform),
      chainCircles: chainCircles.map { $0.applying(transform) }
    )
  }
}

extension InvertedSteinerChain: Hashable, Codable {}

extension InvertedSteinerChain: CustomStringConvertible {
  public var description: String {
    """
    InvertedSteinerChain(\(chainCircles.count) circles)
      outer: \(outerCircle)
      inner: \(innerCircle)
    """
  }
}
