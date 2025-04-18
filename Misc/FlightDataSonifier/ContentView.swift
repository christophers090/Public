import SwiftUI

struct ContentView: View {
    @StateObject private var webSocketClient = ESP32WebSocketClient()
    @StateObject private var flightDataSonifier = FlightDataSonifier()
    @StateObject private var dataSpoofer = DataSpoofer()
    @State private var latestPitch: String = "N/A"
    @State private var latestRoll: String = "N/A"
    @State private var latestVertU: String = "N/A"
    @State private var latestMsStart: String = "N/A"
    @State private var showingToneGenerator = false
    @State private var showingDataSpoofer = false
    @State private var isUsingRealData = true
    @State private var count: Int = 0
    
    init() {
        // Set the webSocketClient reference in the dataSpoofer
        _dataSpoofer = StateObject(wrappedValue: {
            let spoofer = DataSpoofer()
            return spoofer
        }())
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                Button(action: {
                    if isUsingRealData {
                        webSocketClient.connect()
                    } else {
                        dataSpoofer.start()
                    }
                }) {
                    Text("Connect")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                Button(action: {
                    if isUsingRealData {
                        webSocketClient.disconnect()
                    } else {
                        dataSpoofer.stop()
                    }
                }) {
                    Text("Disconnect")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            // Data source toggle
            Toggle(isOn: $isUsingRealData) {
                Text(isUsingRealData ? "Using ESP32 Data" : "Using Simulated Data")
                    .font(.headline)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            // Roll Sonification Toggle
            Toggle("Roll Angle Sonification", isOn: $flightDataSonifier.isRollEnabled)
                .padding(.horizontal, 40)
                .padding(.vertical, 5)
                .onChange(of: flightDataSonifier.isRollEnabled) { newValue in
                    if newValue {
                        flightDataSonifier.enableRoll()
                    } else {
                        flightDataSonifier.disableRoll()
                    }
                }
            
            // Vertical Velocity Sonification Toggle
            Toggle("Vertical Velocity Sonification", isOn: $flightDataSonifier.isVertEnabled)
                .padding(.horizontal, 40)
                .padding(.vertical, 5)
                .onChange(of: flightDataSonifier.isVertEnabled) { newValue in
                    if newValue {
                        flightDataSonifier.enableVert()
                    } else {
                        flightDataSonifier.disableVert()
                    }
                }
            
            VStack(spacing: 10) {
                Text("PITCH: \(latestPitch)").font(.title2)
                Text("ROLL: \(latestRoll)").font(.title2)
                Text("VERT_U: \(latestVertU)").font(.title2)
                Text("MS_START: \(latestMsStart)").font(.title2)
            }
            .padding()
            
            SpeedometerView(value: CGFloat(webSocketClient.activeTasksCount))
                .frame(width: 100, height: 100)
                .padding()
            
            // Buttons VStack
            VStack(spacing: 10) {
                // Data Simulator Button
                Button(action: {
                    showingDataSpoofer = true
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Open Data Simulator")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 40)
                
                // Tone Generator Button
                Button(action: {
                    showingToneGenerator = true
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Open Tone Generator")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 10)
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(webSocketClient.logMessages, id: \.self) { logMessage in
                        Text(logMessage)
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }
                .padding()
            }
        }
        .onReceive(webSocketClient.$receivedMessages) { messages in
            if let lastDecodedMessage = messages.first {
                DispatchQueue.main.async {
                    updateDisplayValues(lastDecodedMessage)
                    flightDataSonifier.processTelemetryData(lastDecodedMessage)
                    
//                    count = count + 1
//                    
//                    if count == 100 {
//                        count = 0
//                        flightDataSonifier.processTelemetryData(lastDecodedMessage)
//                    }
                }
            }
        }
        .sheet(isPresented: $showingToneGenerator) {
            ToneControlView2()
        }
        .sheet(isPresented: $showingDataSpoofer) {
            DataSpooferView(dataSpoofer: dataSpoofer)
        }
        .onAppear {
            // Set the webSocketClient reference in the dataSpoofer
            dataSpoofer.webSocketClient = webSocketClient
        }
        .onChange(of: isUsingRealData) { newValue in
            // When switching data sources, stop the current one
            if newValue {
                dataSpoofer.stop()
            } else {
                webSocketClient.disconnect()
            }
        }
    }
    
    // Helper function to update display values
    private func updateDisplayValues(_ data: [String: String]) {
        latestPitch = data["PITCH"] ?? "N/A"
        latestRoll = data["ROLL"] ?? "N/A"
        latestVertU = data["PITCH"] ?? "N/A"
        latestMsStart = data["MS_START"] ?? "N/A"
    }
}
