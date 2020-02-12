//
//  ViewController.swift
//  CoolaborativeSession
//
//  Created by Vineet Choudhary on 12/02/20.
//  Copyright © 2020 Developer Insider. All rights reserved.
//

import UIKit
import ARKit
import RealityKit
import MultipeerConnectivity
import Combine

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    let serviceType = "coolabrative"
    let uuidSeperator = "::::"
    
    private(set) var mcSession: MCSession!
    private(set) var mcService: MultipeerConnectivityService?
    private(set) var mcServiceBrowser: MCNearbyServiceBrowser!
    private(set) var mcServiceAdvertiser: MCNearbyServiceAdvertiser!
    
    private(set) var connectedPeers = [MCPeerID]()
    private(set) var cancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMultipeerConnectivityService()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [unowned self] in
            if self.connectedPeers.count == 0 {
                self.setupARView()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.enableCollaboration()
    }
    
    
    fileprivate func setupARView() {
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.15, 0.15])
        arView.scene.addAnchor(anchor)
        
        cancellable = ModelEntity.loadModelAsync(named: "tv").sink(receiveCompletion: { (error) in
            print("Loading AR TV Model - \(error)")
        }, receiveValue: { [unowned self] (entity) in
            anchor.addChild(entity)
            entity.scale = [1, 1, 1] * 0.01
            
            entity.generateCollisionShapes(recursive: true)
            self.arView.installGestures(.all, for: entity)
        })
    }
    
    fileprivate func enableCollaboration() {
        guard let config = arView.session.configuration as? ARWorldTrackingConfiguration else {
            return
        }
        config.isCollaborationEnabled = true
        arView.session.run(config, options: .init())
    }
    
    fileprivate func setupMultipeerConnectivityService() {
        
        let deviceName = "\(UIDevice.current.name)\(uuidSeperator)\(UUID().uuidString)"
        let peerId = MCPeerID(displayName: deviceName)
        
        mcSession = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        mcServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: nil, serviceType: serviceType)
        mcServiceAdvertiser.delegate = self
        mcServiceAdvertiser.startAdvertisingPeer()
        
        mcServiceBrowser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)
        mcServiceBrowser.delegate = self
        mcServiceBrowser.startBrowsingForPeers()
        
        do {
            mcService = try MultipeerConnectivityService(session: mcSession)
            arView.scene.synchronizationService = mcService
        } catch {
            print("Unable to start multipeer connectivity service - \(error.localizedDescription)")
        }
    
        arView.session.delegate = self
    }
    
    fileprivate func addConnectedDevice(peerId: MCPeerID) {
        //remove peerId if already exists
        removeConnectedDevice(lostPeerId: peerId)
        
        //add new peerId
        connectedPeers.append(peerId)
    }
    
    fileprivate func removeConnectedDevice(lostPeerId: MCPeerID) {
        if let lostPeerIndex = connectedPeers.firstIndex(where: { $0.displayName == lostPeerId.displayName }) {
            connectedPeers.remove(at: lostPeerIndex)
        }
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let collaborationData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true) else {
            print("Cannot encode collaboration data.")
            return
        }
        do {
            try mcSession.send(collaborationData, toPeers: connectedPeers, with: .reliable)
        } catch {
            print("Unable to send colloboaration data \(error.localizedDescription)")
        }

    }
}

extension ViewController: MCSessionDelegate {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let collaborativeData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            arView.session.update(with: collaborativeData)
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

extension ViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        addConnectedDevice(peerId: peerID)
        invitationHandler(true, mcSession)
    }
}

extension ViewController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        addConnectedDevice(peerId: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        removeConnectedDevice(lostPeerId: peerID)
    }
}
