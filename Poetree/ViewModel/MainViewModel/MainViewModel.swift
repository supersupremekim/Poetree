//
//  MainViewModel.swift
//  Poetree
//
//  Created by 김동환 on 2021/08/10.
//

import Foundation
import RxSwift
import RxCocoa
import NSObject_Rx


class MainViewModel: ViewModelType {
    
    let photoService: PhotoService
    let poemService: PoemService
    
    
    struct Input {
        let selectedIndex: BehaviorSubject<Int>
    }
    
    struct Output {
        let currentDate: Driver<String>
        let thisWeekPhotoURL: Observable<[WeekPhoto]>
        let displayingPoems: Observable<[Poem]>
    }
    
    var input: Input
    var output: Output
    
    init(poemService: PoemService, photoService: PhotoService){
        
        
        self.poemService = poemService
        self.photoService = photoService
        
        let poems = poemService.allPoems()
        let photos = photoService.photos()
        
        let currentDate = Observable<String>.just(poemService.getCurrentDate())
            .asDriver(onErrorJustReturn: "Jan 1st")
        
        
        let thisWeekPhotoURL = photos.map(photoService.getThisWeekPhoto)
        
        
        let selectedIndex = BehaviorSubject<Int>(value: 0)
        
        let selectedPhotoId = Observable.combineLatest(photos, selectedIndex){ photos, index -> Int in
            let photoId = photoService.fetchPhotoId(photos: photos, index)
            return photoId
        }
        
        let displayingPoems = Observable.combineLatest(poems, selectedPhotoId){ poems, photoId -> [Poem] in
            
            let disPlayingPoem = poems.filter { poem in
                poem.photoId == photoId
            }
            
            return disPlayingPoem
        }
        
        self.input = Input(selectedIndex: selectedIndex)
        self.output = Output(currentDate: currentDate, thisWeekPhotoURL: thisWeekPhotoURL, displayingPoems: displayingPoems)
    }
}
