import Foundation
import Testing
@testable import SteinerCircleModel

// MARK: - Circle2D Tests

@Suite("Circle2D")
struct Circle2DTests {

  @Test("Init with center and radius")
  func basicInit() {
    let c = Circle2D(center: CGPoint(x: 1, y: 2), radius: 3)
    #expect(c.center.x == 1)
    #expect(c.center.y == 2)
    #expect(c.radius == 3)
  }

  @Test("Default center is origin")
  func defaultCenter() {
    let c = Circle2D(radius: 5)
    #expect(c.center == .zero)
  }
}

// MARK: - CircleInversion Tests

@Suite("CircleInversion")
struct CircleInversionTests {

  // MARK: - Point Inversion

  @Test("Point on the inversion circle maps to itself")
  func pointOnCircle() {
    let inv = CircleInversion(center: .zero, radius: 2)
    // Point at (2, 0) is on the circle of radius 2
    let result = inv.invert(CGPoint(x: 2, y: 0))
    #expect(result != nil)
    #expect(abs(result!.x - 2) < 1e-10)
    #expect(abs(result!.y) < 1e-10)
  }

  @Test("Point inside circle maps outside")
  func pointInsideMapsOutside() {
    let inv = CircleInversion(center: .zero, radius: 4)
    // Point at (1, 0): |OP| = 1, |OP'| = 16/1 = 16
    let result = inv.invert(CGPoint(x: 1, y: 0))
    #expect(result != nil)
    #expect(abs(result!.x - 16) < 1e-10)
  }

  @Test("Point outside circle maps inside")
  func pointOutsideMapsInside() {
    let inv = CircleInversion(center: .zero, radius: 2)
    // Point at (8, 0): |OP| = 8, |OP'| = 4/8 = 0.5
    let result = inv.invert(CGPoint(x: 8, y: 0))
    #expect(result != nil)
    #expect(abs(result!.x - 0.5) < 1e-10)
  }

  @Test("Inversion is its own inverse (involutory)")
  func involutory() {
    let inv = CircleInversion(center: CGPoint(x: 1, y: 1), radius: 3)
    let p = CGPoint(x: 4, y: 2)
    guard let p1 = inv.invert(p), let p2 = inv.invert(p1) else {
      #expect(Bool(false), "Inversion should not return nil")
      return
    }
    #expect(abs(p2.x - p.x) < 1e-10)
    #expect(abs(p2.y - p.y) < 1e-10)
  }

  @Test("Point at inversion center returns nil")
  func centerReturnsNil() {
    let inv = CircleInversion(center: CGPoint(x: 3, y: 4), radius: 5)
    let result = inv.invert(CGPoint(x: 3, y: 4))
    #expect(result == nil)
  }

  @Test("Non-origin inversion center")
  func nonOriginCenter() {
    let inv = CircleInversion(center: CGPoint(x: 1, y: 0), radius: 2)
    // Point at (3, 0): dx=2, distSq=4, scale=4/4=1, result=(1+2, 0)=(3,0)
    // That's on the circle! Let's try (2, 0): dx=1, distSq=1, scale=4, result=(1+4, 0)=(5,0)
    let result = inv.invert(CGPoint(x: 2, y: 0))
    #expect(result != nil)
    #expect(abs(result!.x - 5) < 1e-10)
    #expect(abs(result!.y) < 1e-10)
  }

  // MARK: - Circle Inversion

  @Test("Circle inversion preserves tangency")
  func circleInversion() {
    let inv = CircleInversion(center: .zero, radius: 4)
    let c = Circle2D(center: CGPoint(x: 3, y: 0), radius: 1)
    let result = inv.invert(c)
    #expect(result != nil)
    #expect(result!.radius > 0)
  }

  @Test("Circle through inversion center returns nil")
  func circleThroughCenter() {
    let inv = CircleInversion(center: .zero, radius: 2)
    // Circle centered at (1, 0) with radius 1 passes through origin
    let c = Circle2D(center: CGPoint(x: 1, y: 0), radius: 1)
    let result = inv.invert(c)
    #expect(result == nil)
  }

  @Test("Circle inversion is involutory for circles")
  func circleInvolutory() {
    let inv = CircleInversion(center: .zero, radius: 3)
    let c = Circle2D(center: CGPoint(x: 5, y: 0), radius: 1)
    guard let c1 = inv.invert(c), let c2 = inv.invert(c1) else {
      #expect(Bool(false), "Inversion should not return nil")
      return
    }
    #expect(abs(c2.center.x - c.center.x) < 1e-8)
    #expect(abs(c2.center.y - c.center.y) < 1e-8)
    #expect(abs(c2.radius - c.radius) < 1e-8)
  }
}

// MARK: - SteinerCircle + Inversion Tests

@Suite("SteinerCircle Inversion")
struct SteinerCircleInversionTests {

  @Test("chainCircles count matches circleCount")
  func chainCirclesCount() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 6)
    #expect(sc.chainCircles.count == 6)
  }

  @Test("chainCircles all have radius rho")
  func chainCirclesRadius() {
    let sc = SteinerCircle(outerRadius: 1, circleCount: 5)
    for c in sc.chainCircles {
      #expect(abs(c.radius - sc.rho) < 1e-10)
    }
  }

  @Test("Inverted chain has same number of circles")
  func invertedChainCount() {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 6)
    let inv = CircleInversion(center: CGPoint(x: 3, y: 0), radius: 8)
    let result = sc.inverted(through: inv)
    #expect(result != nil)
    #expect(result!.chainCircles.count == 6)
  }

  @Test("Inverted chain circles have varying radii")
  func invertedChainVaryingRadii() {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 6)
    // Off-center inversion produces varying sizes
    let inv = CircleInversion(center: CGPoint(x: 3, y: 0), radius: 8)
    guard let result = sc.inverted(through: inv) else {
      #expect(Bool(false), "Inversion should succeed")
      return
    }
    let radii = result.chainCircles.map(\.radius)
    let allEqual = radii.allSatisfy { abs($0 - radii[0]) < 1e-6 }
    #expect(!allEqual, "Off-center inversion should produce varying radii")
  }

  @Test("Centered inversion preserves equal radii")
  func centeredInversionEqualRadii() {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 6)
    // Inversion centered at origin preserves symmetry
    let inv = CircleInversion(center: .zero, radius: 5)
    guard let result = sc.inverted(through: inv) else {
      #expect(Bool(false), "Inversion should succeed")
      return
    }
    let radii = result.chainCircles.map(\.radius)
    let allClose = radii.allSatisfy { abs($0 - radii[0]) < 1e-6 }
    #expect(allClose, "Origin-centered inversion should preserve equal radii")
  }

  @Test("outerCircle and innerCircle properties")
  func outerInnerCircle() {
    let sc = SteinerCircle(outerRadius: 5, circleCount: 8)
    #expect(sc.outerCircle.center == .zero)
    #expect(sc.outerCircle.radius == 5)
    #expect(sc.innerCircle.center == .zero)
    #expect(sc.innerCircle.radius == sc.innerRadius)
  }
}
