import Testing
import simd
@testable import SoddyHexletModel

// MARK: - Sphere3D and Plane3D Tests

@Suite("Sphere3D and Plane3D")
struct SphereAndPlaneTests {

  @Test("Sphere3D contains interior and boundary points, not exterior")
  func sphereContains() {
    let s = Sphere3D(center: [1, 1, 1], radius: 2)
    #expect(s.contains([1, 1, 1]))
    #expect(s.contains([1, 1, 3]))
    #expect(!s.contains([1, 1, 3.01]))
  }

  @Test("Float conversion keeps center and radius")
  func floatConversion() {
    let s = Sphere3D(center: [1.5, -2, 3], radius: 0.25)
    #expect(s.floatCenter == SIMD3<Float>(1.5, -2, 3))
    #expect(s.floatRadius == 0.25)
  }

  @Test("Plane3D normalizes its normal and scales the offset to match")
  func planeNormalizes() {
    let p = Plane3D(normal: [0, 0, 2], offset: 4)
    #expect(p.normal == [0, 0, 1])
    #expect(p.offset == 2)
    #expect(p.signedDistance(to: [5, 5, 3]) == 1)
    #expect(p.signedDistance(to: [5, 5, 0]) == -2)
  }

  @Test("Plane3D through a point contains that point")
  func planeThroughPoint() {
    let point = SIMD3<Double>(1, 2, 3)
    let p = Plane3D(normal: [1, 1, 0], through: point)
    #expect(abs(p.signedDistance(to: point)) < 1e-12)
  }
}

// MARK: - SphereInversion Tests

@Suite("SphereInversion")
struct SphereInversionTests {

  // MARK: - Point Inversion

  @Test("Point on the inversion sphere maps to itself")
  func pointOnSphere() throws {
    let inv = SphereInversion(center: .zero, radius: 2)
    let result = try #require(inv.invert(SIMD3<Double>(0, 2, 0)))
    #expect(simd_distance(result, [0, 2, 0]) < 1e-12)
  }

  @Test("Point inversion is involutory")
  func pointInvolutory() throws {
    let inv = SphereInversion(center: [1, -1, 2], radius: 3)
    let p = SIMD3<Double>(4, 2, -1)
    let image = try #require(inv.invert(p))
    let back = try #require(inv.invert(image))
    #expect(simd_distance(back, p) < 1e-10)
  }

  @Test("Point at inversion center returns nil")
  func centerReturnsNil() {
    let inv = SphereInversion(center: [3, 4, 5], radius: 1)
    #expect(inv.invert(SIMD3<Double>(3, 4, 5)) == nil)
  }

  // MARK: - Sphere Inversion

  @Test("Sphere inversion is involutory")
  func sphereInvolutory() throws {
    let inv = SphereInversion(center: [0.5, 0, -1], radius: 3)
    let s = Sphere3D(center: [5, 1, 0], radius: 1.5)
    let image = try #require(inv.invert(s))
    let back = try #require(inv.invert(image))
    #expect(simd_distance(back.center, s.center) < 1e-9)
    #expect(abs(back.radius - s.radius) < 1e-9)
  }

  @Test("Points on a sphere land on its image")
  func sphereImageContainsImagePoints() throws {
    let inv = SphereInversion(center: [1, 2, 0], radius: 2.5)
    let s = Sphere3D(center: [-2, 0, 1], radius: 1.2)
    let image = try #require(inv.invert(s))
    for direction in unitDirections {
      let p = try #require(inv.invert(s.center + direction * s.radius))
      #expect(abs(simd_distance(p, image.center) - image.radius) < 1e-9)
    }
  }

  @Test("Sphere through the inversion center returns nil")
  func sphereThroughCenter() {
    let inv = SphereInversion(center: .zero, radius: 2)
    #expect(inv.invert(Sphere3D(center: [0, 0, 1], radius: 1)) == nil)
    #expect(inv.signedCurvature(ofImageOf: Sphere3D(center: [0, 0, 1], radius: 1)) == nil)
  }

  @Test("Sphere curvature is positive from outside, negative from inside")
  func sphereCurvatureSign() throws {
    let s = Sphere3D(center: .zero, radius: 2)
    let outside = SphereInversion(center: [5, 0, 0], radius: 3)
    let inside = SphereInversion(center: [0.5, 0, 0], radius: 3)
    let kOut = try #require(outside.signedCurvature(ofImageOf: s))
    let kIn = try #require(inside.signedCurvature(ofImageOf: s))
    #expect(kOut > 0)
    #expect(kIn < 0)
    #expect(abs(abs(kOut) - 1 / (try #require(outside.invert(s))).radius) < 1e-12)
    #expect(abs(abs(kIn) - 1 / (try #require(inside.invert(s))).radius) < 1e-12)
  }

  // MARK: - Plane Inversion

  @Test("Plane image passes through the inversion center and contains image points")
  func planeImage() throws {
    let inv = SphereInversion(center: [1, 2, 3], radius: 2)
    let plane = Plane3D(normal: [1, -1, 2], through: [0, 0, 6])
    let image = try #require(inv.invert(plane))
    #expect(abs(simd_distance(image.center, inv.center) - image.radius) < 1e-9)

    // Points on the plane: foot of the perpendicular plus in-plane offsets.
    let foot = inv.center - plane.normal * plane.signedDistance(to: inv.center)
    let u = simd_normalize(simd_cross(plane.normal, [1, 0, 0]))
    let v = simd_cross(plane.normal, u)
    for (a, b) in [(0.0, 0.0), (3.0, 0.0), (-1.0, 2.0), (10.0, -7.0)] {
      let p = try #require(inv.invert(foot + u * a + v * b))
      #expect(abs(simd_distance(p, image.center) - image.radius) < 1e-9)
    }
  }

  @Test("Plane curvature is 2δ/s², positive when the center is outside the interior")
  func planeCurvature() throws {
    let plane = Plane3D(normal: [0, 0, 1], offset: 1)
    let outside = SphereInversion(center: [0, 0, -1], radius: 2)
    let inside = SphereInversion(center: [0, 0, 2], radius: 2)
    #expect(abs(try #require(outside.signedCurvature(ofImageOf: plane)) - 1) < 1e-12)
    #expect(abs(try #require(inside.signedCurvature(ofImageOf: plane)) + 0.5) < 1e-12)
    #expect(abs(try #require(outside.invert(plane)).radius - 1) < 1e-12)
  }

  @Test("Plane containing the inversion center returns nil")
  func planeThroughCenter() {
    let inv = SphereInversion(center: [2, 3, 0], radius: 1)
    let plane = Plane3D(normal: [0, 0, 1], offset: 0)
    #expect(inv.invert(plane) == nil)
    #expect(inv.signedCurvature(ofImageOf: plane) == nil)
  }

  @Test("A sphere resting on a plane stays tangent after inversion")
  func planeSphereTangency() throws {
    let plane = Plane3D(normal: [0, 0, -1], offset: -1)
    let sphere = Sphere3D(center: [0, 0, 2], radius: 1)
    let inv = SphereInversion(center: [0.7, -0.4, 4], radius: 3)
    let a = try #require(inv.invert(plane))
    let b = try #require(inv.invert(sphere))
    let d = simd_distance(a.center, b.center)
    let tolerance = 1e-9 * max(a.radius, b.radius)
    #expect(abs(d - (a.radius + b.radius)) < tolerance
            || abs(d - abs(a.radius - b.radius)) < tolerance)
  }

  private let unitDirections: [SIMD3<Double>] = [
    [1, 0, 0], [0, -1, 0], [0, 0, 1],
    simd_normalize([1, 1, 1]), simd_normalize([-2, 1, 0.5]),
  ]
}
