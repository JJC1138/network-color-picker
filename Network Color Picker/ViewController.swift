import AppKit
import Foundation

class ViewController: NSViewController, NetServiceDelegate {
    
    var color = NSColor.magenta
    
    @IBOutlet weak var colorWell: NSColorWell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        service = NetService(domain: "local.", type: "_colorpicker._tcp.", name: "", port: 0)
        service.delegate = self
        service.publish(options: [.listenForConnections])
        
        colorWell.addObserver(self, forKeyPath: #keyPath(NSColorWell.color), options: [.initial], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        color = colorWell.color
        
        for stream in openSocketStreams {
            sendColor(to: stream)
        }
    }
    
    func sendColor(to outputStream: OutputStream) {
        let data = self.data(from: color)
        let bytesWritten = data.withUnsafeBytes { pointer in
            return outputStream.write(pointer, maxLength: data.count)
        }
        if bytesWritten == -1 {
            outputStream.close()
            openSocketStreams.remove(at: openSocketStreams.index(of: outputStream)!)
        } else {
            assert(bytesWritten == data.count)
        }
    }
    
    func data(from color: NSColor) -> Data {
        let extendedSRGBColor = color.usingColorSpace(.extendedSRGB)!
        
        let archiver = NSKeyedArchiver()
        
        archiver.encode(Double(extendedSRGBColor.redComponent), forKey: "red")
        archiver.encode(Double(extendedSRGBColor.greenComponent), forKey: "green")
        archiver.encode(Double(extendedSRGBColor.blueComponent), forKey: "blue")
        archiver.encode(Double(extendedSRGBColor.alphaComponent), forKey: "alpha")
        
        return archiver.encodedData
    }
    
    private var service: NetService!
    
    // MARK: NetServiceDelegate
    
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        assert(Thread.isMainThread)
        inputStream.close()
        outputStream.open()
        openSocketStreams.append(outputStream)
        sendColor(to: outputStream)
    }
    
    private var openSocketStreams = [OutputStream]()
    
}
