//
//  SwiftUIView.swift
//  FastSky
//
//  Created by Chris Sheehan on 11/27/23.
//

import SwiftUI

struct HomeView: View {
    @State private var paint = false
    @State private var game = false
    @State private var light = false
    @State private var life = false
    @StateObject private var webSocketManager = WebSocketManager(url: URL(string: "ws://192.168.1.126:8080")!)
    
    var body: some View {
        VStack{
            HStack{
                Button(action: {
                    paint = true
                    
                }) {
                    Image(systemName: "paintbrush.fill") // SF Symbol for undo
                        .foregroundColor(.white)
                        .imageScale(.large)  // Make the symbol larger
                        .font(.system(size: 240))// Set the color of the symbol to white
                }
                
                .padding()
                .frame(width: 300, height: 300)
                .background(Color.black)
                .cornerRadius(8)
                .padding(40)
                
                
                Button(action: {
                    light = true
                }) {
                    Image(systemName: "lightbulb.fill") // SF Symbol for undo
                        .foregroundColor(.white)
                        .imageScale(.large)  // Make the symbol larger
                        .font(.system(size: 180))// Set the color of the symbol to white
                }
                .padding()
                .frame(width: 300, height: 300)
                .background(Color.black)
                .cornerRadius(8)
                .padding(40)
                
            }
            
            HStack{
                Button(action: {
                    life = true
                }) {
                    Image(systemName: "tree.fill") // SF Symbol for undo
                        .foregroundColor(.white)
                        .imageScale(.large)  // Make the symbol larger
                        .font(.system(size: 140))// Set the color of the symbol to white
                }
                .padding()
                .frame(width: 300, height: 300)
                .background(Color.black)
                .cornerRadius(8)
                .padding(40)
                
                Button(action: {
                    game = true
                }) {
                    Image(systemName: "gamecontroller.fill") // SF Symbol for undo
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
        }
        .fullScreenCover(isPresented: $paint) {
            ContentView(webSocketManager: webSocketManager)
            }
        .fullScreenCover(isPresented: $game) {
            GameView(webSocketManager: webSocketManager)
            }
        .fullScreenCover(isPresented: $light) {
            LightView(webSocketManager: webSocketManager)
            }
        .fullScreenCover(isPresented: $life) {
            LightView(webSocketManager: webSocketManager)
            }
        .onAppear {
            webSocketManager.connect()
            }
        }
    }

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
