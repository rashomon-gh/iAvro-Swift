import Foundation

/// Manages in-memory and on-disk caching of suggestion data.
///
/// Three separate caches are maintained:
/// - **weightCache**: Persists the user's previously selected suggestion for each input term.
///   Written to `~/Library/Application Support/OmicronLab/Avro Keyboard/weight.plist`.
/// - **phoneticCache**: In-memory cache of suggestion lists keyed by Romanized input.
/// - **recentBaseCache**: In-memory cache tracking suffix-combination base words.
class CacheManager {
    static let shared = CacheManager()

    /// Persisted weight selections (input → selected Bengali word).
    private var weightCache: NSMutableDictionary = [:]

    /// Cached phonetic suggestion lists (input → array of Bengali candidates).
    private var phoneticCache: NSMutableDictionary = [:]

    /// Tracks base word + suffix mappings for the current suggestion session.
    private var recentBaseCache: NSMutableDictionary = [:]

    private init() {
        let path = sharedFolder
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }

        let weightPath = (path as NSString).appendingPathComponent("weight.plist")
        if fileManager.fileExists(atPath: weightPath),
           let dict = NSMutableDictionary(contentsOfFile: weightPath) {
            weightCache = dict
        }
    }

    /// The directory used for persistent storage.
    private var sharedFolder: String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        return ((paths[0] as NSString).appendingPathComponent("OmicronLab") as NSString).appendingPathComponent("Avro Keyboard")
    }

    /// Persists the weight cache to disk.
    func persist() {
        let weightPath = (sharedFolder as NSString).appendingPathComponent("weight.plist")
        weightCache.write(toFile: weightPath, atomically: true)
    }

    /// Retrieves a previously selected Bengali word for the given input term.
    ///
    /// - Parameter key: The Romanized input term.
    /// - Returns: The selected Bengali word, or `nil` if none was cached.
    func string(forKey key: String) -> String? {
        return weightCache.object(forKey: key) as? String
    }

    /// Records the user's selected Bengali word for the given input term.
    ///
    /// - Parameters:
    ///   - string: The Bengali word the user selected.
    ///   - key: The Romanized input term.
    func setString(_ string: String, forKey key: String) {
        weightCache.setObject(string, forKey: key as NSString)
    }

    /// Removes the cached selection for the given input term.
    func removeString(forKey key: String) {
        weightCache.removeObject(forKey: key)
    }

    /// Retrieves a cached suggestion list for the given input term.
    ///
    /// - Parameter key: The Romanized input term.
    /// - Returns: An array of cached suggestion candidates, or `nil` if none cached.
    func array(forKey key: String) -> [Any]? {
        return phoneticCache.object(forKey: key) as? [Any]
    }

    /// Caches a suggestion list for the given input term.
    ///
    /// - Parameters:
    ///   - array: The list of suggestion candidates.
    ///   - key: The Romanized input term.
    func setArray(_ array: [Any], forKey key: String) {
        phoneticCache.setObject(array as NSArray, forKey: key as NSString)
    }

    /// Clears all suffix-combination base entries for the current suggestion session.
    func removeAllBase() {
        recentBaseCache.removeAllObjects()
    }

    /// Retrieves the base word information for a suffix-combined suggestion.
    ///
    /// - Parameter key: The suffix-combined Bengali word.
    /// - Returns: An array containing `[baseTerm, baseWord]`, or `nil` if not tracked.
    func base(forKey key: String) -> [Any]? {
        return recentBaseCache.object(forKey: key) as? [Any]
    }

    /// Records the base word information for a suffix-combined suggestion.
    ///
    /// - Parameters:
    ///   - base: An array containing `[baseTerm, baseWord]`.
    ///   - key: The suffix-combined Bengali word.
    func setBase(_ base: [Any], forKey key: String) {
        recentBaseCache.setObject(base as NSArray, forKey: key as NSString)
    }
}
