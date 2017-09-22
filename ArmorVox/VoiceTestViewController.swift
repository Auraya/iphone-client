//
//  VoiceTestViewController.swift
//  ArmorVox
//
//  Created by Rob Dixon on 07/08/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - VoiceTestViewController
class VoiceTestViewController: UIViewController {
    
    // MARK: - UI
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var resultsTextView: UITextView!
    
    
    // MARK: - Data
    
    let audioRecorder = AudioRecorder()
    var recordingMode = RecordingMode.notReady {
        didSet {
            switch recordingMode {
            case .notReady:
                startStopButton.setTitle("Start", for: .normal)
                startStopButton.isEnabled = false
                view.backgroundColor = UIColor.backgroundWhenNotRecording
            case .ready:
                startStopButton.setTitle("Start", for: .normal)
                startStopButton.isEnabled = true
                view.backgroundColor = UIColor.backgroundWhenNotRecording
            case .recording:
                startStopButton.setTitle("Stop", for: .normal)
                startStopButton.isEnabled = true
                view.backgroundColor = UIColor.backgroundWhenRecording
            }
        }
    }
    
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // audioRecorder
        audioRecorder.delegate = self
        if audioRecorder.prepareToRecord() {
            recordingMode = .ready
        }
        // subscribe to notification that we're ready to record
        NotificationCenter.default.addObserver(forName: AudioRecorder.Notifications.readyToRecord, object: nil, queue: OperationQueue.main) { (notification) in
            if self.recordingMode == .notReady {
                self.recordingMode = .ready
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if audioRecorder.isRecording {
            audioRecorder.stop()
            recordingMode = .ready
        }
        audioRecorder.deleteRecordings()
    }
    
    
    
    // MARK: - Action
    
    @IBAction func startStopButtonPress(_ sender: UIButton) {
        switch recordingMode {
        case.notReady:
            break
        case .ready:
            // start
            if audioRecorder.record(filename: "test", completion: { (url: URL?, newRecordingMode: RecordingMode) in
                self.recordingMode = newRecordingMode
                if let utteranceURL = url  { // success, got recording at url
                    logger.log(.debug, "file: \(utteranceURL.lastPathComponent)")
                } else { // voice recording failure
                    logger.log(.error, "Voice Recording failed")
                }
            }) {
                //Recording started successfully
                recordingMode = .recording
            }
        case .recording:
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioRecorder.stop()
        recordingMode = .ready
    }
    
    
    
    // MARK: - Methods
    
}



// MARK: - AudioRecorderDelegate
extension VoiceTestViewController: AudioRecorderDelegate {
    
    func didDetectEndOfSpeech() {
        stopRecording()
    }
    
    func didUpdateMetering(result: String) {
        resultsTextView.text = result
    }
}
