import Foundation
import UIKit

public class NetworkColorPickerClient: NSObject, NetServiceBrowserDelegate, StreamDelegate {
    
    public var delegate: ((UIColor) -> Void)? {
        didSet {
            delegate?(color)
        }
    }
    
    public func start() {
        serviceBrowser = NetServiceBrowser()
        serviceBrowser.delegate = self
        searchForService()
    }
    
    public func stop() {
        serviceBrowser.stop()
        socketStream?.close()
        socketStream = nil
    }
    
    private func searchForService() {
        serviceBrowser.searchForServices(ofType: "_colorpicker._tcp.", inDomain: "local.")
    }
    
    private var serviceBrowser: NetServiceBrowser!
    
    // MARK: NetServiceBrowserDelegate
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        assert(Thread.isMainThread)
        
        serviceBrowser.stop()
        
        var outputStream: OutputStream?
        service.getInputStream(&self.socketStream, outputStream: &outputStream)
        
        outputStream!.close()
        
        let socketStream = self.socketStream!
        socketStream.delegate = self
        socketStream.schedule(in: .main, forMode: .defaultRunLoopMode)
        socketStream.open()
    }
    
    private var socketStream: InputStream?
    
    // MARK: StreamDelegate
    
    public func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        assert(Thread.isMainThread)
        
        let socketStream = self.socketStream!
        
        if eventCode == .hasBytesAvailable {
            let data = NSMutableData()
            
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate(capacity: bufferSize) }
            
            while socketStream.hasBytesAvailable {
                let readBytes = socketStream.read(buffer, maxLength: bufferSize)
                assert(readBytes >= 0)
                data.append(buffer, length: readBytes)
            }
            
            if data.length > 0 {
                process(data: data as Data)
            }
        } else if eventCode == .endEncountered || eventCode == .errorOccurred {
            socketStream.close()
            self.socketStream = nil
            searchForService()
        }
    }
    
    private func process(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        
        let color = UIColor(
            red: CGFloat(unarchiver.decodeDouble(forKey: "red")),
            green: CGFloat(unarchiver.decodeDouble(forKey: "green")),
            blue: CGFloat(unarchiver.decodeDouble(forKey: "blue")),
            alpha: CGFloat(unarchiver.decodeDouble(forKey: "alpha")))
        
        self.color = color
    }
    
    private var color = UIColor.white {
        didSet {
            delegate?(color)
        }
    }
    
}
