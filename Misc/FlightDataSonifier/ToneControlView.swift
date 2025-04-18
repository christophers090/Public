import SwiftUI

struct ToneControlView2: View {
    @StateObject private var toneGenerator = ToneGenerator2()
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tone Generator")
                .font(.title)
                .padding(.top)
                
            // Frequency Slider
            VStack(alignment: .leading) {
                Text("Frequency: \(Int(toneGenerator.freq)) Hz")
                Slider(value: $toneGenerator.freq, in: 300...800, step: 1)
            }
            .padding(.horizontal)
            
            // Volume Slider
            VStack(alignment: .leading) {
                Text("Volume: \(Int(toneGenerator.vol * 100))%")
                Slider(value: $toneGenerator.vol, in: 0...1, step: 0.01)
            }
            .padding(.horizontal)
            
            // t1 Slider (Modulation Rate)
            VStack(alignment: .leading) {
                Text("Modulation Rate (t1): \(String(format: "%.2f", toneGenerator.t1)) sec")
                Slider(value: $toneGenerator.t1, in: 0...0.5, step: 0.01)
            }
            .padding(.horizontal)
            
            // t2 Slider (Modulation Depth)
            VStack(alignment: .leading) {
                Text("Modulation Depth (t2): \(String(format: "%.2f", toneGenerator.t2))")
                Slider(value: $toneGenerator.t2, in: 0...0.5, step: 0.01)
            }
            .padding(.horizontal)
            
            // Pan Slider
            VStack(alignment: .leading) {
                Text("Pan: \(String(format: "%.1f", toneGenerator.pan))")
                    .padding(.bottom, 4)
                HStack {
                    Text("Left")
                    Slider(value: $toneGenerator.pan, in: -1...1, step: 0.1)
                    Text("Right")
                }
            }
            .padding(.horizontal)
            
            // Play/Stop Button
            Button(action: {
                if isPlaying {
                    toneGenerator.stopTone()
                } else {
                    toneGenerator.startTone()
                }
                isPlaying.toggle()
            }) {
                Text(isPlaying ? "Stop Tone" : "Play Tone")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 200)
                    .background(isPlaying ? Color.red : Color.green)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .onDisappear {
            toneGenerator.stopTone()
            isPlaying = false
        }
    }
}

#Preview {
    ToneControlView2()
}
