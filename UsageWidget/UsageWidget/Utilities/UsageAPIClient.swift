import Foundation

struct UsageData {
    struct Window {
        let utilization: Double // 0-100 percentage
        let resetsAt: Date?
    }

    var fiveHour: Window?
    var sevenDay: Window?
    var sevenDaySonnet: Window?
    var sevenDayOpus: Window?
    var lastFetched: Date = Date()
}

final class UsageAPIClient {
    private let keychainService = "Claude Code-credentials"

    func fetchUsage() async -> UsageData? {
        guard let token = readTokenFromKeychain() else {
            print("UsageAPIClient: No token found in Keychain")
            return nil
        }

        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("claude-code/2.1.50", forHTTPHeaderField: "User-Agent")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("UsageAPIClient: HTTP \(code)")
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            return parseResponse(json)
        } catch {
            print("UsageAPIClient: \(error)")
            return nil
        }
    }

    // MARK: - Private

    private func readTokenFromKeychain() -> String? {
        // Use `security` CLI to read keychain — avoids needing code signing / entitlements
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", keychainService, "-w"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("UsageAPIClient: security CLI failed: \(error)")
            return nil
        }

        guard process.terminationStatus == 0 else {
            print("UsageAPIClient: security CLI exit \(process.terminationStatus)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let hexString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hexString.isEmpty else {
            return nil
        }

        // The output is hex-encoded — decode it
        if let hexDecoded = hexDecode(hexString),
           let str = String(data: hexDecoded, encoding: .utf8) {
            return extractToken(from: str)
        }

        // Might be raw JSON
        return extractToken(from: hexString)
    }

    private func extractToken(from string: String) -> String? {
        guard let startIdx = string.firstIndex(of: "{") else { return nil }
        let jsonStr = String(string[startIdx...])

        let decoder = JSONDecoder()
        // Use raw_decode equivalent: find matching brace
        var depth = 0
        var endIdx = jsonStr.startIndex
        for (i, char) in jsonStr.enumerated() {
            if char == "{" { depth += 1 }
            else if char == "}" {
                depth -= 1
                if depth == 0 {
                    endIdx = jsonStr.index(jsonStr.startIndex, offsetBy: i + 1)
                    break
                }
            }
        }

        let fragment = String(jsonStr[jsonStr.startIndex..<endIdx])
        guard let data = fragment.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["accessToken"] as? String else {
            return nil
        }
        return token
    }

    private func hexDecode(_ hex: String) -> Data? {
        let cleanHex = hex.filter { $0.isHexDigit }
        guard cleanHex.count % 2 == 0 else { return nil }

        var data = Data()
        var index = cleanHex.startIndex
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            guard let byte = UInt8(cleanHex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        return data
    }

    private func parseResponse(_ json: [String: Any]) -> UsageData {
        var usage = UsageData()

        if let fiveHour = json["five_hour"] as? [String: Any] {
            usage.fiveHour = parseWindow(fiveHour)
        }
        if let sevenDay = json["seven_day"] as? [String: Any] {
            usage.sevenDay = parseWindow(sevenDay)
        }
        if let sonnet = json["seven_day_sonnet"] as? [String: Any] {
            usage.sevenDaySonnet = parseWindow(sonnet)
        }
        if let opus = json["seven_day_opus"] as? [String: Any] {
            usage.sevenDayOpus = parseWindow(opus)
        }

        return usage
    }

    private func parseWindow(_ dict: [String: Any]) -> UsageData.Window? {
        guard let utilization = dict["utilization"] as? Double else { return nil }
        var resetDate: Date?
        if let resetStr = dict["resets_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            resetDate = formatter.date(from: resetStr)
            if resetDate == nil {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                resetDate = formatter.date(from: resetStr)
            }
        }
        return UsageData.Window(utilization: utilization, resetsAt: resetDate)
    }
}
