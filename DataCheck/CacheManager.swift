//
//  CacheManager.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import Foundation

class CacheManager {
    static let shared = CacheManager()
    private let userDefaults = UserDefaults.standard

    private init() {}

    func saveData<T: Codable>(_ data: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(data) {
            userDefaults.set(encodedData, forKey: key)
        }
    }

    func loadData<T: Codable>(forKey key: String) -> T? {
        if let savedData = userDefaults.object(forKey: key) as? Data {
            let decoder = JSONDecoder()
            if let loadedData = try? decoder.decode(T.self, from: savedData) {
                return loadedData
            }
        }
        return nil
    }
}
