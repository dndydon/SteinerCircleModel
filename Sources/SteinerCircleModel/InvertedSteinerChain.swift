/// The result of inverting a concentric Steiner chain through
/// a `CircleInversion`. The outer and inner circles become
/// non-concentric, and the chain circles have varying radii.

import Foundation

public struct InvertedSteinerChain: Sendable {
  public let outerCircle: Circle2D
  public let innerCircle: Circle2D
  public let chainCircles: [Circle2D]
}

extension InvertedSteinerChain: CustomStringConvertible {
  public var description: String {
    """
    InvertedSteinerChain(\(chainCircles.count) circles)
      outer: \(outerCircle)
      inner: \(innerCircle)
    """
  }
}
