import Foundation
import SwiftUI
import Combine

class DataSpoofer: ObservableObject {
    @Published var rollAngle: Double = 0.0
    @Published var vertU: Double = 0.0
    @Published var isRunning: Bool = false
    
    // Reference to the WebSocketClient to update its data
    weak var webSocketClient: ESP32WebSocketClient?
    
    private var timer: Timer?
    private let updateFrequency: TimeInterval = 1.0 / 50.0 // 50Hz
    
    // For time-based data
    private var startTime: Date?
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        startTime = Date()
        
        // Create a timer that fires 50 times per second
        timer = Timer.scheduledTimer(withTimeInterval: updateFrequency, repeats: true) { [weak self] _ in
            self?.generateData()
        }
        
        // Make sure the timer fires even during scrolling
        RunLoop.current.add(timer!, forMode: .common)
        
        // Clear any existing log messages and add a simulation notification
        webSocketClient?.logMessages = []
        webSocketClient?.logMessages.insert("✅ Simulation started", at: 0)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        // Add a log message about simulation stopping
        webSocketClient?.logMessages.insert("🚫 Simulation stopped", at: 0)
    }
    
    private func generateData() {
        guard let webSocketClient = webSocketClient else { return }
        
        // Create a new data entry with current values
        var dataEntry: [String: String] = [:]
        
        // Add time-based telemetry
        if let startTime = startTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            dataEntry["MS_START"] = "\(Int(elapsedTime * 1000))"
            
            // Set date/time values
            let now = Date()
            let calendar = Calendar.current
            dataEntry["YEAR"] = "\(calendar.component(.year, from: now))"
            dataEntry["MONTH"] = "\(calendar.component(.month, from: now))"
            dataEntry["DAY"] = "\(calendar.component(.day, from: now))"
            dataEntry["HOUR"] = "\(calendar.component(.hour, from: now))"
            dataEntry["MIN"] = "\(calendar.component(.minute, from: now))"
            dataEntry["SEC"] = "\(calendar.component(.second, from: now))"
        }
        
        // Add user-controlled parameters
        dataEntry["ROLL"] = String(format: "%.1f", rollAngle)
        dataEntry["PITCH"] = "2.5" // Default fixed value
        dataEntry["VERT_U"] = String(format: "%.1f", vertU)
        
        // Add other required parameters with default values
        dataEntry["ALT"] = "1500"
        dataEntry["AIRCRAFT"] = "N675CP"
        dataEntry["GND_SPD"] = "120.5"
        dataEntry["LAT"] = "37.12345"
        dataEntry["LONG"] = "-122.54321"
        dataEntry["POS_U"] = "0.4"
        dataEntry["VEL_U"] = "0.3"
        dataEntry["YAW"] = "355.5"
        dataEntry["GND_TRACK"] = "355.2"
        dataEntry["ALT_WGS84"] = "1520"
        dataEntry["PRESS_ALT"] = "1480"
        dataEntry["FLT_PATH"] = "0.0"
        dataEntry["ROC"] = "0"
        
        // Add to the WebSocketClient's receivedMessages array
        DispatchQueue.main.async {
            webSocketClient.receivedMessages.insert(dataEntry, at: 0)
            
            // Limit the size of the array to prevent memory issues
            if webSocketClient.receivedMessages.count > 100 {
                webSocketClient.receivedMessages.removeLast()
            }
        }
    }
}

