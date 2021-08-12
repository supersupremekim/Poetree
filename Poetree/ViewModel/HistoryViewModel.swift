//
//  HistoryViewModel.swift
//  Poetree
//
//  Created by 김동환 on 2021/08/11.
//

import Foundation

class HistoryViewModel: ViewModelType {
    
    
    let poemSevice: PoemService!
    
    struct Input {
        
    }
    
    struct Output {
        
    }
    
    var input: Input
    var output: Output
    
    init(poemSevice: PoemService) {
        self.input = Input()
        self.output = Output()
        self.poemSevice = poemSevice
    }
}
