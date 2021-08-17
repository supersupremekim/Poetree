//
//  WritingViewController.swift
//  Poetree
//
//  Created by 김동환 on 2021/08/10.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import Kingfisher

class WritingViewController: UIViewController, ViewModelBindable, StoryboardBased, HasDisposeBag {
    
    var viewModel: WriteViewModel!
    
    @IBOutlet weak var selectedPhoto: UIImageView!
    @IBOutlet weak var userDateLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var privateChechBtn: UIButton!
    @IBOutlet weak var editComplete: UIButton!
    @IBOutlet weak var writeComplete: UIButton!
    
    var isPrvate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI(){
        selectedPhoto.kf.setImage(with: viewModel.output.photoDisplayed)
        
        if let _ = viewModel.output.editingPoem {
            self.writeComplete.isHidden = true
        } else {
            self.editComplete.isHidden = true
        }
        
    }
    
    
    func bindViewModel() {
      
        viewModel.output.getCurrentDate
            .drive(userDateLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        titleTextField.rx.text.orEmpty
            .debug()
            .bind(to: viewModel.input.title)
            .disposed(by: rx.disposeBag)
        
        contentTextView.rx.text.orEmpty
            .debug()
            .bind(to: viewModel.input.content)
            .disposed(by: rx.disposeBag)
        
        privateChechBtn.rx.tap
            .do(onNext:{self.isPrvate = !self.isPrvate
                self.privateChechBtn.isSelected.toggle()
            })
            .map{[unowned self] in self.isPrvate}
            .bind(to: viewModel.input.isPrivate)
            .disposed(by: rx.disposeBag)
        
        if let editingPoem = viewModel.output.editingPoem {
            self.contentTextView.text = editingPoem.content
            self.titleTextField.text = editingPoem.title
            self.isPrvate = editingPoem.isPrivate
            self.privateChechBtn.isSelected = !isPrvate
        }
    }
    
    @IBAction func sendPoemTapped(_ sender: UIButton) {
        
        viewModel.output.aPoem
            .take(1)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(queue: DispatchQueue.global()))
            .subscribe(onNext: {[unowned self] aPoem in
                self.viewModel.createPeom(poem: aPoem)
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    @IBAction func editCompleteTapped(_ sender: UIButton) {
        
        viewModel.output.aPoem
            .take(1)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(queue: DispatchQueue.global()))
            .subscribe(onNext:{ [unowned self] poem in
                self.viewModel.editePoem(editedPoem: poem)
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: rx.disposeBag)
    }
}
