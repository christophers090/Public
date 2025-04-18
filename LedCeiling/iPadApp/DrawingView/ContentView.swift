//
//  ContentView.swift
//  PaintApp
//
//  Created by Mohammad Azam on 12/7/21.
//

import SwiftUI

struct Line {
    var points = [CGPoint]()
    var color: Color = .red
    var lineWidth: Double = 50.0
    var lineBlur: Double = 50.0
}

struct ContentView: View {
    
    @ObservedObject var webSocketManager: WebSocketManager
    @State private var currentLine = Line()
    @State private var lines: [Line] = []
    @State private var thickness: Double = 50.0
    @State private var fadeFactor: Double = 1.0
    @State private var background: Color = .black
    @State private var fade: Double = 50.0
    @Environment(\.dismiss) var dismiss
    @State var lastSentPoint: CGPoint? = nil
    @State var lastSentTime = Date()
    @State var bpm: Double = 10
    @State var deltaHue: Double = 0
    @State var deltaHue2: Double = 10
    @State var offset: Double = 5
    @State var rainbow: Bool = false
    @State var oldColor: Color = .red
    @State var timer: Bool = false
    
    var body: some View {
        VStack {
           
            Canvas { context, size in
                for line in lines {
                    var path = Path()
                    path.addLines(line.points)
                    
                    // Create a StrokeStyle with rounded line cap and join
                    let strokeStyle = StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round)

                    // Now stroke the path with the specified stroke style
                    context.stroke(path, with: .color(line.color), style: strokeStyle)
                    
                    if line.lineBlur != 0 {
                        var path2 = Path()
                        path.addLines(line.points)
                        
                        // Create a StrokeStyle with rounded line cap and join
                        let strokeStyle = StrokeStyle(lineWidth: line.lineWidth + line.lineBlur, lineCap: .round, lineJoin: .round)

                        // Now stroke the path with the specified stroke style
                        context.stroke(path, with: .color(line.color.opacity(0.5)), style: strokeStyle)
                        
                    }
                    
                }
            }
            .frame(maxWidth: 1240, maxHeight: 480)
            .background(background)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged({ value in
                let newPoint = value.location
                let timeElapsed = -lastSentTime.timeIntervalSinceNow // Time since last sent
                let distance = lastSentPoint.map { CGPointDistance(from: $0, to: newPoint) } ?? .infinity
                if timeElapsed > 0.5 || distance > 1 {
                    webSocketManager.sendLocation2(location: newPoint)
                    lastSentPoint = newPoint
                    lastSentTime = Date()
                }
                currentLine.points.append(newPoint)
                if !self.lines.isEmpty {
                    self.lines[self.lines.count - 1] = currentLine
                } else {
                    self.lines.append(currentLine)
                }
              })
            .onEnded({ value in
                if timer {
                    lines = []
                    self.currentLine = Line(points: [], color: currentLine.color, lineWidth: thickness, lineBlur: fade)
                }
                if !self.lines.isEmpty {
                    self.lines[self.lines.count - 1] = currentLine
                }
                self.currentLine = Line(points: [], color: currentLine.color, lineWidth: thickness, lineBlur: fade)
                self.lines.append(currentLine)
                webSocketManager.sendText(text: "4,0,0,0")
            })
            )
            .padding(20)
            .background(Color.gray)
            .cornerRadius(10)
            
            Spacer()
            
            HStack{
                
                VStack{
                    
                    Slider(value: $thickness, in: 5...150) {
                        Text("Thickness")
                    }.frame(maxWidth: 200)
                        .onChange(of: thickness) { newThickness in
                            currentLine.lineWidth = newThickness
                            webSocketManager.sendBrush(fade: fade, thickness: thickness)
                        }
                        .padding()
                    
                Slider(value: $fade, in: 0...150) {
                    Text("Fade")
                }.frame(maxWidth: 200)
                    .onChange(of: fade) { newFade in
                        currentLine.lineBlur = newFade
                        webSocketManager.sendBrush(fade: fade, thickness: thickness)
                    }
                    .padding()
                    
                    
                }
                
                
                ZStack {
                    // Inner Circle
                    Circle()
                        .strokeBorder(currentLine.color == Color.white ? Color.black : currentLine.color, lineWidth: 2)
                        .background(Circle().fill(currentLine.color))
                        .frame(width: thickness, height: thickness)

                    // Outer Circle
                    Circle()
                        .strokeBorder(currentLine.color == Color.white ? Color.black : currentLine.color.opacity(0.5), lineWidth: 2)
                        .background(Circle().fill(currentLine.color.opacity(0.5)))
                        .frame(width: thickness + fade, height: thickness + fade)
                }

                .frame(width: 300, height: 300)
                
                
                
                
                Spacer()
                
                HStack{
                    
                    
                    Image(systemName: "rainbow") // SF Symbol for undo
                        .foregroundColor(.teal)
                        .imageScale(.large)  // Make the symbol larger
                        .font(.system(size: 80))// Set the color of the symbol to
                        .padding()
                        .frame(width: 150, height: 150)
                        .cornerRadius(8)
                    
                    
                    VStack{
                        
                        HStack{
                            
                            Image(systemName: "gauge.with.needle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            
                            Slider(value: $bpm, in: 5...50) {
                                Text("Thickness")
                            }.frame(maxWidth: 200)
                                .onChange(of: bpm) {
                                    webSocketManager.sendText(text: "8,\(Int(bpm)),\(Int(deltaHue2)),\(Int(offset))")
                                }
                                .padding()
                            
                        }
                        
                        
                        HStack{
                            
                            Image(systemName: "triangle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            
                            Slider(value: $deltaHue, in: 0...3) {
                                Text("Fade")
                            }.frame(maxWidth: 200)
                                .onChange(of: deltaHue) { newHue in
                                    deltaHue2 = newHue * newHue * 5
                                    webSocketManager.sendText(text: "8,\(Int(bpm)),\(Int(deltaHue2)),\(Int(offset))")
                                }
                                .padding()
                            
                        }
                        
                        
                        HStack{
                            
                            Image(systemName: "arrow.backward")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            
                            Slider(value: $offset, in: 0...50) {
                                Text("Fade")
                            }.frame(maxWidth: 200)
                                .onChange(of: offset) {
                                    webSocketManager.sendText(text: "8,\(Int(bpm)),\(Int(deltaHue2)),\(Int(offset))")
                                }
                                .padding()
                        }
                        
                        
                    }
                    .padding()
                }
                
            }
            
            HStack {
                
                HStack{
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "x.circle") // SF Symbol for undo
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 24))// Set the color of the symbol to white
                    }
                    .padding()
                    .frame(width: 55, height: 55)
                    .background(Color.black)
                    .cornerRadius(8)
                    
                    
                    Button(action: {
                        webSocketManager.connect()
                    }) {
                        Image(systemName: "wifi") // SF Symbol for undo
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 24))// Set the color of the symbol to white
                    }
                    .padding()
                    .frame(width: 55, height: 55)
                    .background(Color.black)
                    .cornerRadius(8)

                    
                }
                
                Spacer()
                
                HStack{
                    
                    ColorPicker("", selection: $currentLine.color)
                        .onChange(of: currentLine.color){ newColor in
                            currentLine.color = newColor
                            webSocketManager.sendColor(color: newColor)
                        }
                        .padding()
                        .frame(maxWidth: 100)
                    
                    
                    Button(action: {
                        rainbow = false
                        currentLine.color = oldColor
                        webSocketManager.sendText(text: "9,1,0,0")
                    }) {
                        Image(systemName: "pencil.and.scribble") // SF Symbol for undo
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 24))// Set the color of the symbol to
                        
                    }
                    .padding()
                    .frame(width: 55, height: 55)
                    .background(!rainbow ? Color.green.opacity(0.8) : Color.black)
                    .cornerRadius(8)
                    
                    
                    Button(action: {
                        rainbow = true
                        oldColor = currentLine.color
                        currentLine.color = .white
                        webSocketManager.sendText(text: "9,2,0,0")
                    }) {
                        Image(systemName: "rainbow") // SF Symbol for undo
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 24))// Set the color of the symbol to
                        
                    }
                    .padding()
                    .frame(width: 55, height: 55)
                    .background(rainbow ? Color.green.opacity(0.8) : Color.black)
                    .cornerRadius(8)
                    
                    
                    Button(action: {
                        fade = 0
                        thickness = 50
                        currentLine.color = .black
                        webSocketManager.sendBrush(fade: fade, thickness: thickness)
                        webSocketManager.sendColor(color: .black)
                        webSocketManager.sendText(text: "9,1,0,0")
                        rainbow = false
                        
                    }) {
                        Image(systemName: "eraser.fill") // SF Symbol for undo
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 24))// Set the color of the symbol to white
                    }
                    .padding()
                    .frame(width: 55, height: 55)
                    .background(Color.black)
                    .cornerRadius(8)  // Make the button round
                    
                    
                    Button(action: {
                        background = currentLine.color
                        lines = []
                        if rainbow {
                        webSocketManager.sendText(text: "9,3,0,0")
                        } else {
                            webSocketManager.fill(color: currentLine.color)
                        }
                    }) {
                        Image(systemName: "drop.fill") // SF Symbol for undo
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 24))// Set the color of the symbol to white
                    }
                    .padding()
                    .frame(width: 55, height: 55)
                    .background(Color.black)
                    .cornerRadius(8)
                    
                    
                    
                    Button(action: {
                        background = .black
                        lines = []
                        webSocketManager.sendText(text: "1,0,0,0")
                    }) {
                        Image(systemName: "trash") // SF Symbol for undo
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 24))// Set the color of the symbol to
                        
                    }
                    .padding()
                    .frame(width: 55, height: 55)
                    .background(Color.black)
                    .cornerRadius(8)
                    
                    
                }
                
                Spacer()
                
                HStack{
                    Button(action: {
                        timer.toggle()
                        if timer {
                            webSocketManager.sendText(text: "10,1,0,0")
                        } else {
                            webSocketManager.sendText(text: "10,0,0,0")
                        }
                        
                        lines = []
                    }) {
                        Image(systemName: "timer.circle.fill") // SF Symbol for undo
                            .foregroundColor(.white)
                            .imageScale(.large)  // Make the symbol larger
                            .font(.system(size: 24))// Set the color of the symbol to
                        
                    }
                    .padding()
                    .frame(width: 55, height: 55)
                    .background(timer ? Color.green.opacity(0.8) : Color.black)
                    .cornerRadius(8)
                    
                    Slider(value: $fadeFactor, in: 1...50) {
                        Text("Fade")
                    }.frame(maxWidth: 200)
                        .onChange(of: fadeFactor) { newFadeFactor in
                            fadeFactor = newFadeFactor
                            webSocketManager.sendText(text: "11,\(Int(fadeFactor)),0,0")
                        }
                        .padding()
                    
                }
            
        
                        
                
            }
            .padding(20)
            .background(Color.gray)
            .cornerRadius(10)
        
            
        }.padding()
        .onAppear {
            webSocketManager.sendText(text: "14,0,0,0")
            webSocketManager.sendText(text: "15,0,0,0")
            webSocketManager.sendBrush(fade: fade, thickness: thickness)
            webSocketManager.sendText(text: "11,\(Int(fadeFactor)),0,0")
            webSocketManager.sendText(text: "1,0,0,0")
            webSocketManager.sendText(text: "9,1,0,0")
            webSocketManager.sendText(text: "10,0,0,0")
            webSocketManager.sendText(text: "10,0,0,0")
            webSocketManager.sendColor(color: currentLine.color)
            
            }
    }
    
    
    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = from.x - to.x
        let dy = from.y - to.y
        return sqrt(dx * dx + dy * dy)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(webSocketManager: WebSocketManager(url: URL(string: "ws://example.com")!))
    }
}
