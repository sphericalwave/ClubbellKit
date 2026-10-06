import SwiftUI

/// Side-on silhouette of the club (knob on the left, barrel on the right) with a
/// draggable translucent band showing where the hand grips, plus a centre-of-mass
/// marker and an inch ruler. Dragging the band moves the grip.
public struct ClubProfileView: View {
    let dims: ClubDimensions
    @Binding var gripCenterIn: Double
    let handWidthIn: Double
    let comFromBottomIn: Double
    /// Optional second (upper) hand for a two-handed grip.
    private let secondGrip: Binding<Double>?

    private let hPad: CGFloat = 16

    public init(dims: ClubDimensions,
                gripCenterIn: Binding<Double>,
                handWidthIn: Double,
                comFromBottomIn: Double,
                secondGripCenterIn: Binding<Double>? = nil) {
        self.dims = dims
        self._gripCenterIn = gripCenterIn
        self.handWidthIn = handWidthIn
        self.comFromBottomIn = comFromBottomIn
        self.secondGrip = secondGripCenterIn
    }

    public var body: some View {
        GeometryReader { geo in
            let L = max(dims.totalLength, 0.0001)
            let plotW = geo.size.width - hPad * 2
            let maxR = max(dims.barrelDiameter, dims.ballDiameter) / 2
            let rulerH: CGFloat = 24                  // bottom strip reserved for the ruler
            let drawH = geo.size.height - rulerH      // vertical room for the club itself
            // Single isometric scale: same px/in on both axes, fit to whichever
            // dimension is the binding constraint. The club no longer stretches to
            // fill the frame, so proportions are true and clubs are comparable.
            let s = min(plotW / CGFloat(L),
                        maxR > 0 ? (drawH * 0.40) / CGFloat(maxR) : .greatestFiniteMagnitude)
            let scaleX = s
            let scaleY = s
            let centerY = drawH / 2
            let leftPad = (geo.size.width - CGFloat(L) * s) / 2   // centre horizontally
            let px: (Double) -> CGFloat = { xIn in leftPad + CGFloat(xIn) * s }

            // Grip band geometry.
            let halfHand = handWidthIn / 2
            let bandW = CGFloat(handWidthIn) * scaleX
            // Fingers wrapped round the handle: about a fifth of the hand
            // width thick, on each side of the handle.
            let fingerIn = handWidthIn * 0.22
            let lo = dims.ballDiameter + halfHand   // can't grip the knob
            let hi = max(L - halfHand, lo)

            ZStack(alignment: .topLeading) {
                // Upper hand (two-handed): mirrored and drawn under the club, so
                // the fingers wrapping behind the shaft are hidden by it.
                if let secondGrip {
                    GripBand(center: secondGrip, halfHand: halfHand, bandW: bandW,
                             dims: dims, fingerIn: fingerIn,
                             centerY: centerY, leftPad: leftPad, s: s, lo: lo, hi: hi,
                             tint: .purple, mirrored: true)
                }

                Canvas { ctx, _ in
                    // --- Club body (grip → taper → barrel); the knob is drawn
                    //     separately as a sphere, so exclude it here. ---
                    let pts = dims.silhouette(samples: 200, includeKnob: false)
                    let topY = { (r: Double) in centerY - CGFloat(r) * scaleY }
                    let botY = { (r: Double) in centerY + CGFloat(r) * scaleY }
                    let xEnd = px(L)
                    let rb   = dims.barrelDiameter / 2
                    // Slightly rounded barrel end (drawing only — not in the maths).
                    let corner = min(8, CGFloat(rb) * scaleY * 0.6,
                                     CGFloat(dims.barrelLength) * scaleX * 0.5)

                    var path = Path()
                    // Top edge, stopping `corner` short of the barrel end.
                    var started = false
                    for p in pts where px(p.x) <= xEnd - corner {
                        let pt = CGPoint(x: px(p.x), y: topY(p.r))
                        if started { path.addLine(to: pt) } else { path.move(to: pt); started = true }
                    }
                    // Round the two barrel-end corners, then run the bottom edge back.
                    path.addLine(to: CGPoint(x: xEnd - corner, y: topY(rb)))
                    path.addQuadCurve(to: CGPoint(x: xEnd, y: topY(rb) + corner),
                                      control: CGPoint(x: xEnd, y: topY(rb)))
                    path.addLine(to: CGPoint(x: xEnd, y: botY(rb) - corner))
                    path.addQuadCurve(to: CGPoint(x: xEnd - corner, y: botY(rb)),
                                      control: CGPoint(x: xEnd, y: botY(rb)))
                    for p in pts.reversed() where px(p.x) <= xEnd - corner {
                        path.addLine(to: CGPoint(x: px(p.x), y: botY(p.r)))
                    }
                    path.closeSubpath()
                    ctx.fill(path, with: .linearGradient(
                        Gradient(colors: [Color(white: 0.55), Color(white: 0.32)]),
                        startPoint: CGPoint(x: 0, y: centerY - 30),
                        endPoint: CGPoint(x: 0, y: centerY + 30)))
                    ctx.stroke(path, with: .color(Color(white: 0.2)), lineWidth: 1)

                    // --- Knob as a shaded sphere, cut flat so the face = grip ⌀ ---
                    let rk = dims.ballDiameter / 2
                    let rg = dims.gripDiameter / 2
                    let rkPx = CGFloat(rk) * scaleY
                    let ballCX = px(rk)
                    // Cut where the drawn circle's chord equals the grip diameter, so
                    // the handle's top/bottom edges meet the sphere with no notch.
                    // The ball is a circle in scaleY space, so offset in scaleY too.
                    let cutDxPx = rk > rg ? CGFloat((rk * rk - rg * rg).squareRoot()) * scaleY : rkPx
                    let xCut = ballCX + cutDxPx
                    let ball = Path(ellipseIn: CGRect(x: ballCX - rkPx, y: centerY - rkPx,
                                                      width: rkPx * 2, height: rkPx * 2))
                    var ballCtx = ctx                          // clip the sphere at the cut
                    ballCtx.clip(to: Path(CGRect(x: 0, y: 0, width: xCut, height: geo.size.height)))
                    ballCtx.fill(ball, with: .radialGradient(
                        Gradient(colors: [Color(white: 0.7), Color(white: 0.3)]),
                        center: CGPoint(x: ballCX - rkPx * 0.3, y: centerY - rkPx * 0.3),
                        startRadius: 0, endRadius: rkPx * 1.4))
                    ballCtx.stroke(ball, with: .color(Color(white: 0.2)), lineWidth: 1)

                    // --- Black section dividers: knob|grip and grip|taper ---
                    let cutHalf = CGFloat(min(rg, rk)) * scaleY   // = grip half-diameter
                    func vLine(x: CGFloat, halfH: CGFloat) {
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: centerY - halfH))
                        p.addLine(to: CGPoint(x: x, y: centerY + halfH))
                        ctx.stroke(p, with: .color(.black), lineWidth: 1.5)
                    }
                    vLine(x: xCut, halfH: cutHalf)                                   // sphere cut
                    vLine(x: px(dims.gripEnd),                                       // grip → taper
                          halfH: CGFloat(dims.gripDiameter / 2) * scaleY)

                    // --- Centre-of-mass marker ---
                    let comX = px(comFromBottomIn)
                    var com = Path()
                    com.move(to: CGPoint(x: comX, y: centerY - drawH * 0.42))
                    com.addLine(to: CGPoint(x: comX, y: centerY + drawH * 0.42))
                    ctx.stroke(com, with: .color(.orange.opacity(0.9)),
                               style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    let dot = Path(ellipseIn: CGRect(x: comX - 5, y: centerY - 5, width: 10, height: 10))
                    ctx.fill(dot, with: .color(.orange))

                    // --- Length ruler (inches), isometric with the club ---
                    let baseY = drawH + 3
                    let tint = Color(white: 0.45)
                    var axis = Path()
                    axis.move(to: CGPoint(x: px(0), y: baseY))
                    axis.addLine(to: CGPoint(x: px(L), y: baseY))
                    ctx.stroke(axis, with: .color(tint), lineWidth: 1)
                    for inch in 0...Int(L.rounded(.down)) {
                        let x = px(Double(inch))
                        let major = inch % 5 == 0
                        var tick = Path()
                        tick.move(to: CGPoint(x: x, y: baseY))
                        tick.addLine(to: CGPoint(x: x, y: baseY + (major ? 7 : 4)))
                        ctx.stroke(tick, with: .color(tint), lineWidth: 1)
                        if major {
                            ctx.draw(Text("\(inch)").font(.system(size: 8)).foregroundColor(tint),
                                     at: CGPoint(x: x, y: baseY + 14))
                        }
                    }
                }
                // Let drags through to the upper hand underneath.
                .allowsHitTesting(false)

                // --- Draggable lower / only hand, in front of the club ---
                GripBand(center: $gripCenterIn, halfHand: halfHand, bandW: bandW,
                         dims: dims, fingerIn: fingerIn,
                         centerY: centerY, leftPad: leftPad, s: s, lo: lo, hi: hi,
                         tint: .accentColor)
            }
        }
        .frame(height: 170)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.95)))
    }
}

/// A single draggable translucent hand (a fist wrapped round the handle,
/// seen side-on) over the club silhouette. Pinky toward the knob, thumb toward
/// the barrel; in a two-handed grip the upper hand is mirrored so the hands
/// face each other, thumbs meeting between them, as you'd see it.
private struct GripBand: View {
    @Binding var center: Double
    let halfHand: Double
    let bandW: CGFloat
    let dims: ClubDimensions
    /// Finger thickness, inches — added above and below the handle.
    let fingerIn: Double
    let centerY: CGFloat
    let leftPad: CGFloat
    let s: CGFloat
    let lo: Double
    let hi: Double
    let tint: Color
    var mirrored = false

    var body: some View {
        let bandX = leftPad + CGFloat(center - halfHand) * s
        // True to scale: handle thickness where the hand sits plus a finger
        // either side, so a thin handle gets a slimmer fist.
        let handleIn = 2 * dims.radius(atX: center, includeKnob: false)
        let bandH = CGFloat(handleIn + 2 * fingerIn) * s
        FistShape()
            .fill(tint.opacity(0.3))
            .overlay(FistShape().stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round)))
            .frame(width: max(bandW, 6), height: bandH)
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            .contentShape(Rectangle())
            .position(x: bandX + bandW / 2, y: centerY)
            .gesture(
                DragGesture().onChanged { v in
                    let xIn = Double((v.location.x - leftPad) / s)
                    center = min(max(xIn, lo), hi)
                }
            )
    }
}

/// Side-on fist: four finger segments across the hand width (pinky shortest,
/// on the left / knob side) with the thumb laid along the top toward the
/// barrel. Subpaths share winding, so the fill is one even translucent shape
/// and the stroke shows the finger separations.
private struct FistShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let fingerW = w / 4
        // pinky, ring, middle, index
        let heights: [CGFloat] = [0.70, 0.84, 0.90, 0.84]
        for (i, f) in heights.enumerated() {
            let fh = h * f
            let rect = CGRect(x: r.minX + CGFloat(i) * fingerW,
                              y: r.midY - fh / 2 + h * 0.06,
                              width: fingerW, height: fh)
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: fingerW * 0.45, height: fingerW * 0.45))
        }
        // Thumb along the top of the handle, over the middle and index fingers
        // (kept inside the hand width so a stacked upper hand stays clear).
        let thumb = CGRect(x: r.minX + w * 0.40, y: r.minY + h * 0.02,
                           width: w * 0.60, height: h * 0.22)
        p.addRoundedRect(in: thumb, cornerSize: CGSize(width: h * 0.11, height: h * 0.11))
        return p
    }
}

#if DEBUG
#Preview("ClubProfileView") {
    ClubbellKitSamples.profileView
        .frame(height: 180)
        .padding()
}
#endif
