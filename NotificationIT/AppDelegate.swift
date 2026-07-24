// 원본 ios/Runner/AppDelegate.swift + main.dart 의 Firebase 초기화 대응
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure() // ✅ 반드시 맨 위에서 호출

        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        Messaging.messaging().delegate = self

        return true
    }

    // APNs 토큰 등록
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // FCM 토큰 갱신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔑 FCM registration token: \(fcmToken ?? "")")
    }
}
