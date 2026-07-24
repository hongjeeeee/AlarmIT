// majorCategory.dart 변환
import SwiftUI

struct CategoryPage: View {
    let selectedMajor: String
    // Navigator.pop(context, {selectedMajor, changed}) 대응
    var onFinish: ((_ selectedMajor: String, _ changed: Bool) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var isSelected = ""
    @State private var searchText = ""
    @State private var isChanged = false

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
                HStack(spacing: 0) {
                    Button {
                        Task { await finish() } // 뒤로도 완료와 동일하게 처리
                    } label: {
                        Text("⟨ 전공 선택")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    if !isSelected.isEmpty {
                        Button {
                            Task { await finish() }
                        } label: {
                            Text("완료")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(argb: 0xff009D72))
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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            isSelected = selectedMajor // 일단 기본값
        }
        .task {
            await loadMainMajor() // prefs 값 있으면 덮어씌움
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
                if isSelected != name {
                    isChanged = true
                    isSelected = name
                }
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

    // ✅ init 대표 전공 우선 로드
    private func loadMainMajor() async {
        let prefs = UserDefaults.standard
        let savedMainMajor = prefs.string(forKey: kMainMajorKey)
        isSelected = (savedMainMajor != nil && !savedMainMajor!.isEmpty)
            ? savedMainMajor!
            : selectedMajor // fallback
    }

    private func saveMainMajor(_ major: String) async {
        UserDefaults.standard.set(major, forKey: kMainMajorKey)
    }

    @MainActor
    private func finish() async {
        if isSelected.isEmpty { return }
        // 현재 선택값을 대표 전공으로 저장(덮어쓰기)
        await saveMainMajor(isSelected)
        onFinish?(isSelected, isChanged)
        dismiss()
    }
}
