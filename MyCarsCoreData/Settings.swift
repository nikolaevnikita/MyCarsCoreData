//
//  Settings.swift
//  MyCarsCoreData
//
//  Created by Николаев Никита on 30.10.2020.
//  Copyright © 2020 Николаев Никита. All rights reserved.
//

import Foundation

final class Settings {
    static var dataObtained: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "dataObtained")
        } set {
            UserDefaults.standard.set(newValue, forKey: "dataObtained")
        }
    }
}
