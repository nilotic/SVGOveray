//
//  LocaleManager.swift
//  SVGOveray
//
//  Created by Den Jo on 2020/10/31.
//

import Foundation

struct LocaleManager {
   
    // MARK: - Value
    // MARK: Public
    /// "ko-US" → "ko"
    static var languageCode: String? {
        guard var splits = Locale.preferredLanguages.first?.split(separator: "-"), let first = splits.first else { return nil }
        guard 1 < splits.count else { return String(first) }
        splits.removeLast()
        return String(splits.joined(separator: "-"))
    }
    
    static var locale: Locale? {
        guard let languageCode = languageCode else { return nil }
        return Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.languageCode.rawValue : languageCode]))
    }
}
