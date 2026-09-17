//
//  JourneyDiceView.swift
//  BankrollBoard
//
//  SceneKit die at the center of the Journey hero, with two soft ground shadows.
//

import SceneKit
import SwiftUI

struct JourneyDiceView: View {
    let tumbleToken: Int
    let strongTumble: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.42))
                .frame(width: 172, height: 48)
                .blur(radius: 22)
                .offset(x: 7, y: 61)

            Ellipse()
                .fill(Color.black.opacity(0.67))
                .frame(width: 116, height: 25)
                .blur(radius: 8)
                .offset(x: 4, y: 53)

            JourneyDiceSceneView(tumbleToken: tumbleToken, strongTumble: strongTumble)
                .frame(width: 198, height: 198)
                .accessibilityHidden(true)
        }
        .frame(width: 152, height: 152)
        .contentShape(Rectangle())
    }
}

private struct JourneyDiceSceneView: UIViewRepresentable {
    let tumbleToken: Int
    let strongTumble: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = false
        view.rendersContinuously = true
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        guard context.coordinator.lastTumbleToken != tumbleToken else { return }
        context.coordinator.lastTumbleToken = tumbleToken
        context.coordinator.tumble(strong: strongTumble)
    }

    final class Coordinator {
        let scene = SCNScene()
        let cameraNode = SCNNode()
        private let dieNode = SCNNode()
        var lastTumbleToken = 0

        init() {
            configureCamera()
            configureLights()
            configureDie()
        }

        private func configureCamera() {
            let camera = SCNCamera()
            camera.usesOrthographicProjection = true
            camera.orthographicScale = 3.65
            camera.zNear = 0.1
            camera.zFar = 100
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0, 7)
            scene.rootNode.addChildNode(cameraNode)
        }

        private func configureLights() {
            let key = SCNNode()
            key.light = SCNLight()
            key.light?.type = .omni
            key.light?.intensity = 1_050
            key.light?.temperature = 5_100
            key.position = SCNVector3(-4, 5, 7)
            scene.rootNode.addChildNode(key)

            let fill = SCNNode()
            fill.light = SCNLight()
            fill.light?.type = .omni
            fill.light?.intensity = 290
            fill.light?.color = UIColor(red: 0.53, green: 0.68, blue: 0.56, alpha: 1)
            fill.position = SCNVector3(4, 1, 3)
            scene.rootNode.addChildNode(fill)

            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 260
            ambient.light?.color = UIColor(red: 0.25, green: 0.34, blue: 0.27, alpha: 1)
            scene.rootNode.addChildNode(ambient)
        }

        private func configureDie() {
            let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.27)
            box.chamferSegmentCount = 14

            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor(red: 0.075, green: 0.20, blue: 0.12, alpha: 1)
            material.roughness.contents = 0.31
            material.metalness.contents = 0.02
            box.materials = [material]

            dieNode.geometry = box
            dieNode.eulerAngles = SCNVector3(degrees: 29, -36, -3)
            scene.rootNode.addChildNode(dieNode)

            addPips(value: 1, face: .front)
            addPips(value: 6, face: .back)
            addPips(value: 3, face: .right)
            addPips(value: 4, face: .left)
            addPips(value: 5, face: .top)
            addPips(value: 2, face: .bottom)
        }

        func tumble(strong: Bool) {
            dieNode.removeAllActions()
            let turns: Float = strong ? 4 : 2
            let duration = strong ? 1.42 : 0.58
            let rotation = SCNAction.rotateBy(
                x: CGFloat(Float.pi * turns),
                y: CGFloat(Float.pi * turns * 1.08),
                z: CGFloat(Float.pi * 2),
                duration: duration
            )
            rotation.timingMode = .easeInEaseOut
            let settle = SCNAction.rotateTo(
                x: CGFloat(29 * Float.pi / 180),
                y: CGFloat(-36 * Float.pi / 180),
                z: CGFloat(-3 * Float.pi / 180),
                duration: strong ? 0.20 : 0.10,
                usesShortestUnitArc: true
            )
            settle.timingMode = .easeOut
            dieNode.runAction(.sequence([rotation, settle]))
        }

        private enum Face {
            case front, back, right, left, top, bottom
        }

        private func addPips(value: Int, face: Face) {
            for position in pipPositions(value) {
                let cavity = makePip(radius: 0.125, color: UIColor.black.withAlphaComponent(0.46))
                place(pip: cavity, face: face, u: position.x, v: position.y, lift: 1.006)
                dieNode.addChildNode(cavity)

                let ivory = makePip(radius: 0.095, color: UIColor(red: 0.91, green: 0.82, blue: 0.63, alpha: 1))
                place(pip: ivory, face: face, u: position.x, v: position.y, lift: 1.024)
                dieNode.addChildNode(ivory)
            }
        }

        private func makePip(radius: CGFloat, color: UIColor) -> SCNNode {
            let geometry = SCNCylinder(radius: radius, height: 0.028)
            geometry.radialSegmentCount = 28
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = color
            material.roughness.contents = 0.38
            geometry.materials = [material]
            return SCNNode(geometry: geometry)
        }

        private func place(pip: SCNNode, face: Face, u: CGFloat, v: CGFloat, lift: Float) {
            let u = Float(u)
            let v = Float(v)
            switch face {
            case .front:
                pip.position = SCNVector3(u, v, lift)
                pip.eulerAngles.x = .pi / 2
            case .back:
                pip.position = SCNVector3(-u, v, -lift)
                pip.eulerAngles.x = .pi / 2
            case .right:
                pip.position = SCNVector3(lift, v, -u)
                pip.eulerAngles.z = .pi / 2
            case .left:
                pip.position = SCNVector3(-lift, v, u)
                pip.eulerAngles.z = .pi / 2
            case .top:
                pip.position = SCNVector3(u, lift, -v)
            case .bottom:
                pip.position = SCNVector3(u, -lift, v)
            }
        }

        private func pipPositions(_ value: Int) -> [CGPoint] {
            let low: CGFloat = -0.43
            let high: CGFloat = 0.43
            let center: CGFloat = 0
            switch value {
            case 1: return [.init(x: center, y: center)]
            case 2: return [.init(x: low, y: high), .init(x: high, y: low)]
            case 3: return [.init(x: low, y: high), .init(x: center, y: center), .init(x: high, y: low)]
            case 4: return [.init(x: low, y: high), .init(x: high, y: high), .init(x: low, y: low), .init(x: high, y: low)]
            case 5: return [.init(x: low, y: high), .init(x: high, y: high), .init(x: center, y: center), .init(x: low, y: low), .init(x: high, y: low)]
            default: return [.init(x: low, y: high), .init(x: high, y: high), .init(x: low, y: center), .init(x: high, y: center), .init(x: low, y: low), .init(x: high, y: low)]
            }
        }
    }
}

private extension SCNVector3 {
    init(degrees x: Float, _ y: Float, _ z: Float) {
        self.init(x * .pi / 180, y * .pi / 180, z * .pi / 180)
    }
}
