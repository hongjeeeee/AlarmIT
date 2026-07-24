// Flutter 위젯 변환에 공통으로 쓰이는 헬퍼
import SwiftUI
import UIKit

// MARK: - Color(0xAARRGGBB) 대응
extension Color {
    /// Flutter 의 Color(0xff009D72) 형태(ARGB) 대응 초기화
    init(argb value: UInt32) {
        let a = Double((value >> 24) & 0xFF) / 255.0
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - SvgPicture.asset('assets/icons/xxx.svg') 대응
/// Xcode 에셋 카탈로그에 추가된 SVG(벡터 보존)를 파일명 기준으로 불러온다.
/// 예) "assets/icons/알림it_bell.svg" -> Image("알림it_bell")
func svgImage(_ assetPath: String) -> Image {
    let name = (assetPath as NSString).lastPathComponent
        .replacingOccurrences(of: ".svg", with: "")
    return Image(name).renderingMode(.original)
}

// MARK: - majorMap (Dart Map<String, List<String>>) 대응
/// Dart 의 Map 은 삽입 순서를 유지하므로 순서 보존을 위해 배열로 표현한다.
struct FacultyGroup: Identifiable {
    let id: Int
    let faculty: String
    let majors: [String]
}

/// [(학부명, [전공])] 형태를 순서를 유지한 FacultyGroup 배열로 변환
func makeFacultyGroups(_ pairs: [(String, [String])]) -> [FacultyGroup] {
    pairs.enumerated().map { FacultyGroup(id: $0.offset, faculty: $0.element.0, majors: $0.element.1) }
}

// MARK: - url_launcher 대응
enum UrlLauncher {
    /// launchUrl(uri, mode: LaunchMode.externalApplication)
    static func launch(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    /// canLaunchUrl(uri)
    static func canLaunch(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
