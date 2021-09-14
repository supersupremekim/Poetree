//
//  Function.swift
//  Poetree
//
//  Created by 김동환 on 2021/08/12.
//

import Foundation


func convertDateToString(format: String, date: Date) -> String {
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    let dateString = dateFormatter.string(from: date)
    return dateString
    
}

func convertStringToDate(dateFormat: String, dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    let date = dateFormatter.date(from: dateString)!
    return date
}

func getWeek(day: Int) -> String {
    switch day {
    case 1...7:
        return "1st"
    case 8...14:
        return "2nd"
    case 15...21:
        return "3rd"
    case 22...27:
        return "4th"
    default:
        return "5th"
    }
}

func getCycleString(time: Int) -> String {
    switch time {
    case 6..<12:
       return "아침"
    case 12..<18:
       return "낮"
    case 18..<21:
       return "저녁"
    default:
       return "밤"
    }
}

func getMonday(myDate: Date) -> Date {
    let cal = Calendar.current
    var comps = cal.dateComponents([.weekOfYear, .yearForWeekOfYear], from: myDate)
    comps.weekday = 2 // Monday
    let mondayInWeek = cal.date(from: comps)!
    return mondayInWeek
}


struct BadWords: Codable {
    var badwords: [String]
}

func loadBadWordsFromJson() -> [String] {
    if let path = Bundle.main.path(forResource: "badwords", ofType: "json") {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            do {
                let badwordsModel = try JSONDecoder().decode(BadWords.self, from: data)
                return badwordsModel.badwords
            }
            catch {
                print("decode error")
                return []
            }
        }
        catch {
            print("path error")
            return []
        }
    } else {
        print("path nil")
        return []
    }
}

func checkBadWords(content: String) -> Bool {
    let badwords = loadBadWordsFromJson()
    for badword in badwords {
        if content.contains(badword) {
            return true
        }
    }
    return false
}


import CryptoKit

// Unhashed nonce.
var currentNonce: String?

@available(iOS 13, *)

@available(iOS 13, *)
func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}



func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}
