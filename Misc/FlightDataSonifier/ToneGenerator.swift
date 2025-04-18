import Foundation
import AVFoundation

class ToneGenerator2: ObservableObject {
    // Published properties for UI binding
    @Published var t1: Double = 0.5 // Target time for sound ON (seconds)
    @Published var t2: Double = 0.5 // Target time for sound OFF (seconds)
    @Published var freq: Double = 440.0 // Frequency (Hz)
    @Published var vol: Double = 0.5 // Volume (0-1)
    @Published var pan: Double = 0.0 // Pan (-1 to 1, left to right)
    
    // Audio engine components
    private var audioEngine: AVAudioEngine?
    private var oscillatorNode: AVAudioSourceNode?
    private var isPlaying = false
    
    // Time tracking for pulse state
    private var pulseIsOn: Bool = true
    private var lastStateChangeTime: Double = 0
    private var trueT1: Double = 0 // Actual time spent in ON state
    private var trueT2: Double = 0 // Actual time spent in OFF state
    
    // Constants for transition
    private let transitionTime: Double = 0.01 // 10ms transition - fast but not instant
    
    // Sine wave generation
    private var sampleRate: Double = 44100.0
    private var phase: Double = 0.0
    
    init() {
        setupAudioEngine()
    }
    
    deinit {
        stopTone()
        audioEngine?.stop()
        audioEngine = nil
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else { return }
        
        // Get the actual sample rate from the output
        sampleRate = audioEngine.outputNode.outputFormat(forBus: 0).sampleRate
        
        // Create oscillator node for continuous tone generation
        oscillatorNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            // Get the current parameter values
            let frequency = self.freq
            let baseVolume = Float(self.vol)
            let panValue = Float(self.pan)
            let t1Value = self.t1
            let t2Value = self.t2
            
            // Current time for pulse state calculation
            let currentTime = CACurrentMediaTime()
            
            // Update pulse state for this buffer
            self.updatePulseState(currentTime: currentTime, t1: t1Value, t2: t2Value)
            
            // Calculate left and right channel volumes based on pan
            let leftVolume = baseVolume * (1.0 - max(0.0, panValue))
            let rightVolume = baseVolume * (1.0 + min(0.0, panValue))
            
            // Pre-calculate the amplitude envelope for this buffer
            var amplitudeEnvelope = [Float](repeating: 0, count: Int(frameCount))
            
            for i in 0..<Int(frameCount) {
                let frameTime = currentTime + Double(i) / self.sampleRate
                let timeSinceStateChange = frameTime - self.lastStateChangeTime
                
                // Determine amplitude based on state and transition time
                if self.pulseIsOn {
                    if timeSinceStateChange < self.transitionTime {
                        // Rising edge
                        amplitudeEnvelope[i] = Float(timeSinceStateChange / self.transitionTime)
                    } else {
                        // Full on
                        amplitudeEnvelope[i] = 1.0
                    }
                } else {
                    if timeSinceStateChange < self.transitionTime {
                        // Falling edge
                        amplitudeEnvelope[i] = Float(1.0 - timeSinceStateChange / self.transitionTime)
                    } else {
                        // Full off
                        amplitudeEnvelope[i] = 0.0
                    }
                }
            }
            
            // Generate audio samples for each frame using pre-calculated envelope
            for frame in 0..<Int(frameCount) {
                // Calculate sine value for current phase
                let sineValue = sin(self.phase)
                
                // Get amplitude from pre-calculated envelope
                let amplitude = amplitudeEnvelope[frame]
                
                // Apply envelope to sine wave
                let leftSample = Float(sineValue) * amplitude * leftVolume
                let rightSample = Float(sineValue) * amplitude * rightVolume
                
                // Set samples for each channel
                if let leftChannel = ablPointer[0].mData?.assumingMemoryBound(to: Float.self) {
                    leftChannel[frame] = leftSample
                }
                
                if ablPointer.count > 1, let rightChannel = ablPointer[1].mData?.assumingMemoryBound(to: Float.self) {
                    rightChannel[frame] = rightSample
                }
                
                // Increment phase for next sample
                self.phase += 2.0 * .pi * frequency / self.sampleRate
                if self.phase > 2.0 * .pi {
                    self.phase -= 2.0 * .pi
                }
            }
            
            return noErr
        }
        
        // Connect the oscillator to the main mixer
        if let oscillatorNode = oscillatorNode {
            audioEngine.attach(oscillatorNode)
            
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            audioEngine.connect(oscillatorNode, to: audioEngine.mainMixerNode, format: format)
            
            // Prepare the engine
            audioEngine.prepare()
        }
    }
    
    // Update pulse state based on current time and target durations
    private func updatePulseState(currentTime: Double, t1: Double, t2: Double) {
        // Skip if not playing
        guard isPlaying else { return }
        
        // Calculate time since last state change
        let timeSinceStateChange = currentTime - lastStateChangeTime
        
        // Update the appropriate true time counter
        if pulseIsOn {
            trueT1 = timeSinceStateChange
            // Check if we've reached the target ON time
            if trueT1 >= t1 {
                // Switch to OFF state
                pulseIsOn = false
                lastStateChangeTime = currentTime
                trueT2 = 0 // Reset the OFF time counter
            }
        } else {
            trueT2 = timeSinceStateChange
            // Check if we've reached the target OFF time
            if trueT2 >= t2 {
                // Switch to ON state
                pulseIsOn = true
                lastStateChangeTime = currentTime
                trueT1 = 0 // Reset the ON time counter
            }
        }
    }
    
    // MARK: - Public Methods
    
    func startTone() {
        guard !isPlaying, let audioEngine = audioEngine else { return }
        
        // Reset state
        pulseIsOn = true
        lastStateChangeTime = CACurrentMediaTime()
        trueT1 = 0
        trueT2 = 0
        phase = 0.0
        
        // Start the audio engine if it's not running
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
                isPlaying = true
            } catch {
                print("Could not start audio engine: \(error.localizedDescription)")
            }
        } else {
            isPlaying = true
        }
    }
    
    func stopTone() {
        guard isPlaying else { return }
        
        // Mark as not playing
        isPlaying = false
    }
    
    // Update parameters - changes take effect immediately
    func updateParameters(vol: Double? = nil, pan: Double? = nil, freq: Double? = nil, t1: Double? = nil, t2: Double? = nil) {
        // Update any provided parameters
        DispatchQueue.main.async {
            if let vol = vol { self.vol = vol }
            if let pan = pan { self.pan = pan }
            if let freq = freq { self.freq = freq }
            if let t1 = t1 { self.t1 = max(0.02, t1) } // Minimum 20ms for t1
            if let t2 = t2 { self.t2 = max(0.02, t2) } // Minimum 20ms for t2
        }
    }
}
