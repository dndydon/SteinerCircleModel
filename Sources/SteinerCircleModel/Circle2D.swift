/// A circle in 2D space, defined by its center and radius.

import CoreGraphics
import Foundation

public struct Circle2D: Sendable {
  public var center: CGPoint
  public var radius: CGFloat

  public init(center: CGPoint = .zero, radius: CGFloat) {
    self.center = center
    self.radius = radius
  }

  public static func == (lhs: Circle2D, rhs: Circle2D) -> Bool {
    lhs.center.x == rhs.center.x &&
    lhs.center.y == rhs.center.y &&
    lhs.radius == rhs.radius
  }
}

extension Circle2D: Equatable {}

extension Circle2D: CustomStringConvertible {
  public var description: String {
    "Circle2D(center: (\(center.x), \(center.y)), radius: \(radius))"
  }
}
