import SwiftUI

struct TimerView: View {
    @ObservedObject var busylight: BusylightManager
    @Environment(\.dismiss) var dismiss
    
    @State private var minutes = 25
    @State private var secondsLeft = 1500
    @State private var running = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 25) {
            Text("⏱️ POMODORO")
                .font(.largeTitle)
                .bold()
            
            Picker("Time", selection: $minutes) {
                Text("15 min").tag(15)
                Text("25 min").tag(25)
                Text("45 min").tag(45)
            }
            .pickerStyle(.segmented)
            .disabled(running)
            .frame(width: 250)
            
            Text(timeString)
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundColor(running ? .green : .primary)
            
            HStack(spacing: 15) {
                Button(running ? "⏸ Pause" : "▶ Start") {
                    running ? pause() : start()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("⏹ Stop") {
                    stop()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("✕ Close") {
                    stop()
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(30)
        .frame(width: 400, height: 300)
    }
    
    var timeString: String {
        String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }
    
    func start() {
        running = true
        secondsLeft = minutes * 60
        busylight.green()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                finish()
            }
        }
    }
    
    func pause() {
        running = false
        timer?.invalidate()
        busylight.off()
    }
    
    func stop() {
        running = false
        timer?.invalidate()
        secondsLeft = minutes * 60
        busylight.off()
    }
    
    func finish() {
        stop()
        busylight.alert()
    }
}
