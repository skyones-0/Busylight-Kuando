//
//  LocationManager.swift
//  Busylight
//
//  Servicio de detección de país vía Locale (sin GPS, sandbox-friendly)
//

import Foundation
import SwiftData
import Combine

@MainActor
class LocationManager: ObservableObject {
    static let shared = LocationManager()

    private var modelContext: ModelContext?
    private var hasAutoSubscribed = false

    @Published var detectedCountryCode: String?
    @Published var detectedCountryName: String?
    @Published var detectedCountryFlag: String?

    private init() {}

    func configure(with context: ModelContext) {
        self.modelContext = context
        detectCountryFromLocale()
    }

    private func detectCountryFromLocale() {
        let locale = Locale.current
        let countryCode = locale.region?.identifier ?? "US"
        processCountry(countryCode)
        BusylightLogger.shared.info("Locale detectado: \(locale.identifier)")
        BusylightLogger.shared.info("Región del sistema: \(locale.region?.identifier ?? "nil")")
        BusylightLogger.shared.info("País detectado: \(countryCode)")

    }

    func manualSelectCountry(code: String) {
        processCountry(code)
    }

    private func processCountry(_ countryCode: String) {
        guard let country = CountryData.supportedCountries.first(where: { $0.code == countryCode }) else {
            detectedCountryCode = countryCode
            detectedCountryName = countryCode
            detectedCountryFlag = "🌎"
            return
        }

        detectedCountryCode = country.code
        detectedCountryName = country.name
        detectedCountryFlag = country.flag

        saveAndAutoSubscribe(country: country)
    }

    private func saveAndAutoSubscribe(country: Country) {
        guard let context = modelContext else { return }

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

        if !hasAutoSubscribed {
            hasAutoSubscribed = true
            autoSubscribeToHolidayCalendar(country: country)
        }
    }

    private func autoSubscribeToHolidayCalendar(country: Country) {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<CalendarConfiguration>(
            predicate: #Predicate { $0.calendarType == "holiday" }
        )
        guard (try? context.fetch(descriptor))?.isEmpty == true else { return }

        let holidayConfig = CalendarConfiguration(
            calendarIdentifier: "holidays.\(country.code)",
            calendarName: "\(country.flag) Festivos \(country.name)",
            calendarType: "holiday"
        )
        context.insert(holidayConfig)
        try? context.save()

        let holidays = HolidayData.holidays(for: country.code, year: Calendar.current.component(.year, from: Date()))
        BusylightLogger.shared.info("Locale: Auto-suscrito a festivos de \(country.name) - \(holidays.count) días")
    }
}

// MARK: - Country Data
struct Country: Codable {
    let code: String
    let name: String
    let flag: String
}

enum CountryData {
    static let supportedCountries: [Country] = [
        Country(code: "US", name: "Estados Unidos", flag: "🇺🇸"),
        Country(code: "MX", name: "México", flag: "🇲🇽"),
        Country(code: "ES", name: "España", flag: "🇪🇸"),
        Country(code: "AR", name: "Argentina", flag: "🇦🇷"),
        Country(code: "CO", name: "Colombia", flag: "🇨🇴"),
        Country(code: "CL", name: "Chile", flag: "🇨🇱"),
        Country(code: "PE", name: "Perú", flag: "🇵🇪"),
        Country(code: "VE", name: "Venezuela", flag: "🇻🇪"),
        Country(code: "EC", name: "Ecuador", flag: "🇪🇨"),
        Country(code: "BO", name: "Bolivia", flag: "🇧🇴"),
        Country(code: "PY", name: "Paraguay", flag: "🇵🇾"),
        Country(code: "UY", name: "Uruguay", flag: "🇺🇾"),
        Country(code: "BR", name: "Brasil", flag: "🇧🇷"),
        Country(code: "GB", name: "Reino Unido", flag: "🇬🇧"),
        Country(code: "DE", name: "Alemania", flag: "🇩🇪"),
        Country(code: "FR", name: "Francia", flag: "🇫🇷"),
        Country(code: "IT", name: "Italia", flag: "🇮🇹"),
        Country(code: "CA", name: "Canadá", flag: "🇨🇦"),
        Country(code: "AU", name: "Australia", flag: "🇦🇺"),
        Country(code: "JP", name: "Japón", flag: "🇯🇵")
    ]
}
