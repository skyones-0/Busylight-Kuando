//
//  HolidayData.swift
//  Busylight
//

import Foundation

struct HolidayData {
    static func holidays(for countryCode: String, year: Int) -> [Date] {
        let calendar = Calendar.current
        var holidays: [Date] = []
        
        switch countryCode {
        case "US":
            // New Year's Day
            holidays.append(calendar.date(from: DateComponents(year: year, month: 1, day: 1))!)
            
            // MLK Day - Third Monday of January
            if let jan1 = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
               let firstMonday = calendar.nextDate(after: jan1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime),
               let thirdMonday = calendar.date(byAdding: .weekOfYear, value: 2, to: firstMonday) {
                holidays.append(thirdMonday)
            }
            
            // Presidents Day - Third Monday of February
            if let feb1 = calendar.date(from: DateComponents(year: year, month: 2, day: 1)),
               let firstMonday = calendar.nextDate(after: feb1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime),
               let thirdMonday = calendar.date(byAdding: .weekOfYear, value: 2, to: firstMonday) {
                holidays.append(thirdMonday)
            }
            
            // Memorial Day - Last Monday of May
            if let may31 = calendar.date(from: DateComponents(year: year, month: 5, day: 31)),
               let lastMonday = calendar.previousDate(before: may31, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
                holidays.append(lastMonday)
            }
            
            // Juneteenth - June 19
            holidays.append(calendar.date(from: DateComponents(year: year, month: 6, day: 19))!)
            
            // Independence Day - July 4
            holidays.append(calendar.date(from: DateComponents(year: year, month: 7, day: 4))!)
            
            // Labor Day - First Monday of September
            if let sep1 = calendar.date(from: DateComponents(year: year, month: 9, day: 1)),
               let laborDay = calendar.nextDate(after: sep1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
                holidays.append(laborDay)
            }
            
            // Columbus Day - Second Monday of October
            if let oct1 = calendar.date(from: DateComponents(year: year, month: 10, day: 1)),
               let firstMonday = calendar.nextDate(after: oct1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime),
               let secondMonday = calendar.date(byAdding: .weekOfYear, value: 1, to: firstMonday) {
                holidays.append(secondMonday)
            }
            
            // Veterans Day - November 11
            holidays.append(calendar.date(from: DateComponents(year: year, month: 11, day: 11))!)
            
            // Thanksgiving - Fourth Thursday of November
            if let nov1 = calendar.date(from: DateComponents(year: year, month: 11, day: 1)),
               let firstThursday = calendar.nextDate(after: nov1, matching: DateComponents(weekday: 5), matchingPolicy: .nextTime),
               let thanksgiving = calendar.date(byAdding: .weekOfYear, value: 3, to: firstThursday) {
                holidays.append(thanksgiving)
            }
            
            // Christmas - December 25
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 25))!)
            
        case "MX":
            // New Year's Day
            holidays.append(calendar.date(from: DateComponents(year: year, month: 1, day: 1))!)
            
            // Constitution Day - First Monday of February
            if let feb1 = calendar.date(from: DateComponents(year: year, month: 2, day: 1)),
               let firstMonday = calendar.nextDate(after: feb1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
                holidays.append(firstMonday)
            }
            
            // Benito Juárez Birthday - Third Monday of March
            if let mar1 = calendar.date(from: DateComponents(year: year, month: 3, day: 1)),
               let firstMonday = calendar.nextDate(after: mar1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime),
               let thirdMonday = calendar.date(byAdding: .weekOfYear, value: 2, to: firstMonday) {
                holidays.append(thirdMonday)
            }
            
            // Labor Day - May 1
            holidays.append(calendar.date(from: DateComponents(year: year, month: 5, day: 1))!)
            
            // Independence Day - September 16
            holidays.append(calendar.date(from: DateComponents(year: year, month: 9, day: 16))!)
            
            // Revolution Day - Third Monday of November
            if let nov1 = calendar.date(from: DateComponents(year: year, month: 11, day: 1)),
               let firstMonday = calendar.nextDate(after: nov1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime),
               let thirdMonday = calendar.date(byAdding: .weekOfYear, value: 2, to: firstMonday) {
                holidays.append(thirdMonday)
            }
            
            // Christmas - December 25
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 25))!)
            
        case "ES":
            // New Year's Day
            holidays.append(calendar.date(from: DateComponents(year: year, month: 1, day: 1))!)
            
            // Epiphany - January 6
            holidays.append(calendar.date(from: DateComponents(year: year, month: 1, day: 6))!)
            
            // Labor Day - May 1
            holidays.append(calendar.date(from: DateComponents(year: year, month: 5, day: 1))!)
            
            // Constitution Day - December 6
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 6))!)
            
            // Immaculate Conception - December 8
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 8))!)
            
            // Christmas - December 25
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 25))!)
            
        case "UK":
            // New Year's Day
            holidays.append(calendar.date(from: DateComponents(year: year, month: 1, day: 1))!)
            
            // Early May Bank Holiday - First Monday of May
            if let may1 = calendar.date(from: DateComponents(year: year, month: 5, day: 1)),
               let firstMonday = calendar.nextDate(after: may1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
                holidays.append(firstMonday)
            }
            
            // Spring Bank Holiday - Last Monday of May
            if let may31 = calendar.date(from: DateComponents(year: year, month: 5, day: 31)),
               let lastMonday = calendar.previousDate(before: may31, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
                holidays.append(lastMonday)
            }
            
            // Summer Bank Holiday - Last Monday of August
            if let aug31 = calendar.date(from: DateComponents(year: year, month: 8, day: 31)),
               let lastMonday = calendar.previousDate(before: aug31, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
                holidays.append(lastMonday)
            }
            
            // Christmas Day
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 25))!)
            
            // Boxing Day
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 26))!)
            
        case "CA":
            // New Year's Day
            holidays.append(calendar.date(from: DateComponents(year: year, month: 1, day: 1))!)
            
            // Family Day - Third Monday of February
            if let feb1 = calendar.date(from: DateComponents(year: year, month: 2, day: 1)),
               let firstMonday = calendar.nextDate(after: feb1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime),
               let thirdMonday = calendar.date(byAdding: .weekOfYear, value: 2, to: firstMonday) {
                holidays.append(thirdMonday)
            }
            
            // Victoria Day - Monday before May 25
            if let may25 = calendar.date(from: DateComponents(year: year, month: 5, day: 25)),
               let victoriaDay = calendar.previousDate(before: may25, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
                holidays.append(victoriaDay)
            }
            
            // Canada Day - July 1
            holidays.append(calendar.date(from: DateComponents(year: year, month: 7, day: 1))!)
            
            // Labour Day - First Monday of September
            if let sep1 = calendar.date(from: DateComponents(year: year, month: 9, day: 1)),
               let laborDay = calendar.nextDate(after: sep1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
                holidays.append(laborDay)
            }
            
            // Thanksgiving - Second Monday of October
            if let oct1 = calendar.date(from: DateComponents(year: year, month: 10, day: 1)),
               let firstMonday = calendar.nextDate(after: oct1, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime),
               let thanksgiving = calendar.date(byAdding: .weekOfYear, value: 1, to: firstMonday) {
                holidays.append(thanksgiving)
            }
            
            // Remembrance Day - November 11
            holidays.append(calendar.date(from: DateComponents(year: year, month: 11, day: 11))!)
            
            // Christmas - December 25
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 25))!)
            
            // Boxing Day - December 26
            holidays.append(calendar.date(from: DateComponents(year: year, month: 12, day: 26))!)
            
        default:
            break
        }
        
        return holidays.sorted()
    }
}

extension Calendar {
    func previousDate(before date: Date, matching components: DateComponents, matchingPolicy: MatchingPolicy) -> Date? {
        var current = date
        for _ in 0..<365 {
            current = self.date(byAdding: .day, value: -1, to: current)!
            if self.date(current, matchesComponents: components) {
                return current
            }
        }
        return nil
    }
}
