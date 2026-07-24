// GET_notice.dart 변환
// 원본에서 다른 파일이 import 하지 않는 미사용 모델. api_service.swift 의 Notice 와
// 이름이 겹치므로 네임스페이스(enum)로 감싸 원본을 그대로 보존한다.
import Foundation

enum GET_notice {
    struct Notice {
        let id: Int
        let title: String
        let date: String
        let link: String
        let category: String

        init(id: Int, title: String, date: String, link: String, category: String) {
            self.id = id
            self.title = title
            self.date = date
            self.link = link
            self.category = category
        }

        static func fromJson(_ json: [String: Any]) -> Notice {
            return Notice(
                id: json["id"] as! Int,
                title: json["title"] as! String,
                date: json["date"] as! String,
                link: json["link"] as! String,
                category: json["category"] as! String
            )
        }
    }
}
