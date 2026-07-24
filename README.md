# 알림IT - 울산대학교 학과 공지 알림 앱

<p align="center">
  <img src="docs/logo.png" alt="알림IT" width="120"/>
</p>

<p align="center">
  <strong>"놓치는 공지 없이" - 학과 공지를 모아서 알려주는 iOS 앱</strong>
</p>

---

## 소개

**알림IT**는 울산대학교 학과 공지를 한곳에서 확인하고, 새 공지를 푸시로 받아볼 수 있는 iOS 앱입니다.

학과 홈페이지를 일일이 들어가지 않아도 관심 있는 전공의 공지를 모아서 보여주고, 구독한 학과에 새 글이 올라오면 알림을 보냅니다.

기존 Flutter 앱을 SwiftUI로 다시 작성한 버전입니다.

## 주요 기능

### 1. 공지 모아보기
- 전공별 공지 목록을 최신순으로 제공
- 스크롤 시 다음 페이지 자동 로딩
- 중요 공지 / 필독 공지를 배지로 구분

### 2. 필터 & 검색
- 전체 / 중요 공지 / 북마크 3가지 필터
- 키워드 검색으로 원하는 공지 탐색

### 3. 공지 알림
- 학과별 알림 구독 (여러 개 선택 가능)
- FCM 기반 푸시 알림
- 알림 설정 화면에서 학과별 on/off

### 4. 북마크
- 관심 공지를 저장해두고 모아보기
- 기기에 로컬 저장

### 5. 원문 열람
- 앱 안에서 공지 원문 확인
- 사파리로 열어 공유·저장

## 화면

<p align="center">
  <img src="docs/screenshots/04-main.png" width="240" alt="공지 목록"/>
  <img src="docs/screenshots/05-bookmark.png" width="240" alt="북마크"/>
  <img src="docs/screenshots/06-alarm-settings.png" width="240" alt="알림 설정"/>
</p>

<p align="center">
  <sub>공지 목록 · 북마크 · 알림 설정</sub>
</p>

<p align="center">
  <img src="docs/screenshots/01-consent.png" width="240" alt="개인정보 동의"/>
  <img src="docs/screenshots/02-major-select.png" width="240" alt="전공 선택"/>
  <img src="docs/screenshots/03-alarm-major.png" width="240" alt="알림 받을 학과"/>
</p>

<p align="center">
  <sub>첫 실행: 개인정보 동의 · 전공 선택 · 알림 받을 학과</sub>
</p>

## 기술 스택

| 분류 | 기술 |
|------|------|
| **UI** | SwiftUI |
| **상태관리** | ObservableObject, @StateObject, @EnvironmentObject |
| **동시성** | Swift Concurrency (async/await, @MainActor) |
| **네트워킹** | URLSession |
| **푸시 알림** | Firebase Cloud Messaging, UserNotifications |
| **웹뷰** | WKWebView (UIViewRepresentable) |
| **로컬 저장** | UserDefaults |
| **빌드** | XcodeGen + CocoaPods |
| **최소 지원** | iOS 16.0+ |

## 프로젝트 구조

```
NotificationIT/
├── NotificationITApp.swift     # @main 엔트리
├── AppDelegate.swift           # Firebase 초기화, APNs 등록
├── AppRouter.swift             # 루트 화면 전환 (스플래시 → 온보딩 → 메인)
│
├── SplashScreen.swift          # 버전 체크, 강제 업데이트 안내
├── IntroPage.swift             # 동의 여부에 따른 분기
├── ConsentManager.swift        # 개인정보 동의 + 바텀시트
├── init_selecet_page.swift     # 전공 선택 (대표 전공 / 알림 학과)
│
├── mainPage.swift              # 공지 목록, 검색, 필터, 페이징
├── list_elements.swift         # 공지 셀
├── majorCategory.swift         # 전공 변경
├── alram.swift                 # 알림 설정
├── webView.swift               # 공지 원문
│
├── ApiService.swift            # REST 호출 + Notice 모델
├── BookmarkManager.swift       # 북마크 저장
├── NotificationService.swift   # 로컬 알림, 권한, 디바이스 ID
├── FcmMessaging.swift          # FCM / APNs 토큰
├── Helpers.swift               # 색상, SVG 에셋, URL 열기
│
└── Assets.xcassets/            # 아이콘(SVG 벡터) 및 앱 아이콘
```

## 아키텍처

```
┌──────────────┐
│     View     │  SwiftUI 화면
├──────────────┤
│  ViewModel   │  상태 관리 (@Published, @MainActor)
├──────────────┤
│  ApiService  │  API 호출 (async/await)
├──────────────┤
│   Backend    │  공지 수집 서버
└──────────────┘
```

화면 전환은 `AppRouter`가 담당합니다. 스플래시에서 온보딩 또는 메인으로 루트를 통째로 교체하는 흐름이라, `NavigationStack`과 별개로 루트 상태를 두고 관리합니다.

## 실행 방법

### 사전 요구사항
- Xcode 16.0+
- CocoaPods
- iOS 16.0+ 디바이스 또는 시뮬레이터

### 빌드 & 실행

```bash
# 1. 워크스페이스 열기 (.xcworkspace로 열어야 합니다)
open NotificationIT.xcworkspace
```

`Pods/`가 포함되어 있어 바로 빌드됩니다. 프로젝트 파일을 새로 만들 경우:

```bash
# 1. Xcode 프로젝트 생성
xcodegen generate

# 2. Pod 설치 (LANG 필수)
LANG=en_US.UTF-8 pod install

# 3. 워크스페이스 열기
open NotificationIT.xcworkspace
```

> **참고:** `.xcodeproj`가 아닌 `.xcworkspace`로 열어야 CocoaPods 의존성이 정상적으로 로드됩니다.

> **참고:** `pod install` 앞의 `LANG`은 생략하면 안 됩니다. 에셋 파일명이 한글이라 로케일이 UTF-8이 아니면 CocoaPods가 인코딩 오류로 중단됩니다.

### 실기기 배포
Signing & Capabilities에서 **Push Notifications**와 **Background Modes → Remote notifications**를 활성화해야 합니다. 번들 ID는 `com.uou.alarmit`입니다.

## 화면 구성

| 화면 | 설명 |
|------|------|
| 스플래시 | 앱 버전 확인, 강제/권장 업데이트 안내 |
| 온보딩 | 개인정보 동의 → 대표 전공 선택 → 알림 받을 학과 선택 |
| 공지 목록 | 전체 / 중요 공지 / 북마크 필터, 검색, 무한 스크롤 |
| 전공 변경 | 공지를 확인할 대표 전공 변경 |
| 알림 설정 | 학과별 알림 구독 on/off |
| 공지 원문 | 웹뷰로 공지 확인, 사파리로 열기 |

## 참고 사항

**서버 파라미터** — 공지 목록은 `type` 값으로 필터링됩니다. `전체`는 모든 공지, `공지`는 중요 공지만 반환합니다.

**URL 인코딩** — 쿼리에 한글이 포함되지만 별도로 인코딩하면 안 됩니다. `URL(string:)`이 처리하므로, 미리 퍼센트 인코딩하면 `%`가 중복 인코딩되어 요청이 깨집니다.

**첫 실행 화면 확인** — 시뮬레이터는 앱을 삭제해도 `cfprefsd`가 `UserDefaults`를 캐싱해 온보딩이 다시 표시되지 않습니다. 기기를 초기화해야 합니다.

```bash
xcrun simctl shutdown all && xcrun simctl erase all
```

**미사용 코드** — `GET_notice.swift`, `keyword.swift`, `mainPage.swift`의 `showPrivacyConsentBottomSheet`는 원본 Flutter 코드에도 존재하지만 호출되지 않습니다. 변환 시 함께 옮겨두었습니다.

## 팀 정보

울산대학교 ICT융합학부 프로젝트로 개발되었습니다.
