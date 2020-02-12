//
//  ViewController.swift
//  PeopleOcclusion
//
//  Created by Vineet Choudhary on 12/02/20.
//  Copyright © 2020 Developer Insider. All rights reserved.
//

import UIKit
import ARKit
import RealityKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    @IBOutlet var peopleOcclusionToggleButton: UIButton!
    var cancellable: AnyCancellable? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.15, 0.15])
        arView.scene.addAnchor(anchor)
        
        cancellable = ModelEntity.loadModelAsync(named: "tv").sink(receiveCompletion: { (error) in
            print("Loading AR TV model - \(error) ")
        }) { [unowned self](entity) in 
            anchor.children.append(entity)
            entity.scale = [1, 1, 1] * 0.006

            entity.generateCollisionShapes(recursive: true)
            self.arView.installGestures(.all, for: entity)
            self.setPeopleOcclusionToggleButtonTitle(for: false)
        }
    }
    
    @IBAction func peopleOcclusionButtonAction(_ sender: UIButton) {
        togglePeopleOcclusion()
    }
    
    fileprivate func togglePeopleOcclusion() {
        guard let config = arView.session.configuration as? ARWorldTrackingConfiguration else {
            return
        }
        
        switch config.frameSemantics {
        case .personSegmentationWithDepth:
            config.frameSemantics.remove(.personSegmentationWithDepth)
            setPeopleOcclusionToggleButtonTitle(for: false)
        default:
            config.frameSemantics.insert(.personSegmentationWithDepth)
            setPeopleOcclusionToggleButtonTitle(for: true)
        }
        
        arView.session.run(config, options: .resetTracking)
    }
    
    fileprivate func setPeopleOcclusionToggleButtonTitle(for isOn: Bool) {
        peopleOcclusionToggleButton.isHidden = false
        if !ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
                print("This device doesn't support People Occlusion.")
                peopleOcclusionToggleButton.setTitle("People Occlusion isn't Supported.", for: .normal)
                peopleOcclusionToggleButton.isEnabled = false
                return
        }
        
        peopleOcclusionToggleButton.setTitle("Turn \(isOn ? "off" : "on") People Occlussion", for: .normal)
    }
}
