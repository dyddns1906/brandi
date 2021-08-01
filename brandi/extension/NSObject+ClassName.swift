//
//  NSObject+ClassName.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import Foundation

extension NSObject {
    class var className: String {
        return String(describing: self)
    }
    
    var className: String {
        return type(of: self).className
    }
}
