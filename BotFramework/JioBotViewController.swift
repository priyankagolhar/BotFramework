//
//  JioBotViewController.swift
//  JioBots
//
//  Created by Santhosh Sahukari on 13/12/18.
//  Copyright © 2018 RelianceJIO. All rights reserved.
//

import UIKit
import Speech

let speechRecognitionTimeout: Double = 1.5
let maximumAllowedTimeDuration = 14
import WebKit

@available(iOS 10.0, *)
public class JioBotViewController: UIViewController, WKScriptMessageHandler, UINavigationControllerDelegate {
    
    //IBOutlet
    @IBOutlet weak var webContainerView: UIView!
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var incresedCameraPreview: UIView!
    
    @IBOutlet weak var cameraPreviewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cameraPreviewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cameraPreviewTopConstraint: NSLayoutConstraint!
    
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    //Properties
    public var botURL:String!
    let webViewLoadDelay = 2.0
    var presentedViewCount = 0
    public var bottitle = ""
    let iphone11 = "iPhone 11"
    public var wkWebView: WKWebView!
    // A utility to easily use the speech recognition facility.
     var speechRecognizerUtility: SpeechRecognitionUtility?
    private var timer: Timer?
    private var totalTime: Int = 0
    private var _speechRecognizer: Any? = nil
    
    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    var imageBuffer: CVPixelBuffer?
    var videoInitialFrame: CGRect?
    
    
   public override func viewDidLoad() {
        super.viewDidLoad()

    
    }
    
   public override func viewDidAppear(_ animated: Bool) {
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        if self.bottitle == "Umang New bot"{
        self.view.backgroundColor = UIColor(red: 81/255, green: 199/255, blue: 183/255, alpha: 1.0)
        }
    }
    
   public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        initializeUI()
        self.navigationController?.isNavigationBarHidden = true
        
    }
    
    //MARK:- SetUpWKWebView
   public func setWKWebView(){
        let contentController = WKUserContentController()
        contentController.add(self, name: JavaScriptCallBack.CallBackName)
        let wkWebconfiguration = WKWebViewConfiguration()
        wkWebconfiguration.userContentController = contentController
        wkWebconfiguration.allowsInlineMediaPlayback = true
        
        if #available(iOS 10.0, *) {
            wkWebconfiguration.mediaTypesRequiringUserActionForPlayback = []
        } else {
            // Fallback on earlier versions
            wkWebconfiguration.requiresUserActionForMediaPlayback = false
        }
        let wkWebFrame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width:self.webContainerView.frame.size.height, height: self.webContainerView.frame.size.height))
        self.wkWebView = WKWebView(frame:wkWebFrame,configuration: wkWebconfiguration)
        self.wkWebView.translatesAutoresizingMaskIntoConstraints = false
        self.wkWebView.navigationDelegate = self
        self.wkWebView.uiDelegate = self
        self.wkWebView.scrollView.delegate = self
        //self.wkWebView.configuration.preferences.setOfflineApplicationCacheIsEnabled = true
         webContainerView.addSubview(self.wkWebView)
        
        self.wkWebView.topAnchor.constraint(equalTo: self.webContainerView.topAnchor).isActive = true
        self.wkWebView.rightAnchor.constraint(equalTo: self.webContainerView.rightAnchor).isActive = true
        self.wkWebView.leftAnchor.constraint(equalTo: self.webContainerView.leftAnchor).isActive = true
        self.wkWebView.bottomAnchor.constraint(equalTo: self.webContainerView.bottomAnchor).isActive = true
        self.wkWebView.heightAnchor.constraint(equalTo: self.webContainerView.heightAnchor).isActive = true
        self.wkWebView.reloadFromOrigin()
        
//        if #available(iOS 9.0, *)
//        {
//            let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeWebSQLDatabases])
//            let date = NSDate(timeIntervalSince1970: 0)
//
//            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler:{ })
//        }
//        else
//        {
//            var libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, false).first!
//            libraryPath += "/Cookies"
//
//            do {
//                try FileManager.default.removeItem(atPath: libraryPath)
//            } catch {
//                print("error")
//            }
//            URLCache.shared.removeAllCachedResponses()
//        }
        
    }
    
    //initialize viewController UI
   public func initializeUI() {
        setWKWebView()
        let url = URL(string: botURL)
        var urlRequest = URLRequest(url: url!)
        urlRequest.cachePolicy = .returnCacheDataElseLoad
        self.wkWebView.load(urlRequest)
    }
    
   public func initializeCameraUI() {
        self.view.bringSubviewToFront(cameraPreview)
        self.wkWebView.addSubview(cameraPreview)
        self.setupAVCapture()
        startImageCapture()
    }
    
   public func speakButtonPressed(locale: String) {
        self.stopTimeCounter()
        if speechRecognizerUtility == nil {
            // Initialize the speech recognition utility here
            speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                self?.toggleSpeechRecognitionState()
                }, stateUpdateBlock: { [weak self] (currentSpeechRecognitionState, finalOutput) in
                    // A block to update the status of speech recognition. This block will get called every time Speech framework recognizes the speech input
                    self?.stateChangedWithNew(state: currentSpeechRecognitionState)
                    // We won't perform translation until final input is ready. We will usually wait for users to finish speaking their input until translation request is sent
                    if finalOutput {
                        //self?.stopTimeCounter()
                        self?.toggleSpeechRecognitionState()
                        //SpeechRecognisitionDone
                    }
                }, timeoutPeriod: speechRecognitionTimeout,  // We will set the Speech recognition Timeout to make sure we get the full string output once user has stopped talking. For example, if we specify timeout as 2 seconds. User initiates speech recognition, speaks continuously (Hopegully way less than full one minute), and if pauses for more than 2 seconds, value of finalOutput in above block will be true. Before that you will keep getting output, but that won't be the final one.
                locale: locale)
            
        } else {
            // We will call this method to toggle the state on/off of speech recognition operation.
            self.toggleSpeechRecognitionState()
        }
    }
    
    
    //this function is controller in which we get call from javaScript
   public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("AllValues-->",message.name)
        if(message.name == JavaScriptCallBack.CallBackName) {
            if let decodedData = Data(base64Encoded: String(describing: message.body), options: Data.Base64DecodingOptions.ignoreUnknownCharacters) {
                if let decodedDictionary = (try? JSONSerialization.jsonObject(with: decodedData, options: .allowFragments)) as? [AnyHashable: Any] {
                    self.processInput(jsonOutput: decodedDictionary as NSDictionary)
                    print("AllValues-->",decodedDictionary)
                }
            }
        }
        
    }
    
    //handling the callbacks from javaScript
    func processInput(jsonOutput:NSDictionary) {
        print("AllValues-->",jsonOutput.allKeys as NSArray)
        if (jsonOutput.allKeys as NSArray).contains(JavaScriptCallBack.TypeValue) {
            if (jsonOutput.value(forKey: JavaScriptCallBack.TypeValue) as! String) == JavaScriptCallBack.Close {
                self.dismiss(animated: true, completion: nil)
            }
            else if (jsonOutput.value(forKey: JavaScriptCallBack.TypeValue) as! String) == JavaScriptCallBack.startcamera {
                self.initializeCameraUI()
            }
            else if (jsonOutput.value(forKey: JavaScriptCallBack.TypeValue) as! String) == JavaScriptCallBack.opencamera {
                if (jsonOutput["data"] as! Bool) {
                    self.previewLayer.isHidden = false
                    startImageCapture()
                }
                else {
                    stopImageCapture()
                }
            }
            else if (jsonOutput.value(forKey: JavaScriptCallBack.TypeValue) as! String) == JavaScriptCallBack.hidecamera {
                if (jsonOutput["data"] as! Bool) {
                    self.previewLayer.isHidden = true
                }
                else {
                    self.previewLayer.isHidden = false
                }
            }
            else if (jsonOutput.value(forKey: JavaScriptCallBack.TypeValue) as! String) == JavaScriptCallBack.LaunchWebBrowser {
                if let stringValue = jsonOutput[JavaScriptCallBack.Value] as? String, let urlValue = URL(string: stringValue) {
                    UIApplication.shared.open(urlValue, completionHandler:nil)
                }
            }
            else if (jsonOutput.value(forKey: JavaScriptCallBack.TypeValue) as! String) == JavaScriptCallBack.QuestionTapped {
                //self.speechRecognizer.restartSpeechTimeout()
                do {
                    try self.speechRecognizerUtility?.stopSpeechRecognitionActivity()
                    stopTimeCounter()
                }
                catch {
                    print("Error Occured")
                }
            }
            else if (jsonOutput.value(forKey: JavaScriptCallBack.TypeValue) as! String) == JavaScriptCallBack.MicrophoneRecording {
                if #available(iOS 10.0, *) {
                    let langConfig = jsonOutput["config"] as? Dictionary<String,Any>
                    if langConfig != nil {
                        if let lang = langConfig!["language"] as? String {
                            if lang.caseInsensitiveCompare("hi") == .orderedSame {
                                // Do nothing
                                speechRecognizerUtility = nil
                                speakButtonPressed(locale: "hi-IN")
                            }else {
                                speechRecognizerUtility = nil
                                speakButtonPressed(locale: "en_US")
                            }
                        }
                    }else{
                        //speakButtonPressed()
                    }
                }
            }
        }
    }
    
    
    private func stateChangedWithNew(state: SpeechRecognitionOperationState) {
        switch state {
        case .authorized:
            print("State: Speech recognition authorized")
        case .audioEngineStart:
            self.startTimeCounterAndUpdateUI()
            print("State: Audio Engine Started")
        case .audioEngineStop:
            print("State: Audio Engine Stopped")
        case .recognitionTaskCancelled:
            print("State: Recognition Task Cancelled")
        case .speechRecognized(let recognizedString):
            print("State: Recognized String \(recognizedString)")
        case .speechNotRecognized:
            print("State: Speech Not Recognized")
        case .availabilityChanged(let availability):
            print("State: Availability changed. New availability \(availability)")
        case .speechRecognitionStopped(let finalRecognizedString):
            self.stopTimeCounter()
            self.didRecognizeSpeech(recongnizedString: finalRecognizedString, isFinal: true)
            print("State: Speech Recognition Stopped with final string \(finalRecognizedString)")
        }
    }
    
    
    private func startTimeCounterAndUpdateUI() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let weakSelf = self else { return }
            guard weakSelf.totalTime < maximumAllowedTimeDuration else {
                do {
                    try weakSelf.speechRecognizerUtility?.stopSpeechRecognitionActivity()
                    self?.timer?.invalidate()
                    self?.timer = nil
                }
                catch let error{
                    print("ErrorIS->", error.localizedDescription)
                }
                return
            }
            weakSelf.totalTime = weakSelf.totalTime + 1
        })
    }
    
    // A method to toggle the speech recognition state between on/off
    private func toggleSpeechRecognitionState() {
        do {
            try self.speechRecognizerUtility?.toggleSpeechRecognitionActivity()
        } catch SpeechRecognitionOperationError.denied {
            print("Speech Recognition access denied")
        } catch SpeechRecognitionOperationError.notDetermined {
            print("Unrecognized Error occurred")
        } catch SpeechRecognitionOperationError.restricted {
            print("Speech recognition access restricted")
        } catch SpeechRecognitionOperationError.audioSessionUnavailable {
            print("Audio session unavailable")
        } catch SpeechRecognitionOperationError.invalidRecognitionRequest {
            print("Recognition request is null. Expected non-null value")
        } catch SpeechRecognitionOperationError.audioEngineUnavailable {
            print("Audio engine is unavailable. Cannot perform speech recognition")
        } catch {
            print("Unknown error occurred")
        }
    }
    
    private func stopTimeCounter() {
        self.timer?.invalidate()
        self.timer = nil
        self.totalTime = 0
        do {
            try self.speechRecognizerUtility?.stopSpeechRecognitionActivity()
        }
        catch {
            print("Error Occured")
        }
        print("TimeOut....")
    }
}



