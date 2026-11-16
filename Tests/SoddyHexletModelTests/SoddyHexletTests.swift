import Testing
import simd
@testable import SoddyHexletModel

// MARK: - Standard Form

@Suite("SoddyHexlet standard form")
struct SoddyHexletStandardTests {

  @Test("Ring spheres have radius r, centers at 2r in the z = 0 plane, 60° apart")
  func layout() {
    let hexlet = SoddyHexlet(radius: 1.5)
    #expect(abs(hexlet.ringRadius - 1.5) < 1e-12)
    #expect(abs(hexlet.nucleus.radius - 1.5) < 1e-12)
    for i in 0..<6 {
      let p = hexlet.centerPoint(at: i)
      let q = hexlet.centerPoint(at: i + 1)
      #expect(abs(simd_length(p) - 3) < 1e-12)
      #expect(p.z == 0)
      #expect(abs(simd_distance(p, q) - 3) < 1e-12)
    }
  }

  @Test("Sphere 0 sits on the −y axis at phase 0")
  func firstSphere() {
    let p = SoddyHexlet(radius: 1).centerPoint(at: 0)
    #expect(abs(p.x) < 1e-12)
    #expect(abs(p.y + 2) < 1e-12)
  }

  @Test("Every ring sphere touches both planes, the nucleus, and its neighbors",
        arguments: [0.0, 0.5, 2.3])
  func tangency(phase: Double) {
    let hexlet = SoddyHexlet(radius: 2, phase: phase)
    let ring = hexlet.ringSpheres
    for (i, sphere) in ring.enumerated() {
      #expect(abs(-hexlet.planeA.signedDistance(to: sphere.center) - sphere.radius) < 1e-12)
      #expect(abs(-hexlet.planeB.signedDistance(to: sphere.center) - sphere.radius) < 1e-12)
      #expect(isTangent(sphere, hexlet.nucleus))
      #expect(isTangent(sphere, ring[(i + 1) % 6]))
    }
  }

  @Test("opposite wraps around the ring")
  func opposite() {
    #expect(SoddyHexlet.opposite(0) == 3)
    #expect(SoddyHexlet.opposite(4) == 1)
    #expect(SoddyHexlet.opposite(9) == 0)
    #expect(SoddyHexlet.opposite(-1) == 2)
  }

  @Test("Phase rotates the ring about the z-axis")
  func phaseRotates() {
    let base = SoddyHexlet(radius: 1)
    let rotated = SoddyHexlet(radius: 1, phase: 0.3)
    for i in 0..<6 {
      let a = base.centerPoint(at: i)
      let b = rotated.centerPoint(at: i)
      let turned = SIMD3(a.x * cos(0.3) - a.y * sin(0.3), a.x * sin(0.3) + a.y * cos(0.3), 0)
      #expect(simd_distance(b, turned) < 1e-12)
    }
  }
}

// MARK: - Inversion

@Suite("SoddyHexlet inversion")
struct SoddyHexletInversionTests {

  /// Inversion centers in different regions: in a gap between the planes,
  /// inside the nucleus, above plane A, and inside ring sphere 0.
  static let centers: [SIMD3<Double>] = [
    [1, -1.732, 0.3], [0.2, 0.1, 0.3], [0.5, 0.5, 2.5], [0.1, -2.2, 0.3],
  ]

  @Test("Every tangency survives inversion", arguments: centers)
  func tangency(center: SIMD3<Double>) throws {
    let hexlet = SoddyHexlet(radius: 1, phase: 0.7)
    let inverted = try #require(hexlet.inverted(through: SphereInversion(center: center, radius: 2)))
    #expect(isTangent(inverted.a, inverted.b))
    #expect(isTangent(inverted.a, inverted.c))
    #expect(isTangent(inverted.b, inverted.c))
    for (i, sphere) in inverted.spheres.enumerated() {
      #expect(isTangent(sphere, inverted.a))
      #expect(isTangent(sphere, inverted.b))
      #expect(isTangent(sphere, inverted.c))
      #expect(isTangent(sphere, inverted.spheres[(i + 1) % 6]))
    }
  }

  @Test("Opposite curvatures sum to 2(kA + kB + kC)", arguments: centers)
  func oppositeCurvatures(center: SIMD3<Double>) throws {
    let k = try curvatures(SoddyHexlet(radius: 1, phase: 0.7), SphereInversion(center: center, radius: 2))
    let expected = 2 * (k.a + k.b + k.c)
    for i in 0..<3 {
      #expect(abs(k.ring[i] + k.ring[i + 3] - expected) < 1e-9 * abs(expected))
    }
  }

  @Test("Soddy–Gosset holds for A, B, C, and two neighbors", arguments: centers)
  func soddyGosset(center: SIMD3<Double>) throws {
    let k = try curvatures(SoddyHexlet(radius: 1, phase: 0.7), SphereInversion(center: center, radius: 2))
    for i in 0..<6 {
      let five = [k.a, k.b, k.c, k.ring[i], k.ring[(i + 1) % 6]]
      let sum = five.reduce(0, +)
      let sumOfSquares = five.reduce(0) { $0 + $1 * $1 }
      #expect(abs(sum * sum - 3 * sumOfSquares) < 1e-9 * sum * sum)
    }
  }

  @Test("The six ring centers stay coplanar", arguments: centers)
  func coplanarCenters(center: SIMD3<Double>) throws {
    let hexlet = SoddyHexlet(radius: 1, phase: 0.7)
    let inverted = try #require(hexlet.inverted(through: SphereInversion(center: center, radius: 2)))
    let p = inverted.spheres.map(\.center)
    let normal = simd_normalize(simd_cross(p[1] - p[0], p[2] - p[0]))
    let scale = inverted.spheres.map(\.radius).max() ?? 1
    for q in p {
      #expect(abs(simd_dot(q - p[0], normal)) < 1e-9 * scale)
    }
  }

  @Test("Enclosing sphere matches the region holding the inversion center")
  func enclosingSphere() throws {
    let hexlet = SoddyHexlet(radius: 1)
    func inverted(at center: SIMD3<Double>) throws -> InvertedSoddyHexlet {
      try #require(hexlet.inverted(through: SphereInversion(center: center, radius: 2)))
    }
    #expect(try inverted(at: [1, -1.732, 0.3]).enclosingSphere == nil)
    let above = try inverted(at: [0.5, 0.5, 2.5])
    #expect(above.enclosingSphere == above.a)
    let nucleus = try inverted(at: [0.2, 0.1, 0.3])
    #expect(nucleus.enclosingSphere == nucleus.c)
    let ring = try inverted(at: [0.1, -2.2, 0.3])
    #expect(ring.enclosingSphere == ring.spheres[0])
  }

  @Test("Inversion center on a plane or sphere returns nil")
  func degenerate() {
    let hexlet = SoddyHexlet(radius: 1)
    #expect(hexlet.inverted(through: SphereInversion(center: [3, 3, 1], radius: 2)) == nil)
    #expect(hexlet.inverted(through: SphereInversion(center: [1, 0, 0], radius: 2)) == nil)
  }

  private struct Curvatures {
    let a: Double, b: Double, c: Double
    let ring: [Double]
  }

  private func curvatures(_ hexlet: SoddyHexlet, _ inversion: SphereInversion) throws -> Curvatures {
    Curvatures(
      a: try #require(inversion.signedCurvature(ofImageOf: hexlet.planeA)),
      b: try #require(inversion.signedCurvature(ofImageOf: hexlet.planeB)),
      c: try #require(inversion.signedCurvature(ofImageOf: hexlet.nucleus)),
      ring: try hexlet.ringSpheres.map { try #require(inversion.signedCurvature(ofImageOf: $0)) }
    )
  }
}

// MARK: - From Three Tangent Spheres

@Suite("InvertedSoddyHexlet from three tangent spheres")
struct HexletFromTangentSpheresTests {

  /// A and B touch externally at the origin; C sits beside them.
  static let external = (
    Sphere3D(center: [0, 0, 1], radius: 1),
    Sphere3D(center: [0, 0, -1], radius: 1),
    Sphere3D(center: [Double(3).squareRoot(), 0, 0], radius: 1)
  )

  /// A encloses B and C: the classic hexlet picture.
  static let enclosing = (
    Sphere3D(center: .zero, radius: 3),
    Sphere3D(center: [0, 0, 1], radius: 2),
    Sphere3D(center: [0, 0, -2], radius: 1)
  )

  @Test("Ring touches A, B, C, and its neighbors, and keeps the given spheres",
        arguments: [0.0, 0.9, 4.0])
  func ringTangency(phase: Double) throws {
    for (a, b, c) in [Self.external, Self.enclosing] {
      let hexlet = try InvertedSoddyHexlet(tangentTo: a, b, c, phase: phase)
      #expect(hexlet.a == a && hexlet.b == b && hexlet.c == c)
      #expect(hexlet.spheres.count == 6)
      expectRing(hexlet)
    }
  }

  @Test("Works for any hexlet produced by inversion, in any argument order",
        arguments: SoddyHexletInversionTests.centers)
  func fromInvertedHexlet(center: SIMD3<Double>) throws {
    let source = try #require(SoddyHexlet(radius: 1, phase: 0.7)
      .inverted(through: SphereInversion(center: center, radius: 2)))
    for (a, b, c) in [(source.a, source.b, source.c), (source.c, source.a, source.b),
                      (source.b, source.c, source.a)] {
      expectRing(try InvertedSoddyHexlet(tangentTo: a, b, c, phase: 1.1))
    }
  }

  @Test("The enclosing sphere is A when A holds the others")
  func enclosingA() throws {
    let (a, b, c) = Self.enclosing
    #expect(try InvertedSoddyHexlet(tangentTo: a, b, c).enclosingSphere == a)
  }

  @Test("Spheres that don't touch, or coincide, are rejected")
  func notTangent() {
    let (a, b, _) = Self.external
    #expect(throws: HexletError.notMutuallyTangent) {
      try InvertedSoddyHexlet(tangentTo: a, b, Sphere3D(center: [5, 0, 0], radius: 1))
    }
    #expect(throws: HexletError.notMutuallyTangent) {
      try InvertedSoddyHexlet(tangentTo: a, a, b)
    }
  }

  @Test("Three spheres touching at one point, or a zero radius, are degenerate")
  func degenerate() {
    let a = Sphere3D(center: [0, 0, 1], radius: 1)
    let b = Sphere3D(center: [0, 0, -1], radius: 1)
    #expect(throws: HexletError.degenerate) {
      try InvertedSoddyHexlet(tangentTo: a, b, Sphere3D(center: [0, 0, 2], radius: 2))
    }
    #expect(throws: HexletError.degenerate) {
      try InvertedSoddyHexlet(tangentTo: a, b, Sphere3D(center: [1, 0, 0], radius: 0))
    }
  }

  private func expectRing(_ hexlet: InvertedSoddyHexlet) {
    for (i, sphere) in hexlet.spheres.enumerated() {
      #expect(isTangent(sphere, hexlet.a))
      #expect(isTangent(sphere, hexlet.b))
      #expect(isTangent(sphere, hexlet.c))
      #expect(isTangent(sphere, hexlet.spheres[(i + 1) % 6]))
    }
  }
}

// MARK: - Helpers

/// Two spheres are tangent (internally or externally) when the distance
/// between centers equals the sum or difference of their radii.
func isTangent(_ a: Sphere3D, _ b: Sphere3D) -> Bool {
  let d = simd_distance(a.center, b.center)
  let tolerance = 1e-9 * max(a.radius, b.radius)
  return abs(d - (a.radius + b.radius)) < tolerance
    || abs(d - abs(a.radius - b.radius)) < tolerance
}
