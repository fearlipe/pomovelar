import SwiftUI
import AVFoundation

// MARK: - Models and Enums
enum TimerState: String, Codable {
    case work = "Work Time"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    case idle = "Pomodoro Timer"
}

enum SoundType: String, CaseIterable {
    case workStart = "work-start"
    case breakStart = "break-start"
    case timerComplete = "timer-complete"
    
    var filename: String { rawValue }
}

// MARK: - Models
struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: TimerState
    let duration: Int
    let completed: Bool
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    var typeString: String { type.rawValue }
}

// MARK: - Sound Manager
final class SoundManager {
    static let shared = SoundManager()
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    
    private init() {
        for soundType in SoundType.allCases {
            if let soundPath = Bundle.main.path(forResource: soundType.filename, ofType: "wav") {
                let soundUrl = URL(fileURLWithPath: soundPath)
                do {
                    let player = try AVAudioPlayer(contentsOf: soundUrl)
                    player.prepareToPlay()
                    audioPlayers[soundType] = player
                } catch {
                    print("Error loading sound: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func playSound(_ type: SoundType) {
        audioPlayers[type]?.play()
    }
}

@MainActor
final class PomodoroTimer: ObservableObject {
    // MARK: - Default Values
    private static let defaultWorkTime = 25 * 60  // 25 minutes in seconds
    private static let defaultShortBreakTime = 5 * 60  // 5 minutes in seconds
    private static let defaultLongBreakTime = 15 * 60  // 15 minutes in seconds
    
    // MARK: - Published Properties
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var pomodorosCompleted: Int = 0
    @Published private(set) var isActive = false
    @Published var history: [HistoryEntry] = []
    @Published var timeRemaining: Int
    @Published var isSoundEnabled: Bool
    
    // MARK: - UserDefaults Properties
    @AppStorage("workTime") var workTime: Int = PomodoroTimer.defaultWorkTime
    @AppStorage("shortBreakTime") var shortBreakTime: Int = PomodoroTimer.defaultShortBreakTime
    @AppStorage("longBreakTime") var longBreakTime: Int = PomodoroTimer.defaultLongBreakTime
    
    @AppStorage("isSoundEnabled") var storedIsSoundEnabled: Bool = true
    private var timer: Timer?
    private var sessionStartTime: Date?
    
    // MARK: - Initialization
    init() {
        self.timeRemaining = PomodoroTimer.defaultWorkTime
        self.isSoundEnabled = UserDefaults.standard.bool(forKey: "isSoundEnabled")
        self.isSoundEnabled = storedIsSoundEnabled
        loadHistory()
    }
    
    // MARK: - Methods
    func start() {
        if state == .idle {
            state = .work
            if isSoundEnabled {
                SoundManager.shared.playSound(.workStart)
            }
        }
        
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        isActive = false
        timer?.invalidate()
        timer = nil
        
        if let startTime = sessionStartTime {
            addHistoryEntry(startTime: startTime, completed: false)
            sessionStartTime = nil
        }
    }
    
    func reset() {
        if let startTime = sessionStartTime {
            addHistoryEntry(startTime: startTime, completed: false)
        }
        pause()
        state = .idle
        timeRemaining = workTime
        pomodorosCompleted = 0
        sessionStartTime = nil
    }
    
    private func tick() {
        guard timeRemaining > 0 else {
            handleTimerComplete()
            return
        }
        timeRemaining -= 1
    }
    
    private func handleTimerComplete() {
        if isSoundEnabled {
            SoundManager.shared.playSound(.timerComplete)
        }
        
        if let startTime = sessionStartTime {
            addHistoryEntry(startTime: startTime, completed: true)
            sessionStartTime = nil
        }
        
        pause()
        
        switch state {
        case .work:
            pomodorosCompleted += 1
            state = pomodorosCompleted % 4 == 0 ? .longBreak : .shortBreak
            timeRemaining = pomodorosCompleted % 4 == 0 ? longBreakTime : shortBreakTime
            if isSoundEnabled {
                SoundManager.shared.playSound(.breakStart)
            }
        case .shortBreak, .longBreak:
            state = .work
            timeRemaining = workTime
            if isSoundEnabled {
                SoundManager.shared.playSound(.workStart)
            }
        case .idle:
            break
        }
        
        sessionStartTime = Date()
        start()
    }
    
    private func addHistoryEntry(startTime: Date, completed: Bool) {
        let duration = switch state {
        case .work: workTime
        case .shortBreak: shortBreakTime
        case .longBreak: longBreakTime
        case .idle: 0
        }
        
        let entry = HistoryEntry(
            id: UUID(),
            date: startTime,
            type: state,
            duration: duration,
            completed: completed
        )
        history.insert(entry, at: 0)
        saveHistory()
    }
    
    // MARK: - Persistence
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "pomodoroHistory")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "pomodoroHistory"),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            history = decoded
        }
    }
}
// MARK: - Views
struct TimerView: View {
    @ObservedObject var pomodoroTimer: PomodoroTimer
    
    var body: some View {
        VStack(spacing: 20) {
            Text(pomodoroTimer.state.rawValue)
                .font(.title)
                .fontWeight(.bold)
            
            Text(timeString)
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .padding()
            
            HStack(spacing: 20) {
                Button(pomodoroTimer.isActive ? "Pause" : "Start") {
                    if pomodoroTimer.isActive {
                        pomodoroTimer.pause()
                    } else {
                        pomodoroTimer.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 100)
                .font(.title2)
                
                Button("Reset", action: pomodoroTimer.reset)
                    .buttonStyle(.bordered)
                    .frame(width: 100)
                    .font(.title2)
            }
            
            Text("Pomodoros completed: \(pomodoroTimer.pomodorosCompleted)")
                .padding(.top)
            
            Toggle(isOn: $pomodoroTimer.isSoundEnabled) {
                Label("Sound Notifications",
                      systemImage: pomodoroTimer.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .toggleStyle(.switch)
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 300)
    }
    
    private var timeString: String {
        let minutes = pomodoroTimer.timeRemaining / 60
        let seconds = pomodoroTimer.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct HistoryView: View {
    @ObservedObject var pomodoroTimer: PomodoroTimer
    
    var body: some View {
        List(pomodoroTimer.history) { entry in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.typeString)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(entry.formattedDate)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(entry.duration / 60) minutes")
                    Spacer()
                    Image(systemName: entry.completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(entry.completed ? .green : .red)
                }
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("History")
        .frame(minWidth: 250)
    }
}

extension NumberFormatter {
    static let minuteFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

struct TimerSettingView: View {
    let title: String
    @Binding var time: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("minutes", value: Binding(
                get: { time / 60 },  // Convert seconds to minutes
                set: { time = $0 * 60 }  // Convert minutes back to seconds
            ), formatter: NumberFormatter.minuteFormatter)
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.roundedBorder)
            .frame(width: 300)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var pomodoroTimer: PomodoroTimer

    var body: some View {
        Form {
            Section("Timer Durations") {
                TimerSettingView(title: "Work Time", time: $pomodoroTimer.workTime)
                TimerSettingView(title: "Short Break", time: $pomodoroTimer.shortBreakTime)
                TimerSettingView(title: "Long Break", time: $pomodoroTimer.longBreakTime)
            }
        }
        .navigationTitle("Settings")
        .frame(minWidth: 200, maxWidth: .infinity)
    }
}


struct ContentView: View {
    @StateObject private var pomodoroTimer = PomodoroTimer()
    
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("Timer") {
                    TimerView(pomodoroTimer: pomodoroTimer)
                }
                NavigationLink("History") {
                    HistoryView(pomodoroTimer: pomodoroTimer)
                }
                NavigationLink("Settings") {
                    SettingsView(pomodoroTimer: pomodoroTimer)
                }
            }
            .navigationTitle("Pomodoro Timer")
        } detail: {
            TimerView(pomodoroTimer: pomodoroTimer)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
