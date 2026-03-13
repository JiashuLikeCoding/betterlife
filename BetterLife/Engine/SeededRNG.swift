import Foundation
import CryptoKit

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64*
        var x = state
        x &+= 0x9E3779B97F4A7C15
        x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9
        x = (x ^ (x >> 27)) &* 0x94D049BB133111EB
        x = x ^ (x >> 31)
        state = x
        return x
    }
}

enum Seed {
    static func boardSeed(habitId: UUID, dateKey: String) -> (seedString: String, seed64: UInt64) {
        let raw = "\(habitId.uuidString)|\(dateKey)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        let hex = digest.compactMap { String(format: "%02x", $0) }.joined()
        // take first 16 hex chars -> 64-bit
        let prefix = String(hex.prefix(16))
        let seed64 = UInt64(prefix, radix: 16) ?? 0
        return (hex, seed64)
    }
}
