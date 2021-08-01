//
//  String+safeURL.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/30.
//

import UIKit

extension String {
    func safeURL() -> URL? {
        if !self.isEmpty,
           let url = URL(string: self),
           UIApplication.shared.canOpenURL(url) {
            return url
        }
        return nil
    }
}
