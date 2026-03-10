//
//  SmartFeaturesManager.swift
//  Busylight
//
//  Smart features: Calendar sync, focus mode, deep work, work profiles,
//  meeting detection (Zoom/Teams), and work hours checking.
//
//  Relationships:
//  - Uses: BusylightManager (automatic color changes based on context)
//  - Uses: PomodoroManager (pauses timer during deep work)
//  - Used by: DeepWorkView.swift, DashboardView.swift, MenuBarView.swift
//  - Note: Auto-adjust work hours by ML has been removed (manual only)
//

import Foundation
import SwiftUI
import EventKit
import Combine
import AVFoundation
import SwiftData
import UserNotifications

// MARK: - Smart Features Manager (Singleton)
@MainActor
final class SmartFeaturesManager: ObservableObject {
    static let shared = SmartFeaturesManager()

    // MARK: - Published States
    @Published var calendarStatus: CalendarStatus = .none
    @Published var calendarAccessGranted = false
    @Published var availableCalendars: [EKCalendar] = []
    @Published var focusMode: FocusMode = .none
    @Published var isInMeeting: Bool = false
    @Published var isPresenting: Bool = false
    @Published var currentWorkProfile: WorkProfile = .standard
    @Published var isDeepWorkActive: Bool = false
    @Published var dashboardData: ProductivityDashboard = ProductivityDashboard()
    @Published var isWithinWorkHours: Bool = true
    @Published var deepWorkRemainingMinutes: Int = 0

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var workHoursTimer: Timer?
    private var meetingCheckTimer: Timer?
    private var deepWorkTimer: Timer?
    private var eventStore = EKEventStore()
    private var captureSession: AVCaptureSession?

    // MARK: - Settings
    @AppStorage("calendarSyncEnabled") var calendarSyncEnabled = true
    @AppStorage("selectedCalendarIdentifier") var selectedCalendarIdentifier: String = ""
    @AppStorage("focusModeSyncEnabled") var focusModeSyncEnabled = true
    @AppStorage("deepWorkEnabled") var deepWorkEnabled = true
    @AppStorage("presentationModeEnabled") var presentationModeEnabled = true
    @AppStorage("workHoursEnabled") var workHoursEnabled = true
    @AppStorage("workStartTime") var workStartTime = 9
    @AppStorage("workEndTime") var workEndTime = 18
    @AppStorage("workDays") var workDays = "1,2,3,4,5" // Mon-Fri
    @AppStorage("selectedWorkProfile") var selectedWorkProfile = "standard"
    @AppStorage("zoomDetectionEnabled") var zoomDetectionEnabled = true

    private init() {
        setupFeatures()
    }

    // MARK: - Setup
    private func setupFeatures() {
        loadWorkProfile()
        setupCalendarSync()
        setupFocusModeSync()
        setupWorkHoursChecker()
        setupMeetingDetection()
        setupPresentationDetection()
        updateDashboard()
    }

    // MARK: - 1. Calendar Sync
    private var isCalendarSetupAttempted = false

    func requestCalendarAccess() {
        guard !isCalendarSetupAttempted else { return }
        isCalendarSetupAttempted = true

        let status = EKEventStore.authorizationStatus(for: .event)

        if status == .fullAccess {
            calendarAccessGranted = true
            NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
            startCalendarMonitoring()
            return
        }

        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.calendarAccessGranted = granted
                NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
                if granted {
                    self.startCalendarMonitoring()
                } else if let error = error {
                    print("Calendar access denied: \(error.localizedDescription)")
                }
            }
        }
    }

    private func setupCalendarSync() {
        guard calendarSyncEnabled, !isCalendarSetupAttempted else { return }

        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .fullAccess, .writeOnly:
            calendarAccessGranted = true
            NotificationCenter.default.post(name: NSNotification.Name("CalendarStatusChanged"), object: nil)
            startCalendarMonitoring()
        case .notDetermined:
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.requestCalendarAccess()
                }
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
        loadAvailableCalendars()
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

    // MARK: - 3. Dashboard Data
    func updateDashboard() {
        dashboardData = ProductivityDashboard()
    }

    // MARK: - 6. Deep Work Mode
    func startDeepWorkMode(durationMinutes: Int = 90) {
        if PomodoroManager.shared.isRunning {
            PomodoroManager.shared.stop()
        }

        isDeepWorkActive = true
        deepWorkRemainingMinutes = durationMinutes
        BusylightManager.shared.red()

        deepWorkTimer?.invalidate()
        deepWorkTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.deepWorkRemainingMinutes -= 1
                if self.deepWorkRemainingMinutes <= 0 {
                    self.endDeepWorkMode()
                }
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
        UserInteractionLogger.shared.profileChanged(to: profile.displayName)
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

        meetingCheckTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkCameraAndMicrophone()
            }
        }
    }

    private func checkCameraAndMicrophone() {
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
    }

    private func checkPresentationMode() {
        let runningApps = NSWorkspace.shared.runningApplications
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

        workHoursTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkWorkHours()
            }
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

    // MARK: - Work Hours Management
}

// MARK: - User Interaction Logger (forward declaration)
extension SmartFeaturesManager {
    func logWorkProfileChange(to profile: WorkProfile) {
        UserInteractionLogger.shared.profileChanged(to: profile.displayName)
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
