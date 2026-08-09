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

            ZStack(alignment: .topLeading) {
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
                    vLine(x: px(dims.gripLength),                                    // grip → taper
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

                // --- Draggable grip band(s) ---
                let halfHand = handWidthIn / 2
                let bandW = CGFloat(handWidthIn) * scaleX
                let bandH = drawH * 0.72
                let lo = dims.ballDiameter + halfHand   // can't grip the knob
                let hi = max(L - halfHand, lo)

                GripBand(center: $gripCenterIn, halfHand: halfHand, bandW: bandW, bandH: bandH,
                         centerY: centerY, leftPad: leftPad, s: s, lo: lo, hi: hi,
                         tint: .accentColor, symbol: "hand.draw.fill")
                if let secondGrip {
                    GripBand(center: secondGrip, halfHand: halfHand, bandW: bandW, bandH: bandH,
                             centerY: centerY, leftPad: leftPad, s: s, lo: lo, hi: hi,
                             tint: .purple, symbol: "hand.draw")
                }
            }
        }
        .frame(height: 170)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.95)))
    }
}

/// A single draggable translucent hand band over the club silhouette.
private struct GripBand: View {
    @Binding var center: Double
    let halfHand: Double
    let bandW: CGFloat
    let bandH: CGFloat
    let centerY: CGFloat
    let leftPad: CGFloat
    let s: CGFloat
    let lo: Double
    let hi: Double
    let tint: Color
    let symbol: String

    var body: some View {
        let bandX = leftPad + CGFloat(center - halfHand) * s
        RoundedRectangle(cornerRadius: 6)
            .fill(tint.opacity(0.28))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint, lineWidth: 2))
            .frame(width: max(bandW, 6), height: bandH)
            .overlay(Image(systemName: symbol).font(.caption2).foregroundStyle(tint))
            .position(x: bandX + bandW / 2, y: centerY)
            .gesture(
                DragGesture().onChanged { v in
                    let xIn = Double((v.location.x - leftPad) / s)
                    center = min(max(xIn, lo), hi)
                }
            )
    }
}

#if DEBUG
#Preview("ClubProfileView") {
    ClubbellKitSamples.profileView
        .frame(height: 180)
        .padding()
}
#endif
