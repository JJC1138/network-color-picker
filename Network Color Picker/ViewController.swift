import Cocoa
import MultipeerConnectivity

class ViewController: NSViewController, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
    
    var color = NSColor.magenta
    
    @IBOutlet weak var colorWell: NSColorWell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: MCPeerID(displayName: "Server"), discoveryInfo: nil, serviceType: "colorpicker")
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
        
        colorWell.addObserver(self, forKeyPath: #keyPath(NSColorWell.color), options: [.initial], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        color = colorWell.color
        print("Color changed to: \(color)") // FIXME remove
        
        for session in sessions {
            sendColor(to: session.connectedPeers, of: session)
        }
    }
    
    func sendColor(to peers: [MCPeerID], of session: MCSession) {
        try? session.send(data(from: color), toPeers: peers, with: .reliable)
    }
    
    func data(from color: NSColor) -> Data {
        // FIXME Serialize for real instead of:
        return Data()
    }
    
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    
    // MARK: MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let session = MCSession(peer: serviceAdvertiser.myPeerID)
        session.delegate = self
        invitationHandler(true, session)
        DispatchQueue.main.async {
            self.sessions.append(session)
        }
    }
    
    private var sessions = [MCSession]()
    
    // MARK: MCSessionDelegate
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            DispatchQueue.main.async {
                self.sendColor(to: [peerID], of: session)
            }
        } else if state == .notConnected {
            DispatchQueue.main.async {
                self.sessions.remove(at: self.sessions.index(of: session)!)
            }
        }
    }
    
}
