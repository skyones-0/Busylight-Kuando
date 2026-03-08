//
//  SmartFeaturesManager.swift
//  Busylight
//
//  Super App - 15 Productivity Features
//

import Foundation
import SwiftUI
import EventKit
import Combine
import AVFoundation
import SwiftData
import UserNotifications

// MARK: - Smart Features Manager (Singleton)
class SmartFeaturesManager: ObservableObject {
    static let shared = SmartFeaturesManager()
    
    // MARK: - Published States
    @Published var calendarStatus: CalendarStatus = .none
    @Published var calendarAccessGranted = false
    @Published var selectedCalendarIdentifier: String = ""
    @Published var availableCalendars: [EKCalendar] = []
    @Published var focusMode: FocusMode = .none
    @Published var isIdle: Bool = false
    @Published var isInMeeting: Bool = false
    @Published var isPresenting: Bool = false
    @Published var currentWorkProfile: WorkProfile = .standard
    @Published var isDeepWorkActive: Bool = false
    @Published var visualBreakTimer: Int = 0
    @Published var isVisualBreakActive: Bool = false
    @Published var dashboardData: ProductivityDashboard = ProductivityDashboard()
    @Published var currentTheme: LightTheme = .minimal
    @Published var isWithinWorkHours: Bool = true
    @Published var smartBreakStatus: SmartBreakStatus = .waiting
    @Published var deepWorkRemainingMinutes: Int = 0
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var idleTimer: Timer?
    private var visualBreakTimerObj: Timer?
    private var workHoursTimer: Timer?
    private var meetingCheckTimer: Timer?
    private var lastActivityTime: Date = Date()
    private var eventStore = EKEventStore()
    private var captureSession: AVCaptureSession?
    
    // MARK: - Settings
    @AppStorage("calendarSyncEnabled") var calendarSyncEnabled = true
    @AppStorage("focusModeSyncEnabled") var focusModeSyncEnabled = true
    @AppStorage("idleDetectionEnabled") var idleDetectionEnabled = true
    @AppStorage("idleTimeoutMinutes") var idleTimeoutMinutes = 5
    @AppStorage("visualBreakEnabled") var visualBreakEnabled = true
    @AppStorage("deepWorkEnabled") var deepWorkEnabled = true
    @AppStorage("presentationModeEnabled") var presentationModeEnabled = true
    @AppStorage("workHoursEnabled") var workHoursEnabled = true
    @AppStorage("workStartTime") var workStartTime = 9
    @AppStorage("workEndTime") var workEndTime = 18
    @AppStorage("workDays") var workDays = "1,2,3,4,5" // Mon-Fri
    @AppStorage("smartBreaksEnabled") var smartBreaksEnabled = true
    @AppStorage("selectedWorkProfile") var selectedWorkProfile = "standard"
    @AppStorage("selectedLightTheme") var selectedLightTheme = "minimal"
    @AppStorage("zoomDetectionEnabled") var zoomDetectionEnabled = true
    
    private init() {
        setupFeatures()
    }
    
    // MARK: - Setup
    private func setupFeatures() {
        loadWorkProfile()
        loadTheme()
        // Todos habilitados excepto visualBreakTimer que causa freeze
        setupCalendarSync()
        setupFocusModeSync()
        setupIdleDetection()
        // setupVisualBreakTimer()  // ← DESHABILITADO: Causa freeze por @Published updates cada 60s
        setupWorkHoursChecker()
        setupMeetingDetection()
        setupPresentationDetection()
        updateDashboard()
    }
    
    // MARK: - 1. Calendar Sync
    private var isCalendarSetupAttempted = false
    
    func requestCalendarAccess() {
        // Prevent multiple requests
        guard !isCalendarSetupAttempted else { return }
        isCalendarSetupAttempted = true
        
        // Check if already authorized
        let status = EKEventStore.authorizationStatus(for: .event)
        
        if status == .fullAccess {
            calendarAccessGranted = true
            NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
            startCalendarMonitoring()
            return
        }
        
        // Request access - wrapped in try/catch for sandbox safety
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.calendarAccessGranted = granted
                NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
                if granted {
                    self?.startCalendarMonitoring()
                } else if let error = error {
                    print("Calendar access denied: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupCalendarSync() {
        guard calendarSyncEnabled, !isCalendarSetupAttempted else { return }
        
        // Check current authorization status
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .fullAccess, .writeOnly:
            calendarAccessGranted = true
            NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
            startCalendarMonitoring()
        case .notDetermined:
            // Delay request to avoid sandbox issues at startup
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.requestCalendarAccess()
            }
        case .denied, .restricted:
            calendarAccessGranted = false
            NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
            print("Calendar access denied. Enable in System Settings > Privacy & Security > Calendars")
        @unknown default:
            calendarAccessGranted = false
            NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
            break
        }
    }
    
    private func startCalendarMonitoring() {
        guard calendarAccessGranted else { return }
        
        // Load available calendars
        loadAvailableCalendars()
        
        // TEMPORALMENTE DESHABILITADO para debugging
        /*
        Timer.publish(every: 300, on: .main, in: .common) // Cada 5 minutos
            .autoconnect()
            .sink { _ in self.checkCalendarStatus() }
            .store(in: &cancellables)
        */
        checkCalendarStatus()
    }
    
    func loadAvailableCalendars() {
        guard calendarAccessGranted else { return }
        availableCalendars = eventStore.calendars(for: .event)
    }
    
    func setSelectedCalendar(_ identifier: String) {
        selectedCalendarIdentifier = identifier
    }
    
    private func checkCalendarStatus() {
        guard calendarAccessGranted else { return }
        
        let now = Date()
        
        // Get calendars to check
        var calendarsToCheck: [EKCalendar]
        
        if !selectedCalendarIdentifier.isEmpty,
           let selectedCalendar = availableCalendars.first(where: { $0.calendarIdentifier == selectedCalendarIdentifier }) {
            calendarsToCheck = [selectedCalendar]
        } else {
            calendarsToCheck = availableCalendars.isEmpty ? eventStore.calendars(for: .event) : availableCalendars
        }
        
        guard !calendarsToCheck.isEmpty else {
            calendarStatus = .none
            return
        }
        
        let predicate = eventStore.predicateForEvents(withStart: now.addingTimeInterval(-3600), 
                                                       end: now.addingTimeInterval(3600), 
                                                       calendars: calendarsToCheck)
        let events = eventStore.events(matching: predicate)
        
        if let currentEvent = events.first(where: { $0.startDate <= now && $0.endDate >= now }) {
            calendarStatus = .inMeeting(currentEvent.title ?? "Meeting")
        } else if let upcomingEvent = events.first(where: { $0.startDate > now && $0.startDate.timeIntervalSince(now) < 300 }) {
            calendarStatus = .preparing(upcomingEvent.title ?? "Meeting")
        } else {
            calendarStatus = .available
        }
        
        // Notificar cambio para UI no-observable
        NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
        
        updateLightFromCalendar()
    }
    
    private func updateLightFromCalendar() {
        guard calendarSyncEnabled else { return }
        
        switch calendarStatus {
        case .inMeeting:
            BusylightManager.shared.red()
        case .preparing:
            BusylightManager.shared.yellow()
        case .available:
            if !PomodoroManager.shared.isRunning {
                BusylightManager.shared.green()
            }
        case .none:
            break
        }
    }
    
    // MARK: - 2. Focus Mode Sync
    private func setupFocusModeSync() {
        guard focusModeSyncEnabled else { return }
        // Monitor Focus Mode changes via distributed notifications
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(focusModeChanged),
            name: NSNotification.Name("com.apple.focusmode.active"),
            object: nil
        )
    }
    
    @objc private func focusModeChanged(_ notification: Notification) {
        guard focusModeSyncEnabled,
              let userInfo = notification.userInfo,
              let mode = userInfo["focusMode"] as? String else { return }
        
        switch mode {
        case "com.apple.focus.work":
            focusMode = .work
            BusylightManager.shared.green()
        case "com.apple.focus.sleep":
            focusMode = .sleep
            BusylightManager.shared.off()
        case "com.apple.focus.doNotDisturb":
            focusMode = .doNotDisturb
            BusylightManager.shared.pulseRed()
        default:
            focusMode = .personal
            BusylightManager.shared.blue()
        }
    }
    
    // MARK: - 3. Idle Detection
    private func setupIdleDetection() {
        guard idleDetectionEnabled else { return }
        
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown]) { _ in
            self.lastActivityTime = Date()
            if self.isIdle {
                self.isIdle = false
                self.resumeFromIdle()
            }
        }
        
        idleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.checkIdleStatus()
        }
    }
    
    @Published var wasPomodoroRunningBeforeIdle = false
    
    private func checkIdleStatus() {
        let idleTime = Date().timeIntervalSince(lastActivityTime)
        let timeout = Double(idleTimeoutMinutes * 60)
        
        if idleTime > timeout && !isIdle {
            isIdle = true
            BusylightManager.shared.orange()
            
            // Pause Pomodoro if running (but don't stop it)
            let pomodoro = PomodoroManager.shared
            if pomodoro.isRunning && !pomodoro.isPaused {
                wasPomodoroRunningBeforeIdle = true
                pomodoro.pause()
                
                // Show notification
                let content = UNMutableNotificationContent()
                content.title = "⏸️ Pomodoro Pausado"
                content.body = "Detectamos inactividad. El timer se pausó automáticamente."
                content.sound = .default
                
                let request = UNNotificationRequest(identifier: "idlePause", content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func resumeFromIdle() {
        // Resume Pomodoro if it was paused by idle detection
        if wasPomodoroRunningBeforeIdle {
            wasPomodoroRunningBeforeIdle = false
            PomodoroManager.shared.start() // Resume
            
            // Show notification
            let content = UNMutableNotificationContent()
            content.title = "▶️ Pomodoro Reanudado"
            content.body = "Bienvenido de vuelta. El timer sigue corriendo."
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: "idleResume", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
        
        if PomodoroManager.shared.isRunning {
            // Let pomodoro handle light color
        } else if case .inMeeting = calendarStatus {
            BusylightManager.shared.red()
        } else {
            BusylightManager.shared.green()
        }
    }
    
    // MARK: - 4. 20-20-20 Visual Break Timer
    private func setupVisualBreakTimer() {
        guard visualBreakEnabled else { return }
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            print("Notification permission: \(granted)")
        }
        
        visualBreakTimerObj = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.visualBreakTimer += 1
            if self.visualBreakTimer >= 20 {
                self.triggerVisualBreak()
            }
        }
    }
    
    private func triggerVisualBreak() {
        isVisualBreakActive = true
        visualBreakTimer = 0
        
        // Gentle blue pulse for 20 seconds
        BusylightManager.shared.pulseBlue()
        
        // Show notification
        let content = UNMutableNotificationContent()
        content.title = "👁️ Descanso Visual (20-20-20)"
        content.body = "Mira a 6 metros (20 pies) de distancia durante 20 segundos para cuidar tus ojos"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "visualBreak", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
        
        // Auto-reset after 20 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            self.isVisualBreakActive = false
            self.visualBreakTimer = 0
            if !PomodoroManager.shared.isRunning {
                BusylightManager.shared.off()
            }
        }
    }
    
    // MARK: - 5. Dashboard Data
    func updateDashboard() {
        // Simplified dashboard without SwiftData fetch
        dashboardData = ProductivityDashboard()
    }
    
    // MARK: - 6. Deep Work Mode
    private var deepWorkTimer: Timer?
    
    func startDeepWorkMode(durationMinutes: Int = 90) {
        // Stop Pomodoro if running
        if PomodoroManager.shared.isRunning {
            PomodoroManager.shared.stop()
        }
        
        isDeepWorkActive = true
        deepWorkRemainingMinutes = durationMinutes
        
        // Set light
        BusylightManager.shared.red()
        
        // Start countdown timer (updates every minute)
        deepWorkTimer?.invalidate()
        deepWorkTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.deepWorkRemainingMinutes -= 1
            if self.deepWorkRemainingMinutes <= 0 {
                self.endDeepWorkMode()
            }
        }
    }
    
    func endDeepWorkMode() {
        isDeepWorkActive = false
        deepWorkRemainingMinutes = 0
        deepWorkTimer?.invalidate()
        deepWorkTimer = nil
        BusylightManager.shared.off()
    }
    
    // MARK: - 7. Work Profiles
    private func loadWorkProfile() {
        currentWorkProfile = WorkProfile(rawValue: selectedWorkProfile) ?? .standard
    }
    
    func setWorkProfile(_ profile: WorkProfile) {
        currentWorkProfile = profile
        selectedWorkProfile = profile.rawValue
        applyWorkProfile(profile)
    }
    
    private func applyWorkProfile(_ profile: WorkProfile) {
        switch profile {
        case .coding:
            PomodoroManager.shared.workTimeMinutes = 50
            PomodoroManager.shared.shortBreakMinutes = 10
        case .meetings:
            calendarSyncEnabled = true
        case .deepWork:
            PomodoroManager.shared.workTimeMinutes = 90
            PomodoroManager.shared.shortBreakMinutes = 15
        case .learning:
            PomodoroManager.shared.workTimeMinutes = 25
            PomodoroManager.shared.shortBreakMinutes = 5
        case .standard:
            PomodoroManager.shared.workTimeMinutes = 25
            PomodoroManager.shared.shortBreakMinutes = 5
        }
    }
    
    // MARK: - 10. Zoom/Meet Detection
    private func setupMeetingDetection() {
        guard zoomDetectionEnabled else { return }
        
        meetingCheckTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.checkCameraAndMicrophone()
        }
    }
    
    private func checkCameraAndMicrophone() {
        // Check for running video apps
        let runningApps = NSWorkspace.shared.runningApplications
        let videoApps = ["zoom.us", "com.microsoft.teams", "com.google.Chrome"]
        let isVideoAppRunning = runningApps.contains { app in
            videoApps.contains(app.bundleIdentifier ?? "")
        }
        
        let wasInMeeting = isInMeeting
        isInMeeting = isVideoAppRunning
        
        if isInMeeting && !wasInMeeting {
            BusylightManager.shared.red()
        } else if !isInMeeting && wasInMeeting {
            BusylightManager.shared.green()
        }
    }
    
    // MARK: - 12. Presentation Mode
    private func setupPresentationDetection() {
        guard presentationModeEnabled else { return }
        
        // TEMPORALMENTE DESHABILITADO para debugging
        /*
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in self.checkPresentationMode() }
            .store(in: &cancellables)
        */
    }
    
    private func checkPresentationMode() {
        let runningApps = NSWorkspace.shared.runningApplications
        
        // Check for presentation apps
        let presentationApps = ["com.apple.iWork.Keynote", "com.microsoft.Powerpoint"]
        let isPresentingNow = runningApps.contains { app in
            presentationApps.contains(app.bundleIdentifier ?? "") && app.isActive
        }
        
        let wasPresenting = isPresenting
        isPresenting = isPresentingNow
        
        if isPresenting && !wasPresenting {
            BusylightManager.shared.red()
        } else if !isPresenting && wasPresenting {
            BusylightManager.shared.off()
        }
    }
    
    // MARK: - 13. Work Hours
    private func setupWorkHoursChecker() {
        guard workHoursEnabled else { return }
        
        checkWorkHours()
        
        workHoursTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.checkWorkHours()
        }
    }
    
    private func checkWorkHours() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        let workDaysArray = workDays.split(separator: ",").compactMap { Int($0) }
        let isWorkDay = workDaysArray.contains(weekday)
        let isWorkHour = hour >= workStartTime && hour < workEndTime
        
        isWithinWorkHours = isWorkDay && isWorkHour
    }
    
    // MARK: - 14. Light Themes
    private func loadTheme() {
        currentTheme = LightTheme(rawValue: selectedLightTheme) ?? .minimal
    }
    
    func setTheme(_ theme: LightTheme) {
        currentTheme = theme
        selectedLightTheme = theme.rawValue
    }
    
    func getThemeColor(for phase: PomodoroPhase) -> Color {
        switch currentTheme {
        case .aurora:
            return phase == .work ? .green : .blue
        case .minimal:
            return phase == .work ? .white : .gray
        case .nature:
            return phase == .work ? Color(red: 0.4, green: 0.7, blue: 0.4) : Color(red: 0.6, green: 0.8, blue: 0.6)
        case .cyber:
            return phase == .work ? .cyan : .purple
        case .calm:
            return phase == .work ? Color(red: 0.5, green: 0.6, blue: 0.5) : Color(red: 0.6, green: 0.5, blue: 0.6)
        }
    }
    
    // MARK: - 11. Smart Breaks
    func checkBreakActivity() {
        guard smartBreaksEnabled,
              PomodoroManager.shared.isRunning,
              PomodoroManager.shared.currentPhase == .shortBreak else { return }
        
        let timeSinceBreakStarted = Date().timeIntervalSince(lastActivityTime)
        
        if timeSinceBreakStarted < 10 {
            smartBreakStatus = .skipped
        } else {
            smartBreakStatus = .completed
        }
    }
    
    // MARK: - ML Integration
    func updateWorkHours(start: Int, end: Int) {
        workStartTime = max(0, min(23, start))
        workEndTime = max(1, min(24, end))
        
        // Notificar cambio
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkHoursChanged"),
            object: nil,
            userInfo: ["start": workStartTime, "end": workEndTime]
        )
        
        // Recheck work hours immediately
        checkWorkHours()
        
        BusylightLogger.shared.info("Work hours updated by ML: \(workStartTime):00 - \(workEndTime):00")
    }
}

// MARK: - Supporting Types

enum CalendarStatus: Equatable {
    case none
    case available
    case preparing(String)
    case inMeeting(String)
}

enum FocusMode {
    case none
    case work
    case sleep
    case doNotDisturb
    case personal
}

enum WorkProfile: String, CaseIterable {
    case standard = "standard"
    case coding = "coding"
    case meetings = "meetings"
    case deepWork = "deepWork"
    case learning = "learning"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .coding: return "Coding"
        case .meetings: return "Meetings"
        case .deepWork: return "Deep Work"
        case .learning: return "Learning"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "timer"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .meetings: return "person.2.fill"
        case .deepWork: return "brain.head.profile"
        case .learning: return "book.fill"
        }
    }
}

enum LightTheme: String, CaseIterable {
    case minimal = "minimal"
    case aurora = "aurora"
    case nature = "nature"
    case cyber = "cyber"
    case calm = "calm"
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .aurora: return "Aurora"
        case .nature: return "Nature"
        case .cyber: return "Cyber"
        case .calm: return "Calm"
        }
    }
}

enum SmartBreakStatus {
    case waiting
    case skipped
    case completed
}

struct ProductivityDashboard {
    var totalFocusHours: Double = 0
    var pomodorosCompleted: Int = 0
    var breaksTaken: Int = 0
    var breaksSkipped: Int = 0
    var currentStreak: Int = 5
    var bestDay: String = "Monday"
    var bestDayHours: Double = 6.5
    var weeklyData: [DailyData] = []
    
    struct DailyData {
        let date: Date
        let hours: Double
        let pomodoros: Int
    }
    
    init() {}
}
