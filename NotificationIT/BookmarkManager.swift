// list_elements.dart 의 BookmarkManager 클래스 변환
import Foundation

/// 북마크 관리 클래스 (원본 lib/list_elements.dart)
class BookmarkManager {
    static let bookmarkKey = "bookmarks"

    static func toggleBookmark(_ id: String) async {
        let prefs = UserDefaults.standard
        let key = id
        var bookmarks = prefs.stringArray(forKey: bookmarkKey) ?? []

        if bookmarks.contains(key) {
            bookmarks.removeAll { $0 == key }
        } else {
            bookmarks.append(key)
        }
        prefs.set(bookmarks, forKey: bookmarkKey)
    }

    static func isBookmarked(_ id: String) async -> Bool {
        let prefs = UserDefaults.standard
        let bookmarks = prefs.stringArray(forKey: bookmarkKey) ?? []
        return bookmarks.contains(id)
    }

    func getBookmarks() async -> [String] {
        let prefs = UserDefaults.standard
        print(prefs.stringArray(forKey: BookmarkManager.bookmarkKey) as Any)
        return prefs.stringArray(forKey: BookmarkManager.bookmarkKey) ?? []
    }

    static func clearBookmarks() async {
        let prefs = UserDefaults.standard
        prefs.removeObject(forKey: bookmarkKey)  // 저장된 모든 북마크 데이터 삭제
    }
}
