import AVFoundation
import Combine

@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    

    @Published var isPlaying = false
    @Published var currentTrack: String?
    @Published var volume: Double = 0.5 {  // ← Aquí sí va
            didSet {
                player?.volume = Float(volume)
            }
        }

    let tracks = ["Distant", "Forest", "White Noise", "Focus", "Sleep"]

    func play(_ name: String) {
        let filename = name.replacingOccurrences(of: " ", with: "_")

        guard let url = Bundle.main.url(forResource: filename, withExtension: "aac") else {
            BusylightLogger.shared.info("❌ Audio file not found: \(filename).aac")
            return
        }

        BusylightLogger.shared.info("✅ Audio file found: \(url.lastPathComponent)")

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = Float(volume)  // ← Aplica volumen al iniciar
            player?.play()
            currentTrack = name  // ← Guardas el nombre original, no el filename
            isPlaying = true
            BusylightLogger.shared.info("🔊 Playing: \(name)")
        } catch {
            BusylightLogger.shared.info("❌ Audio play error: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        isPlaying = false
        currentTrack = nil
    }
}
