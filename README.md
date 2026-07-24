# NotificationIT (알림IT) — Swift 변환본

`lib/` 아래 Flutter(Dart) 코드를 **네이티브 Swift(SwiftUI)** 로 1:1 변환한 결과물입니다.
Flutter에 있던 코드만 직접 옮겼으며, 원본에 없는 기능은 추가하지 않았습니다.

## 파일 매핑 (Dart → Swift)

| Flutter (lib/) | Swift (NotificationIT/) | 내용 |
|---|---|---|
| `main.dart` | `NotificationITApp.swift`, `AppDelegate.swift` | 앱 진입점, Firebase/로컬알림/FCM 초기화 |
| `keys.dart` | `Keys.swift` | 전역 상수 |
| `firebase_options.dart` | `FirebaseOptions.swift` | Firebase 옵션 |
| `splashScreen.dart` | `SplashScreen.swift` | 스플래시 + 버전 체크/업데이트 다이얼로그 |
| `intro.dart` | `IntroPage.swift` | 인트로 → 동의 → 전공선택 분기 |
| `consent_manager.dart` | `ConsentManager.swift` | 개인정보 동의 관리 + 동의 시트 |
| `init_selecet_page.dart` | `init_selecet_page.swift` | InitSelectPage1 / InitSelectPage2 |
| `api_service.dart` | `ApiService.swift` | REST API + `Notice` 모델 |
| `mainPage.dart` | `mainPage.swift` | 메인 화면(공지 목록/검색/필터/북마크/FCM) |
| `webView.dart` | `webView.swift` | WKWebView 화면 |
| `alram.dart` | `alram.swift` | 알림 설정 화면 |
| `majorCategory.dart` | `majorCategory.swift` | 대표 전공 변경 화면 |
| `list_elements.dart` | `list_elements.swift`, `BookmarkManager.swift` | 공지 셀 위젯 + 북마크 매니저 |
| `GET_notice.dart` | `GET_notice.swift` | (미사용) Notice 모델 — 네임스페이스로 보존 |
| `keyword.dart` | `keyword.swift` | (미사용) 키워드 알림 화면 |
| — | `AppRouter.swift` | `Navigator.pushReplacement` 루트 전환 대응 |
| — | `NotificationService.swift` | 로컬알림/권한/디바이스ID 전역 함수 |
| — | `FcmMessaging.swift` | FirebaseMessaging 토큰/APNs 래퍼 |
| — | `Helpers.swift` | `Color(0x..)`, SVG 에셋, URL 실행 헬퍼 |

## Flutter 패키지 → iOS 대응

| Flutter 패키지 | iOS 대응 |
|---|---|
| `shared_preferences` | `UserDefaults` |
| `flutter_local_notifications` | `UNUserNotificationCenter` |
| `firebase_core` / `firebase_messaging` | `FirebaseCore` / `FirebaseMessaging` |
| `device_info_plus` (identifierForVendor) | `UIDevice.current.identifierForVendor` |
| `package_info_plus` | `Bundle.main` (CFBundleShortVersionString) |
| `url_launcher` | `UIApplication.shared.open` |
| `webview_flutter` | `WKWebView` (`UIViewRepresentable`) |
| `flutter_svg` (`SvgPicture.asset`) | 에셋 카탈로그(벡터 보존) + `Image(_:)` |
| `http` | `URLSession` |

## 빌드 방법 (검증됨 ✅)

이 저장소에는 이미 `pod install` 이 완료된 상태(`NotificationIT.xcworkspace`, `Pods/`)가 포함되어 있어
바로 빌드할 수 있습니다. 아래 절차로 **BUILD SUCCEEDED** 를 확인했습니다 (Xcode 26.2, Firebase 12.16.0).

### 바로 빌드
```bash
cd NotificationIT-Swift
open NotificationIT.xcworkspace   # Xcode 에서 실행
```
또는 커맨드라인:
```bash
cd NotificationIT-Swift
xcodebuild -workspace NotificationIT.xcworkspace -scheme NotificationIT \
  -destination 'generic/platform=iOS Simulator' build
```

### 프로젝트를 처음부터 다시 생성할 경우
`.xcodeproj` / `Pods/` 를 지우고 다시 만들려면:
```bash
brew install xcodegen           # 최초 1회
cd NotificationIT-Swift
xcodegen generate               # project.yml → NotificationIT.xcodeproj
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8   # ⚠️ 경로에 한글 자산명이 있어 필수
pod install                     # Podfile → NotificationIT.xcworkspace + Pods/
xcodebuild -workspace NotificationIT.xcworkspace -scheme NotificationIT \
  -destination 'generic/platform=iOS Simulator' build
```
> Firebase 는 `Podfile` 로 주입합니다(`FirebaseCore`, `FirebaseMessaging`). SPM(Swift Package Manager)
> 으로 붙이려면 Xcode GUI 에서 `https://github.com/firebase/firebase-ios-sdk` 를 추가하고 두 라이브러리를 링크하세요.

### 실기기 배포 시
- Signing & Capabilities: **Push Notifications**, **Background Modes → Remote notifications** 활성화 (이미 `NotificationIT.entitlements` 에 `aps-environment` 포함).
- Bundle Identifier: `com.uou.alarmit`.

## 배포 타깃
- iOS **16.0+** (`NavigationStack`, `sheetPresentationController` 사용)

## 원본 그대로 보존한 부분(의도된 quirk)
- `splashScreen.dart` 는 `assets/icons/알림it_splash_image.svg` 를 참조하지만 실제 파일명은 `알림it_splash_icon.svg` 입니다. 원본 코드의 참조를 그대로 유지했으므로 스플래시 이미지는 원본과 동일하게 렌더링되지 않습니다.
- `GET_notice.dart`, `keyword.dart`, `mainPage.dart` 의 `showPrivacyConsentBottomSheet` 는 원본에서도 다른 코드가 사용하지 않는 미사용 코드이지만, "모든 코드 변환" 요구에 따라 함께 변환했습니다.
