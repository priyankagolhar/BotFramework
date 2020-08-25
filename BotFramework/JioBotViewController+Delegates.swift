//
//  JioBotViewController+Delegates.swift
//  JioBots
//
//  Created by Supreem Mishra on 22/11/19.
//  Copyright © 2019 RelianceJIO. All rights reserved.
//

import Foundation
import WebKit
import AVFoundation

//MARK:- Jio Speech recoginizer delegate methods
extension JioBotViewController: MJioSpeechRecognizerDelegate {
    
    
   public func didRecognizeSpeech(recongnizedString: String, isFinal: Bool) {
        if isFinal {
            let javascript = "sendTextForSpeech(\""+recongnizedString+"\")"
            self.wkWebView.evaluateJavaScript(javascript, completionHandler: nil)
        }
    }
    
   public func errorOccuredInSpeechRecognition() {
        print("errorOccuredCalled")
        let javascript = "sendTextForSpeech('"+"ASR_ERROR"+"')"
        self.wkWebView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
   public func didRecognizeCamera(cameraBuffer: String) {
        if let _ = self.wkWebView {
            DispatchQueue.main.async {
                let javascript =  "captureCameraFeed('\(cameraBuffer)')"
                self.wkWebView.evaluateJavaScript(javascript, completionHandler: nil)
            }
            
        }
    }
}

//MARK:- WKNavigationDelegate
extension JioBotViewController: WKUIDelegate, WKNavigationDelegate {
    
   public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        //Start to load
    }
    
   public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    }
    
  public  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    }
    
   public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + webViewLoadDelay) {
            //self.view.activityStopAnimating()
            self.activityIndicator.stopAnimating()
        }
        
    }
    
}

extension JioBotViewController: UIScrollViewDelegate {
   public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}
