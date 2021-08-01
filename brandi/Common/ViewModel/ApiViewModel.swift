//
//  ApiViewModel.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import Foundation
import RxSwift
import RxCocoa
import RxAlamofire

class ApiViewModel: ViewModelType {
    struct Input {
        var keyword: BehaviorRelay<String>
        var page: BehaviorRelay<Int>
        var size: BehaviorRelay<Int>
    }
    struct Output {
        var url: PublishRelay<String>
    }
    
    static let shared = ApiViewModel()
    private let baseKakaoUrl = "https://dapi.kakao.com/v2/search/image?"
    
    var input: Input
    var output: Output
    
    private var disposeBag = DisposeBag()
    
    private let keyword = BehaviorRelay<String>(value: "")
    private let page = BehaviorRelay<Int>(value: 1)
    private let size = BehaviorRelay<Int>(value: 30)
    
    private let searchUrl = PublishRelay<String>()
    
    init() {
        input = Input(keyword: keyword, page: page, size: size)
        output = Output(url: searchUrl)
        
        Observable.combineLatest(keyword, page, size)
            .map { self.search($0, page: $1, size: $2) }
            .bind(to: searchUrl)
            .disposed(by: disposeBag)
    }
    
    private func search(_ keywrod: String, page: Int = 1, size: Int = 30) -> String {
        return baseKakaoUrl + "query=\(keywrod)&page=\(page)&size=\(size)"
    }
}
