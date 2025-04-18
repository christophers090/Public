import Foundation
import SwiftUI

class FlightDataSonifier: ObservableObject {
    // Main control toggles
    @Published var isRollEnabled = false
    @Published var isVertEnabled = false
    
    // Last known values
    @Published var lastRoll: Double = 0.0
    @Published var previousRoll: Double = 0.0
    @Published var lastVertU: Double = 0.0
    @Published var previousVertU: Double = 0.0
    
    // Tone generators
    private var rollToneGenerator: ToneGenerator2?
    private var vertToneGenerator: ToneGenerator2?
    
    // State tracking
    private var isRollToneActive = false
    private var isVertToneActive = false
    private var beeping = false
    
    init() {
        // Create the roll tone generator
        rollToneGenerator = ToneGenerator2()
        rollToneGenerator?.freq = 360.0  // Set frequency to 360 Hz
        rollToneGenerator?.t1 = 99999.0  // Very long ON time (effectively constant)
        rollToneGenerator?.t2 = 0.0      // No OFF time
        rollToneGenerator?.vol = 0.0     // Start with no volume until we get roll data
        
        // Create the vertical velocity tone generator
        vertToneGenerator = ToneGenerator2()
        vertToneGenerator?.t1 = 0.05     // 50ms ON time
        vertToneGenerator?.t2 = 999999.0 // Start with effectively infinite OFF time (silence)
        vertToneGenerator?.vol = 0.5     // Medium volume
    }
    
    func processTelemetryData(_ data: [String: String]) {
        // Process ROLL if available
        if let rollString = data["ROLL"], let roll = Double(rollString) {
            previousRoll = lastRoll
            lastRoll = roll
            
            // Update roll sonification if enabled
            if isRollEnabled {
                updateRollSonification()
            }
        }
        
        // Process VERT_U if available
        if let vertUString = data["PITCH"], let vertU = Double(vertUString) {
            previousVertU = lastVertU
            lastVertU = vertU
            
            // Update vertical velocity sonification if enabled
            if isVertEnabled {
                updateVertUSonification( )
            }
        }
    }
    
    // MARK: - Roll Sonification Methods
    
    func updateRollSonification() {
        guard let toneGenerator = rollToneGenerator else { return }
        
        // Get the absolute roll value
        let absRoll = abs(lastRoll)
        
        // Set volume based on roll angle (up to 20 degrees)
        let volume = min(absRoll / 30.0, 1.0)
        
        if volume >= 0.999 {
            if !beeping {
                toneGenerator.updateParameters(t1:0.05, t2: 0.2)
            }
            beeping = true
        } else if beeping {
            toneGenerator.updateParameters(t1:999999.0, t2: 0.0)
            beeping = false
        }
        
        // Set pan based on roll direction
        // -1.0 = full left (negative roll)
        // 1.0 = full right (positive roll)
        let pan = lastRoll < 0 ? -1.0 : 1.0
        
        // Update the tone generator
        toneGenerator.updateParameters(vol: volume, pan: pan)
        
        // Start the tone if not already playing
        if !isRollToneActive {
            toneGenerator.startTone()
            isRollToneActive = true
        }
    }
    
    func enableRoll() {
        isRollEnabled = true
        updateRollSonification()
    }
    
    func disableRoll() {
        isRollEnabled = false
        rollToneGenerator?.stopTone()
        isRollToneActive = false
        
        // Reset volume to zero
        rollToneGenerator?.updateParameters(vol: 0.0)
    }
    
    // MARK: - Vertical Velocity Sonification Methods
    
    func updateVertUSonification() {
        guard let toneGenerator = vertToneGenerator else { return }
        
        let vertU = lastVertU
        let absVertU = abs(vertU)
        
        // Set frequency based on sign of vertical velocity
        let freq = vertU < 0 ? 300.0 : 600.0
        
        // Determine OFF time based on magnitude of vertical velocity
        let offTime: Double
        
        // Dead zone: if between -0.5 and 0.5, use effectively infinite off time (silence)
        if absVertU < 1 {
            offTime = 999999.0
        }
        // Maximum vertical velocity: if >= 10, use 0 off time (constant beeping)
        else if absVertU >= 5 {
            offTime = 0.0
        }
        // Otherwise scale from 0.5s (at 0.5 vert U) to 0s (at 10 vert U)
        else {
            // Scale offTime linearly from 0.5 to 0.0 as vertU goes from 0.5 to 10.0
            let normalizedValue = (absVertU - 1) / (5 - 1)
            offTime = 1 * (1.0 - normalizedValue)
        }
        
        // Update the tone generator parameters
        toneGenerator.updateParameters(freq: freq, t2: offTime)
        
        // Start or restart the tone if needed
        if !isVertToneActive {
            toneGenerator.startTone()
            isVertToneActive = true
        }
    }
    
    func enableVert() {
        isVertEnabled = true
        updateVertUSonification()
    }
    
    func disableVert() {
        isVertEnabled = false
        vertToneGenerator?.stopTone()
        isVertToneActive = false
    }
}
