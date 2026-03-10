//
//  NotificationManager.swift
//  Busylight
//
//  Gestiona notificaciones: 20-20-20, Deep Work, ML Learning
//

import Foundation
import UserNotifications
import Combine

/// Tipos de notificaciones de Busylight
enum BusylightNotificationType: String {
    case twentyTwentyTwenty = "20-20-20"
    case deepWorkStart = "deep-work-start"
    case deepWorkEnd = "deep-work-end"
    case mlLearning = "ml-learning"
    case dayCategory = "day-category"
    case breakReminder = "break-reminder"
}

/// Manager de notificaciones
@MainActor
class NotificationCenterManager: ObservableObject {
    static let shared = NotificationCenterManager()
    
    @Published var isAuthorized = false
    @Published var twentyTwentyTimer: Timer?
    @Published var isTwentyTwentyActive = false
    
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    private init() {
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            Task { @MainActor in
                self?.isAuthorized = granted
                if granted {
                    BusylightLogger.shared.info("🔔 Notificaciones autorizadas")
                } else if let error = error {
                    BusylightLogger.shared.info("❌ Error autorizando notificaciones: \(error)")
                }
            }
        }
    }
    
    // MARK: - 20-20-20 Rule
    
    /// Inicia el timer para la regla 20-20-20
    func startTwentyTwentyTimer() {
        guard isAuthorized else {
            BusylightLogger.shared.info("⚠️ Notificaciones no autorizadas")
            return
        }
        
        stopTwentyTwentyTimer() // Limpiar timer anterior
        isTwentyTwentyActive = true
        
        BusylightLogger.shared.info("🔔 Iniciando timer 20-20-20")
        
        // Programar notificación inicial
        Task { @MainActor in
            self.scheduleTwentyTwentyNotification()
        }
        
        // Crear timer que repite cada 20 minutos
        twentyTwentyTimer = Timer.scheduledTimer(withTimeInterval: 20 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleTwentyTwentyNotification()
            }
        }
    }
    
    func stopTwentyTwentyTimer() {
        twentyTwentyTimer?.invalidate()
        twentyTwentyTimer = nil
        isTwentyTwentyActive = false
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [BusylightNotificationType.twentyTwentyTwenty.rawValue])
        BusylightLogger.shared.info("🔔 Timer 20-20-20 detenido")
    }
    
    private func scheduleTwentyTwentyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "👀 20-20-20 Rule"
        content.body = "Look at something 20 feet away for 20 seconds. Protect your eyes!"
        content.sound = .default
        content.categoryIdentifier = "TWENTY_TWENTY"
        
        // Mostrar inmediatamente
        let request = UNNotificationRequest(
            identifier: "\(BusylightNotificationType.twentyTwentyTwenty.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                BusylightLogger.shared.info("❌ Error programando 20-20-20: \(error)")
            }
        }
    }
    
    // MARK: - Deep Work Notifications
    
    /// Notifica inicio de sesión de Deep Work
    func showDeepWorkStartNotification(duration: Int) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 Deep Work Session Started"
        content.body = "You're now in deep work mode for \(duration) minutes. Stay focused!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: BusylightNotificationType.deepWorkStart.rawValue,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
        
        BusylightLogger.shared.info("🔔 Notificación: Deep Work iniciado (\(duration) min)")
    }
    
    /// Notifica fin de sesión de Deep Work
    func showDeepWorkEndNotification(completed: Bool) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = completed ? "✅ Deep Work Complete!" : "⏱️ Deep Work Paused"
        content.body = completed 
            ? "Great job! You completed your deep work session. Take a break."
            : "Your deep work session was interrupted. Ready to resume?"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: BusylightNotificationType.deepWorkEnd.rawValue,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    /// Notificación durante Deep Work (información de progreso)
    func showDeepWorkProgressNotification(minutesRemaining: Int) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 Deep Work in Progress"
        content.body = "\(minutesRemaining) minutes remaining. Keep your focus!"
        content.sound = .none // Silenciosa
        
        let request = UNNotificationRequest(
            identifier: "\(BusylightNotificationType.deepWorkStart.rawValue)-progress",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - ML Learning Notifications
    
    /// Notifica que la app está aprendiendo
    func showLearningNotification(message: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🧠 Busylight is Learning"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "\(BusylightNotificationType.mlLearning.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
        
        BusylightLogger.shared.info("🔔 Notificación: App aprendiendo - \(message)")
    }
    
    /// Notifica cuando se completa el entrenamiento del modelo
    func showTrainingCompleteNotification(accuracy: Double) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "✅ ML Model Updated"
        content.body = "Your personal work patterns model has been updated with \(String(format: "%.0f%%", accuracy * 100)) accuracy!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "\(BusylightNotificationType.mlLearning.rawValue)-complete",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - Day Category Notifications
    
    /// Muestra notificación con la categoría del día
    func showDayCategoryNotification(category: DayCategory) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(category.emoji) Today: \(category.displayName)"
        content.body = category.recommendation
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: BusylightNotificationType.dayCategory.rawValue,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
        
        BusylightLogger.shared.info("🔔 Notificación: Categoría del día - \(category.displayName)")
    }
    
    /// Notifica cambio en la categoría del día
    func showDayCategoryChangedNotification(from oldCategory: DayCategory, to newCategory: DayCategory) {
        guard isAuthorized, oldCategory != newCategory else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📊 Day Status Changed"
        content.body = "From \(oldCategory.emoji) \(oldCategory.displayName) to \(newCategory.emoji) \(newCategory.displayName). \(newCategory.recommendation)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "\(BusylightNotificationType.dayCategory.rawValue)-changed",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - Break Reminders
    
    /// Recordatorio para tomar descanso
    func showBreakReminderNotification(workDuration: TimeInterval) {
        guard isAuthorized else { return }
        
        let minutes = Int(workDuration / 60)
        let content = UNMutableNotificationContent()
        content.title = "☕ Time for a Break"
        content.body = "You've been working for \(minutes) minutes. Take a 5-minute break to recharge."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: BusylightNotificationType.breakReminder.rawValue,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    /// Recordatorio de burnout (cuando la categoría es BurnoutRisk)
    func showBurnoutWarningNotification() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 Burnout Risk Detected"
        content.body = "Your day is looking overwhelming. Consider delegating tasks or taking longer breaks."
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: "burnout-warning",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - General Notifications
    
    /// Muestra una notificación informativa genérica
    func showInfoNotification(title: String, body: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "info-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - Utility
    
    /// Cancela todas las notificaciones pendientes
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        BusylightLogger.shared.info("🔔 Todas las notificaciones canceladas")
    }
    
    /// Cancela notificaciones de un tipo específico
    func cancelNotifications(ofType type: BusylightNotificationType) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [type.rawValue])
    }
    
    /// Obtiene estadísticas de notificaciones entregadas
    func getDeliveredNotifications(completion: @Sendable @escaping ([UNNotification]) -> Void) {
        notificationCenter.getDeliveredNotifications(completionHandler: completion)
    }
}

// MARK: - Notification Categories

extension NotificationCenterManager {
    /// Configura las categorías de notificaciones con acciones
    func setupNotificationCategories() {
        // Categoría para 20-20-20
        let twentyDoneAction = UNNotificationAction(
            identifier: "TWENTY_DONE",
            title: "Done ✅",
            options: []
        )
        
        let twentySkipAction = UNNotificationAction(
            identifier: "TWENTY_SKIP",
            title: "Skip",
            options: []
        )
        
        _ = UNNotificationCategory(
            identifier: "TWENTY_TWENTY",
            actions: [twentyDoneAction, twentySkipAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Categoría para Deep Work
        let deepWorkExtendAction = UNNotificationAction(
            identifier: "DEEP_EXTEND",
            title: "Extend +15 min",
            options: []
        )
        
        let deepWorkStopAction = UNNotificationAction(
            identifier: "DEEP_STOP",
            title: "Stop",
            options: [.destructive]
        )
        
        let _deepWorkCategory = UNNotificationCategory(
            identifier: "DEEP_WORK",
            actions: [deepWorkExtendAction, deepWorkStopAction],
            intentIdentifiers: [],
            options: []
        )
        
       // NotificationCenterManager.setNotificationCategories([twentyCategory, deepWorkCategory])
    }
}

