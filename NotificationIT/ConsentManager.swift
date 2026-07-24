// consent_manager.dart 변환
import SwiftUI
import UIKit

enum ConsentManager {
    static func isConsented() async -> Bool {
        let p = UserDefaults.standard
        return p.object(forKey: kConsentKey) as? Bool ?? false
    }

    static func setConsented(_ v: Bool) async {
        let p = UserDefaults.standard
        p.set(v, forKey: kConsentKey)
    }

    /// ✅ 개인정보 동의 팝업
    /// showModalBottomSheet<bool>(...) 와 동일하게 결과(true/false/nil)를 await 로 반환한다.
    @MainActor
    static func showPrivacyConsentSheet(
        policyUrl: String = "https://leekuejea.github.io/alarmIT/"
    ) async -> Bool? {
        guard let topVC = Self.topViewController() else { return nil }

        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool?, Never>) in
            var didResume = false
            weak var hostRef: UIViewController?

            let finish: (Bool?) -> Void = { result in
                guard !didResume else { return }
                didResume = true
                hostRef?.dismiss(animated: true) {
                    continuation.resume(returning: result)
                }
            }

            let sheet = ConsentSheetView(policyUrl: policyUrl, onResult: finish)
            let host = UIHostingController(rootView: sheet)
            hostRef = host
            host.view.backgroundColor = .white
            host.isModalInPresentation = true // isDismissible:false, enableDrag:false
            if let presentation = host.sheetPresentationController {
                presentation.detents = [.medium(), .large()]
                presentation.preferredCornerRadius = 24
                presentation.prefersGrabberVisible = false
            }
            topVC.present(host, animated: true)
        }
    }

    // 최상단 뷰 컨트롤러 탐색
    @MainActor
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        var top = windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

/// showPrivacyConsentSheet 내부 UI (원본 StatefulBuilder Column)
struct ConsentSheetView: View {
    let policyUrl: String
    let onResult: (Bool?) -> Void

    @State private var checked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 25)
            Text("알림IT 이용을 위해")
                .font(.system(size: 25, weight: .bold))
            Text("동의가 필요해요")
                .font(.system(size: 25, weight: .bold))
            Spacer().frame(height: 16)

            HStack(alignment: .center, spacing: 0) {
                Button {
                    checked.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(checked ? Color(argb: 0xff009D72) : Color(argb: 0xFFBDBDBD), lineWidth: 1.5)
                            .background(Circle().fill(checked ? Color(argb: 0xff009D72) : Color.clear))
                            .frame(width: 25, height: 25)
                        if checked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer().frame(width: 5)
                Text("개인정보 처리 동의")
                    .font(.system(size: 18))
                Spacer()
                Button {
                    if UrlLauncher.canLaunch(policyUrl) {
                        UrlLauncher.launch(policyUrl)
                    }
                } label: {
                    Text("[자세히보기]")
                        .font(.system(size: 18))
                        .foregroundColor(Color(argb: 0xff878787))
                }
            }

            Spacer().frame(height: 50)

            HStack(spacing: 12) {
                Button {
                    onResult(false)
                } label: {
                    Text("닫기")
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(argb: 0xffE9E9E9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color(argb: 0xffE0E0E0), lineWidth: 1)
                        )
                }

                Button {
                    if checked { onResult(true) }
                } label: {
                    Text("다음")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(checked ? Color(argb: 0xff009D72) : Color(argb: 0xffBDBDBD))
                }
                .disabled(!checked)
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}
