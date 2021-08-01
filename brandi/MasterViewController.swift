//
//  MasterViewController.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import UIKit
import RxSwift
import RxCocoa
import RxOptional
import Kingfisher
import Hero
import NVActivityIndicatorView
import SnapKit

class MasterViewController: UIViewController {
    
    @IBOutlet weak var resultCollectionView: UICollectionView!
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var disposeBag = DisposeBag()
    private let searchViewModel = SearchViewModel()
    
    private let lineitemCount: CGFloat = 3
    
    private let isScrolling = BehaviorRelay<Bool>(value: false)
    private let isScrollingAnimation = BehaviorRelay<Bool>(value: false)
    private let isPossibleFetch = BehaviorRelay<Bool>(value: false)
    
    private let loadingIndicator: NVActivityIndicatorView = {
        let indicator = NVActivityIndicatorView(frame: CGRect.zero, type: .ballPulseSync, color: .black)
        return indicator
    }()
    
    private let resultEmptyView: UIView = {
        let view = UIView()
        let label = UILabel()
        label.text = "검색 결과가 없습니다."
        label.font = .systemFont(ofSize: 20)
        label.textColor = UIColor(cgColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2))
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        setupLoadingIndicator()
        setSearchBar()
        setupCollectionView()
        setupEmptyView()
    }
    
    private func setupLoadingIndicator() {
        self.view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.center.equalTo(self.view)
        }
    }
    
    private func setupCollectionView() {
        resultCollectionView.rx.setDelegate(self).disposed(by: disposeBag)
        resultCollectionView.register(UINib(nibName: SearchResultCollectionViewCell.className, bundle: nil), forCellWithReuseIdentifier: SearchResultCollectionViewCell.className)
    }
    
    private func setSearchBar() {
        guard let navigationController = navigationController else { return }
        navigationController.navigationBar.prefersLargeTitles = true
        
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.backgroundColor = .secondarySystemBackground
        navigationController.navigationBar.standardAppearance = standardAppearance
        
        let scrollAppearance = UINavigationBarAppearance()
        scrollAppearance.configureWithTransparentBackground()
        navigationController.navigationBar.scrollEdgeAppearance = scrollAppearance
        
        searchController.searchBar.placeholder = "이미지 검색"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.definesPresentationContext = true
        searchController.automaticallyShowsSearchResultsController = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        navigationController.navigationBar.sizeToFit()
    }
    
    private func setupEmptyView() {
        self.view.addSubview(resultEmptyView)
        resultEmptyView.snp.makeConstraints { make in
            make.edges.equalTo(self.resultCollectionView.snp.edges)
        }
        self.view.bringSubviewToFront(resultEmptyView)
    }
    
    private func setupBindings() {
        searchController.searchBar.rx.text.orEmpty
            .skip(1)
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .filterEmpty()
            .do(onNext: { _ in
                self.resultCollectionView.setContentOffset(.zero, animated: false)
            })
            .bind(to: searchViewModel.input.keyword)
            .disposed(by: disposeBag)
        
        searchViewModel.output.sectionModel
            .do(onNext: { datas in
                self.resultEmptyView.isHidden = !(datas.first?.items.isEmpty ?? true)
            })
            .bind(to: resultCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        searchViewModel.output.isFetching
            .skip(1)
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { isFetching in
                if isFetching {
                    self.loadingIndicator.startAnimating()
                } else {
                    self.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
        
        resultCollectionView.rx.modelSelected(DocumentData.self)
            .asDriver()
            .drive(onNext: { data in
                self.view.endEditing(true)
                let vc = ImageDetailViewController()
                vc.viewModel.input.data.accept(data)
                vc.hero.isEnabled = true
                vc.view.hero.id = data.thumbnail_url
                vc.view.hero.modifiers = [.durationMatchLongest]
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(isScrolling.distinctUntilChanged(),
                                 isScrollingAnimation.distinctUntilChanged(),
                                 isPossibleFetch.distinctUntilChanged())
            .map { !$0 && !$1 && $2 }
            .bind(to: searchViewModel.input.fetchNextPage)
            .disposed(by: disposeBag)
    }
    
    private lazy var dataSource = SearchModel.DataSource<SearchModel.SearchResultSectionModel>(configureCell: configureCell)
    
    private lazy var configureCell: SearchModel.DataSource<SearchModel.SearchResultSectionModel>.ConfigureCell = { [weak self] (dataSource, view, indexPath, item) in
        guard let strongSelf = self else { return UICollectionViewCell() }
        return strongSelf.customCell(indexPath: indexPath, data: item)
    }
    
    private func customCell(indexPath: IndexPath, data: DocumentData) -> UICollectionViewCell {
        let cell = resultCollectionView.dequeueReusableCell(withReuseIdentifier: SearchResultCollectionViewCell.className, for: indexPath) as! SearchResultCollectionViewCell
        if let imageUrl = URL(string: data.thumbnail_url) {
            let placeHolder = UIImage(systemName: "photo.tv")?.alpha(0.1)
            cell.imageView.kf.setImage(with: imageUrl, placeholder: placeHolder)
            cell.hero.id = data.thumbnail_url
        }
        return cell
    }
}

extension MasterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let sectionSpacing = layout.sectionInset.left + layout.sectionInset.right
        let width = collectionView.bounds.width - sectionSpacing
        let cellWidth = (width - layout.minimumLineSpacing) / lineitemCount
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling.accept(true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isScrolling.accept(false)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        isScrollingAnimation.accept(true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrollingAnimation.accept(false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let startMoreData = resultCollectionView.contentSize.height - scrollView.frame.size.height - 150
        let requestFetch = offsetY > startMoreData && offsetY > 0 && startMoreData > 0
        self.isPossibleFetch.accept(requestFetch)
    }
}
