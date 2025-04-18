import SwiftUI

struct DataSpooferView: View {
    @ObservedObject var dataSpoofer: DataSpoofer
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Data Simulator")
                .font(.title)
                .padding(.top)
            
            // Roll Angle Slider
            VStack(alignment: .leading) {
                Text("Roll Angle: \(String(format: "%.1f°", dataSpoofer.rollAngle))")
                HStack {
                    Text("-45°")
                    Slider(value: $dataSpoofer.rollAngle, in: -45...45, step: 0.5)
                    Text("45°")
                }
                
                // Button to reset roll to zero
                Button("Reset Roll") {
                    dataSpoofer.rollAngle = 0
                }
                .font(.caption)
                .padding(.top, 4)
            }
            .padding(.horizontal)
            
            // Vertical Speed Slider
            VStack(alignment: .leading) {
                Text("Vertical Speed: \(String(format: "%.1f", dataSpoofer.vertU))")
                HStack {
                    Text("-10")
                    Slider(value: $dataSpoofer.vertU, in: -10...10, step: 0.1)
                    Text("10")
                }
                
                // Button to reset vertical speed to zero
                Button("Reset Vertical Speed") {
                    dataSpoofer.vertU = 0
                }
                .font(.caption)
                .padding(.top, 4)
            }
            .padding(.horizontal)
            
            // Simulator Controls
            Button(dataSpoofer.isRunning ? "Stop Simulator" : "Start Simulator") {
                if dataSpoofer.isRunning {
                    dataSpoofer.stop()
                } else {
                    dataSpoofer.start()
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(dataSpoofer.isRunning ? Color.red : Color.green)
            .cornerRadius(10)
            .padding(.top, 10)
            
            // Data Display
            VStack(alignment: .leading) {
                Text("Latest Simulated Data:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                if let webSocketClient = dataSpoofer.webSocketClient,
                   let latestData = webSocketClient.receivedMessages.first {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(latestData.keys.sorted().prefix(8)), id: \.self) { key in
                                if let value = latestData[key] {
                                    Text("\(key): \(value)")
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(height: 150)
                } else {
                    Text("No data yet. Start the simulator.")
                        .italic()
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}
