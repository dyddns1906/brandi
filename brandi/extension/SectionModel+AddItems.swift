//
//  SectionModel+AddItems.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/30.
//

import Foundation
import RxDataSources

extension SectionModel {
    mutating func addItems(items: [Item]) {
        self.items += items
    }
}
