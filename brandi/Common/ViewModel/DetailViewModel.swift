//
//  DetailViewModel.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import Foundation
import RxSwift
import RxCocoa
import Kingfisher

class ImageDetailViewModel: ViewModelType {
    struct Input {
        var data: PublishRelay<DocumentData>
    }
    struct Output {
        var image: BehaviorRelay<RetrieveImageResult?>
        var thumb: BehaviorRelay<RetrieveImageResult?>
        var date: BehaviorRelay<String>
        var sourceLink: BehaviorRelay<URL?>
        var displaySiteName: BehaviorRelay<String>
    }
    
    var input: Input
    var output: Output
    
    private var disposeBag = DisposeBag()
    private let data = PublishRelay<DocumentData>()
    
    private let imageOb = BehaviorRelay<RetrieveImageResult?>(value: nil)
    private let thumb = BehaviorRelay<RetrieveImageResult?>(value: nil)
    private let date = BehaviorRelay<String>(value: "")
    private let sourceLink = BehaviorRelay<URL?>(value: nil)
    private let displaySiteName = BehaviorRelay<String>(value: "")
    
    init() {
        input = Input(data: data)
        output = Output(image: imageOb,
                        thumb: thumb,
                        date: date,
                        sourceLink: sourceLink,
                        displaySiteName: displaySiteName)
        setupBindings()
    }
    
    private func setupBindings() {
        data
            .subscribe(onNext: { data in
                if let thumb = data.thumbnail_url.safeURL() {
                    KingfisherManager.shared.retrieveImage(with: thumb) { result in
                        switch result {
                        case .success(let value):
                            self.thumb.accept(value)
                        case .failure(let error):
                            ErrorViewModel.shared.input.errorHandlr.accept(.extensionError(error))
                        }
                    }
                }
                
                if let mainImage = data.image_url.safeURL() {
                    KingfisherManager.shared.retrieveImage(with: mainImage) { result in
                        switch result {
                        case .success(let value):
                            self.imageOb.accept(value)
                        case .failure(let error):
                            ErrorViewModel.shared.input.errorHandlr.accept(.extensionError(error))
                        }
                    }
                }
                
                self.date.accept(data.displayDate)
                
                self.displaySiteName.accept(data.display_sitename ?? "")
                if let url = data.doc_url.safeURL() {
                    self.sourceLink.accept(url)
                }
            })
            .disposed(by: disposeBag)
        
    }
}
