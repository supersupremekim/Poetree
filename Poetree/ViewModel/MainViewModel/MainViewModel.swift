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
    let userService: UserService
    
    struct Input {

        let selectedIndex: PublishSubject<Int>
    }
    
    struct Output {
        let currentDate: Driver<String>
        let thisWeekPhotoURL: Observable<[WeekPhoto]>
        let displayingPoems: Observable<[Poem]>
        let selectedPhotoId: Observable<Int>

    }
    
    var input: Input
    var output: Output
    
    init(poemService: PoemService, photoService: PhotoService, userService: UserService){
        
        
        self.poemService = poemService
        self.photoService = photoService
        self.userService = userService
        let poems = poemService.allPoems()
            .map(poemService.filterPoemsForPublic)
            .map(poemService.filterBlockedPoem)
        
        let photos = photoService.photos()
        
        let currentDate = Observable<String>.just(poemService.getCurrentWeek())
            .asDriver(onErrorJustReturn: "Jan 1st")
        
        let thisWeekPhotoURL = photos.map(photoService.getThisWeekPhoto)
        
        let selectedIndex = PublishSubject<Int>()
            
        let selectedPhotoId = Observable.combineLatest(photos, selectedIndex){ photos, index -> Int in
            
            let photoId = photoService.fetchPhotoId(photos: photos, index)
            return photoId
        }
        
        let displayingPoems = Observable.combineLatest(poems, selectedPhotoId){ poems, photoId -> [Poem] in
            let displayingPoem = poemService.fetchPoemsByPhotoId_SortedLikesCount(poems: poems, photoId: photoId)
                .prefix(3)
            
            return Array(displayingPoem)
        }
        
        self.input = Input(selectedIndex: selectedIndex)
        self.output = Output(currentDate: currentDate, thisWeekPhotoURL: thisWeekPhotoURL, displayingPoems: displayingPoems, selectedPhotoId: selectedPhotoId)
    }
}
