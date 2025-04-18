//
//  LightView.swift
//  FastSky
//
//  Created by Chris Sheehan on 11/27/23.
//

import SwiftUI

struct LightView: View {
    
    @ObservedObject var webSocketManager: WebSocketManager
    @State private var colorTemperature: CGFloat = 0.5 // 0.0 = warm, 1.0 = cool
    @State private var brightness: CGFloat = 0.5 // 0.0 = dim, 1.0 = bright
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            // Light representation
            Circle()
                .fill(calculateColor())
                .padding()
                .background(.black)
                .cornerRadius(8)
                .frame(width: 500, height: 500)

            // Color temperature slider
            VStack {
                
                HStack {
                    Text("Warm")
                    Slider(value: $colorTemperature, in: -0.4...0.4)
                        .onChange(of: colorTemperature) {
                            
                        }
                    Text("Cool")
                }.padding()
                
                // Brightness slider
                HStack {
                    Text("Dim")
                    Slider(value: $brightness)
                        .onChange(of: brightness) {
                            
                        }
                    Text("Bright")
                }.padding()
            }
            .frame(maxWidth: 500)
            
            Spacer()
            
            
            HStack{
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "x.circle") // SF Symbol for undo
                        .foregroundColor(.white)
                        .imageScale(.large)  // Make the symbol larger
                        .font(.system(size: 24))// Set the color of the symbol to white
                }
                .frame(width: 55, height: 55)
                .background(Color.black)
                .cornerRadius(8)
                .padding(30)
                
                
                Spacer()
                
                Button(action: {
                    webSocketManager.sendText(text: "9989,0,0,0")
                    
                }) {
                    Image(systemName: "wifi") // SF Symbol for undo
                        .foregroundColor(.white)
                        .imageScale(.large)  // Make the symbol larger
                        .font(.system(size: 24))// Set the color of the symbol to white
                }
                .frame(width: 55, height: 55)
                .background(Color.black)
                .cornerRadius(8)
                .padding(30)
            }
        }
    }

    private func calculateColor() -> Color {
        // Define the hue values for warm, neutral, and cool colors
        let warmHue: CGFloat = 0.08 // Orange hue
        let coolHue: CGFloat = 0.58 // Light blue hue
        var hue: CGFloat = 0
        var sat: CGFloat = 0
        
        if colorTemperature > 0 {
            hue = coolHue
            sat = colorTemperature
        } else {
            hue = warmHue
            sat = abs(colorTemperature)
        }
        
        let color = Color(hue: hue, saturation: sat, brightness: brightness, opacity: Double(brightness))
        
        webSocketManager.fill(color: color)
        
        return color
    }

}

struct LightControlView_Previews: PreviewProvider {
    static var previews: some View {
        LightView(webSocketManager: WebSocketManager(url: URL(string: "ws://example.com")!))
    }
}
