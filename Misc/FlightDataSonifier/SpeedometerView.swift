import SwiftUI

struct SpeedometerView: View {
    var value: CGFloat // The current task count (value to represent)
    let maxValue: CGFloat = 10 // Max value for the task count
    let minValue: CGFloat = 0    // Min value (can adjust based on need)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background circle (the full gauge arc)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                
                // Foreground arc (task count)
                Circle()
                    .trim(from: 0, to: normalizedValue())
                    .stroke(Color.red, lineWidth: 20)
                    .rotationEffect(.degrees(-90)) // Rotate to start from the bottom
                
                // Center circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                
                // Task count text
                Text("\(Int(value)) tasks")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // Calculate normalized value (range between 0 and 1)
    private func normalizedValue() -> CGFloat {
        return min(max((value - minValue) / (maxValue - minValue), 0), 1)
    }
}
