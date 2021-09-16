//
//  SemiDetailViewModel.swift
//  Poetree
//
//  Created by 김동환 on 2021/09/08.
//

import Foundation
import RxSwift
import RxCocoa

class SemiDetailViewModel: ViewModelType {
    
    var input: Input
    var output: Output
    
    let poemService: PoemService
    let userService: UserService
    
    struct Input{
        let isLikeThisPoem: PublishSubject<Bool>
    }
    
    struct Output{
        let displayingPoem: Driver<Poem>
    }
    
    
    init(poem: Poem, poemService: PoemService, userService: UserService){
        
        self.poemService = poemService
        self.userService = userService
        
        let isLikeThisPoem = PublishSubject<Bool>()
        
        let poems = poemService.allPoems()
        
        let displayingPoem = poems.map{poems in poemService.fetchPoem(poems: poems, poem: poem)}
            .asDriver(onErrorJustReturn: poem)
        
//        let displayingPoem = Observable.combineLatest(initialPoem.asObservable(), isLikeThisPoem) { poem, isLikeThisPoem -> Poem in
//            poem.isLike = isLikeThisPoem
//            return poem
//        }
        
        
        self.input = Input(isLikeThisPoem: isLikeThisPoem)
        self.output = Output(displayingPoem: displayingPoem)
    }
}
