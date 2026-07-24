// alram.dart 변환
import SwiftUI

struct AlarmPage: View {
    let deviceId: String

    @Environment(\.dismiss) private var dismiss
    @State private var isChecked = false
    @State private var isSelectedList: [String] = []
    @State private var searchText = ""

    init(deviceId: String = "") {
        self.deviceId = deviceId
    }

    private let majorMap: [FacultyGroup] = makeFacultyGroups([
        ("미래엔지니어링융합대학", [
            "ICT융합학부",
            "미래모빌리티공학부",
            "신소재반도체융합학부",
            "전기전자융합학부",
            "바이오매디컬헬스학부",
        ]),
        ("스마트도시융합대학", ["건축도시환경학부", "디자인융합학부", "스포츠과학부"]),
        ("경영·공공정책대학", ["경영경제융합학부"]),
        ("인문예술대학", ["글로벌인문학부", "예술학부"]),
        ("아산아너스칼리지", ["자율전공학부"]),
        ("IT융합학부", ["IT융합전공", "AI융합전공"]),
    ])

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // 상단: 뒤로가기 + 스위치
                HStack(spacing: 0) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 0) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                            Spacer().frame(width: 5)
                            Text("알림 설정")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { isChecked },
                        set: { newValue in Task { await onSwitchChanged(newValue) } }
                    ))
                    .labelsHidden()
                    .tint(Color(argb: 0xFF009D72))
                }
                .padding(EdgeInsets(top: 20, leading: 30, bottom: 0, trailing: 30))

                Spacer().frame(height: 30)

                VStack(alignment: .leading, spacing: 0) {
                    searchForm
                    Rectangle().fill(Color(argb: 0xff009D72)).frame(height: 2)
                    Spacer().frame(height: 40)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            filteredList
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 25, trailing: 30))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await onInit()
        }
    }

    private var searchForm: some View {
        HStack(spacing: 0) {
            TextField("", text: $searchText, prompt: Text("알림 받을 학과를 입력해주세요").foregroundColor(Color(argb: 0xffA3A3A3)))
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .layoutPriority(7)
            Button { } label: {
                Text("검색")
                    .foregroundColor(Color(argb: 0xff009D72))
                    .fontWeight(.bold)
            }
            .layoutPriority(1)
        }
    }

    private func selector(_ major: String) -> some View {
        HStack(spacing: 0) {
            Text(major).font(.system(size: 17))
            Spacer()
            Button {
                Task { await onTapSelector(major) }
            } label: {
                if isSelectedList.contains(major) {
                    svgImage("assets/icons/알림it_bell_O.svg")
                } else {
                    svgImage("assets/icons/알림it_bell_X.svg")
                }
            }
        }
        .padding(.top, 30)
    }

    @ViewBuilder
    private var filteredList: some View {
        ForEach(majorMap) { group in
            let matched = group.majors.filter { searchText.isEmpty || $0.contains(searchText) }
            if !matched.isEmpty {
                Text(group.faculty)
                    .foregroundColor(Color(argb: 0xff009D72))
                    .font(.system(size: 12, weight: .bold))
                ForEach(matched, id: \.self) { major in
                    selector(major)
                }
                Spacer().frame(height: 60)
            }
        }
    }

    // MARK: - 로직

    /// ✅ FCM 토큰 등록
    private func registerFcmTokenIfNeeded() async {
        do {
            let token = try await FcmMessaging.getToken()
            print("📱 FCM Token: \(token ?? "")")
            // 서버에 deviceId + token 등록 로직 필요시 추가
        } catch {
            print("❌ FCM 토큰 등록 실패: \(error)")
        }
    }

    @MainActor
    private func onTapSelector(_ major: String) async {
        let consented = await ConsentManager.isConsented()

        // ✅ 개인정보 동의 체크
        if !consented {
            let result = await ConsentManager.showPrivacyConsentSheet()
            if result == true {
                await ConsentManager.setConsented(true)
                await registerFcmTokenIfNeeded()
            } else {
                return
            }
        }

        if isSelectedList.contains(major) {
            isSelectedList.removeAll { $0 == major }
        } else {
            isSelectedList.append(major)
            // 👉 하나라도 선택하면 스위치 자동 ON
            if !isChecked {
                isChecked = true
            }
        }

        // ✅ 저장 + 구독/해제
        await saveSelectedMajors()

        if isSelectedList.contains(major) {
            await subscribeMajor(major)
        } else {
            await unsubscribeMajor(major)
        }

        // ✅ bell on/off 기준 업데이트
        isChecked = !isSelectedList.isEmpty
    }

    @MainActor
    private func onSwitchChanged(_ value: Bool) async {
        let consented = await ConsentManager.isConsented()

        // ✅ 동의 안 한 상태에서 켜려는 경우
        if value && !consented {
            let result = await ConsentManager.showPrivacyConsentSheet()
            if result == true {
                await ConsentManager.setConsented(true)
                await registerFcmTokenIfNeeded()
                isChecked = true
                // 켜면 현재 선택된 전공들 구독
                for major in isSelectedList {
                    await subscribeMajor(major)
                }
            } else {
                isChecked = false
            }
            return
        }

        // ✅ OFF로 내리는 경우: 전체 해제 + 리스트 비움 + 저장 비움
        let next = value

        if !next {
            for major in isSelectedList {
                await unsubscribeMajor(major)
            }

            isChecked = false
            isSelectedList = []

            await saveSelectedMajors()
            return
        }

        // ✅ ON으로 켜는 경우: 현재 리스트 구독
        isChecked = true

        for major in isSelectedList {
            await subscribeMajor(major)
        }
    }

    private func showNotification(_ text: String) async {
        flutterLocalNotificationsPlugin.show(0, "알림 설정", text)
    }

    private func subscribeMajor(_ major: String) async {
        let apiService = ApiService(url: "\(port)/fcm/subscribe")
        do {
            let response = try await apiService.subscribeNotice(deviceId, major)
            print("📨 서버 응답: \(response["message"] ?? "")")
        } catch {
            print("❌ 오류 발생: \(error)")
        }
    }

    private func unsubscribeMajor(_ major: String) async {
        let apiService = ApiService(url: "\(port)/fcm/subscribe")
        do {
            try await apiService.unsubscribeNotice(deviceId, major)
        } catch {
            print("❌ 오류 발생: \(error)")
        }
    }

    // ✅ InitSelectPage2와 같은 키(kAlarmMajorsKey)로 통일
    private func saveSelectedMajors() async {
        UserDefaults.standard.set(isSelectedList, forKey: kAlarmMajorsKey)
    }

    // ✅ InitSelectPage2에서 저장된 값으로 초기화
    @MainActor
    private func loadFromInitPrefs() async {
        let prefs = UserDefaults.standard
        let savedAlarmMajors = prefs.stringArray(forKey: kAlarmMajorsKey) ?? []

        isSelectedList = savedAlarmMajors
        isChecked = !savedAlarmMajors.isEmpty // ✅ init에서 설정했으면 ON
    }

    // initState 대응
    @MainActor
    private func onInit() async {
        // ✅ 동의한 경우에만 init 저장값 반영
        let consented = await ConsentManager.isConsented()
        if consented {
            await loadFromInitPrefs()
        } else {
            // ❌ 동의 안 한 경우 → OFF + 선택값 없음 + 저장도 비움
            isChecked = false
            isSelectedList = []

            UserDefaults.standard.set([String](), forKey: kAlarmMajorsKey)
        }
    }
}
