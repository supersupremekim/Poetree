//
//  HistoryViewController.swift
//  Poetree
//
//  Created by 김동환 on 2021/08/10.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import Kingfisher

class HistoryViewController: UIViewController, ViewModelBindable, StoryboardBased, UICollectionViewDelegate {

    
    @IBOutlet weak var allPoemsBtn: UIButton!
    
    @IBOutlet weak var lastWeekPhotoCollectionView: UICollectionView!
    @IBOutlet weak var allPhotoCollectionView: UICollectionView!
    
    
    
    var viewModel: HistoryViewModel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        collectionViewDelegate()
    }
    
    func collectionViewDelegate() {
        
        allPhotoCollectionView.decelerationRate = .fast
        allPhotoCollectionView.isPagingEnabled = false
        allPhotoCollectionView.delegate = self
        lastWeekPhotoCollectionView.delegate = self
        lastWeekPhotoCollectionView.decelerationRate = .fast
        lastWeekPhotoCollectionView.isPagingEnabled = false
        
        
        
        //        LastWeekPhotoCollectionView.decelerationRate = .fast
        //        LastWeekPhotoCollectionView.isPagingEnabled = false
        //        LastWeekPhotoCollectionView.delegate = self
        
        let flowlayout = UICollectionViewFlowLayout()
        flowlayout.itemSize = CGSize(width: 100, height: 100 * 10 / 7)
        flowlayout.minimumInteritemSpacing = 30
        flowlayout.minimumLineSpacing = 30
        flowlayout.scrollDirection = .horizontal
        
        let totalCellWidth = 100 * 3
        let totalSpacingWidth = 30 * 2
        
        let leftInset = (lastWeekPhotoCollectionView.bounds.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset
        
        let inset = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        flowlayout.sectionInset = inset
        
        lastWeekPhotoCollectionView.collectionViewLayout = flowlayout
    }
    
    private func configureUI() {
        
        configureNavTab()
        allPoemsBtn.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        allPoemsBtn.layer.cornerRadius = 8
    }
    
    private func configureNavTab() {
        self.navigationItem.title = "History"
        self.navigationItem.largeTitleDisplayMode = .automatic
        self.tabBarItem.image = UIImage(systemName: "book.fill")
        self.tabBarItem.selectedImage = UIImage(systemName: "book.fill")
        self.tabBarItem.title = "History"
        let backItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
    }
    
    
    func bindViewModel() {
        
      
        viewModel.output.allPhotos
            .bind(to:
                    allPhotoCollectionView.rx.items(cellIdentifier: "AllPhotoCell", cellType: HistoryPhotoCollectionViewCell.self)){indexPath, photo, cell in
                print("all photo \(self.viewModel.photoService.photos())")
                print("all photo id \(photo.id)")

                cell.photoImageView.kf.setImage(with: photo.url)
            }
            .disposed(by: rx.disposeBag)
        
       
        
        allPoemsBtn.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                let viewModel = PoemListViewModel(poemService: self.viewModel.poemSevice, listType: .allPoems)
                var vc = PoemListViewController.instantiate(storyboardID: "ListRelated")
                vc.bind(viewModel: viewModel)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.output.lastWeekPhotos
            .bind(to: lastWeekPhotoCollectionView.rx.items(cellIdentifier: "LastWeekPhotoCell", cellType: LastWeekPhotoCollectionViewCell.self)){indexPath, photos, cell in
                cell.lastWeekPhotoImageView.kf.setImage(with: photos.url)
            }
            .disposed(by: rx.disposeBag)
    }
}


extension HistoryViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 100, height: 100 * 10 / 7)
    }
    
    
}
