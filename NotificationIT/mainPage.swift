// mainPage.dart 변환
import SwiftUI
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MainPage 내부 push 라우트
enum MainRoute: Hashable {
    case category
    case alarm(deviceId: String)
    case webview(url: String)
}

@MainActor
final class MainPageViewModel: ObservableObject {
    // 위젯 파라미터
    let widgetSelectedAlram: [String]
    let widgetSelectedMajor: String
    let widgetChangeMajor: Bool

    // 북마크
    let bookmarkManager = BookmarkManager()

    @Published var pageNum = 0
    @Published var type = "전체"

    // 기본값 세팅
    @Published var selectedMajor = "IT융합전공"
    @Published var selectedAlarmMajors: [String] = []
    @Published var elements: [Notice] = []

    // 알림
    @Published var selected_bell = false

    // FirebaseMessaging.instance
    // (네이티브에서는 Messaging.messaging() 사용)

    // 디버그
    private var _debugApnsToken: String?
    private var _debugFcmToken: String?
    private var _debugAuthStatus: UNAuthorizationStatus?
    private var _debugStatusLog = ""

    // 검색
    @Published var isTextFieldVisible = true
    @Published var controllerText = ""
    @Published var searchQuery = ""

    // 필터
    @Published var selectedIndex = 0
    @Published var isLoading = false
    private var _missingBookmarksInCache = 0

    // 캐시
    private var _noticeCache: [Int: Notice] = [:]

    // changeMajor 스낵바
    @Published var showChangeMajorSnackBar = false

    init(selectedMajor: String, selectedAlram: [String], changeMajor: Bool) {
        self.widgetSelectedMajor = selectedMajor
        self.widgetSelectedAlram = selectedAlram
        self.widgetChangeMajor = changeMajor
    }

    // MARK: - Firebase / FCM

    func _initializeFirebase() async {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: DefaultFirebaseOptions.currentPlatform)
        }

        _debugStatusLog = "Firebase init OK\n"

        // Platform.isIOS
        let status = await FcmMessaging.requestPermission(alert: true, badge: true, sound: true)
        _debugAuthStatus = status
        _debugStatusLog += "iOS 권한: \(status)\n"

        // ✅ FCM
        _debugFcmToken = try? await FcmMessaging.getToken()
        if _debugFcmToken != nil {
            _debugStatusLog += "FCM token OK\n"
            await _fcmPost()
        } else {
            _debugStatusLog += "❌ FCM token NULL\n"
        }

        // ✅ APNs
        for _ in 0..<5 {
            _debugApnsToken = await FcmMessaging.getAPNSToken()
            if _debugApnsToken != nil { break }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }

        if _debugApnsToken != nil {
            _debugStatusLog += "APNs token OK\n"
        } else {
            _debugStatusLog += "❌ APNs token NULL\n"
        }
    }

    func setupMessageListener() {
        print("setupmessageListener 함수 정상 적용")
        // FirebaseMessaging.onMessage 및 알림 클릭 payload 처리.
        // 네이티브에서는 UNUserNotificationCenter 델리게이트로 포그라운드 표시가 처리된다.
        flutterLocalNotificationsPlugin.initialize(onDidReceiveNotificationResponse: { payload in
            if let payload = payload {
                print("🔔 알림 클릭 시 payload: \(payload)")
            }
        })

        // getInitialMessage: 앱 종료 상태에서 알림 클릭 링크
        // (AppDelegate launchOptions 로 전달되는 원격 알림에서 link 확인)
    }

    func _fcmPost() async {
        print("\n===== 기기등록 API =====")

        if _debugFcmToken == nil {
            _debugStatusLog += "❌ 서버 전송 실패: FCM 토큰 NULL\n"
            return
        }

        let deviceId = await getDeviceId()
        let apiService = ApiService(url: "\(port)/fcm/fcm_token")

        do {
            let response = try await apiService.postFCMToken(deviceId, _debugFcmToken!)
            _debugStatusLog += "📡 [FCM 등록 응답]\n\(response)\n"
        } catch {
            _debugStatusLog += "❌ FCM 등록 API 에러: \(error)\n"
        }
    }

    func _subscribeMajor() async {
        print("\n===== 전공구독 API =====")

        // ✅ prefs 기반 리스트로 구독
        let majors = selectedAlarmMajors
        print("구독요청 전공: \(majors)")

        let deviceId = await getDeviceId()
        let apiService = ApiService(url: "\(port)/fcm/subscribe")

        var allSuccess = true

        for major in majors {
            do {
                let response = try await apiService.subscribeNotice(deviceId, major)
                let message = response["message"] ?? "응답 메시지가 없습니다."
                print("✅ [\(major)] 구독 성공: \(message)")
            } catch {
                allSuccess = false
                print("❌ [\(major)] 구독 실패: \(error)")
            }
        }

        if allSuccess {
            selected_bell = true
        } else {
            await showNotification("일부 전공 구독에 실패했습니다.")
        }
    }

    func showNotification(_ text: String) async {
        flutterLocalNotificationsPlugin.show(0, "알림 설정", text)
    }

    // MARK: - 검색

    func _onSearchChanged(_ query: String) {
        if query.count < 2 { return }
        Task { await _fetchSearchResults(query) }
    }

    func _fetchSearchResults(_ keyword: String) async {
        if isLoading { return }
        isLoading = true
        let requested = (index: selectedIndex, major: selectedMajor)

        do {
            let apiServiceSearch = ApiService(url: "\(port)/search?keyWord=\(keyword)&major=\(selectedMajor)&page=0")

            let notices = try await apiServiceSearch.fetchNotices()

            for n in notices {
                _noticeCache[n.id] = n
            }

            // 검색 응답이 늦게 온 사이 탭/전공이 바뀌었으면 버린다.
            guard selectedIndex == requested.index, selectedMajor == requested.major else {
                isLoading = false
                return
            }

            elements = notices
            isLoading = false
        } catch {
            isLoading = false
            print("데이터 로드 실패: \(error)")
        }
    }

    // MARK: - 필터/로드

    func onTapAll() {
        elements = []
        selectedIndex = 0
        pageNum = 0
        type = "전체"
        Task { await loadData() }
    }

    func onTapImportant() {
        selectedIndex = 1
        elements = []
        pageNum = 0
        type = "중요 공지"
        Task { await loadData() }
    }

    func onTapBookmark() {
        selectedIndex = 2
        pageNum = 0
        elements = []
        Task { await updateElements() }
    }

    func updateElements() async {
        let bookmarkedItems = await bookmarkManager.getBookmarks()
        let notices = await loadBookmarkedItemsFromCache(bookmarkedItems)

        if selectedIndex == 2 {
            elements = notices
        }
    }

    func loadBookmarkedItems(_ bookmarkedItems: [String]) async throws -> [Notice] {
        let apiService = ApiService(url: "\(port)/notice?type=전체&page=\(pageNum)&major=\(selectedMajor)")

        let allNotices = try await apiService.fetchNotices()
        return allNotices.filter { bookmarkedItems.contains("\($0.id)") }
    }

    func loadBookmarkedItemsFromCache(_ bookmarkedItems: [String]) async -> [Notice] {
        let ids = bookmarkedItems.compactMap { Int($0) }

        var result: [Notice] = []
        var missingCount = 0

        for id in ids {
            if let hit = _noticeCache[id] {
                result.append(hit)
            } else {
                missingCount += 1
            }
        }

        _missingBookmarksInCache = missingCount
        return result
    }

    func loadData() async {
        if isLoading { return }
        isLoading = true
        // 응답이 늦게 도착하는 사이 사용자가 탭/전공을 바꿀 수 있으므로 요청 시점을 기억한다.
        let requested = (index: selectedIndex, major: selectedMajor)

        do {
            let apiServiceAll = ApiService(url: "\(port)/notice?type=전체&page=0&major=\(selectedMajor)")
            let apiServiceImportant = ApiService(url: "\(port)/notice?type=공지&page=0&major=\(selectedMajor)")

            let bookmarkedItems = await bookmarkManager.getBookmarks()
            var notices: [Notice]

            if selectedIndex == 0 {
                notices = try await apiServiceAll.fetchNotices()
            } else if selectedIndex == 1 {
                notices = try await apiServiceImportant.fetchNotices()
            } else if selectedIndex == 2 {
                notices = try await loadBookmarkedItems(bookmarkedItems)
            } else {
                notices = []
            }

            for n in notices {
                _noticeCache[n.id] = n
            }

            // 요청 도중 탭/전공이 바뀌었으면 지난 응답이므로 화면에 반영하지 않는다.
            guard selectedIndex == requested.index, selectedMajor == requested.major else {
                isLoading = false
                return
            }

            elements = notices
            isLoading = false
        } catch {
            isLoading = false
            print("데이터 로드 실패: \(error)")
        }
    }

    func loadNewData() async {
        if isLoading { return }
        isLoading = true
        // 원본은 selectedIndex == 0 에서만 증가시켜 '중요 공지' 탭 무한스크롤이 동작하지 않았음.
        // 무한 스크롤 요청에 따라 서버 페이징을 쓰는 두 탭(전체/중요 공지) 모두 증가시킨다.
        // (북마크 탭은 원본대로 유지)
        if selectedIndex == 0 || selectedIndex == 1 { pageNum += 1 }
        let requested = (index: selectedIndex, major: selectedMajor)

        do {
            let apiServiceAll = ApiService(url: "\(port)/notice?type=전체&page=\(pageNum)&major=\(selectedMajor)")
            // 원본은 여기서만 type=중요 공지 를 썼는데, 서버가 인식하지 못하는 값이라
            // 다음 페이지부터 필독(NECESSARY)이 섞여 들어왔다. 첫 로드(loadData)와 같은 type=공지 로 통일.
            let apiServiceImportant = ApiService(url: "\(port)/notice?type=공지&page=\(pageNum)&major=\(selectedMajor)")

            let bookmarkedItems = await bookmarkManager.getBookmarks()
            var notices: [Notice]

            if selectedIndex == 0 {
                notices = try await apiServiceAll.fetchNotices()
            } else if selectedIndex == 1 {
                notices = try await apiServiceImportant.fetchNotices()
            } else if selectedIndex == 2 {
                notices = try await loadBookmarkedItems(bookmarkedItems)
            } else {
                notices = []
            }

            for n in notices {
                _noticeCache[n.id] = n
            }

            // 다음 페이지 응답이 늦게 온 사이 탭/전공이 바뀌었으면 다른 목록에 덧붙이지 않는다.
            guard selectedIndex == requested.index, selectedMajor == requested.major else {
                isLoading = false
                return
            }

            let existingIds = Set(elements.map { $0.id })
            let fetchedElements = notices.filter { !existingIds.contains($0.id) }

            elements.append(contentsOf: fetchedElements)
            isLoading = false
        } catch {
            isLoading = false
            print("데이터 로드 실패: \(error)")
        }
    }

    // MARK: - 전공 변경 결과 처리 (_navigateAndGetMajor)

    func handleCategoryResult(_ newMajor: String, _ changed: Bool) {
        if newMajor.isEmpty { return }
        selectedMajor = newMajor
        Task { await loadData() }
        // scrollController.animateTo(0) 및 changed 스낵바는 원본에서도 비활성(주석) 상태
    }

    // MARK: - prefs 로드/초기화

    func _loadPrefsAndApply() async {
        let prefs = UserDefaults.standard

        let mainMajor = prefs.string(forKey: kMainMajorKey)
        let alarmMajors = prefs.stringArray(forKey: kAlarmMajorsKey) ?? []

        let resolvedMainMajor = (mainMajor != nil && !mainMajor!.isEmpty) ? mainMajor! : widgetSelectedMajor
        let resolvedAlarmMajors = !alarmMajors.isEmpty ? alarmMajors : [resolvedMainMajor]

        selectedMajor = resolvedMainMajor
        selectedAlarmMajors = resolvedAlarmMajors
        selected_bell = !alarmMajors.isEmpty
    }

    func _checkConsentAndInitFCM() async {
        let prefs = UserDefaults.standard
        let consented = prefs.object(forKey: "privacy_consent_v1") as? Bool ?? false

        if consented {
            await _initializeFirebase()
            setupMessageListener()
            print("✅ 개인정보 동의함 → FCM 구독 진행")
        } else {
            print("❌ 개인정보 동의 안 함 → FCM 구독 막음")
        }
    }

    // initState → _bootstrap
    func bootstrap() async {
        // 기본값 먼저 세팅
        selectedMajor = widgetSelectedMajor
        selectedAlarmMajors = widgetSelectedAlram
        selected_bell = false

        await _loadPrefsAndApply()
        await loadData()
        await _checkConsentAndInitFCM()
        await _subscribeMajor()

        if widgetChangeMajor {
            showChangeMajorSnackBar = true
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showChangeMajorSnackBar = false
            }
        }
    }
}

struct MainPage: View {
    let selectedMajor: String
    let selectedAlram: [String]
    let changeMajor: Bool

    @EnvironmentObject var router: AppRouter
    @StateObject private var vm: MainPageViewModel
    @State private var path: [MainRoute] = []

    init(selectedMajor: String = "IT융합전공", selectedAlram: [String] = ["IT융합전공"], changeMajor: Bool = false) {
        self.selectedMajor = selectedMajor
        self.selectedAlram = selectedAlram
        self.changeMajor = changeMajor
        _vm = StateObject(wrappedValue: MainPageViewModel(
            selectedMajor: selectedMajor,
            selectedAlram: selectedAlram,
            changeMajor: changeMajor
        ))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    contentBody
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))

                if vm.showChangeMajorSnackBar {
                    changeMajorSnackBar
                }
            }
            .navigationDestination(for: MainRoute.self) { route in
                switch route {
                case .category:
                    CategoryPage(selectedMajor: vm.selectedMajor) { newMajor, changed in
                        vm.handleCategoryResult(newMajor, changed)
                    }
                case .alarm(let deviceId):
                    AlarmPage(deviceId: deviceId)
                case .webview(let url):
                    WebViewPage(url: url)
                }
            }
        }
        .task {
            await vm.bootstrap()
        }
    }

    // MARK: - 헤더
    private var header: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)
            HStack(spacing: 0) {
                svgImage("assets/icons/알림it_icon.svg")
                    .frame(width: 21, height: 22)
                Spacer().frame(width: 10)
                Button {
                    path.append(.category)
                } label: {
                    HStack(spacing: 0) {
                        Text(vm.selectedMajor).foregroundColor(.black)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 15))
                    }
                }
                Spacer()
                bellIcon
                // Flutter IconButton 의 기본 여백(8pt) 대응 — 벨/검색 버튼이 붙지 않도록
                Spacer().frame(width: 16)
                if !vm.isTextFieldVisible {
                    Button {
                        vm.isTextFieldVisible.toggle()
                        vm.searchQuery = ""
                        Task { await vm.loadData() }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 20)).foregroundColor(.black)
                    }
                } else {
                    Button {
                        vm.isTextFieldVisible.toggle()
                    } label: {
                        svgImage("assets/icons/알림it_검색.svg")
                    }
                }
            }
            Spacer().frame(height: 20)

            if vm.isTextFieldVisible {
                HStack(spacing: 0) {
                    allInfoButton
                    Spacer().frame(width: 8)
                    importantInfoButton
                    Spacer().frame(width: 8)
                    bookmarkInfoButton
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        TextField("", text: $vm.controllerText, prompt: Text("검색어를 입력해주세요").foregroundColor(Color(argb: 0xffA3A3A3)))
                            .font(.system(size: 15.12, weight: .bold))
                            .textFieldStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .onChange(of: vm.controllerText) { val in
                                vm.searchQuery = val
                                vm._onSearchChanged(val)
                            }
                        Button { } label: {
                            Text("검색").foregroundColor(Color(argb: 0xff009D72))
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 15))
                    }
                    Rectangle().fill(Color(argb: 0xff009D72)).frame(height: 2)
                }
            }
            Spacer().frame(height: 23)
            if vm.isTextFieldVisible {
                Rectangle().fill(Color.black).frame(height: 1).frame(maxWidth: .infinity)
            }
        }
    }

    // _bellIcon
    private var bellIcon: some View {
        Button {
            Task { @MainActor in
                let deviceID = await getDeviceId()
                path.append(.alarm(deviceId: deviceID))
            }
        } label: {
            if vm.selected_bell {
                svgImage("assets/icons/알림it_bell.svg")
            } else {
                svgImage("assets/icons/알림it_bell_f.svg")
            }
        }
    }

    private var allInfoButton: some View {
        Button {
            vm.onTapAll()
        } label: {
            (vm.selectedIndex == 0
                ? svgImage("assets/icons/알림it_전체_O.svg")
                : svgImage("assets/icons/알림it_전체_X.svg"))
        }
        .frame(width: 47.6, height: 26.64)
    }

    private var importantInfoButton: some View {
        Button {
            vm.onTapImportant()
        } label: {
            (vm.selectedIndex == 1
                ? svgImage("assets/icons/알림it_중요공지_O.svg")
                : svgImage("assets/icons/알림it_중요공지_X.svg"))
        }
        .frame(width: 76.6, height: 26.64)
    }

    private var bookmarkInfoButton: some View {
        Button {
            vm.onTapBookmark()
        } label: {
            (vm.selectedIndex == 2
                ? svgImage("assets/icons/알림it_북마_O.svg")
                : svgImage("assets/icons/알림it_북마_X.svg"))
        }
        .frame(width: 60.6, height: 26.64)
    }

    // MARK: - 본문
    @ViewBuilder
    private var contentBody: some View {
        if vm.elements.isEmpty && vm.isLoading {
            // 최초 로딩 (원본은 빈 화면이었으나 로딩 UI 로 대체)
            VStack(spacing: 0) {
                Spacer().frame(height: 230)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color(argb: 0xff009D72))
                    .scaleEffect(1.2)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if !vm.elements.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.elements) { notice in
                        ElementWidget(
                            id: notice.id,
                            title: notice.title,
                            date: notice.date,
                            link: notice.link,
                            type: notice.type,
                            major: notice.major,
                            onOpen: { link in path.append(.webview(url: link)) },
                            onBookmarkChanged: { Task { await vm.updateElements() } }
                        )
                        .onAppear {
                            // 스크롤 하단 도달 시 다음 페이지 로드 (_scrollListener 대응)
                            if notice.id == vm.elements.last?.id {
                                Task { await vm.loadNewData() }
                            }
                        }
                    }

                    // 다음 페이지 로딩 표시 (목록은 계속 보이도록 유지)
                    if vm.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color(argb: 0xff009D72))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }

                    // 마지막 항목이 화면 끝에 붙지 않도록 여백
                    Spacer().frame(height: 16)
                }
            }
            .frame(maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                Spacer().frame(height: 230)
                Text("공지된 북마크가 없습니다")
                    .font(.system(size: 20))
                    .foregroundColor(Color(argb: 0xff9C9C9C))
            }
        }
    }

    // 개인정보 (원본 showPrivacyConsentBottomSheet — 정의되어 있으나 호출되지 않음, 원본 준수용 변환)
    @MainActor
    func showPrivacyConsentBottomSheet() async -> Bool? {
        guard let topVC = ConsentManager.topViewController() else { return nil }
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool?, Never>) in
            var didResume = false
            weak var hostRef: UIViewController?
            let finish: (Bool?) -> Void = { result in
                guard !didResume else { return }
                didResume = true
                hostRef?.dismiss(animated: true) { continuation.resume(returning: result) }
            }
            let sheet = MainPageConsentSheetView(onResult: finish)
            let host = UIHostingController(rootView: sheet)
            hostRef = host
            host.isModalInPresentation = true // isDismissible:false, enableDrag:false
            if let presentation = host.sheetPresentationController {
                presentation.detents = [.medium()]
                presentation.preferredCornerRadius = 20
            }
            topVC.present(host, animated: true)
        }
    }

    // changeMajor 스낵바
    private var changeMajorSnackBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("전공이 변경되었어요!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("공지 채널을 변경해도 새 공지의\n알림을 받는 채널은 변경되지 않아요!")
                .font(.system(size: 11))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 60).fill(Color(argb: 0xff009D72))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

/// showPrivacyConsentBottomSheet 내부 UI (원본 mainPage.dart StatefulBuilder Column)
struct MainPageConsentSheetView: View {
    let onResult: (Bool?) -> Void
    @State private var checked = true

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "megaphone")
                .font(.system(size: 40))
                .foregroundColor(Color(argb: 0xff009D72))
            Spacer().frame(height: 8)
            Text("알림U 이용을 위해 동의가 필요해요")
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
            Spacer().frame(height: 12)
            HStack(spacing: 0) {
                Button {
                    checked.toggle()
                } label: {
                    Image(systemName: checked ? "checkmark.square.fill" : "square")
                        .foregroundColor(checked ? Color(argb: 0xff009D72) : .gray)
                }
                Text("개인정보 처리 동의")
                Spacer()
                Button {
                    // TODO: 상세보기 링크/화면
                } label: {
                    Text("[자세히보기]")
                }
            }
            Spacer().frame(height: 8)
            HStack(spacing: 10) {
                Button {
                    onResult(false)
                } label: {
                    Text("닫기")
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(argb: 0xffE9E9E9))
                }
                Button {
                    if checked { onResult(true) }
                } label: {
                    Text("다음")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(argb: 0xff009D72))
                }
                .disabled(!checked)
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
