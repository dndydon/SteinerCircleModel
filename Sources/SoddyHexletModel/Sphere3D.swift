/// A sphere in 3D space, defined by its center and radius.

import simd

public struct Sphere3D: Sendable, Equatable {
  public var center: SIMD3<Double>
  public var radius: Double

  public init(center: SIMD3<Double> = .zero, radius: Double) {
    self.center = center
    self.radius = radius
  }
}

// MARK: - Hit Testing

extension Sphere3D {
  /// Whether `point` lies inside or on this sphere.
  public func contains(_ point: SIMD3<Double>) -> Bool {
    simd_distance_squared(point, center) <= radius * radius
  }
}

// MARK: - Float Conversion

extension Sphere3D {
  /// `center` as single precision, for RealityKit transforms.
  public var floatCenter: SIMD3<Float> { SIMD3<Float>(center) }

  /// `radius` as single precision, for RealityKit meshes and scales.
  public var floatRadius: Float { Float(radius) }
}

extension Sphere3D: CustomStringConvertible {
  public var description: String {
    "Sphere3D(center: (\(center.x), \(center.y), \(center.z)), radius: \(radius))"
  }
}
