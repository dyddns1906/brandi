//
//  SearchModel.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import Foundation
import DynamicCodable

import RxDataSources

import SwiftDate


struct SearchModel {
    typealias DataSource = RxCollectionViewSectionedReloadDataSource
    typealias SearchResultSectionModel = SectionModel<Int, DocumentData>
}

struct SearchResult: Codable {
    let meta: MetaData
    let documents: [DocumentData]
    
    private enum CodingKeys: String, CodingKey {
        case meta
        case documents
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        meta = try values.decode(MetaData.self, forKey: .meta)
        documents = try values.decode([DocumentData].self, forKey: .documents)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(meta, forKey: .meta)
        try container.encode(documents, forKey: .documents)
    }
    
}

struct MetaData: Codable {
    /// 검색된 문서 수
    let total_count: Int
    
    /// total_count 중 노출 가능 문서 수
    let pageable_count: Int
    
    /// 현재 페이지가 마지막 페이지인지 여부,
    /// 값이 false면 page를 증가시켜 다음 페이지를 요청할 수 있음
    let is_end: Bool
    
    private enum CodingKeys: String, CodingKey {
        case total_count
        case pageable_count
        case is_end
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        total_count = try values.decode(Int.self, forKey: .total_count)
        pageable_count = try values.decode(Int.self, forKey: .pageable_count)
        is_end = try values.decode(Bool.self, forKey: .is_end)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(total_count, forKey: .total_count)
        try container.encode(pageable_count, forKey: .pageable_count)
        try container.encode(is_end, forKey: .is_end)
    }
}

struct DocumentData: Codable {
    /// 컬렉션
    let collection: String
    
    /// 미리보기 이미지 URL
    let thumbnail_url: String
    
    /// 이미지 URL
    let image_url: String
    
    ///이미지의 가로 길이
    let width: Int
    
    ///이미지의 세로 길이
    let height: Int
    
    ///출처
    let display_sitename: String?
    
    ///문서 URL
    let doc_url: String
    
    /// 문서 작성시간, ISO 8601
    /// [YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].000+[tz]
    let datetime: DateInRegion?
    
    /// datetime 변수의 디스플레이용 포맷된 문자열
    var displayDate: String {
        return self.datetime?.toFormat("yyyy년 MM월 dd일 HH:mm:ss") ?? ""
    }
    
    private enum CodingKeys: String, CodingKey {
        case collection
        case thumbnail_url
        case image_url
        case width
        case height
        case display_sitename
        case doc_url
        case datetime
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        collection = try values.decode(String.self, forKey: .collection)
        thumbnail_url = try values.decode(String.self, forKey: .thumbnail_url)
        image_url = try values.decode(String.self, forKey: .image_url)
        width = try values.decode(Int.self, forKey: .width)
        height = try values.decode(Int.self, forKey: .height)
        display_sitename = try values.decodeIfPresent(String.self, forKey: .display_sitename)
        doc_url = try values.decode(String.self, forKey: .doc_url)
        let dateTime = try values.decodeIfPresent(String.self, forKey: .datetime)
        self.datetime = dateTime?.toDate()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(collection, forKey: .collection)
        try container.encode(thumbnail_url, forKey: .thumbnail_url)
        try container.encode(image_url, forKey: .image_url)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(display_sitename, forKey: .display_sitename)
        try container.encode(doc_url, forKey: .doc_url)
        try container.encode(datetime, forKey: .datetime)
    }
}
