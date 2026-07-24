// list_elements.dart 의 ElementWidget 변환 (BookmarkManager 는 BookmarkManager.swift)
import SwiftUI

struct ElementWidget: View, Identifiable {
    let id: Int
    let title: String
    let date: String
    let link: String
    let type: String
    let major: String

    // Navigator.push(WebViewPage) 및 MainPage.updateElements() 대응 콜백
    var onOpen: ((String) -> Void)?
    var onBookmarkChanged: (() -> Void)?

    @State private var isBookmarked = false

    var body: some View {
        Button {
            // InkWell onTap → WebViewPage 이동
            onOpen?(link)
        } label: {
            content
        }
        .buttonStyle(.plain)
        .frame(width: 315, height: 79)
        .task {
            await loadBookmarkStatus()
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Flutter Row 의 기본 crossAxisAlignment 는 center (북마크 아이콘 세로 중앙)
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 15)
                    HStack(spacing: 0) {
                        if type == "NOTICE" {
                            badge(text: "중요", color: Color(argb: 0xff009D72))
                        }
                        if type == "NECESSARY" {
                            badge(text: "필독", color: Color(argb: 0xffF2BC1B))
                        }
                        // 날짜 박스
                        Text(date)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(argb: 0xff666666))
                            .frame(width: 70, height: 15)
                            .background(
                                RoundedRectangle(cornerRadius: 3).fill(Color(argb: 0xffEEEEEE))
                            )
                    }
                    Spacer().frame(height: 10)
                    Text(title)
                        .font(.system(size: 14.42, weight: .bold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer().frame(height: 15)
                }
                Spacer()
                Button {
                    Task { await toggleBookmark() }
                } label: {
                    if isBookmarked {
                        svgImage("assets/icons/알림it_북마크_O.svg")
                    } else {
                        svgImage("assets/icons/알림it_북마크_X.svg")
                    }
                }
            }
            Rectangle()
                .fill(Color(argb: 0xffE0E0E0))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 45, height: 15)
            .background(RoundedRectangle(cornerRadius: 3).fill(color))
            .padding(.leading, 2)
            .padding(.trailing, 5)
    }

    // 북마크
    @MainActor
    private func loadBookmarkStatus() async {
        let bookmarked = await BookmarkManager.isBookmarked(String(id))
        isBookmarked = bookmarked
    }

    @MainActor
    private func toggleBookmark() async {
        await BookmarkManager.toggleBookmark(String(id))
        isBookmarked.toggle() // 즉시 상태 업데이트
        onBookmarkChanged?() // MainPage 의 updateElements() 대응
    }
}
