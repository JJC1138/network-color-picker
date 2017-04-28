import MultipeerConnectivity
import UIKit

class ViewController: UIViewController, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        serviceBrowser = MCNearbyServiceBrowser(peer: MCPeerID(displayName: "Client"), serviceType: "colorpicker")
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        serviceBrowser.stopBrowsingForPeers()
        session?.disconnect()
        session = nil
    }
    
    private var serviceBrowser: MCNearbyServiceBrowser!
    
    // MARK: MCNearbyServiceBrowserDelegate
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.stopBrowsingForPeers()
        
        let session = MCSession(peer: browser.myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 5)
        self.session = session
    }
    
    private var session: MCSession?
    
    // MCSessionDelegate
    
    // MARK: MCSessionDelegate
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .notConnected {
            DispatchQueue.main.async {
                self.session = nil
                self.serviceBrowser.startBrowsingForPeers()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("received data") // FIXME remove
    }
    
}
