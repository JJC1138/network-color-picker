import Foundation
import UIKit

class ViewController: UIViewController, NetServiceBrowserDelegate, StreamDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        networkColorPickerClient.start()
        
        networkColorPickerClient.delegate = { color in
            print(color)
            self.view.backgroundColor = color
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        networkColorPickerClient.stop()
        
        networkColorPickerClient.delegate = nil
    }
    
    private var networkColorPickerClient = NetworkColorPickerClient()
    
}
