//
//  ViewModelType.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    var input: Input { get }
    var output: Output { get }
}
