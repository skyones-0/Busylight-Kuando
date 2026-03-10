//
//  CalendarPickerView.swift
//  Busylight
//
//  Vista para seleccionar calendarios del sistema
//

import SwiftUI
import EventKit

struct CalendarPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let eventStore: EKEventStore
    let availableCalendars: [EKCalendar]
    @State var selectedCalendars: Set<String>
    let onSave: (Set<String>) -> Void

    @State private var searchText = ""

    private var filteredCalendars: [EKCalendar] {
        if searchText.isEmpty {
            return availableCalendars
        }
        return availableCalendars.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header con botones (antes estaban en toolbar)
                HStack {
                    Button("Cancelar") { dismiss() }
                        .buttonStyle(.bordered)

                    Spacer()

                    Text("Calendarios")
                        .font(.headline)

                    Spacer()

                    Button("Guardar") {
                        onSave(selectedCalendars)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .fontWeight(.semibold)
                }
                .padding()

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Buscar calendarios...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Material.thinMaterial)
                )
                .padding(.horizontal)

                // Selected count
                HStack {
                    Text("\(selectedCalendars.count) seleccionados")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Calendars list
                List {
                    ForEach(filteredCalendars, id: \.calendarIdentifier) { calendar in
                        CalendarRow(
                            calendar: calendar,
                            isSelected: selectedCalendars.contains(calendar.calendarIdentifier)
                        ) {
                            toggleCalendar(calendar)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 400, height: 500)
    }

    private func toggleCalendar(_ calendar: EKCalendar) {
        if selectedCalendars.contains(calendar.calendarIdentifier) {
            selectedCalendars.remove(calendar.calendarIdentifier)
        } else {
            selectedCalendars.insert(calendar.calendarIdentifier)
        }
    }
}

struct CalendarRow: View {
    let calendar: EKCalendar
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(Color(calendar.cgColor))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(calendar.title)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(.primary)

                    Text(calendar.type == .local ? "Local" : calendar.source.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

// MARK: - Holiday Calendar Picker

struct HolidayCalendarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    @State private var selectedCountry = "US"

    private let countries = CalendarConfiguration.supportedCountries

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header con botones (antes estaban en toolbar)
                HStack {
                    Button("Cancelar") { dismiss() }
                        .buttonStyle(.bordered)

                    Spacer()

                    Text("Festivos")
                        .font(.headline)

                    Spacer()

                    Button("Agregar") {
                        onSelect(selectedCountry)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .fontWeight(.semibold)
                }
                .padding()

                // Info header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 28))
                            .foregroundStyle(.orange)
                    }

                    Text("Calendario de Festivos")
                        .font(.headline)

                    Text("Selecciona tu país para incluir los días festivos en el análisis de ML")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)

                // Country list
                List {
                    Section("País") {
                        ForEach(countries, id: \.code) { country in
                            Button {
                                selectedCountry = country.code
                            } label: {
                                HStack(spacing: 12) {
                                    Text(country.flag)
                                        .font(.title2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(country.name)
                                            .font(.subheadline.weight(.medium))

                                        // Show holiday count
                                        let holidayCount = HolidayData.holidays(for: country.code, year: Calendar.current.component(.year, from: Date())).count
                                        Text("\(holidayCount) festivos este año")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedCountry == country.code {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .focusable(false)
                        }
                    }

                    // Preview of selected country's holidays
                    Section("Vista previa de festivos") {
                        let holidays = HolidayData.holidays(for: selectedCountry, year: Calendar.current.component(.year, from: Date()))
                        ForEach(holidays.prefix(5), id: \.self) { date in
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text(date, style: .date)
                                    .font(.subheadline)
                            }
                        }

                        if holidays.count > 5 {
                            Text("... y \(holidays.count - 5) más")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(width: 400, height: 550)
    }
}

// MARK: - Preview
struct CalendarPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarPickerView(
            eventStore: EKEventStore(),
            availableCalendars: [],
            selectedCalendars: [],
            onSave: { _ in }
        )
    }
}

struct HolidayCalendarPickerView_Previews: PreviewProvider {
    static var previews: some View {
        HolidayCalendarPickerView { _ in }
    }
}
