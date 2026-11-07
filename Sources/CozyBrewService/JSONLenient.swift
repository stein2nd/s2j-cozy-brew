import Foundation

/// Homebrew JSON で文字列と数値が混在するフィールド向けのデコード補助
enum JSONLenient {
    static func decodeString(from container: SingleValueDecodingContainer) -> String? {
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decode(Int.self) {
            return String(value)
        }
        if let value = try? container.decode(Double.self) {
            if value.rounded(.towardZero) == value {
                return String(Int(value))
            }
            return String(value)
        }
        if let value = try? container.decode(Bool.self) {
            return value ? "true" : "false"
        }
        if container.decodeNil() {
            return nil
        }
        return nil
    }

    static func decodeString<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> String? {
        guard container.contains(key) else { return nil }
        if let nested = try? container.decode(String.self, forKey: key) {
            return nested
        }
        if let nested = try? container.decode(Int.self, forKey: key) {
            return String(nested)
        }
        if let nested = try? container.decode(Double.self, forKey: key) {
            if nested.rounded(.towardZero) == nested {
                return String(Int(nested))
            }
            return String(nested)
        }
        if (try? container.decodeNil(forKey: key)) == true {
            return nil
        }
        return nil
    }

    static func decodeStringArray<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> [String]? {
        guard container.contains(key),
              var nested = try? container.nestedUnkeyedContainer(forKey: key)
        else {
            return nil
        }
        var values: [String] = []
        while !nested.isAtEnd {
            guard let itemDecoder = try? nested.superDecoder(),
                  let single = try? itemDecoder.singleValueContainer(),
                  let value = decodeString(from: single)
            else {
                continue
            }
            values.append(value)
        }
        return values
    }
}
