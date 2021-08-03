//
//  SearchViewModel.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import Foundation
import RxSwift
import RxCocoa
import RxAlamofire
import Alamofire
import KakaoSDKCommon


class SearchViewModel: ViewModelType {
    struct Input {
        var keyword: BehaviorRelay<String>
        var fetchNextPage: PublishRelay<Bool>
        var size: BehaviorRelay<Int>
    }
    struct Output {
        var sectionModel: BehaviorRelay<[SearchModel.SearchResultSectionModel]>
        var isFetching: BehaviorRelay<Bool>
    }
    
    private let baseKakaoUrl = "https://dapi.kakao.com/v2/search/image?"
    private let ApiKey = "eca7278e1d9e4383a065fff207f29245"
    
    var input: Input
    var output: Output
    
    private var disposeBag = DisposeBag()
    private var requestDisposeBag = DisposeBag()
    
    private let keyword = BehaviorRelay<String>(value: "")
    private let fetchNextPage = PublishRelay<Bool>()
    private let page = BehaviorRelay<Int?>(value: nil)
    private let size = BehaviorRelay<Int>(value: 30)
    
    private let sectionModel = BehaviorRelay<[SearchModel.SearchResultSectionModel]>(value: [])
    private let searchUrl = PublishSubject<String>()
    
    private let changeData = PublishSubject<SearchResult?>()
    private let addData = PublishSubject<SearchResult?>()
    
    private let errorHandlr = PublishRelay<ErrorModel>()
    
    private let isFetching = BehaviorRelay<Bool>(value: true)
    private let isLastData = BehaviorRelay<Bool>(value: false)
    
    init() {
        input = Input(keyword: keyword, fetchNextPage: fetchNextPage, size: size)
        output = Output(sectionModel: sectionModel,
                        isFetching: isFetching)
        
        keyword.filterEmpty()
            .flatMap { keyword in
                return self.search(keyword, page: self.page.value ?? 1, size: self.size.value)
            }
            .flatMap{ url in
                return self.mappingResultData(url: url)
            }
            .do(onNext: { _ in
                self.page.accept(1)
            })
            .bind(to: changeData)
            .disposed(by: disposeBag)
        
        fetchNextPage
            .distinctUntilChanged()
            .map { fetchNextPage in
                return fetchNextPage && !self.isFetching.value && !self.isLastData.value
            }
            .filter { $0 }
            .flatMap { _ -> Observable<Int?> in
                return .just(self.page.value)
            }
            .filterNil()
            .flatMap { pageNumber -> Observable<String> in
                return self.search(self.keyword.value, page: pageNumber + 1, size: self.size.value)
            }
            .distinctUntilChanged()
            .flatMap{ url in
                return self.mappingResultData(url: url)
            }
            .filterNil()
            .bind(to: addData)
            .disposed(by: disposeBag)
        
        changeData
            .map{ result in
                guard let result = result else { return [] }
                return [SearchModel.SearchResultSectionModel(model: 0, items: result.documents)]
            }
            .bind(to: sectionModel)
            .disposed(by: disposeBag)
        
        
        addData
            .map{ result in
                guard let result = result,
                      var originData = self.sectionModel.value.first else { return [] }
                originData.addItems(items: result.documents)
                return [originData]
            }
            .do(onNext: { _ in
                self.page.accept((self.page.value ?? 1) + 1)
            })
            .bind(to: sectionModel)
            .disposed(by: disposeBag)
    }
    
    private func search(_ keywrod: String, page: Int = 1, size: Int = 30) -> Observable<String> {
        return Observable<String>.create { observe -> Disposable in
            let keywordEncodes = keywrod.urlEncode()
            let result = self.baseKakaoUrl + "query=\(keywordEncodes)&page=\(page)&size=\(size)"
            if !keywordEncodes.isEmpty {
                observe.onNext(result)
            } else {
                let error = AFError.invalidURL(url: result)
                ErrorViewModel.shared.input.errorHandlr.accept(.extensionError(error))
            }
            return Disposables.create()
        }
        .debug(keywrod)
    }
    
    private func mappingResultData(url: String) -> Observable<SearchResult?> {
        return self.request(url)
            .map { result -> Data? in
                switch result {
                case .success(let data):
                    return data
                case .failure(let error):
                    ErrorViewModel.shared.input.errorHandlr.accept(.extensionError(error))
                    return nil
                }
            }
            .map { data in
                guard let data = data else { return nil }
                return try? SdkJSONDecoder.default.decode(SearchResult.self, from: data)
            }
            .catchError { error in
                ErrorViewModel.shared.input.errorHandlr.accept(.extensionError(error))
                return .just(nil)
            }.do(onNext: { result in
                if let result = result {
                    self.isLastData.accept(result.meta.is_end)
                } else {
                    self.isLastData.accept(false)
                }
            })
    }
    
    private func request(_ url: URLConvertible) -> Observable<AFResult<Data>> {
        requestDisposeBag = DisposeBag()
        self.isFetching.accept(true)
        return Observable<AFResult<Data>>.create { observe -> Disposable in
            let authorization = HTTPHeader(name: "Authorization", value: "KakaoAK " + self.ApiKey)
            RxAlamofire.request(.get, url, headers: [authorization])
                .validate(statusCode: 200..<300)
                .responseData()
                .subscribe { response, data in
                    observe.onNext(.success(data))
                    self.isFetching.accept(false)
                } onError: { error in
                    observe.onNext(.failure(error.asAFError ?? .invalidURL(url: url)))
                    self.isFetching.accept(false)
                } onCompleted: {
                    self.isFetching.accept(false)
                } onDisposed: {
                    self.isFetching.accept(false)
                }
                .disposed(by: self.requestDisposeBag)
            return Disposables.create()
        }
    }
}

extension String {
    func urlEncode() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}
