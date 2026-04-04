import Foundation

class CacheManager {
    static let shared = CacheManager()

    private var weightCache: NSMutableDictionary = [:]
    private var phoneticCache: NSMutableDictionary = [:]
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

    private var sharedFolder: String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        return ((paths[0] as NSString).appendingPathComponent("OmicronLab") as NSString).appendingPathComponent("Avro Keyboard")
    }

    func persist() {
        let weightPath = (sharedFolder as NSString).appendingPathComponent("weight.plist")
        weightCache.write(toFile: weightPath, atomically: true)
    }

    func string(forKey key: String) -> String? {
        return weightCache.object(forKey: key) as? String
    }

    func setString(_ string: String, forKey key: String) {
        weightCache.setObject(string, forKey: key as NSString)
    }

    func removeString(forKey key: String) {
        weightCache.removeObject(forKey: key)
    }

    func array(forKey key: String) -> [Any]? {
        return phoneticCache.object(forKey: key) as? [Any]
    }

    func setArray(_ array: [Any], forKey key: String) {
        phoneticCache.setObject(array as NSArray, forKey: key as NSString)
    }

    func removeAllBase() {
        recentBaseCache.removeAllObjects()
    }

    func base(forKey key: String) -> [Any]? {
        return recentBaseCache.object(forKey: key) as? [Any]
    }

    func setBase(_ base: [Any], forKey key: String) {
        recentBaseCache.setObject(base as NSArray, forKey: key as NSString)
    }
}
