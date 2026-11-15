import SteinerCircleModel
import SwiftUI

extension Path {
  /// A circular path for `circle`, scaled about the origin by `scale`
  /// and then translated by `offset`.
  ///
  /// Model coordinates put the chain's origin at (0, 0); pass the view's
  /// center as `offset` to draw in view coordinates.
  public init(_ circle: Circle2D, scale: CGFloat = 1, offset: CGPoint = .zero) {
    let center = CGPoint(x: offset.x + circle.center.x * scale,
                         y: offset.y + circle.center.y * scale)
    let r = circle.radius * scale
    self.init(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                width: r * 2, height: r * 2))
  }
}
