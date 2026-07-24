// keyword.dart 변환
import SwiftUI

struct KeywordPage: View {
    @Environment(\.dismiss) private var dismiss

    @State private var keywordList: [String] = []
    @State private var searchText = ""
    @State private var selectedText = ""
    @State private var controllerText = ""

    // 삭제 다이얼로그 상태
    @State private var showDeleteDialog = false
    @State private var pendingDeleteName = ""

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // 상단: 뒤로가기
                HStack(spacing: 0) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 0) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                            Spacer().frame(width: 5)
                            Text("키워드 알림 설정")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 70)
                    searchForm
                    Rectangle().fill(Color(argb: 0xff009D72)).frame(height: 2)
                    Spacer().frame(height: 10)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(keywordList, id: \.self) { keyword in
                                keywordElement(keyword)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(EdgeInsets(top: 20, leading: 30, bottom: 25, trailing: 30))

            if showDeleteDialog {
                deleteDialog
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var searchForm: some View {
        HStack(spacing: 0) {
            TextField("", text: $controllerText, prompt: Text("알림 받을 학과를 입력해주세요").foregroundColor(Color(argb: 0xffA3A3A3)))
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .layoutPriority(7)
                .onChange(of: controllerText) { newValue in
                    searchText = newValue
                }
            Button {
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    keywordList.append(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                    controllerText = ""
                }
            } label: {
                Text("등록")
                    .foregroundColor(Color(argb: 0xff009D72))
                    .fontWeight(.bold)
            }
            .layoutPriority(1)
        }
    }

    private func keywordElement(_ name: String) -> some View {
        HStack(spacing: 0) {
            Text(name)
            Spacer()
            Button {
                pendingDeleteName = name
                showDeleteDialog = true
            } label: {
                svgImage("assets/icons/알림it_trash.svg")
            }
        }
        .padding(.vertical, 7)
    }

    private var deleteDialog: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { showDeleteDialog = false }

            VStack(alignment: .leading, spacing: 0) {
                Text("'\(selectedText)'키워드 알림을 삭제할까요?")
                    .font(.system(size: 18, weight: .bold))
                Spacer().frame(height: 50)
                HStack(spacing: 15) {
                    Button {
                        showDeleteDialog = false
                    } label: {
                        Text("취소")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                            .background(
                                RoundedRectangle(cornerRadius: 5).fill(Color(argb: 0xffE7E8ED))
                            )
                    }
                    Button {
                        keywordList.removeAll { $0 == pendingDeleteName }
                        showDeleteDialog = false
                    } label: {
                        Text("삭제")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                            .background(
                                RoundedRectangle(cornerRadius: 5).fill(Color(argb: 0xff009D72))
                            )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Color.white)
            )
            .padding(.horizontal, 40)
        }
    }
}
