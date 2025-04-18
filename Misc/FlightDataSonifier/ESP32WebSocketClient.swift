import Foundation
//import FirebaseDatabase

class ESP32WebSocketClient: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    @Published var receivedMessages: [[String : String]] = []
    @Published var logMessages: [String] = []
    @Published var activeTasksCount: Int = 0
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private let serverURL = URL(string: "ws://192.168.23.3:8080")! // Replace with your ESP32 IP
    private var reconnectTimer: Timer?
    
    
    func connect() {
        // Bring Firebase back online
//        Database.database().goOnline()
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: serverURL)
        webSocketTask?.resume()
        logMessages = []
        if webSocketTask?.state == .running {
            logMessages.insert("✅ WebSocket connected", at: 0)
        } else {
            logMessages.insert("❌ WebSocket is not active.", at: 0)
        }
        print("Connecting to WebSocket...")
        isConnected = true
        listenForMessages()
    }
    
    private func reconnect() {
        guard !isConnected else { return }
        logMessages.insert("🔄 Attempting to reconnect...", at: 0)
        print("🔄 Attempting to reconnect...")
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    func disconnect() {
        logMessages.insert("🚫 Disconnecting WebSocket & Firebase...", at: 0)
        print("🚫 Disconnecting WebSocket & Firebase...")
        
        // Disconnect from Firebase Realtime Database
//        Database.database().goOffline()
        
        // Disconnect from WebSocket
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        // Invalidate the reconnect timer if it's active
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        // Clear received messages
        receivedMessages.removeAll()
    }
    
    private func listenForMessages() {
        guard let task = webSocketTask else { return }
        
        task.receive { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data):
                        self?.processBinaryMessage(data)
                    case .string(let text):
                        print("📩 Received Text Message: \(text)")
                    @unknown default:
                        print("⚠️ Unknown WebSocket message type received")
                    }
                    self?.listenForMessages() // Keep listening for new messages
                    
                case .failure(let error):
                    self?.logMessages.insert("❌ WebSocket receive error: \(error.localizedDescription)", at: 0)
                    print("❌ WebSocket receive error: \(error.localizedDescription)")
                    self?.reconnect()
                }
            }
        }
    }
    
    private var messageCounter = 0
    
    private func processBinaryMessage(_ data: Data) {
        guard data.count >= 67 else {
            logMessages.insert("⚠️ Invalid data length: \(data.count)", at: 0)
            print("⚠️ Invalid data length: \(data.count)")
            return
        }
        
        let decodedMessage = decodeMessage(data: data)
        DispatchQueue.main.async {
            self.receivedMessages.insert(decodedMessage, at: 0)
        }
        
//        sendToFirebase(decodedMessage: decodedMessage)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {}
    }
    
    var activeTasks: [DispatchWorkItem] = []
    
//    private func sendToFirebase(decodedMessage: [String:String]) {
//        // Reference to the Firebase Realtime Database
//        let ref = Database.database().reference().child("telemetry").child("N675CP")
//        
//        // Increment active task count
//        DispatchQueue.main.async {
//            self.activeTasksCount += 1
//        }
//        
//        // Create a work item for this task
//        let sendWorkItem = DispatchWorkItem {
//            ref.updateChildValues(decodedMessage) { error, _ in
//                if let error = error {
//                    self.logMessages.insert("❌ Error sending data to Firebase: \(error.localizedDescription)", at: 0)
//                    print("❌ Error sending data to Firebase: \(error.localizedDescription)")
//                } else {
//                    DispatchQueue.main.async {
//                        self.activeTasksCount = max(self.activeTasksCount - 1 , 0)
//                    }
//                }
//            }
//        }
//        
//        // Add the work item to the list of active tasks
//        DispatchQueue.global(qos: .background).async {
//            self.activeTasks.append(sendWorkItem)  // Track the work item
//            DispatchQueue.global(qos: .background).async(execute: sendWorkItem)
//            
//            // Check if the active task count exceeds 10
//            if self.activeTasksCount > 10 {
//                self.cancelOldestTask()
//            }
//        }
//    }
    
    private func cancelAllTasks() {
        guard !activeTasks.isEmpty else { return } // Ensure there are tasks to cancel
        
        // Cancel and remove each task from the list
        for task in activeTasks {
            task.cancel()
        }
        
        // Clear the list and reset task count
        activeTasks.removeAll()
        DispatchQueue.main.async {
            self.activeTasksCount = 0  // Reset the active task count
        }
    }
    
    private func cancelOldestTask() {
        guard !activeTasks.isEmpty else { return } // Ensure there are tasks to cancel
        
        print("Cancelling the oldest task.")

        // Cancel and remove the first (oldest) task
        activeTasks.first?.cancel()
        activeTasks.removeFirst()

        // Update the task count
        DispatchQueue.main.async {
            self.activeTasksCount -= 1  // Decrease the active task count
        }
    }
    
    func decodeMessage(data: Data) -> [String: String] {
        var result: [String: String] = [:]
        
        result["AIRCRAFT"] = "N675CP"
        result["VER"] = "\(data[0])"
        result["STATUS"] = "\(Array(data[1...2]))"
        result["CPU_TEMP"] = "\(Int8(bitPattern: data[3]))"
        result["IMU_TEMP"] = "\(Int8(bitPattern: data[4]))"
        result["MAG_TEMP"] = "\(Int8(bitPattern: data[5]))"
        result["PRES_TEMP"] = "\(Int8(bitPattern: data[6]))"
        result["POS_U"] = "\(Float(data[7]) / 10.0)"
        result["VERT_U"] = "\(Float(data[8]) / 10.0)"
        result["VEL_U"] = "\(Float(data[9]) / 10.0)"
        result["GNSS1SAT"] = "\(data[10])"
        result["YEAR"] = "\(Int(data[11]) + 1970)"
        result["MONTH"] = "\(data[12])"
        result["DAY"] = "\(data[13])"
        result["HOUR"] = "\(data[14])"
        result["MIN"] = "\(data[15])"
        result["SEC"] = "\(data[16])"
        result["PITCH"] = "\(Double((Int16(bitPattern: UInt16(data[17]) | (UInt16(data[18]) << 8)))) / 100.0)"
        result["ROLL"] = "\(Double((Int16(bitPattern: UInt16(data[19]) | (UInt16(data[20]) << 8)))) / 100.0)"
        result["MAG_VAR"] = "\(Double((Int16(bitPattern: UInt16(data[21]) | (UInt16(data[22]) << 8)))) / 100.0)"
        result["YAW"] = "\(Double((UInt16(data[23]) | (UInt16(data[24]) << 8))) / 100.0)"
        result["GND_SPD"] = "\(Double((UInt16(data[25]) | (UInt16(data[26]) << 8))) / 100.0)"
        result["GND_TRACK"] = "\(Double((UInt16(data[27]) | (UInt16(data[28]) << 8))) / 100.0)"
        result["FLT_PATH"] = "\(Double((Int16(bitPattern: UInt16(data[29]) | (UInt16(data[30]) << 8)))) / 100.0)"
        result["ROC"] = "\(Double((Int16(bitPattern: UInt16(data[31]) | (UInt16(data[32]) << 8)))))"
        result["LOAD_FACTOR"] = "\(Double((Int16(bitPattern: UInt16(data[33]) | (UInt16(data[34]) << 8)))) / 1000.0)"
        result["GY"] = "\(Double((Int16(bitPattern: UInt16(data[35]) | (UInt16(data[36]) << 8)))) / 10.0)"
        result["GX"] = "\(Double((Int16(bitPattern: UInt16(data[37]) | (UInt16(data[38]) << 8)))) / 10.0)"
        result["GZ"] = "\(Double((Int16(bitPattern: UInt16(data[39]) | (UInt16(data[40]) << 8)))) / 10.0)"
        result["AX"] = "\(Double((Int16(bitPattern: UInt16(data[41]) | (UInt16(data[42]) << 8)))) / 1000.0)"
        result["AY"] = "\(Double((Int16(bitPattern: UInt16(data[43]) | (UInt16(data[44]) << 8)))) / 1000.0)"
        result["AZ"] = "\(Double((Int16(bitPattern: UInt16(data[45]) | (UInt16(data[46]) << 8)))) / 1000.0)"
        result["ALT_WGS84"] = "\(Double((UInt16(data[47]) | (UInt16(data[48]) << 8))) - 10000)"
        result["ALT"] = "\(Double((UInt16(data[49]) | (UInt16(data[50]) << 8))) - 10000)"
        result["PRESS_ALT"] = "\(Double((UInt16(data[51]) | (UInt16(data[52]) << 8))) - 10000)"
        result["PRESS"] = "\(Double((UInt16(data[53]) | (UInt16(data[54]) << 8))) * 2)"
        result["LAT"] = "\(Double((Int32(bitPattern: UInt32(data[55]) | (UInt32(data[56]) << 8) | (UInt32(data[57]) << 16) | (UInt32(data[58]) << 24)))) * 1e-7)"
        result["LONG"] = "\(Double((Int32(bitPattern: UInt32(data[59]) | (UInt32(data[60]) << 8) | (UInt32(data[61]) << 16) | (UInt32(data[62]) << 24)))) * 1e-7)"
        result["MS_START"] = "\(UInt32(data[63]) | (UInt32(data[64]) << 8) | (UInt32(data[65]) << 16) | (UInt32(data[66]) << 24))"
        
        return result
    }
}
