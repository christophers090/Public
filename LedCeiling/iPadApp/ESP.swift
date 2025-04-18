import SwiftUI

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    @Published var isConnected = false

    init(url: URL) {
        self.url = url
    }

    func connect() {
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
    }

    func sendText(text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }
    
    func send(data: Data) {
            let message = URLSessionWebSocketTask.Message.data(data)
            webSocketTask?.send(message) { error in
                if let error = error {
                    // Handle the error
                    print("WebSocket sending error: \(error)")
                }
            }
        }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
    
    private func startPinging() {
            Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
                self?.sendPing()
            }
        }

    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("Error when sending ping: \(error)")
                self?.isConnected = false
                self?.connect()
            }
        }
    }
    
    func sendLocation2(location: CGPoint) {
        
        if location.x < 1240 && location.x > 0 && location.y < 480 && location.y > 0 {
            
            let X100 = UInt8(Int(location.x / 100))
            let Y100 = UInt8(Int(location.y / 100))
            let X = UInt8(location.x.truncatingRemainder(dividingBy: 100))
            let Y = UInt8(location.y.truncatingRemainder(dividingBy: 100))
            
            var byteArray: [UInt8] = []
            
            byteArray = [X100, X, Y100, Y]
            
            print(byteArray)
            
            let data = Data(byteArray)
            print(data)
            send(data: data)
            
        }
    }
    
    func sendRandomDataTest() {
        let width = 155
        let height = 24
        let channels = 3 // Assuming RGB
        let fileSize = width * height * channels
        var randomData = Data(capacity: fileSize)

        for _ in 0..<fileSize {
            let randomByte = UInt8.random(in: 0...255)
            randomData.append(randomByte)
        }

        // Assuming you have a function `send(data: Data)` to send data over WebSocket
        print(randomData)
        send(data: randomData)
    }
    
    func fill(color: Color){
        
        let uiColor = UIColor(color)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let red = Int(r * a * a * 255)
        let green = Int(g * a * a * 255)
        let blue = Int(b * a * a * 255)
        
        sendText(text: "2,\(red),\(green),\(blue)")
        
    }
    
    func sendColor(color: Color){
        
        let uiColor = UIColor(color)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let red = Int(r * a * a * 255)
        let green = Int(g * a * a * 255)
        let blue = Int(b * a * a * 255)
        
        sendText(text: "5,\(red),\(green),\(blue)")
        
    }
    
    func sendBrush(fade: Double, thickness: Double){
        sendText(text: "6,\(Int(thickness/2)),\(Int(fade/2)),0")
    }

    
}

