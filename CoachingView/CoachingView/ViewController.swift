//
//  ViewController.swift
//  CoachingView
//
//  Created by Vineet Choudhary on 13/02/20.
//  Copyright © 2020 Developer Insider. All rights reserved.
//

import UIKit
import ARKit
import Combine
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    private var coachingView: ARCoachingOverlayView!
    private var cancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ARSession Delegate
        arView.session.delegate = self
        
        //create anchor entity
        let anchor = AnchorEntity(plane: .horizontal, classification: .any, minimumBounds: [0.20, 0.20])
        arView.scene.addAnchor(anchor)
        
        cancellable = ModelEntity.loadModelAsync(named: "toy_drummer").sink(receiveCompletion: { (completionResult) in
            print("Toy Drummer Completion Result - \(completionResult)")
        }, receiveValue: { [unowned self] (entity) in
            anchor.addChild(entity)
            entity.scale = [1, 1, 1] * 0.05
            self.arView.installGestures(.scale, for: entity)
        })
        
        // Create ARCoachingOverlayView and add to ARView
        coachingView = ARCoachingOverlayView()
        arView.addSubview(coachingView)
        coachingView.session = arView.session
        coachingView.delegate = self
        
        // Fill superview with coaching view
        coachingView.translatesAutoresizingMaskIntoConstraints = false
        coachingView.topAnchor.constraint(equalTo: arView.topAnchor).isActive = true
        coachingView.bottomAnchor.constraint(equalTo: arView.bottomAnchor).isActive = true
        coachingView.leadingAnchor.constraint(equalTo: arView.leadingAnchor).isActive = true
        coachingView.trailingAnchor.constraint(equalTo: arView.trailingAnchor).isActive = true
    }

}

extension ViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        print("CoachingOverlayView - Requested Session Reset")
    }

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("CoachingOverlayView - Will Activate")
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        print("CoachingOverlayView - Did Deactivate")
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("ARSession Wold Mapping Status - \(frame.worldMappingStatus.description)")
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            print("ARSession Anchore Added - \(String(describing: anchor.name)) - \(anchor.identifier)")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARSession error - \(error.localizedDescription)")
    }
}

extension ARFrame.WorldMappingStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notAvailable:
            return "Not Available"
        case .extending:
            return "Extending"
        case .limited:
            return "Limited"
        case .mapped:
            return "Mapped"
        default:
            return "unknown"
        }
    }
}
