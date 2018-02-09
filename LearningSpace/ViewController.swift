/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    @IBOutlet weak var blurView: UIVisualEffectView!

    // reference nodes for coordinate system
    var referenceNodes = [ReferenceType: ReferenceNode]()
    let neededReferences: [ReferenceType] = [.wall1point1, .wall1point2, .wall2point1, .wall3point1, .wall4point1]

    // Planes
    var planes = [UUID: Plane]()

    // Detected image anchors; need to track so we can reset when floor is detected
    var imageAnchors = [ARImageAnchor]()

    // floorPlane
    var floorPlane: Plane?
    let minFloorSize = CGFloat(1.0)

    // Visualization of coordinate system
    var coordinateSystemPreview: SCNNode!

    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()

    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")

    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.session.delegate = self

        coordinateSystemPreview = SCNNode()
        sceneView.scene.rootNode.addChildNode(coordinateSystemPreview)

        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)

    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {

        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }

        self.imageAnchors.removeAll()
        self.floorPlane = nil
        self.referenceNodes.removeAll()

        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        switch anchor {
        case let imageAnchor as ARImageAnchor:
            if let scene = renderer.scene {
                referenceImageDetected(node: node, anchor: imageAnchor, scene: scene)
            }
        case let planeAnchor as ARPlaneAnchor:
            planeDetected(node: node, planeAnchor: planeAnchor)
        default:
            print("unknown node added: \(node) to anchor: \(anchor)")
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else { return }

        guard let anchor = anchor as? ARPlaneAnchor else { return }

        plane.update(anchor: anchor)

        if floorPlane == nil && plane.area() >= minFloorSize {
            DispatchQueue.main.async {
                self.statusViewController.showMessage("Floor detected. Look around to detect images");
            }
            // Clear any detected image anchors
            for (anchor) in imageAnchors {
                self.session.remove(anchor: anchor)
            }
            floorPlane = plane
        }
        updateQueue.async {
            if let floorPlane = self.floorPlane, floorPlane.anchor.identifier == anchor.identifier {
                for (_, referenceNode) in self.referenceNodes {
                    referenceNode.adjustOntoPlaneAnchor(anchor, using: node)
                }
                self.updateClassroomBounds(scene: self.sceneView.scene)
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if floorPlane?.anchor.identifier == anchor.identifier {
            floorPlane = nil
            DispatchQueue.main.async {
                self.statusViewController.showMessage("Lost floor plane. Resetting...");
                self.resetTracking()
            }
        }
        planes.removeValue(forKey: anchor.identifier)
    }

    func planeDetected(node: SCNNode, planeAnchor: ARPlaneAnchor) {
        print("Plane detected: \(planeAnchor)")
        let plane = Plane(anchor: planeAnchor)
        planes[planeAnchor.identifier] = plane
        node.addChildNode(plane)
    }

    func startImageHighlight(node: SCNNode, referenceImage: ARReferenceImage) {
        updateQueue.async {

            // Create a plane to visualize the initial position of the detected image.
            let plane = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)
            let planeNode = SCNNode(geometry: plane)
            planeNode.opacity = 0.25

            /*
             `SCNPlane` is vertically oriented in its local coordinate space, but
             `ARImageAnchor` assumes the image is horizontal in its local space, so
             rotate the plane to match.
             */
            planeNode.eulerAngles.x = -.pi / 2

            /*
             Image anchors are not tracked after initial detection, so create an
             animation that limits the duration for which the plane visualization appears.
             */
            planeNode.runAction(self.imageHighlightAction)

            // Add the plane visualization to the scene.
            node.addChildNode(planeNode)
        }
    }

    func referenceImageDetected(node: SCNNode, anchor: ARImageAnchor, scene: SCNScene) {
        imageAnchors.append(anchor)

        guard let floorPlane = floorPlane else { return }

        startImageHighlight(node: node, referenceImage: anchor.referenceImage)

        if let referenceType = neededReferences.first(where: { referenceNodes[$0] == nil } ) {
            print("Adding reference image \(String(describing: anchor.referenceImage.name)) for \(referenceType)")
            updateQueue.async {
                let referenceNode = ReferenceNode(anchor: anchor, referenceType: referenceType, referenceImage: anchor.referenceImage)
                referenceNode.position = node.worldPosition
                self.referenceNodes[referenceType] = referenceNode
                scene.rootNode.addChildNode(referenceNode)
                referenceNode.adjustOntoPlaneAnchor(floorPlane.anchor, using: floorPlane)
                self.updateClassroomBounds(scene: scene)
            }
            DispatchQueue.main.async {
                let imageName = anchor.referenceImage.name ?? ""
                self.statusViewController.cancelAllScheduledMessages()
                self.statusViewController.showMessage("Detected image “\(imageName)”")
            }


        }

    }

    func updateClassroomBounds(scene: SCNScene) {
        // Clear out old nodes
        coordinateSystemPreview.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }

        guard let floorPlane = floorPlane,
              let wall1reference1 = referenceNodes[.wall1point1],
              let wall1reference2 = referenceNodes[.wall1point2],
              let wall2reference1 = referenceNodes[.wall2point1] else
        {
                return
        }

        let p1 = floorPlane.convertPosition(wall1reference1.position, from: wall1reference1.parent)
        let p2 = floorPlane.convertPosition(wall1reference2.position, from: wall1reference2.parent)
        let p3 = floorPlane.convertPosition(wall2reference1.position, from: wall2reference1.parent)

        let v1 = p2 - p1
        let v2 = p3 - p1

        let csOriginInFloorCoords = v2.project(onto: v1) + p1
        let csOriginInWorldCoords = floorPlane.convertPosition(csOriginInFloorCoords, to: scene.rootNode)
        print("csOriginInFloorCoords = \(csOriginInFloorCoords)")
        print("csOriginInWorldCoords = \(csOriginInWorldCoords)")

        let classroomRootNode = SCNNode();
        coordinateSystemPreview.addChildNode(classroomRootNode)
        
        // Determine rotation of coordinate system wrt floor plane
        let xAxisVector = p1 - csOriginInFloorCoords
        print("xAxisVector = \(xAxisVector)")
        let flip = xAxisVector.z < 0 ? 1 : -1
        let rotationAdd = Float(flip) * Float.pi / 2
        let csRotation = SCNMatrix4MakeRotation(atan(xAxisVector.x / xAxisVector.z) + rotationAdd, 0, 1, 0)

        if let floorRotation = floorPlane.parent?.rotation {
            classroomRootNode.rotation = floorRotation
        }
        classroomRootNode.position = csOriginInWorldCoords
        classroomRootNode.transform = csRotation * classroomRootNode.transform
        
        

        // Add a plane to show orientation of our classroom coordinate space
        let csPlane = SCNPlane(width: 1, height: 1)
        let csPlaneNode = SCNNode(geometry: csPlane)
        csPlaneNode.eulerAngles.x = -(Float.pi / 2)
        classroomRootNode.addChildNode(csPlaneNode)
        
        // Add a yellow sphere to show x axis of our classroom coordinate space
        let csPlaneXMarker = SCNSphere(radius: 0.025)
        csPlaneXMarker.firstMaterial?.diffuse.contents = UIColor(red: 150.0 / 255.0, green: 150.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
        let csPlaneXMarkerNode = SCNNode(geometry: csPlaneXMarker)
        csPlaneXMarkerNode.position = SCNVector3Make(0.5, 0, 0)
        classroomRootNode.addChildNode(csPlaneXMarkerNode)

        // Add a red sphere to show x axis of our classroom coordinate space
        let csPlaneZMarker = SCNSphere(radius: 0.025)
        csPlaneZMarker.firstMaterial?.diffuse.contents = UIColor(red: 150.0 / 255.0, green: 30.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
        let csPlaneZMarkerNode = SCNNode(geometry: csPlaneZMarker)
        csPlaneZMarkerNode.position = SCNVector3Make(0, 0, 0.5)
        classroomRootNode.addChildNode(csPlaneZMarkerNode)

        for (_, node) in referenceNodes {
            let pos = classroomRootNode.convertPosition(node.position, from: node.parent)
            print("\(node.referenceImage.name) is at \(pos)")
        }


        //let translate = SCNMatrix4MakeTranslation(0, -1, 0)
        //self.session.setWorldOrigin(relativeTransform: simd_float4x4(translate))

        let wall1 = CylinderLine(v1: wall1reference1.worldPosition, v2: wall1reference2.worldPosition, radius: 0.01, radSegmentCount: 5, color: UIColor.cyan)
        coordinateSystemPreview.addChildNode(wall1)
        let wall2 = CylinderLine(v1: wall2reference1.worldPosition, v2: csOriginInWorldCoords, radius: 0.01, radSegmentCount: 5, color: UIColor.blue)
        coordinateSystemPreview.addChildNode(wall2)
    }

    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
}
