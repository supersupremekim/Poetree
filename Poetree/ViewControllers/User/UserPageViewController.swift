//
//  UserPageViewController.swift
//  Poetree
//
//  Created by 김동환 on 2021/08/10.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import FirebaseAuth
import SideMenu

class UserPageViewController: UIViewController, ViewModelBindable, StoryboardBased {
    
    @IBOutlet weak var navBarBtn: UIBarButtonItem!
    @IBOutlet weak var pennameLabel: UILabel!
    @IBOutlet weak var userWritingLabel: UILabel!
    @IBOutlet weak var userLikedLabel: UILabel!
    @IBOutlet weak var likedWrtingsTableView: UITableView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var greetingView: UIView!
    @IBOutlet weak var userWritingCollectionView: UICollectionView!
    @IBOutlet weak var userWritingMoreBtn: UIButton!
    @IBOutlet weak var userWritingMoreBtn2: UIButton!
    @IBOutlet weak var likeWritingMoreBtn: UIButton!
    @IBOutlet weak var likeWritingMoreBtn2: UIButton!
    
    
    
    var viewModel: MyPoemViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        collectionViewDelegate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.pennameLabel.alpha = 0
        self.greetingLabel.alpha = 0
        
        greetingAni()
    }
    
    
    private func configureUI() {
        configureNavTab()
        makeShadow()
        greetingView.layer.masksToBounds = false
    }
    
    private func configureNavTab() {
        self.navigationItem.title = "My Poem"
        self.navigationItem.largeTitleDisplayMode = .automatic
        self.tabBarItem.image = UIImage(systemName: "person.fill")
        self.tabBarItem.selectedImage = UIImage(systemName: "person.fill")
        self.tabBarItem.title = "My Poem"
        let backItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
    }
    
    func collectionViewDelegate(){
        userWritingCollectionView.decelerationRate = .fast
        userWritingCollectionView.isPagingEnabled = false
        userWritingCollectionView.delegate = self
        
        
        let flowlayout = UICollectionViewFlowLayout()
        flowlayout.itemSize = CGSize(width: 150, height: self.userWritingCollectionView.frame.height)
        flowlayout.minimumInteritemSpacing = 15
        flowlayout.scrollDirection = .horizontal
        
        userWritingCollectionView.collectionViewLayout = flowlayout
    }
    
    func bindViewModel() {
        
        self.viewModel.output.loginUser
            .drive(onNext:{ [unowned self] loginUser in
                
                if loginUser.userEmail == "unknowned" {
                    self.userWritingLabel.text = "비회원"
                    self.userLikedLabel.text = "비회원"
                }else {
                    self.userWritingLabel.rx.text.onNext("\(loginUser.userPenname)님의 글")
                    self.userLikedLabel.rx.text.onNext("\(loginUser.userPenname)님이 좋아한 글")
                }
            })
            .disposed(by: rx.disposeBag)
        
        self.navBarBtn.rx.tap
            .subscribe(onNext:{
                
                guard let menuVC = UIStoryboard(name: "UserRelated", bundle: nil).instantiateViewController(identifier: "SideMenuViewController") as? SideMenuViewController else {return}
                
                let viewModel = SideMenuViewModel(userService: self.viewModel.userService)
                menuVC.viewModel = viewModel
                let menu = SideMenuNavigationController(rootViewController: menuVC)
                menu.presentationStyle = .menuSlideIn
                
                
                self.present(menu, animated: true, completion: nil)
                
            })
            .disposed(by: rx.disposeBag)
        
        self.viewModel.output.userWritings
            .bind(to: self.userWritingCollectionView.rx.items(cellIdentifier: "UserWritingCollectionViewCell", cellType: UserWritingCollectionViewCell.self)){
                indexPath, poem, cell in
                
                //좋아요 순으로 되어야함
                cell.imageView.kf.setImage(with: poem.photoURL)
                cell.titleLabel.text = poem.title
                cell.dateLabel.text = convertDateToString(format: "yyyy MMM d", date: poem.uploadAt)
                
                switch indexPath {
                case 0:
                    cell.likeStatusBtn.isHidden = false
                    cell.likeStatusBtn.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
                    cell.likeStatusBtn.setTitle("Most favorite", for: .normal)
                    cell.likeStatusBtn.layer.cornerRadius = 8
                case 1:
                    cell.likeStackView.isHidden = false
                    cell.likesCountLabel.text = "\(poem.likers.count)"
                case 2:
                    cell.likeStackView.isHidden = false
                    cell.likesCountLabel.text = "\(poem.likers.count)"
                default:
                    break
                }
                
            }
            .disposed(by: rx.disposeBag)
        
        
        self.viewModel.output.userLikedWritings
            .bind(to: likedWrtingsTableView.rx.items(cellIdentifier: "UserLikedWritingTableViewCell", cellType: UserLikedWritingTableViewCell.self)){ indexPath, poem, cell in
                
                cell.titleLabel.text = poem.title
                cell.authorLabel.text = poem.userPenname
                cell.likesCountLabel.text = "\(poem.likers.count)"
            }
            .disposed(by: rx.disposeBag)
        
        
    }
    
    func greetingAni(){
        
        if let _ = Auth.auth().currentUser {
            
            self.viewModel.output.loginUser
                .drive(onNext:{ user in
                    
                    if user.userPenname == "비회원" {
                        self.pennameLabel.text = self.viewModel.userService.greetingLine(date: Date())
                    }
                    
                    self.pennameLabel.rx.text.onNext("\(user.userPenname)님")
                    self.greetingLabel.text = self.viewModel.userService.greetingLine(date: Date())
                })
                .disposed(by: rx.disposeBag)
            
            UIView.animate(withDuration: 1, delay: 1, options: .curveEaseOut) {
                self.pennameLabel.alpha = 1
            } completion: { pennameFadeInComplete in
                
                UIView.animate(withDuration: 1, delay: 1, options: .curveEaseOut) {
                    self.pennameLabel.alpha = 0
                    self.greetingLabel.alpha = 1
                }
            }
            
        } else {
            self.greetingLabel.text = self.viewModel.userService.greetingLine(date: Date())
            UIView.animate(withDuration: 1, delay: 1, options: .curveEaseOut) {
                self.greetingLabel.alpha = 1
            }
        }
    }
    
    func makeShadow() {
        greetingView.layer.cornerRadius = 8
        greetingView.layer.shadowColor = UIColor.systemGray3.cgColor
        greetingView.layer.shadowRadius = 8
        greetingView.layer.shadowOffset = .zero
        greetingView.layer.shadowOpacity = 0.4
 
    }
    
}

extension UserPageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (tableView.frame.height) / 5
    }
    
}

extension UserPageViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: self.userWritingCollectionView.frame.height)
    }
}
