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
        // 화면 전환 직후에는 표시할 뷰컨트롤러가 아직 window 에 붙지 않아
        // 시트가 조용히 건너뛰어질 수 있으므로 준비될 때까지 잠시 기다린다.
        var presenter: UIViewController?
        for _ in 0..<30 {
            if let vc = Self.topViewController(),
               vc.viewIfLoaded?.window != nil,
               vc.presentedViewController == nil {
                presenter = vc
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        }
        guard let topVC = presenter else { return nil }

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

            // 내용 높이에 딱 맞게 시트 크기 결정 (medium detent 는 아래 빈 공간이 크게 남음)
            let width = topVC.view.bounds.width
            let fitting = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
            let bottomInset = topVC.view.window?.safeAreaInsets.bottom ?? 0
            let sheetHeight = fitting.height + bottomInset

            if let presentation = host.sheetPresentationController {
                presentation.detents = [.custom { _ in sheetHeight }]
                presentation.preferredCornerRadius = 24
                presentation.prefersGrabberVisible = false
            }
            topVC.present(host, animated: true)
        }
    }

    // 최상단 뷰 컨트롤러 탐색
    @MainActor
    static func topViewController() -> UIViewController? {
        // 시스템 권한 팝업이 떠 있는 동안에는 scene 이 foregroundActive 가 아닐 수 있으므로
        // active scene 이 없으면 아무 UIWindowScene 이라도 사용한다.
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first else {
            return nil
        }
        var top = window.rootViewController
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
        // 세로는 내용만큼만 차지해야 시트 높이를 내용에 맞출 수 있다
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.white)
    }
}
