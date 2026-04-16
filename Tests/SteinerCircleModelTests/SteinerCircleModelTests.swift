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
    // sin(π/2) = 1, so rho = 1*1/(1+1) * (1+0.001) ≈ 0.5005
    let expected = 1.0 * 1.0 / (1.0 + 1.0) * (1.0 + 0.001)
    #expect(abs(sc.rho - expected) < 1e-10)
  }

  @Test("Rho for 6 circles, unit radius")
  func rhoForSix() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    let sinTheta = sin(CGFloat.pi / 6) // 0.5
    let expected = sinTheta / (1 + sinTheta) * (1 + 0.001)
    #expect(abs(sc.rho - expected) < 1e-10)
  }

  @Test("Rho scales linearly with outer radius")
  func rhoScalesWithRadius() {
    let sc1 = SteinerCircle(outerRadius: 1, circleCount: 5)
    let sc2 = SteinerCircle(outerRadius: 3, circleCount: 5)
    #expect(abs(sc2.rho - sc1.rho * 3) < 1e-10)
  }

  // MARK: - Inner Radius

  @Test("Inner radius formula: R - 2ρ(1-gap)")
  func innerRadiusFormula() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    let expected = 1.0 - 2 * sc.rho * (1 - sc.gap)
    #expect(abs(sc.innerRadius - expected) < 1e-10)
  }

  @Test("Inner radius is positive for typical counts")
  func innerRadiusPositive() {
    for n in 2...20 {
      let sc = SteinerCircle(outerRadius: 1, circleCount: n)
      #expect(sc.innerRadius > 0, "innerRadius should be positive for count \(n)")
    }
  }

  // MARK: - Gap

  @Test("Gap is clamped to minimum 0.001")
  func gapClamp() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 5, gap: 0)
    #expect(sc.gap == 0.001)
  }

  @Test("Larger gap increases inner radius")
  func gapIncreasesInnerRadius() {
    let small = SteinerCircle(outerRadius: 1, circleCount: 6, gap: 0.1)
    let large = SteinerCircle(outerRadius: 1, circleCount: 6, gap: 0.5)
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
    #expect(desc.contains("rho:"))
    #expect(desc.contains("innerRadius:"))
  }
}
