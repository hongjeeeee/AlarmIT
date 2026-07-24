// main.dart 의 로컬 알림 / FCM 권한 / 디바이스 정보 관련 전역 함수 변환
import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging

/// flutter_local_notifications 의 전역 플러그인 대응 (UNUserNotificationCenter)
let flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin()

/// flutter_local_notifications 플러그인 래퍼.
/// 원본에서 사용하는 initialize / show 인터페이스를 최소 대응한다.
final class FlutterLocalNotificationsPlugin {
    /// initialize(InitializationSettings, onDidReceiveNotificationResponse:)
    func initialize(onDidReceiveNotificationResponse: ((String?) -> Void)? = nil) {
        NotificationDelegate.shared.onDidReceiveNotificationResponse = onDidReceiveNotificationResponse
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    /// show(id, title, body, details, payload:)
    func show(_ id: Int, _ title: String?, _ body: String?, payload: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title ?? "제목 없음"
        content.body = body ?? "내용 없음"
        content.sound = .default
        if let payload = payload {
            content.userInfo = ["link": payload]
        }
        let request = UNNotificationRequest(
            identifier: "\(id)",
            content: content,
            trigger: nil // 즉시 표시
        )
        UNUserNotificationCenter.current().add(request)
    }
}

/// UNUserNotificationCenterDelegate + 알림 클릭 payload 콜백
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    var onDidReceiveNotificationResponse: ((String?) -> Void)?

    // 포그라운드 표시 (AppDelegate.willPresent 대응)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 클릭 시 payload 전달
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = response.notification.request.content.userInfo["link"] as? String
        onDidReceiveNotificationResponse?(payload)
        completionHandler()
    }
}

/// iOS 로컬 알림 권한 요청 (원본 requestLocalNotificationPermissions)
func requestLocalNotificationPermissions() async {
    do {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    } catch {
        print("로컬 알림 권한 요청 실패: \(error)")
    }
}

/// ✅ 부팅 시 UserDefaults 상태 확인 (디버그용) (원본 debugPrefsAtBoot)
func debugPrefsAtBoot() async {
    let prefs = UserDefaults.standard
    print("🔎 [BOOT] keys=\(prefs.dictionaryRepresentation().keys)")
    print("🔎 [BOOT] hasSeenIntro=\(prefs.object(forKey: "hasSeenIntro") as? Bool as Any)")
}

/// 로컬 알림 초기화 (원본 _initLocalNotifications)
func _initLocalNotifications() async {
    flutterLocalNotificationsPlugin.initialize()
}

/// FCM 권한 요청 (원본 _requestFcmPermissions)
func _requestFcmPermissions() async {
    do {
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        print("🔔 FCM 권한 상태: \(granted)")
    } catch {
        print("🔔 FCM 권한 요청 실패: \(error)")
    }
}

/// device_info_plus 의 identifierForVendor 대응 (원본 getDeviceId)
func getDeviceId() async -> String {
    // Platform.isIOS 분기 → iOS 고정
    return await MainActor.run {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown_ios_id"
    }
}
