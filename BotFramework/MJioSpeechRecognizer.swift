//
//  MJioSpeechRecognizer.swift
//  MyBot
//
//  Created by Supreem Mishra on 27/08/19.
//  Copyright © 2019 Jio. All rights reserved.
//

import Foundation
import UIKit
import Speech

public protocol MJioSpeechRecognizerDelegate {
    func didRecognizeSpeech(recongnizedString:String,isFinal:Bool)
    func errorOccuredInSpeechRecognition()
    func didRecognizeCamera(cameraBuffer: String)
    // Use this method to post action after speech recoginization like open deeplink for eg:launch app
}

let speechEnglishLocaleIdentifier = "en-IN"
let speechHindiLocaleIdentifier = "hi-IN"



@available(iOS 10.0, *)
open class MJioSpeechRecognizer: NSObject ,SFSpeechRecognizerDelegate {
    
    public var delegate:MJioSpeechRecognizerDelegate?
    
    var speechRecognizerEnglish = SFSpeechRecognizer()
    var speechRecognizerHindi: SFSpeechRecognizer?
    
    public override init() {
        super.init()
        speechRecognizerEnglish = SFSpeechRecognizer(locale: Locale.init(identifier: speechEnglishLocaleIdentifier))!
        speechRecognizerEnglish?.delegate = self
        speechRecognizerHindi = SFSpeechRecognizer(locale: Locale.init(identifier: speechHindiLocaleIdentifier))!
        speechRecognizerHindi?.delegate = self
    }
}

