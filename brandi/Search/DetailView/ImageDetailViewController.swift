//
//  ImageDetailViewController.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import UIKit
import Kingfisher
import RxSwift
import RxCocoa
import RxGesture
import RxOptional

class ImageDetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var topContainer: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var siteNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    
    @IBOutlet weak var imageViewDynamicHeightForEqualFrameLayout: NSLayoutConstraint!
    
    var viewModel = ImageDetailViewModel()
    private var disposeBag = DisposeBag()
    
    private let isShowingCovers = PublishRelay<Bool>()
    
    private let imageOptions: KingfisherOptionsInfo = [.transition(.fade(0.3)),
                                                       .forceTransition]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        scrollView.zoomScale = 1
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 3
        scrollView.delegate = self
        imageView.kf.indicatorType = .activity
        self.imageView.isHidden = true
    }
    
    private func setupBindings() {
        viewModel.output.image
            .asDriver(onErrorJustReturn: nil)
            .filterNil()
            .drive(onNext: { result in
                self.imageView.kf.setImage(with: result.source, options: self.imageOptions) { _ in
                    self.setFitViewHeightForImage(imageSize: result.image.size)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.thumb
            .asDriver(onErrorJustReturn: nil)
            .filterNil()
            .drive(onNext: { result in
                let placeHolder = UIImage(systemName: "photo.tv")?.alpha(0.1)
                self.thumbImageView.kf.setImage(with: result.source, placeholder: placeHolder, options: self.imageOptions)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.date
            .bind(to: dateLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.displaySiteName
            .filterEmpty()
            .bind(to: siteNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        bottomContainer.rx.tapGesture()
            .when(.recognized)
            .flatMap{ _ in
                return self.viewModel.output.displaySiteName.filterEmpty()
            }
            .flatMap { _ in
                return self.viewModel.output.sourceLink
            }
            .asDriver(onErrorJustReturn: nil)
            .filterNil()
            .drive(onNext: { url in
                UIApplication.shared.open(url)
            }).disposed(by: disposeBag)
        
        closeButton.rx.tap
            .asDriver()
            .drive(onNext: {
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func setFitViewHeightForImage(imageSize: CGSize) {
        guard let selfView = self.view,
              let imageViewHeiht = imageViewDynamicHeightForEqualFrameLayout else { return }
        let imageRatio = imageSize.height/imageSize.width
        let viewHeight = selfView.frame.height
        let newHeight = (self.imageView.frame.width * imageRatio) - viewHeight
        imageViewHeiht.constant = newHeight >= 0 ? newHeight : 0
        self.thumbImageView.isHidden = true
        self.imageView.isHidden = false
    }
}

extension ImageDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
