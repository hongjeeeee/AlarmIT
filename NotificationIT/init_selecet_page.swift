// init_selecet_page.dart 변환 (InitSelectPage1 + InitSelectPage2)
import SwiftUI

// Page1 → Page2 push 라우트
struct InitSelectRoute: Hashable {
    let major: String
}

// MARK: - InitSelectPage1
struct InitSelectPage1: View {
    let skipSecond: Bool

    @EnvironmentObject var router: AppRouter
    @State private var isSelected = ""
    @State private var searchText = ""
    @State private var path: [InitSelectRoute] = []

    init(skipSecond: Bool = false) {
        self.skipSecond = skipSecond
    }

    // majorMap (원본 순서 보존)
    private let majorMap: [FacultyGroup] = makeFacultyGroups([
        ("미래엔지니어링융합대학", [
            "ICT융합학부",
            "미래모빌리티공학부",
            // "에너지화학공학부",
            "신소재반도체융합학부",
            "전기전자융합학부",
            "바이오매디컬헬스학부",
        ]),
        ("스마트도시융합대학", ["건축도시환경학부", "디자인융합학부", "스포츠과학부"]),
        ("경영공공정책대학", ["경영경제융합학부"]),
        ("인문예술대학", ["글로벌인문학부", "예술학부"]),
        // ("의과대학", ["의예과[의학과]", "간호학과"]),
        ("아산아너스칼리지", ["자율전공학부"]),
        // ("울산대학교", ["SW사업단", "U-STAR"]),
        ("IT융합학부", ["IT융합전공", "AI융합전공"]),
    ])

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: InitSelectRoute.self) { route in
                    InitSelectPage2(major: route.major)
                }
                .navigationBarBackButtonHidden(true)
        }
    }

    private var content: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // 헤더
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("공지를 확인할 전공을\n선택해주세요!")
                            .font(.system(size: 20, weight: .bold))
                            .lineSpacing(20 * 0.1)
                        Text("학과는 언제든지 또 변경할 수 있어요.")
                            .foregroundColor(Color(argb: 0xff495258))
                            .font(.system(size: 12))
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        if isSelected != "" {
                            Button {
                                Task { await onNext() }
                            } label: {
                                Text("다음")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(argb: 0xff009D72))
                            }
                            Spacer().frame(height: 40)
                        }
                    }
                }

                Spacer().frame(height: 40)
                searchForm
                Rectangle().fill(Color(argb: 0xff009D72)).frame(height: 2)
                Spacer().frame(height: 60)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        filteredList
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(EdgeInsets(top: 20, leading: 30, bottom: 25, trailing: 30))
        }
    }

    // SearchForm
    private var searchForm: some View {
        HStack(spacing: 0) {
            TextField("", text: $searchText, prompt: Text("알림 받을 학과를 입력해주세요").foregroundColor(Color(argb: 0xffA3A3A3)))
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .layoutPriority(7)
            Button { } label: {
                Text("검색").foregroundColor(Color(argb: 0xff009D72))
            }
            .layoutPriority(1)
        }
    }

    // Selector
    private func selector(_ name: String) -> some View {
        HStack(spacing: 0) {
            Text(name).font(.system(size: 17))
            Spacer()
            Button {
                Task { await onTapSelector(name) }
            } label: {
                if isSelected == name {
                    svgImage("assets/icons/알림it_checkButton_O.svg")
                } else {
                    svgImage("assets/icons/알림it_checkButton_X.svg")
                }
            }
        }
        .padding(.top, 36)
    }

    // filteredList
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

    @MainActor
    private func onTapSelector(_ name: String) async {
        isSelected = (isSelected == name) ? "" : name

        if !isSelected.isEmpty {
            await saveMainMajor(isSelected)
        } else {
            UserDefaults.standard.removeObject(forKey: kMainMajorKey)
        }
    }

    @MainActor
    private func onNext() async {
        await saveMainMajor(isSelected)
        if skipSecond {
            // 바로 MainPage
            router.root = .main(selectedMajor: isSelected, selectedAlram: ["IT융합전공"], changeMajor: false)
        } else {
            // InitSelectPage2로 이동
            path.append(InitSelectRoute(major: isSelected))
        }
    }

    private func saveMainMajor(_ major: String) async {
        UserDefaults.standard.set(major, forKey: kMainMajorKey)
    }
}

// MARK: - InitSelectPage2
struct InitSelectPage2: View {
    let major: String

    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var isSelectedList: [String] = []

    // majorMap (Page2 전용, 원본 순서/표기 유지)
    private let majorMap: [FacultyGroup] = makeFacultyGroups([
        ("미래엔지니어링융합대학", [
            "ICT융합학부",
            "미래모빌리티공학부",
            // "에너지화학공학부",
            "신소재·반도체융합학부",
            "전기전자융합학부",
            // "바이오매디컬헬스학부",
        ]),
        ("스마트도시융합대학", ["건축도시환경학부", "디자인융합학부", "스포츠과학부"]),
        ("경영공공정책대학", ["경영경제융합학부"]),
        ("인문예술대학", ["글로벌인문학부", "예술학부"]),
        // ("의과대학", ["의예과[의학과]", "간호학과"]),
        ("아산아너스칼리지", ["자율전공학부"]),
        // ("울산대학교", ["SW사업단", "U-STAR"]),
        ("IT융합학부", ["IT융합전공", "AI융합전공"]),
    ])

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Text("< 전공선택")
                        .foregroundColor(Color(argb: 0xff009D72))
                        .font(.system(size: 17, weight: .bold))
                }
                Spacer().frame(height: 30)

                // 헤더
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("공지를 확인할 전공을\n선택해주세요!")
                            .font(.system(size: 20, weight: .bold))
                            .lineSpacing(20 * 0.1)
                        Text("학과는 언제든지 또 변경할 수 있어요.")
                            .foregroundColor(Color(argb: 0xff495258))
                            .font(.system(size: 12))
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        Button {
                            Task { await onDone() }
                        } label: {
                            Text("완료")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(argb: 0xff009D72))
                        }
                        Spacer().frame(height: 40)
                    }
                }

                Spacer().frame(height: 40)
                searchForm
                Rectangle().fill(Color(argb: 0xff009D72)).frame(height: 2)
                Spacer().frame(height: 60)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        filteredList
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(EdgeInsets(top: 20, leading: 30, bottom: 25, trailing: 30))
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await loadSelectedMajors()
        }
    }

    private var searchForm: some View {
        HStack(spacing: 0) {
            TextField("", text: $searchText, prompt: Text("알림 받을 학과를 입력해주세요").foregroundColor(Color(argb: 0xffA3A3A3)))
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .layoutPriority(7)
            Button { } label: {
                Text("검색").foregroundColor(Color(argb: 0xff009D72))
            }
            .layoutPriority(1)
        }
    }

    private func selector(_ name: String) -> some View {
        HStack(spacing: 0) {
            Text(name).font(.system(size: 17))
            Spacer()
            Button {
                Task { await onTapSelector(name) }
            } label: {
                if isSelectedList.contains(name) {
                    svgImage("assets/icons/알림it_bell_O.svg")
                } else {
                    svgImage("assets/icons/알림it_bell_X.svg")
                }
            }
        }
        .padding(.top, 36)
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
                Spacer().frame(height: 20)
            }
        }
    }

    @MainActor
    private func onTapSelector(_ name: String) async {
        if isSelectedList.contains(name) {
            isSelectedList.removeAll { $0 == name }
        } else {
            isSelectedList.append(name)
        }
        await saveSelectedMajors()
        print(isSelectedList)
    }

    @MainActor
    private func onDone() async {
        await saveSelectedMajors()
        router.root = .main(selectedMajor: major, selectedAlram: isSelectedList, changeMajor: false)
    }

    private func saveSelectedMajors() async {
        UserDefaults.standard.set(isSelectedList, forKey: kAlarmMajorsKey)
    }

    private func loadSelectedMajors() async {
        let prefs = UserDefaults.standard
        let savedAlarmMajors = prefs.stringArray(forKey: kAlarmMajorsKey)
        let mainMajor = prefs.string(forKey: kMainMajorKey)

        if let savedAlarmMajors = savedAlarmMajors, !savedAlarmMajors.isEmpty {
            isSelectedList = savedAlarmMajors
        } else if let mainMajor = mainMajor, !mainMajor.isEmpty {
            isSelectedList = [mainMajor] // Page1 대표전공을 초기값으로
        } else {
            isSelectedList = []
        }
    }
}
