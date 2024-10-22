import SwiftUI

enum TimerState {
    case work
    case shortBreak
    case longBreak
    case idle
}

struct HistoryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let type: TimerState
    let duration: Int
    let completed: Bool
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var typeString: String {
        switch type {
        case .work:
            return "Work"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        case .idle:
            return "Idle"
        }
    }
}

class PomodoroTimer: ObservableObject {
    @Published var timeRemaining: Int
    @Published var state: TimerState = .idle
    @Published var pomodorosCompleted: Int = 0
    @Published var isActive = false
    @Published var history: [HistoryEntry] = []
    
    private var timer: Timer?
    private var sessionStartTime: Date?
    
    let workTime = 25 * 60  // 25 minutes
    let shortBreakTime = 5 * 60  // 5 minutes
    let longBreakTime = 15 * 60  // 15 minutes
    
    init() {
        self.timeRemaining = workTime
    }
    
    func start() {
        if state == .idle {
            state = .work
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
        if let startTime = sessionStartTime {
            addHistoryEntry(startTime: startTime, completed: true)
            sessionStartTime = nil
        }
        
        pause()
        
        switch state {
        case .work:
            pomodorosCompleted += 1
            if pomodorosCompleted % 4 == 0 {
                state = .longBreak
                timeRemaining = longBreakTime
            } else {
                state = .shortBreak
                timeRemaining = shortBreakTime
            }
        case .shortBreak, .longBreak:
            state = .work
            timeRemaining = workTime
        case .idle:
            break
        }
        
        sessionStartTime = Date()
        start()
    }
    
    private func addHistoryEntry(startTime: Date, completed: Bool) {
        let duration: Int
        switch state {
        case .work:
            duration = workTime
        case .shortBreak:
            duration = shortBreakTime
        case .longBreak:
            duration = longBreakTime
        case .idle:
            duration = 0
        }
        
        let entry = HistoryEntry(
            date: startTime,
            type: state,
            duration: duration,
            completed: completed
        )
        history.insert(entry, at: 0)
    }
}

struct TimerView: View {
    @ObservedObject var pomodoroTimer: PomodoroTimer
    
    var body: some View {
        VStack(spacing: 20) {
            Text(stateTitle)
                .font(.title)
                .fontWeight(.bold)
            
            Text(timeString)
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .padding()
            
            HStack(spacing: 20) {
                Button(action: {
                    if pomodoroTimer.isActive {
                        pomodoroTimer.pause()
                    } else {
                        pomodoroTimer.start()
                    }
                }) {
                    Text(pomodoroTimer.isActive ? "Pause" : "Start")
                        .font(.title2)
                        .frame(width: 100)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset") {
                    pomodoroTimer.reset()
                }
                .font(.title2)
                .frame(width: 100)
                .buttonStyle(.bordered)
            }
            
            Text("Pomodoros completed: \(pomodoroTimer.pomodorosCompleted)")
                .padding(.top)
        }
        .padding()
        .frame(minWidth: 300)
        .navigationTitle("PomoTimer")
    }
    
    private var timeString: String {
        let minutes = pomodoroTimer.timeRemaining / 60
        let seconds = pomodoroTimer.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var stateTitle: String {
        switch pomodoroTimer.state {
        case .work:
            return "Work Time"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        case .idle:
            return "PomoTimer"
        }
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
                    if entry.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("History")
        .frame(minWidth: 250)
    }
}

struct ContentView: View {
    @StateObject private var pomodoroTimer = PomodoroTimer()
    
    var body: some View {
        NavigationSplitView {
            HistoryView(pomodoroTimer: pomodoroTimer)
        } detail: {
            TimerView(pomodoroTimer: pomodoroTimer)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
