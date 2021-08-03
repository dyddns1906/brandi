//
//  SearchResultCollectionViewCell.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import UIKit

class SearchResultCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        imageView.image = nil
        imageView.hero.id = nil
    }
}
