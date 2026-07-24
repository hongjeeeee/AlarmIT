// api_service.dart 변환
import Foundation

/// 원본 Exception 대응용 에러 타입
struct ApiError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
    init(_ message: String) { self.message = message }
}

/// 원본 lib/api_service.dart 의 ApiService
class ApiService {
    let url: String

    init(url: String) {
        self.url = url
    }

    /// 버전 체크
    func checkAppVersion() async throws -> [String: String] {
        let platform = "ios"  // 타입 고정
        let versionUrl = "\(url)/api/version/\(platform)"

        print("\n📡 [버전 확인 요청]")
        print("🌐 요청 URL: \(versionUrl)")

        do {
            guard let requestUrl = URL(string: versionUrl) else {
                throw ApiError("잘못된 URL: \(versionUrl)")
            }
            let (data, response) = try await URLSession.shared.data(from: requestUrl)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

            print("🔵 상태코드: \(statusCode)")
            print("📨 응답 바디: \(String(data: data, encoding: .utf8) ?? "")")

            if statusCode == 200 {
                guard let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw ApiError("JSON 파싱 실패")
                }

                if let isSuccess = jsonData["isSuccess"] as? Bool, isSuccess == false {
                    throw ApiError("버전 정보 요청 실패: \(jsonData["message"] ?? "")")
                }

                let result = jsonData["result"] as! [String: Any]
                let latest = result["latestVersion"] as! String
                let minimum = result["minimumVersion"] as! String
                let link = result["link"] as! String

                print("✅ 최신 버전: \(latest) / 최소 버전: \(minimum)")

                return [
                    "latestVersion": latest,
                    "minimumVersion": minimum,
                    "link": link,
                ]
            } else {
                throw ApiError("HTTP 오류: \(statusCode)")
            }
        } catch {
            throw ApiError("버전 확인 중 오류 발생: \(error)")
        }
    }

    /// 공지 불러오기
    func fetchNotices() async throws -> [Notice] {
        do {
            guard let requestUrl = URL(string: url) else {
                throw ApiError("잘못된 URL: \(url)")
            }
            let (data, response) = try await URLSession.shared.data(from: requestUrl)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

            if statusCode == 200 {
                // UTF-8 디코딩 적용
                guard let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw ApiError("JSON 파싱 실패")
                }

                if let isSuccess = jsonData["isSuccess"] as? Bool, isSuccess == false {
                    throw ApiError("API 요청 실패: \(jsonData["message"] ?? "")")
                }

                let result = jsonData["result"] as! [String: Any]
                let contentList = result["content"] as! [[String: Any]]

                return contentList.map { Notice.fromJson($0) }
            } else {
                throw ApiError("HTTP 오류: \(statusCode)")
            }
        } catch {
            throw ApiError("API 오류: \(error)")
        }
    }

    /// fcm 등록
    @discardableResult
    func postFCMToken(_ deviceId: String, _ fcmToken: String) async throws -> Any {
        print("\n📡 [FCM 등록 요청]")
        print("📱 deviceId: \(deviceId)")
        print("🔑 fcmToken: \(fcmToken)")

        guard let requestUrl = URL(string: url) else {
            throw ApiError("잘못된 URL: \(url)")
        }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "deviceId": deviceId,
            "fcmToken": fcmToken,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        print("🔵 상태코드: \(statusCode)")
        print("📨 응답 바디: \(String(data: data, encoding: .utf8) ?? "")")

        if statusCode == 200 || statusCode == 201 {
            print("✅ FCM 토큰 등록 성공")
            return try JSONSerialization.jsonObject(with: data)
        } else {
            print("❌ FCM 토큰 등록 실패")
            throw ApiError("HTTP 오류: \(statusCode)")
        }
    }

    /// 공지알람 구독
    @discardableResult
    func subscribeNotice(_ deviceId: String, _ major: String) async throws -> [String: Any] {
        print("\n📡 [전공 구독 요청]")
        print("📱 deviceId: \(deviceId)")
        print("📘 major: \(major)")

        do {
            guard let requestUrl = URL(string: url) else {
                throw ApiError("잘못된 URL: \(url)")
            }
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "deviceId": deviceId,
                "major": major,
            ])

            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

            print("🔵 상태코드: \(statusCode)")
            print("📨 응답 바디: \(String(data: data, encoding: .utf8) ?? "")")

            if statusCode == 200 || statusCode == 201 {
                print("✅ 전공 구독 성공")
                return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            } else {
                print("❌ 전공 구독 실패")
                throw ApiError("HTTP 오류: \(statusCode)")
            }
        } catch {
            print("❌ 예외 발생: \(error)")
            throw ApiError("API 오류: \(error)")
        }
    }

    /// 공지알람 해제
    func unsubscribeNotice(_ deviceId: String, _ major: String) async throws {
        print("\n📡 [전공 구독 해제 요청]")
        print("📱 deviceId: \(deviceId)")
        print("📘 major: \(major)")

        do {
            guard let requestUrl = URL(string: url) else {
                throw ApiError("잘못된 URL: \(url)")
            }
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "deviceId": deviceId,
                "major": major,
            ])

            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

            print("🔵 상태코드: \(statusCode)")
            print("📨 응답 바디: \(String(data: data, encoding: .utf8) ?? "")")

            if statusCode == 200 {
                print("✅ 전공 구독 해제 성공")
            } else {
                print("❌ 전공 구독 해제 실패")
                throw ApiError("HTTP 오류: \(statusCode)")
            }
        } catch {
            print("❌ 예외 발생: \(error)")
            throw ApiError("API 오류: \(error)")
        }
    }
}

/// 원본 lib/api_service.dart 의 Notice
struct Notice: Identifiable {
    let id: Int
    let title: String
    let date: String
    let link: String
    let type: String
    let major: String

    init(id: Int, title: String, date: String, link: String, type: String, major: String) {
        self.id = id
        self.title = title
        self.date = date
        self.link = link
        self.type = type
        self.major = major
    }

    static func fromJson(_ json: [String: Any]) -> Notice {
        return Notice(
            id: json["id"] as! Int,
            title: (json["title"] as? String) ?? "제목 없음",
            date: (json["date"] as? String) ?? "날짜 없음",
            link: (json["link"] as? String) ?? "링크 없음",
            type: json["type"] as! String,
            major: json["major"] as! String
        )
    }
}
