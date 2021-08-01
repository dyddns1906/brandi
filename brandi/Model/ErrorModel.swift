//
//  ErrorModel.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/30.
//

import Foundation

enum ErrorModel: Error {
    case extensionError(Error)
    case DataValidateError
    
    var localizedDescription: String {
        var message = ""
        switch self {
        case .extensionError(let error):
            message = error.localizedDescription
        
        case .DataValidateError:
            message = ""
        }
        
        return "ErrorModel Error =============\n>>>>>\(message)\n\(self)"
    }
}
