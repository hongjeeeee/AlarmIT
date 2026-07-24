// main.dart 변환 (앱 진입점)
import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct NotificationITApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            // MaterialApp(home: SplashScreen()) → 앱 시작은 항상 스플래시
            RootView()
                .environmentObject(router)
                .task {
                    await bootSequence()
                }
        }
    }

    /// 원본 main() 의 초기화 순서 (Firebase 초기화는 AppDelegate 에서 선행)
    private func bootSequence() async {
        // ✅ 디버그 모드에서만 prefs 로그 출력
        #if DEBUG
        await debugPrefsAtBoot()
        #endif

        // 로컬 알림 초기화
        await _initLocalNotifications()

        // iOS 로컬 알림 권한 요청
        await requestLocalNotificationPermissions()

        // FCM 권한 요청
        await _requestFcmPermissions()
    }
}

/// MaterialApp 의 home(SplashScreen) 및 Navigator.pushReplacement 라우팅 대응 루트
struct RootView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        // title: '알림IT', theme: primarySwatch green
        switch router.root {
        case .splash:
            SplashScreen()
        case .intro:
            IntroPage()
        case .initSelectPage1(let skipSecond):
            InitSelectPage1(skipSecond: skipSecond)
        case .main(let selectedMajor, let selectedAlram, let changeMajor):
            MainPage(selectedMajor: selectedMajor, selectedAlram: selectedAlram, changeMajor: changeMajor)
        }
    }
}
