//
//  SpeechRecognitionUtility.swift
//  SpeechRecognitionDemo
//
//  Created by Supreem Mishra on 18/11/19.
//  Copyright © 2019 Supreem Mishra. All rights reserved.
//

import Foundation
import Speech

enum SpeechRecognitionOperationError: Error {
    case denied
    case notDetermined
    case restricted
    case audioSessionUnavailable
    case invalidRecognitionRequest
    case audioEngineUnavailable
}

enum SpeechRecognitionOperationState {
    case authorized
    case audioEngineStart
    case audioEngineStop
    case recognitionTaskCancelled
    case speechRecognized(String)
    case speechNotRecognized
    case availabilityChanged(Bool)
    case speechRecognitionStopped(String)
}

class SpeechRecognitionUtility: NSObject, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private let recognitionStateUpdateBlock: (SpeechRecognitionOperationState, Bool) -> Void
    private var speechRecognitionPermissionState: SFSpeechRecognizerAuthorizationStatus
    private let speechRecognitionAuthorizedBlock: () -> Void
    private let timeoutPeriod: Double
    private var recognizedText: String
    private var previousOperations: [BlockOperation] = []
    
    init(speechRecognitionAuthorizedBlock : @escaping () -> Void, stateUpdateBlock: @escaping (SpeechRecognitionOperationState, Bool) -> Void, timeoutPeriod: Double = 1.5, locale: String) {
        print("Local Called")
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))//SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
        recognitionStateUpdateBlock = stateUpdateBlock
        speechRecognitionPermissionState = .notDetermined
        self.speechRecognitionAuthorizedBlock = speechRecognitionAuthorizedBlock
        self.timeoutPeriod = timeoutPeriod
        self.recognizedText = ""
        
        super.init()
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            self.speechRecognitionPermissionState = status
            if status == .authorized {
                self.audioEngine = AVAudioEngine()
                // Need to return it on Main queue since this block is returned on serial queue. Assuming user wants to do UI actions once request is authorized.
                OperationQueue.main.addOperation {
                    speechRecognitionAuthorizedBlock()
                }
            } else {
                // show denial message on UI
            }
        }
    }
    
    func startSpeechRecognition() throws {
        switch self.speechRecognitionPermissionState {
        case .denied:
            throw SpeechRecognitionOperationError.denied
        case .notDetermined:
            throw SpeechRecognitionOperationError.notDetermined
        case .restricted:
            throw SpeechRecognitionOperationError.restricted
        case .authorized:
            print("User authorized app to access speech recognition")
        }
        
        if audioEngine?.isRunning ?? false {
            audioEngine?.stop()
            recognitionRequest?.endAudio()
        } else {
            try self.runSpeechRecognition()
        }
    }
    
    func runSpeechRecognition() throws  {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            self.updateSpeechRecognitionState(with: .recognitionTaskCancelled)
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch let error {
            print("Error Occurred: \(error.localizedDescription)")
            throw SpeechRecognitionOperationError.audioSessionUnavailable
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let audioEngine = audioEngine else {
            throw SpeechRecognitionOperationError.audioEngineUnavailable
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionOperationError.invalidRecognitionRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest,
                                                            resultHandler: { [weak self] (result, error) in
                                                                
                                                                
                                                                guard let weakSelf = self else { return }
                                                                if result != nil {
                                                                    
                                                                    if let recognizedSpeechString = result?.bestTranscription.formattedString {
                                                                        self?.recognizedText = recognizedSpeechString
                                                                        self?.updateSpeechRecognitionState(with: .speechRecognized(recognizedSpeechString))
                                                                        let op = BlockOperation()
                                                                        op.addExecutionBlock {
                                                                            DispatchQueue.main.asyncAfter(deadline: .now() + weakSelf.timeoutPeriod) {
                                                                                if op == weakSelf.previousOperations.last {
                                                                                    weakSelf.updateSpeechRecognitionState(with: .speechRecognized(recognizedSpeechString), finalOutput: true)
                                                                                } else {
                                                                                    print("Speech recognition in progress. Waiting for user to stop speaking to finalize final output")
                                                                                }
                                                                            }
                                                                        }
                                                                        weakSelf.previousOperations.append(op)
                                                                        OperationQueue.main.addOperation(op)
                                                                    } else {
                                                                        weakSelf.recognizedText = ""
                                                                        weakSelf.updateSpeechRecognitionState(with: .speechNotRecognized)
                                                                    }
                                                                }
                                                                else {
                                                                    print("NO Result Called")
                                                                    weakSelf.recognizedText = ""
                                                                    weakSelf.updateSpeechRecognitionState(with: .speechNotRecognized)
                                                                }
        })
        
        
          //let recordingFormat = inputNode.outputFormat(forBus: 0)
//            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
//            //print(buffer.frameLength)
//            //print("***")
//            //print(time.audioTimeStamp.mSampleTime)
//            self.recognitionRequest?.append(buffer)
//        }
        
                let desiredFS = audioEngine.inputNode.inputFormat(forBus: 0).sampleRate
                let recordingFormat = AVAudioFormat(standardFormatWithSampleRate: desiredFS, channels: 1)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                    self.recognitionRequest?.append(buffer)
                }
        
        
       audioEngine.prepare()
        if let _ = try? audioEngine.start() {
            self.updateSpeechRecognitionState(with: .audioEngineStart)
        } else {
            throw SpeechRecognitionOperationError.audioEngineUnavailable
        }
    }
    
    func toggleSpeechRecognitionActivity() throws {
        if self.isSpeechRecognitionOn() == true {
            self.stopAudioRecognition()
        } else {
            try self.runSpeechRecognition()
        }
    }
    
    func stopSpeechRecognitionActivity() throws {
        if self.isSpeechRecognitionOn() == true {
            self.stopAudioRecognition()
        } else {
            
        }
    }
    
    // A method to stop audio engine thereby stopping device to input user audio and process it. It will remove the input source from specified Bus.
    private func stopAudioRecognition() {
        guard let audioEngine = audioEngine else { return }
        if audioEngine.isRunning {
            audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.updateSpeechRecognitionState(with: .audioEngineStop)
            self.updateSpeechRecognitionState(with: .speechRecognitionStopped(recognizedText))
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        self.recognitionRequest = nil
        
        if self.recognitionTask != nil {
            self.recognitionTask?.cancel()
            self.updateSpeechRecognitionState(with: .recognitionTaskCancelled)
            self.recognitionTask = nil
        }
    }
    
    
    private func updateSpeechRecognitionState(with state: SpeechRecognitionOperationState, finalOutput: Bool = false) {
        if Thread.isMainThread {
            self.recognitionStateUpdateBlock(state, finalOutput)
        } else {
            OperationQueue.main.addOperation {
                self.recognitionStateUpdateBlock(state, finalOutput)
            }
        }
    }
    
    private func isSpeechRecognitionOn() -> Bool {
        return self.audioEngine?.isRunning ?? false
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        self.updateSpeechRecognitionState(with: .availabilityChanged(available))
    }
}
