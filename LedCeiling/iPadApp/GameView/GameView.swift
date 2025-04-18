//
//  GameView.swift
//  FastSky
//
//  Created by Chris Sheehan on 11/29/23.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var webSocketManager: WebSocketManager
    @State private var animation: Int = 0
    @State private var frameNumbers: [Int] = [1410, 449, 911, 6187, 12700, 12700, 750]
    @State private var brightness: CGFloat = 3
    @State private var espBrightness: CGFloat = 9
    @Environment(\.dismiss) var dismiss
    @State private var play: Bool = false
    
    var body: some View {
        
        VStack {
            
            Spacer()
            
            HStack {
                
                Button(action: {
                    
                    if play {
                        webSocketManager.sendText(text: "15,0,0,0")
                        play = false
                    } else {
                        webSocketManager.sendText(text: "15,1,0,0")
                        play = true
                    }
                   
                    
                }) {
                    
                    if play {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 140))
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 140))
                    }
                        
                }
                .padding()
                .frame(width: 300, height: 300)
                .background(Color.black)
                .cornerRadius(8)
                .padding(40)
                
                Button(action: {
                    animation += 1
                    
                    if animation == 7 {
                        animation = 0
                    }
                    
                    webSocketManager.sendText(text: "13,\(animation),\(frameNumbers[animation]),0")
                    
                }) {
                    
                    Image(systemName: "arrow.right") // SF Symbol for undo
                        .foregroundColor(.white)
                        .imageScale(.large)  // Make the symbol larger
                        .font(.system(size: 140))// Set the color of the symbol to white
                }
                .padding()
                .frame(width: 300, height: 300)
                .background(Color.black)
                .cornerRadius(8)
                .padding(40)
                
            }
            
            
            
            HStack {
                Text("Dim")
                Slider(value: $brightness, in: 1...5)
                    .onChange(of: brightness) {
                        espBrightness = brightness * brightness * brightness
                        webSocketManager.sendText(text: "12,\((Int(espBrightness))),0,0")
                    }
                Text("Bright")
            }.padding()
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
            }
            
        }
        .onAppear{
            webSocketManager.sendText(text: "14,1,0,0")
            webSocketManager.sendText(text: "12,\((Int(espBrightness))),0,0")
        }
           
        
        
        
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(webSocketManager: WebSocketManager(url: URL(string: "ws://example.com")!))
    }
}

