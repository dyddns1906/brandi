//
//  ErrorViewModel.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/30.
//

import Foundation
import RxSwift
import RxCocoa
import RxAlamofire

class ErrorViewModel: ViewModelType {
    struct Input {
        var errorHandlr: PublishRelay<ErrorModel>
    }
    struct Output {
    }
    
    static let shared = ErrorViewModel()
    
    var input: Input
    var output: Output
    
    private var disposeBag = DisposeBag()

    private let errorHandlr = PublishRelay<ErrorModel>()
    
    init() {
        input = Input(errorHandlr: errorHandlr)
        output = Output()
    }
    
    private func setupBindings() {
        errorHandlr
            .subscribe { error in
                print(error.localizedDescription)
            } onError: { error in
                print(error.localizedDescription)
            }
            .disposed(by: disposeBag)

    }
}
