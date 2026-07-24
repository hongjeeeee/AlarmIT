// keys.dart 변환
import Foundation

/// 전역 상수 (원본 lib/keys.dart)
enum Keys {
    static let version = "1.0.1"
    static let kHasSeenIntro = "hasSeenIntro"
    static let kConsentKey = "privacy_consent_v1"
    static let port = "https://uou.alarm.it.kr"
    static let kAlarmListKey = "alram_list"        // 선택한 학부/전공 리스트
    static let kIsAllAlarmOnKey = "isAllAlarmOn"   // 전체 알림 스위치 상태
    static let kMainMajorKey = "main_major"        // Page1: 대표 전공(1개)
    static let kAlarmMajorsKey = "alarm_majors"    // Page2: 알림 받을 전공들(여러개)
    static let isBell = false
}

/// 원본 Dart 전역 상수를 그대로 노출 (import 편의)
let version = Keys.version
let KHasSeenIntro = Keys.kHasSeenIntro
let kConsentKey = Keys.kConsentKey
let port = Keys.port
let kAlarmListKey = Keys.kAlarmListKey
let kIsAllAlarmOnKey = Keys.kIsAllAlarmOnKey
let kMainMajorKey = Keys.kMainMajorKey
let kAlarmMajorsKey = Keys.kAlarmMajorsKey
let isBell = Keys.isBell
