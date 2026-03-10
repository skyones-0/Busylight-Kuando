//
//  LocationManager.swift
//  Busylight
//
//  Servicio de GPS para detección automática de país y suscripción a calendario de festivos
//

import Foundation
import CoreLocation
import SwiftData
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private var modelContext: ModelContext?
    private var hasAutoSubscribed = false
    
    @Published var detectedCountryCode: String?
    @Published var detectedCountryName: String?
    @Published var detectedCountryFlag: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var locationError: String?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadSavedCountry()
    }
    
    private func loadSavedCountry() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(descriptor).first,
           let savedCountry = settings.detectedCountryCode {
            detectedCountryCode = savedCountry
            if let country = CalendarConfiguration.supportedCountries.first(where: { $0.code == savedCountry }) {
                detectedCountryName = country.name
                detectedCountryFlag = country.flag
            }
        }
    }
    
    func requestAuthorization() {
        let status = manager.authorizationStatus
        authorizationStatus = status
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdate()
        case .denied, .restricted:
            locationError = "Acceso a ubicación denegado. Por favor habilítalo en Preferencias del Sistema."
        @unknown default:
            break
        }
    }
    
    func startLocationUpdate() {
        isLoading = true
        locationError = nil
        manager.startUpdatingLocation()
    }
    
    private func geocodeCountry(from location: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first,
               let countryCode = placemark.isoCountryCode {
                await processDetectedCountry(countryCode)
            }
        } catch {
            locationError = "Error al obtener ubicación: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func processDetectedCountry(_ countryCode: String) async {
        guard let country = CalendarConfiguration.supportedCountries.first(where: { $0.code == countryCode }) else {
            detectedCountryCode = countryCode
            detectedCountryName = countryCode
            detectedCountryFlag = "🌎"
            return
        }
        
        detectedCountryCode = country.code
        detectedCountryName = country.name
        detectedCountryFlag = country.flag
        
        // Guardar en AppSettings
        if let context = modelContext {
            let descriptor = FetchDescriptor<AppSettings>()
            let settings = (try? context.fetch(descriptor).first) ?? AppSettings()
            if settings.detectedCountryCode == nil {
                context.insert(settings)
            }
            settings.detectedCountryCode = country.code
            settings.detectedCountryName = country.name
            settings.detectedCountryFlag = country.flag
            settings.updatedAt = Date()
            try? context.save()
        }
        
        // Auto-subscribir a calendario de festivos si no hay uno configurado
        if !hasAutoSubscribed {
            hasAutoSubscribed = true
            await autoSubscribeToHolidayCalendar(countryCode: country.code)
        }
    }
    
    private func autoSubscribeToHolidayCalendar(countryCode: String) async {
        guard let context = modelContext else { return }
        
        // Verificar si ya tiene calendario de festivos
        let descriptor = FetchDescriptor<CalendarConfiguration>(
            predicate: #Predicate { $0.calendarType == "holiday" }
        )
        let existingHolidays = (try? context.fetch(descriptor)) ?? []
        
        guard existingHolidays.isEmpty else {
            BusylightLogger.shared.info("Ya existe calendario de festivos configurado")
            return
        }
        
        // Crear configuración de festivos
        let country = CalendarConfiguration.supportedCountries.first { $0.code == countryCode }
        let holidayConfig = CalendarConfiguration(
            calendarIdentifier: "holidays.\(countryCode)",
            calendarName: "\(country?.flag ?? "🌎") Festivos \(country?.name ?? countryCode)",
            calendarType: "holiday"
        )
        context.insert(holidayConfig)
        try? context.save()
        
        // Generar festivos para ML
        let holidays = HolidayData.holidays(for: countryCode, year: Calendar.current.component(.year, from: Date()))
        BusylightLogger.shared.info("GPS: Auto-suscrito a festivos de \(country?.name ?? countryCode) - \(holidays.count) días")
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation()
        Task { @MainActor in
            await geocodeCountry(from: location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLoading = false
            locationError = "Error de GPS: \(error.localizedDescription)"
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                startLocationUpdate()
            case .denied, .restricted:
                isLoading = false
                locationError = "Permiso de ubicación denegado"
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
