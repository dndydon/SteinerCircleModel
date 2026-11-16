import Foundation
import Testing
@testable import SteinerCircleModel

/// Tests for the SteinerCircle geometry calculations.
@Suite("SteinerCircle Geometry")
struct SteinerCircleTests {

  // MARK: - Single Circle

  @Test("Single circle fills the outer radius")
  func singleCircle() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 1)
    #expect(sc.rho == 1.0)
  }

  // MARK: - Theta

  @Test("Theta is π/N")
  func thetaComputation() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    #expect(sc.theta == CGFloat.pi / 6)
  }

  // MARK: - Rho (chain circle radius)

  @Test("Rho for 2 circles")
  func rhoForTwo() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 2)
    // sin(π/2) = 1, so rho = 1*1/(1+1) * (1-0.001) ≈ 0.4995
    let expected = 1.0 * 1.0 / (1.0 + 1.0) * (1.0 - 0.001)
    #expect(abs(sc.rho - expected) < 1e-10)
  }

  @Test("Rho for 6 circles, unit radius")
  func rhoForSix() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    let sinTheta = sin(CGFloat.pi / 6) // 0.5
    let expected = sinTheta / (1 + sinTheta) * (1 - 0.001)
    #expect(abs(sc.rho - expected) < 1e-10)
  }

  @Test("Rho scales linearly with outer radius")
  func rhoScalesWithRadius() {
    let sc1 = SteinerCircle(outerRadius: 1, circleCount: 5)
    let sc2 = SteinerCircle(outerRadius: 3, circleCount: 5)
    #expect(abs(sc2.rho - sc1.rho * 3) < 1e-10)
  }

  // MARK: - Inner Radius

  @Test("Inner radius formula: R - 2ρ")
  func innerRadiusFormula() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    let expected = 1.0 - 2 * sc.rho
    #expect(abs(sc.innerRadius - expected) < 1e-10)
  }

  @Test("Inner radius is non-negative for typical counts")
  func innerRadiusNonNegative() {
    for n in 2...20 {
      let sc = SteinerCircle(outerRadius: 1, circleCount: n)
      #expect(sc.innerRadius >= 0, "innerRadius should be non-negative for count \(n)")
    }
    // For count > 2, inner radius is strictly positive
    for n in 3...20 {
      let sc = SteinerCircle(outerRadius: 1, circleCount: n)
      #expect(sc.innerRadius > 0, "innerRadius should be positive for count \(n)")
    }
  }

  // MARK: - Gap

  @Test("Negative gap is clamped to 0")
  func gapClamp() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 5, gap: -0.5)
    #expect(sc.gap == 0)
  }

  @Test("Default gap is 0.001")
  func gapDefault() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 5)
    #expect(sc.gap == 0.001)
  }

  @Test("Zero gap makes neighbors exactly tangent", arguments: [3, 6, 8, 13])
  func zeroGapTangency(count: Int) {
    let sc = SteinerCircle(outerRadius: 10, circleCount: count, gap: 0)
    let circles = sc.chainCircles
    for i in 0..<count {
      let a = circles[i], b = circles[(i + 1) % count]
      let distance = hypot(b.center.x - a.center.x, b.center.y - a.center.y)
      #expect(abs(distance - (a.radius + b.radius)) < 1e-9)
    }
  }

  @Test("Larger gap shrinks circles and grows inner radius")
  func gapEffect() {
    let small = SteinerCircle(outerRadius: 1, circleCount: 6, gap: 0.1)
    let large = SteinerCircle(outerRadius: 1, circleCount: 6, gap: 0.5)
    #expect(large.rho < small.rho)
    #expect(large.innerRadius > small.innerRadius)
  }

  // MARK: - Center Angle

  @Test("Center angle starts at top (-π/2)")
  func centerAngleStartsAtTop() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    #expect(abs(sc.centerAngle(at: 0) - (-.pi / 2)) < 1e-10)
  }

  @Test("Center angles are evenly spaced by 2π/N")
  func centerAnglesEvenlySpaced() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 5)
    let step = 2 * CGFloat.pi / 5
    for i in 0..<5 {
      let expected = -.pi / 2 + step * CGFloat(i)
      #expect(abs(sc.centerAngle(at: i) - expected) < 1e-10)
    }
  }

  // MARK: - Center Point

  @Test("Center point at index 0 is at the top")
  func centerPointAtTop() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 4)
    let p = sc.centerPoint(at: 0)
    // Top means x ≈ 0, y < 0
    #expect(abs(p.x) < 1e-10)
    #expect(p.y < 0)
  }

  @Test("Center points are equidistant from origin")
  func centerPointsEquidistant() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    let d = sc.chainCenterDistance
    for i in 0..<6 {
      let p = sc.centerPoint(at: i)
      let dist = sqrt(p.x * p.x + p.y * p.y)
      #expect(abs(dist - d) < 1e-10, "Point \(i) distance should equal chainCenterDistance")
    }
  }

  // MARK: - Parameterized

  @Test("Rho is positive for various counts", arguments: [2, 3, 5, 7, 12, 20, 50])
  func rhoPositive(count: Int) {
    let sc = SteinerCircle(outerRadius: 1, circleCount: count)
    #expect(sc.rho > 0)
  }

  // MARK: - Description

  @Test("Description includes key values")
  func descriptionFormat() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    let desc = sc.description
    #expect(desc.contains("count: 6"))
    #expect(desc.contains("windings: 1"))
    #expect(desc.contains("rho:"))
    #expect(desc.contains("innerRadius:"))
  }
}

// MARK: - Multiple Windings

@Suite("Multiple Windings")
struct WindingsTests {

  @Test("Default is one winding")
  func defaultWindings() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 7)
    #expect(sc.windings == 1)
  }

  @Test("Windings clamp to 1...(n - 1)/2")
  func windingsClamp() {
    #expect(SteinerCircle(outerRadius: 1, circleCount: 7, windings: 0).windings == 1)
    #expect(SteinerCircle(outerRadius: 1, circleCount: 7, windings: 3).windings == 3)
    #expect(SteinerCircle(outerRadius: 1, circleCount: 7, windings: 4).windings == 3)
    #expect(SteinerCircle(outerRadius: 1, circleCount: 8, windings: 4).windings == 3)
    #expect(SteinerCircle(outerRadius: 1, circleCount: 2, windings: 5).windings == 1)
  }

  @Test("Theta is mπ/N")
  func thetaWithWindings() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 7, windings: 2)
    #expect(abs(sc.theta - 2 * .pi / 7) < 1e-12)
  }

  @Test("Consecutive centers are 2θ apart")
  func centerSpacing() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 7, windings: 3)
    for i in 0..<6 {
      #expect(abs(sc.centerAngle(at: i + 1) - sc.centerAngle(at: i) - 2 * sc.theta) < 1e-12)
    }
  }

  @Test("Centers land on distinct positions when n and m are coprime")
  func distinctCenters() {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 7, windings: 2)
    let points = (0..<7).map(sc.centerPoint(at:))
    for i in 0..<7 {
      for j in (i + 1)..<7 {
        #expect(hypot(points[i].x - points[j].x, points[i].y - points[j].y) > 1e-6)
      }
    }
  }

  @Test("Neighbors and boundaries stay tangent",
        arguments: [(5, 2), (7, 2), (7, 3), (8, 3), (11, 4)])
  func tangency(count: Int, windings: Int) {
    let sc = SteinerCircle(outerRadius: 10, circleCount: count, windings: windings, gap: 0)
    let circles = sc.chainCircles
    for i in 0..<count {
      let next = circles[(i + 1) % count]
      #expect(isTangent(circles[i], next))
      #expect(isTangent(circles[i], sc.outerCircle))
      #expect(isTangent(circles[i], sc.innerCircle))
    }
    #expect(sc.innerRadius > 0)
  }

  @Test("Inverted multi-winding chain stays tangent at any phase", arguments: [0.0, 0.7, 2.2])
  func invertedTangency(phase: Double) {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 7, windings: 2, gap: 0, phase: phase)
    let inv = CircleInversion(center: CGPoint(x: 0.4, y: -0.3), radius: 10)
    guard let result = sc.inverted(through: inv) else {
      #expect(Bool(false), "Inversion should succeed")
      return
    }
    let circles = result.chainCircles
    for i in circles.indices {
      #expect(isTangent(circles[i], circles[(i + 1) % circles.count]))
      #expect(isTangent(circles[i], result.outerCircle))
      #expect(isTangent(circles[i], result.innerCircle))
    }
  }

  @Test("Focus makes the chosen circle largest", arguments: [0, 2, 5])
  func focusWithWindings(index: Int) {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 7, windings: 2)
    #expect(sc.focused(on: index, magnification: 3)?.largestIndex == index)
  }

  /// Internal or external tangency, relative to the larger radius.
  private func isTangent(_ a: Circle2D, _ b: Circle2D) -> Bool {
    let d = hypot(a.center.x - b.center.x, a.center.y - b.center.y)
    let tolerance = 1e-6 * max(a.radius, b.radius)
    return abs(d - (a.radius + b.radius)) < tolerance
      || abs(d - abs(a.radius - b.radius)) < tolerance
  }
}

// MARK: - Codable and Hashable

@Suite("Codable and Hashable")
struct CodableHashableTests {

  private func roundTrip<T: Codable>(_ value: T) throws -> T {
    try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
  }

  @Test("Every type survives a JSON round trip")
  func roundTrips() throws {
    let circle = Circle2D(center: CGPoint(x: 1.5, y: -2), radius: 3)
    let inversion = CircleInversion(center: CGPoint(x: 0.4, y: 0.1), radius: 8)
    let chain = SteinerCircle(outerRadius: 10, circleCount: 7, windings: 2, gap: 0.1, phase: 0.6)
    let inverted = try #require(chain.inverted(through: inversion))
    #expect(try roundTrip(circle) == circle)
    #expect(try roundTrip(inversion) == inversion)
    #expect(try roundTrip(chain) == chain)
    #expect(try roundTrip(inverted) == inverted)
  }

  @Test("Decoding a SteinerCircle applies init's clamping")
  func decodeClamps() throws {
    let json = Data(#"{"outerRadius": 10, "circleCount": 6, "windings": 9, "gap": -1, "phase": 0}"#.utf8)
    let chain = try JSONDecoder().decode(SteinerCircle.self, from: json)
    #expect(chain.windings == 2)
    #expect(chain.gap == 0)
  }

  @Test("Missing optional keys take init's defaults")
  func decodeDefaults() throws {
    let json = Data(#"{"outerRadius": 10, "circleCount": 6}"#.utf8)
    let chain = try JSONDecoder().decode(SteinerCircle.self, from: json)
    #expect(chain == SteinerCircle(outerRadius: 10, circleCount: 6))
  }

  @Test("Equal values hash equally and deduplicate in a Set")
  func hashing() {
    let a = Circle2D(center: CGPoint(x: 1, y: 2), radius: 3)
    let b = Circle2D(center: CGPoint(x: 1, y: 2), radius: 3)
    let c = Circle2D(center: CGPoint(x: 2, y: 1), radius: 3)
    #expect(Set([a, b, c]).count == 2)
    #expect(Set([CircleInversion(center: .zero, radius: 1),
                 CircleInversion(center: .zero, radius: 1)]).count == 1)
    #expect(Set([SteinerCircle(outerRadius: 1, circleCount: 6),
                 SteinerCircle(outerRadius: 1, circleCount: 6, phase: 0.1)]).count == 2)
  }
}
