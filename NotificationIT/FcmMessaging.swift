// firebase_messaging 의 FirebaseMessaging.instance 관련 API 래퍼
import Foundation
import FirebaseMessaging
import UserNotifications

enum FcmMessaging {
    /// FirebaseMessaging.instance.getToken()
    static func getToken() async throws -> String? {
        return try await Messaging.messaging().token()
    }

    /// FirebaseMessaging.instance.getAPNSToken()
    static func getAPNSToken() async -> String? {
        guard let data = Messaging.messaging().apnsToken else { return nil }
        return data.map { String(format: "%02x", $0) }.joined()
    }

    /// FirebaseMessaging.instance.requestPermission(alert:badge:sound:)
    /// → 권한 요청 후 authorizationStatus 반환
    @discardableResult
    static func requestPermission(alert: Bool = true, badge: Bool = true, sound: Bool = true) async -> UNAuthorizationStatus {
        var options: UNAuthorizationOptions = []
        if alert { options.insert(.alert) }
        if badge { options.insert(.badge) }
        if sound { options.insert(.sound) }
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            print("requestPermission 실패: \(error)")
        }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}
