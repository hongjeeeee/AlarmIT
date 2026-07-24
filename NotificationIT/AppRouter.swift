// Flutter Navigator 의 pushReplacement(루트 교체) 흐름 대응 라우터
import SwiftUI

/// 앱의 루트 화면 상태.
/// splashScreen -> IntroPage / MainPage, IntroPage -> InitSelectPage1, ... 의
/// Navigator.pushReplacement 흐름을 루트 교체로 표현한다.
enum RootScreen: Equatable {
    case splash
    case intro
    case initSelectPage1(skipSecond: Bool)
    case main(selectedMajor: String, selectedAlram: [String], changeMajor: Bool)
}

final class AppRouter: ObservableObject {
    @Published var root: RootScreen = .splash
}
