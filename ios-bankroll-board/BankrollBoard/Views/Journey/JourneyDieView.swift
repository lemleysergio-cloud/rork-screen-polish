//
//  JourneyDieView.swift
//  BankrollBoard
//

import SceneKit
import SwiftUI

/// Bank-green 3D die that tumbles in place and settles on a new face.
/// Bump `rollToken` to trigger a roll; `onLand` reports the resting face.
struct JourneyDieView: UIViewRepresentable {
    let rollToken: Int
    let onLand: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLand: onLand)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.makeScene()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.rendersContinuously = false
        view.isUserInteractionEnabled = false
        view.autoenablesDefaultLighting = false
        context.coordinator.lastToken = rollToken
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.onLand = onLand
        guard rollToken != context.coordinator.lastToken else { return }
        context.coordinator.lastToken = rollToken
        context.coordinator.roll()
    }

    static func dismantleUIView(_ view: SCNView, coordinator: Coordinator) {
        view.scene = nil
    }

    // MARK: - Coordinator

    final class Coordinator {
        var onLand: (Int) -> Void
        var lastToken: Int = 0

        private let dieNode = SCNNode()
        private var currentFace: Int = 5
        private var isRolling: Bool = false

        init(onLand: @escaping (Int) -> Void) {
            self.onLand = onLand
        }

        func makeScene() -> SCNScene {
            let scene = SCNScene()
            scene.background.contents = UIColor.clear

            let box = SCNBox(width: 4, height: 4, length: 4, chamferRadius: 0.74)
            box.chamferSegmentCount = 16
            box.widthSegmentCount = 4
            box.heightSegmentCount = 4
            box.lengthSegmentCount = 4
            // SCNBox material order: front, right, back, left, top, bottom.
            box.materials = [1, 3, 6, 4, 5, 2].map { DieFace.material(for: $0) }

            dieNode.geometry = box
            dieNode.simdOrientation = Self.orientation(for: currentFace)
            scene.rootNode.addChildNode(dieNode)

            // Key light sits high and to the left so the top face reads brightest,
            // the left face mid, and the right face falls into shadow.
            let key = SCNNode()
            key.light = {
                let light = SCNLight()
                light.type = .directional
                light.intensity = 1150
                light.color = UIColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1)
                light.castsShadow = false
                return light
            }()
            key.position = SCNVector3(-6, 11, 7)
            key.look(at: SCNVector3Zero)
            scene.rootNode.addChildNode(key)

            let fill = SCNNode()
            fill.light = {
                let light = SCNLight()
                light.type = .omni
                light.intensity = 300
                light.color = UIColor(red: 0.70, green: 0.84, blue: 0.75, alpha: 1)
                return light
            }()
            fill.position = SCNVector3(9, -4, 7)
            scene.rootNode.addChildNode(fill)

            // Cool rim from behind separates the die from the canvas.
            let rim = SCNNode()
            rim.light = {
                let light = SCNLight()
                light.type = .directional
                light.intensity = 420
                light.color = UIColor(red: 0.78, green: 0.88, blue: 0.80, alpha: 1)
                return light
            }()
            rim.position = SCNVector3(4, 6, -8)
            rim.look(at: SCNVector3Zero)
            scene.rootNode.addChildNode(rim)

            let ambient = SCNNode()
            ambient.light = {
                let light = SCNLight()
                light.type = .ambient
                light.intensity = 250
                light.color = UIColor(red: 0.44, green: 0.57, blue: 0.48, alpha: 1)
                return light
            }()
            scene.rootNode.addChildNode(ambient)

            let camera = SCNNode()
            camera.camera = {
                let lens = SCNCamera()
                lens.fieldOfView = 46
                lens.wantsDepthOfField = false
                return lens
            }()
            camera.position = SCNVector3(0, 0, 9.4)
            scene.rootNode.addChildNode(camera)

            return scene
        }

        /// Tumbles in place: multiple spins that decay exactly onto a new face.
        func roll() {
            guard !isRolling else { return }
            isRolling = true

            let nextFace = Self.nextFace(after: currentFace)
            let start = dieNode.simdOrientation
            let end = Self.orientation(for: nextFace)
            let duration: TimeInterval = 1.05
            let turns: Float = 2
            let axis = simd_normalize(simd_float3(0.34, 1, 0.22))

            let action = SCNAction.customAction(duration: duration) { node, elapsed in
                let t = min(1, Float(elapsed) / Float(duration))
                let eased = 1 - pow(1 - t, 4)
                // Angle is a whole number of turns at t = 0, so the cube starts exactly at `start`.
                let spin = simd_quatf(angle: (eased - 1) * turns * 2 * .pi, axis: axis)
                let settle = sin(Double(eased) * .pi) * 0.05
                let wobble = simd_quatf(angle: Float(settle) * (1 - eased), axis: simd_float3(1, 0, 0))
                node.simdOrientation = simd_slerp(start, end, eased) * spin * wobble
            }
            action.timingMode = .linear
            dieNode.removeAllActions()
            dieNode.runAction(action)

            currentFace = nextFace
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(duration))
                self?.isRolling = false
                self?.onLand(nextFace)
            }
        }

        /// Never lands on the same face twice in a row.
        private static func nextFace(after face: Int) -> Int {
            var candidate = Int.random(in: 1...6)
            while candidate == face {
                candidate = Int.random(in: 1...6)
            }
            return candidate
        }

        /// Resting orientation that shows `face` toward the camera with the hero tilt.
        private static func orientation(for face: Int) -> simd_quatf {
            restTilt * align(face: face)
        }

        /// Signature corner-on pose: the die is turned so one vertical edge faces the
        /// viewer and tipped forward, showing the top face plus both front faces.
        /// Positive X tips the top toward the camera in SceneKit's y-up space; the
        /// negative Y turn swings the lit face to the left, matching the web build's
        /// `rotateX(29deg) rotateY(-36deg) rotateZ(-3deg)` orientation.
        private static var restTilt: simd_quatf {
            let radians: (Float) -> Float = { $0 * .pi / 180 }
            let x = simd_quatf(angle: radians(27), axis: simd_float3(1, 0, 0))
            let y = simd_quatf(angle: radians(-36), axis: simd_float3(0, 1, 0))
            let z = simd_quatf(angle: radians(-3), axis: simd_float3(0, 0, 1))
            return x * y * z
        }

        /// Rotation that brings the given face's normal to +Z.
        private static func align(face: Int) -> simd_quatf {
            switch face {
            case 1: simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
            case 6: simd_quatf(angle: .pi, axis: simd_float3(0, 1, 0))
            case 3: simd_quatf(angle: -.pi / 2, axis: simd_float3(0, 1, 0))
            case 4: simd_quatf(angle: .pi / 2, axis: simd_float3(0, 1, 0))
            case 5: simd_quatf(angle: .pi / 2, axis: simd_float3(1, 0, 0))
            default: simd_quatf(angle: -.pi / 2, axis: simd_float3(1, 0, 0))
            }
        }
    }
}

// MARK: - Face textures

/// Draws die faces: bank-green body with recessed ivory pips.
nonisolated enum DieFace {
    private static let pips: [Int: [CGPoint]] = [
        1: [CGPoint(x: 0.50, y: 0.50)],
        2: [CGPoint(x: 0.28, y: 0.28), CGPoint(x: 0.72, y: 0.72)],
        3: [CGPoint(x: 0.27, y: 0.27), CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.73, y: 0.73)],
        4: [CGPoint(x: 0.28, y: 0.28), CGPoint(x: 0.72, y: 0.28), CGPoint(x: 0.28, y: 0.72), CGPoint(x: 0.72, y: 0.72)],
        5: [
            CGPoint(x: 0.27, y: 0.27), CGPoint(x: 0.73, y: 0.27), CGPoint(x: 0.50, y: 0.50),
            CGPoint(x: 0.27, y: 0.73), CGPoint(x: 0.73, y: 0.73)
        ],
        6: [
            CGPoint(x: 0.28, y: 0.24), CGPoint(x: 0.72, y: 0.24), CGPoint(x: 0.28, y: 0.50),
            CGPoint(x: 0.72, y: 0.50), CGPoint(x: 0.28, y: 0.76), CGPoint(x: 0.72, y: 0.76)
        ]
    ]

    static func material(for value: Int) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = image(for: value)
        // Soft, chalky resin rather than a glossy casino die.
        material.roughness.contents = 0.52
        material.metalness.contents = 0.0
        material.isDoubleSided = false
        return material
    }

    private static func image(for value: Int) -> UIImage {
        let side: CGFloat = 256
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { context in
            let cg = context.cgContext
            let bounds = CGRect(x: 0, y: 0, width: side, height: side)

            let body = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.118, green: 0.204, blue: 0.145, alpha: 1).cgColor,
                    UIColor(red: 0.063, green: 0.125, blue: 0.086, alpha: 1).cgColor
                ] as CFArray,
                locations: [0, 1]
            )
            if let body {
                cg.drawLinearGradient(
                    body,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: side, y: side),
                    options: []
                )
            } else {
                UIColor(red: 0.09, green: 0.16, blue: 0.11, alpha: 1).setFill()
                cg.fill(bounds)
            }

            // Vignette so face edges fall off slightly, as on a molded die.
            if let edge = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 0, alpha: 0).cgColor,
                    UIColor(red: 0.02, green: 0.05, blue: 0.03, alpha: 0.45).cgColor
                ] as CFArray,
                locations: [0.55, 1]
            ) {
                cg.drawRadialGradient(
                    edge,
                    startCenter: CGPoint(x: side / 2, y: side / 2),
                    startRadius: 0,
                    endCenter: CGPoint(x: side / 2, y: side / 2),
                    endRadius: side * 0.78,
                    options: [.drawsAfterEndLocation]
                )
            }

            let pipRadius = side * 0.093
            for pip in pips[value] ?? [] {
                let center = CGPoint(x: pip.x * side, y: pip.y * side)
                let rect = CGRect(
                    x: center.x - pipRadius,
                    y: center.y - pipRadius,
                    width: pipRadius * 2,
                    height: pipRadius * 2
                )

                // Drilled recess: a soft dark halo the pip sits down inside.
                cg.saveGState()
                cg.setShadow(
                    offset: CGSize(width: 0, height: pipRadius * 0.12),
                    blur: pipRadius * 0.55,
                    color: UIColor(red: 0.02, green: 0.05, blue: 0.03, alpha: 0.9).cgColor
                )
                UIColor(red: 0.035, green: 0.075, blue: 0.05, alpha: 0.9).setFill()
                cg.fillEllipse(in: rect.insetBy(dx: -pipRadius * 0.13, dy: -pipRadius * 0.13))
                cg.restoreGState()

                let ivory = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [
                        UIColor(red: 0.992, green: 0.972, blue: 0.906, alpha: 1).cgColor,
                        UIColor(red: 0.941, green: 0.886, blue: 0.761, alpha: 1).cgColor,
                        UIColor(red: 0.769, green: 0.675, blue: 0.482, alpha: 1).cgColor
                    ] as CFArray,
                    locations: [0, 0.55, 1]
                )
                cg.saveGState()
                cg.addEllipse(in: rect)
                cg.clip()
                if let ivory {
                    cg.drawRadialGradient(
                        ivory,
                        startCenter: CGPoint(x: center.x - pipRadius * 0.3, y: center.y - pipRadius * 0.35),
                        startRadius: 0,
                        endCenter: center,
                        endRadius: pipRadius * 1.25,
                        options: [.drawsAfterEndLocation]
                    )
                } else {
                    UIColor(red: 0.9, green: 0.84, blue: 0.7, alpha: 1).setFill()
                    cg.fill(rect)
                }
                cg.restoreGState()
            }
        }
    }
}
