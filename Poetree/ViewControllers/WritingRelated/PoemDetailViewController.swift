//
//  WritingDetailViewController.swift
//  Poetree
//
//  Created by 김동환 on 2021/08/10.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import Firebase
import Toast_Swift

class PoemDetailViewController: UIViewController, ViewModelBindable, StoryboardBased, HasDisposeBag {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var contentLabel: UITextView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var likesCountLabel: UILabel!
    @IBOutlet weak var backBtnItem: UIBarButtonItem!
    @IBOutlet weak var reportBtn: UIBarButtonItem!
    @IBOutlet weak var keepWriteBtn: UIButton!
    @IBOutlet weak var privateBtn: UIButton!
    
    var viewModel: PoemDetailViewModel!
    var isLike: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configNavBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.systemOrange]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = UIColor.systemOrange
    }
    
    func configNavBar() {
        self.navigationController?.navigationBar.shadowImage = UIImage()
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.label]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = UIColor.label
    }
    
    func configureUI(){
        
        makePhotoViewShadow(superView: photoView, photoImageView: photoImageView)
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        let attributes = [NSAttributedString.Key.paragraphStyle: style]
        self.contentLabel.attributedText = NSAttributedString(string: self.contentLabel.text, attributes: attributes)
        self.contentLabel.font = UIFont.systemFont(ofSize: 18, weight: .light)
        
        self.photoImageView.layer.cornerRadius = 8
        self.privateBtn.contentEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
        self.privateBtn.layer.cornerRadius = 5
        
    }
    
    
    func bindViewModel() {
  
        self.viewModel.displayingPoem
            .drive(onNext:{ [weak self] poem in
                
                guard let self = self else {return}
                
                self.photoImageView.kf.setImage(with: poem.photoURL)
                self.titleLabel.text = poem.title
                self.contentLabel.text = poem.content
                self.userLabel.text = "\(poem.userPenname)님이 \(convertDateToString(format: "MMM d", date: poem.uploadAt))에 보낸 글"
                self.isLike = poem.isLike
                self.likesCountLabel.text = "좋아요 \(poem.likers.count)개"
                self.likeBtn.isSelected = poem.isLike
                self.privateBtn.isHidden = !poem.isPrivate
                
                if Auth.auth().currentUser == nil {
                    self.likeBtn.isSelected = false
                }
                
                if self.viewModel.isTempDetail {
                    self.likeBtn.isHidden = true
                    self.likesCountLabel.isHidden = true
                    self.deleteBtn.isHidden = false
                    self.editBtn.isHidden = true
                    self.keepWriteBtn.isHidden = false
                } else if self.viewModel.isUserWriting {
                    self.deleteBtn.isHidden = false
                    self.editBtn.isHidden = false
                    self.keepWriteBtn.isHidden = true
                }
                
            })
            .disposed(by: rx.disposeBag)
        
        
        self.backBtnItem.rx.tap
            .subscribe(onNext:{ _ in
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: rx.disposeBag)
        
        self.editBtn.rx.tap
            .withLatestFrom(self.viewModel.displayingPoem)
            .subscribe(onNext:{[weak self] poem in
                
                guard let self = self else {return}
                
                let viewModel = WriteViewModel(poemService: self.viewModel.poemService, userService: self.viewModel.userService, writingType: .edit(poem), beforeEditedPoem: poem)
                
                let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
                backBarButtonItem.tintColor = .systemOrange
                self.navigationItem.backBarButtonItem = backBarButtonItem
                
                var vc = WritingViewController.instantiate(storyboardID: "WritingRelated")
                vc.bind(viewModel: viewModel)
                
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: rx.disposeBag)
        
        self.keepWriteBtn.rx.tap
            .withLatestFrom(self.viewModel.displayingPoem)
            .subscribe(onNext:{[weak self] poem in
                
                guard let self = self else {return}
                
                let viewModel = WriteViewModel(poemService: self.viewModel.poemService, userService: self.viewModel.userService, writingType: .temp(poem))
                
                let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
                backBarButtonItem.tintColor = .systemOrange
                self.navigationItem.backBarButtonItem = backBarButtonItem
                
                var vc = WritingViewController.instantiate(storyboardID: "WritingRelated")
                vc.bind(viewModel: viewModel)
                
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: rx.disposeBag)
        
        self.deleteBtn.rx.tap
            .withLatestFrom(self.viewModel.displayingPoem)
            .subscribe(onNext:{[weak self] poem in
                
                guard let self = self else {return}
                let deleteAlert = self.fetchAlertForDelete(poem: poem)
                self.present(deleteAlert, animated: true, completion: nil)
                
            })
            .disposed(by: rx.disposeBag)
        
        self.reportBtn.rx.tap
            .withLatestFrom(self.viewModel.displayingPoem)
            .subscribe(onNext:{ poem in
                
                guard self.viewModel.isTempDetail == false else { self.view.makeToast("임시로 저장된 글은 신고할 수 없습니다", duration: 1.0, position: .center)
                    return}
                let reportAlert = self.fetchAlertForReport(poem: poem)
                self.present(reportAlert, animated: true, completion: nil)
            })
            .disposed(by: rx.disposeBag)
        
        
        likeBtn.rx.tap
            .do(onNext:{ [weak self] _ in guard let self = self else {return}
                    self.likeBtn.animateView()})
            .withLatestFrom(self.viewModel.displayingPoem)
            .subscribe(onNext:{ poem in
                if let currentUser = Auth.auth().currentUser {
                    self.viewModel.poemService.likeHandle(poem: poem, user: currentUser){ poem in
                        DispatchQueue.main.async {
                            self.likeBtn.isSelected = poem.isLike
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.view.makeToast("좋아요를 위해서는 로그인이 필요합니다", duration: 0.7, position: .center)
                    }
                }
            })
            .disposed(by: rx.disposeBag)
    }
}

//MARK: - Fetch UIAlert

extension PoemDetailViewController {
    
    func fetchAlertForDelete(poem: Poem) -> UIAlertController {
        let alert = UIAlertController(title: "글 삭제", message: "글을 삭제하시겠습니까?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "확인", style: .destructive) { action in
            self.viewModel.poemService.deletePoem(deletingPoem: poem)
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "unwindfromDetailView", sender: self)
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        return alert
    }
    
    func fetchAlertForReport(poem: Poem) -> UIAlertController {
        let alert = UIAlertController(title: "신고하기", message: "비속어 등 악의적인 표현이 있는 글을 신고해 주시기 바랍니다.\n신고된 글은 추후에 볼 수 없으며\n적절성 검토 후에 글쓴이의 Poetree 이용을 제한합니다.\n또한, 글쓴이를 차단할 경우, 이후 해당 글쓴이의 글은 볼 수 없습니다.\n참여해주셔서 감사합니다.", preferredStyle: .actionSheet)
        let reportAction = UIAlertAction(title: "신고하기", style: .destructive) { _ in
            let currentUser = Auth.auth().currentUser
            
            self.viewModel.poemService.reportPoem(poem: poem, currentUser: currentUser) {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "unwindfromDetailView", sender: self)
                }
            }
        }
        let blockAction = UIAlertAction(title: "글쓴이 차단하기", style: .destructive) { _ in
            guard let currentUser = Auth.auth().currentUser else {
                
                let alert = UIAlertController(title: "로그인이 필요합니다", message: "글쓴이 차단 기능은\n로그인 후 이용할 수 있습니다", preferredStyle: .alert)
                let action = UIAlertAction(title: "확인", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
                return}
            
            self.viewModel.poemService.blockWriter(poem: poem, currentUser: currentUser) {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "unwindfromDetailView", sender: self)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(reportAction)
        alert.addAction(blockAction)
        alert.addAction(cancelAction)
        return alert
    }
}
