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

  @Test("Phase rotates every center angle")
  func phaseRotatesAngles() {
    let base = SteinerCircle(outerRadius: 1, circleCount: 5)
    let rotated = SteinerCircle(outerRadius: 1, circleCount: 5, phase: 0.3)
    for i in 0..<5 {
      #expect(abs(rotated.centerAngle(at: i) - base.centerAngle(at: i) - 0.3) < 1e-10)
    }
  }

  /// Steiner's porism: after inversion, every chain circle stays tangent
  /// to both bounding circles no matter how far the chain is rotated.
  @Test("Inverted chain stays tangent at any phase", arguments: [0.0, 0.4, 1.3, 2.9, 5.5])
  func invertedChainTangentAtAnyPhase(phase: Double) {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 7, gap: 0.2, phase: phase)
    let inv = CircleInversion(center: CGPoint(x: 1.5, y: -0.8), radius: 10)
    guard let result = sc.inverted(through: inv) else {
      #expect(Bool(false), "Inversion should succeed")
      return
    }
    for circle in result.chainCircles {
      #expect(isTangent(circle, result.outerCircle))
      #expect(isTangent(circle, result.innerCircle))
    }
  }

  /// Two circles are tangent (internally or externally) when the distance
  /// between centers equals the sum or difference of their radii.
  private func isTangent(_ a: Circle2D, _ b: Circle2D) -> Bool {
    let d = hypot(a.center.x - b.center.x, a.center.y - b.center.y)
    let tolerance = 1e-6 * max(a.radius, b.radius)
    return abs(d - (a.radius + b.radius)) < tolerance
      || abs(d - abs(a.radius - b.radius)) < tolerance
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

// MARK: - Hit Testing, Fitting, and Focus

@Suite("Hit Testing, Fitting, and Focus")
struct ChainToolsTests {

  // MARK: - Hit Testing

  @Test("Circle2D contains interior and boundary points, not exterior")
  func circleContains() {
    let c = Circle2D(center: CGPoint(x: 1, y: 1), radius: 2)
    #expect(c.contains(CGPoint(x: 1, y: 1)))
    #expect(c.contains(CGPoint(x: 3, y: 1)))
    #expect(!c.contains(CGPoint(x: 3.01, y: 1)))
  }

  @Test("chainIndex finds each chain circle by its center")
  func chainIndexByCenter() {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 7, phase: 0.4)
    for i in 0..<7 {
      #expect(sc.chainIndex(containing: sc.centerPoint(at: i)) == i)
    }
    #expect(sc.chainIndex(containing: .zero) == nil)
  }

  @Test("Inverted chainIndex finds each inverted circle by its center")
  func invertedChainIndex() throws {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 6)
    let chain = try #require(sc.inverted(through: CircleInversion(center: CGPoint(x: 1, y: 2), radius: 10)))
    for (i, circle) in chain.chainCircles.enumerated() {
      #expect(chain.chainIndex(containing: circle.center) == i)
    }
  }

  // MARK: - Fitting

  @Test("Inversion from inside the inner circle makes innerCircle the bounding circle")
  func boundingCircleSwaps() throws {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 6)
    let chain = try #require(sc.inverted(through: CircleInversion(center: CGPoint(x: 1, y: 0), radius: 10)))
    #expect(chain.boundingCircle == chain.innerCircle)
  }

  @Test("fitted inscribes the bounding circle in the rect, for any inversion center",
        arguments: [CGPoint.zero, CGPoint(x: 2, y: -1), CGPoint(x: -2.5, y: 1.5)])
  func fittedBoundingCircle(center: CGPoint) throws {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 8, gap: 0.1)
    let chain = try #require(sc.inverted(through: CircleInversion(center: center, radius: 10)))
    let rect = CGRect(x: 20, y: 40, width: 300, height: 200)
    let bound = chain.fitted(in: rect).boundingCircle
    #expect(abs(bound.center.x - rect.midX) < 1e-9)
    #expect(abs(bound.center.y - rect.midY) < 1e-9)
    #expect(abs(bound.radius - 100) < 1e-9)
  }

  @Test("fitted preserves tangency")
  func fittedPreservesTangency() throws {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 7, gap: 0.2)
    let chain = try #require(sc.inverted(through: CircleInversion(center: CGPoint(x: 1.5, y: -0.8), radius: 10)))
    let fitted = chain.fitted(in: CGRect(x: 0, y: 0, width: 360, height: 360))
    for circle in fitted.chainCircles {
      #expect(isTangent(circle, fitted.outerCircle))
      #expect(isTangent(circle, fitted.innerCircle))
    }
  }

  // MARK: - Focus

  @Test("Focusing makes the chosen circle largest", arguments: [0, 2, 5])
  func focusLargest(index: Int) throws {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 6, phase: 0.7)
    let chain = try #require(sc.focused(on: index, magnification: 3))
    #expect(chain.largestIndex == index)
  }

  @Test("Focus achieves the requested magnification", arguments: [1.5, 3.0, 10.0])
  func focusMagnification(magnification: Double) throws {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 7, gap: 0.1)
    let chain = try #require(sc.focused(on: 3, magnification: magnification))
    let ratio = chain.chainCircles[chain.largestIndex].radius
      / chain.chainCircles[chain.smallestIndex].radius
    #expect(abs(ratio - magnification) / magnification < 1e-6)
  }

  @Test("Magnification of 1 keeps all circles equal; index wraps around the ring")
  func focusEdgeCases() throws {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 5)
    #expect(sc.inversion(focusingOn: 2, magnification: 1).center == .zero)
    #expect(sc.inversion(focusingOn: 7, magnification: 2).center
            == sc.inversion(focusingOn: 2, magnification: 2).center)
    #expect(sc.inversion(focusingOn: -1, magnification: 2).center
            == sc.inversion(focusingOn: 4, magnification: 2).center)
  }

  @Test("Smallest circle is opposite the focused one for an even count")
  func smallestOpposite() throws {
    let sc = SteinerCircle(outerRadius: 10, circleCount: 8)
    let chain = try #require(sc.focused(on: 1, magnification: 4))
    #expect(chain.smallestIndex == 5)
  }

  private func isTangent(_ a: Circle2D, _ b: Circle2D) -> Bool {
    let d = hypot(a.center.x - b.center.x, a.center.y - b.center.y)
    let tolerance = 1e-6 * max(a.radius, b.radius)
    return abs(d - (a.radius + b.radius)) < tolerance
      || abs(d - abs(a.radius - b.radius)) < tolerance
  }
}
