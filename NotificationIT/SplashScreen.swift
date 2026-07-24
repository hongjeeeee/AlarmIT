// splashScreen.dart 변환
import SwiftUI

final class SplashViewModel: ObservableObject {
    @Published var showUpdateDialog = false
    @Published var dialogLink = ""
    @Published var dialogForce = false
    @Published var dialogLatest = ""
    @Published var dialogCurrent = ""

    private var navigated = false
    private var dialogContinuation: CheckedContinuation<Void, Never>?

    func boot(router: AppRouter) async {
        // 스플래시 최소 노출 시간 (800ms)
        let minSplashDeadline = Date().addingTimeInterval(0.8)

        // 1) 첫 실행 여부
        let isFirst = await _isFirstLaunchAndMarkSeen()

        // 2) 버전 체크 (강제 업데이트면 여기서 막히게 됨)
        await _checkVersionAndPrompt()

        // 스플래시 최소 시간 보장
        let remaining = minSplashDeadline.timeIntervalSinceNow
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }

        // 4) 분기 이동
        if navigated { return }
        navigated = true

        await MainActor.run {
            if isFirst {
                router.root = .intro
            } else {
                router.root = .main(selectedMajor: "IT융합전공", selectedAlram: ["IT융합전공"], changeMajor: false)
            }
        }
    }

    private func _isFirstLaunchAndMarkSeen() async -> Bool {
        let prefs = UserDefaults.standard
        let hasSeenIntro = prefs.object(forKey: "hasSeenIntro") as? Bool

        if hasSeenIntro != true {
            // 첫 실행
            prefs.set(true, forKey: "hasSeenIntro")
            return true
        }
        return false
    }

    // ===== 버전 체크 로직 =====

    private func _checkVersionAndPrompt() async {
        do {
            let api = ApiService(url: port)
            let server = try await api.checkAppVersion()

            let pkgVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            func normalizeVersion(_ v: String) -> String {
                return v.split(separator: "+").first.map(String.init)?
                    .split(separator: "-").first.map(String.init) ?? v
            }

            let current = normalizeVersion(pkgVersion)               // ✅ 현재 버전
            let latest = normalizeVersion(server["latestVersion"]!)
            let minimum = normalizeVersion(server["minimumVersion"]!)
            let link = server["link"]!

            print("📦 [VERSION] current=\(current) / latest=\(latest) / minimum=\(minimum)")

            let force = _isLowerThan(current, minimum)
            let soft = !force && _isLowerThan(current, latest)

            print("🧭 [VERSION] force=\(force) / soft=\(soft)")

            if force || soft {
                await _showUpdateDialog(link: link, force: force, latest: latest, current: current)
            }
        } catch {
            print("버전 체크 실패: \(error)")
        }
    }

    private func _isLowerThan(_ a: String, _ b: String) -> Bool {
        var pa = a.split(separator: ".").map { Int($0) ?? 0 }
        var pb = b.split(separator: ".").map { Int($0) ?? 0 }
        while pa.count < 3 { pa.append(0) }
        while pb.count < 3 { pb.append(0) }

        for i in 0..<3 {
            if pa[i] != pb[i] { return pa[i] < pb[i] }
        }
        return false
    }

    func openStore(_ urlString: String) {
        UrlLauncher.launch(urlString)
    }

    @MainActor
    private func _showUpdateDialog(link: String, force: Bool, latest: String, current: String) async {
        dialogLink = link
        dialogForce = force
        dialogLatest = latest
        dialogCurrent = current
        showUpdateDialog = true

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.dialogContinuation = continuation
        }
    }

    /// 다이얼로그 닫기(pop) → boot 흐름 재개
    @MainActor
    func dismissDialog() {
        showUpdateDialog = false
        dialogContinuation?.resume(returning: ())
        dialogContinuation = nil
    }
}

struct SplashScreen: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var vm = SplashViewModel()

    var body: some View {
        ZStack {
            // Scaffold backgroundColor white, Center SvgPicture
            Color.white.ignoresSafeArea()
            svgImage("assets/icons/알림it_splash_image.svg")

            if vm.showUpdateDialog {
                updateDialog
            }
        }
        .onAppear {
            // 첫 프레임 이후 부팅 (addPostFrameCallback)
            Task { await vm.boot(router: router) }
        }
    }

    // _showUpdateDialog 의 Dialog 대응
    private var updateDialog: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // barrierDismissible: !force
                    if !vm.dialogForce { vm.dismissDialog() }
                }

            VStack(spacing: 0) {
                Text("새 버전이 업데이트되었어요!")
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
                Spacer().frame(height: 8)
                Text("현재: \(vm.dialogCurrent)  ·  최신: \(vm.dialogLatest)")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.54))
                Spacer().frame(height: 20)

                Button {
                    vm.openStore(vm.dialogLink)
                    if vm.dialogForce {
                        // 강제 업데이트: 앱 종료 유도
                        exit(0)
                    } else {
                        vm.dismissDialog()
                    }
                } label: {
                    Text("업데이트")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(argb: 0xff009D72))
                        )
                }
                Spacer().frame(height: 8)

                if !vm.dialogForce {
                    Button {
                        vm.dismissDialog()
                    } label: {
                        Text("종료")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12).fill(Color.black)
                            )
                    }
                } else {
                    Button {
                        exit(0)
                    } label: {
                        Text("종료")
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(EdgeInsets(top: 24, leading: 20, bottom: 16, trailing: 20))
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Color.white)
            )
            .padding(.horizontal, 40)
        }
    }
}
