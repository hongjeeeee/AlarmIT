// intro.dart 변환
import SwiftUI

struct IntroPage: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        // Scaffold white, 아이콘+타이틀 중앙 정렬
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                svgImage("assets/icons/알림it_icon.svg")
                    .frame(width: 60, height: 60)
                Spacer().frame(height: 10)
                Text("알림IT")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
        }
        .task {
            await onAppearLogic()
        }
    }

    // initState 의 addPostFrameCallback 로직
    private func onAppearLogic() async {
        _ = UserDefaults.standard // 원본 prefs 획득 (사용은 없음)

        let consented = await ConsentManager.isConsented()

        if !consented {
            // 아직 동의하지 않은 경우: 시트 표시
            let result = await ConsentManager.showPrivacyConsentSheet()

            if result == true {
                // ✅ 동의
                await ConsentManager.setConsented(true)
                await MainActor.run {
                    router.root = .initSelectPage1(skipSecond: false)
                }
            } else {
                // ❌ 닫기
                await MainActor.run {
                    router.root = .initSelectPage1(skipSecond: true)
                }
            }
        } else {
            // 이미 동의한 사용자 → 2단계까지 진행
            await MainActor.run {
                router.root = .initSelectPage1(skipSecond: false)
            }
        }
    }
}
