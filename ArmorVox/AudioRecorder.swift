//
//  AudioRecorder.swift
//  ArmorVox
//
//  Created by Rob Dixon on 28/07/2017.
//  Copyright © 2017 Auraya Systems. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit



// MARK: - RecordingMode
public enum RecordingMode {
    case notReady, ready, recording
}



// MARK: - AudioRecorderDelegate
protocol AudioRecorderDelegate {
    func didDetectEndOfSpeech()
    func didUpdateMetering(result: String) // needs better parameter? (it's only for testing)
}



// MARK: - AudioRecorder
class AudioRecorder: NSObject {
    
    // Notification
    // We send a notification when recordPermission is granted (since a VC might need to refresh, e.g. enable a button)
    struct Notifications {
        static let readyToRecord = Notification.Name("readyToRecord")
    }
    
    
    
    // MARK: - Data
    
    fileprivate var savedDataRootURL: URL = FileManager.default.temporaryDirectory
    
    fileprivate var audioRecorder: AVAudioRecorder?
    fileprivate var audioFileURL: URL?
    
    var isRecording: Bool {
        get {
            return audioRecorder?.isRecording ?? false
        }
    }
    
    var delegate: AudioRecorderDelegate?
    
    var completionClosure: ((URL?, RecordingMode) -> Void)?
    var filenameForRecording: String?
    
    
    
    // MARK: - end-of-speech detection
    
    // don't begin detecting end-of-speech until after a delay
    fileprivate let delayBeforeAutoStop: TimeInterval = 3.0 // seconds
    fileprivate var delayBeforeAutoStopTimer: Timer? // if this timer is valid, don't detect end-of-speech
    // don't record for more than a maximum duration
    fileprivate let maxRecordingDuration: TimeInterval = 10.0 // Note: after testing, make sure it's set to 10 seconds
    fileprivate var maxRecordingDurationTimer: Timer? // stop recording if/when this fires
    // examine record-level meters while recording is in progress
    fileprivate let meteringTimerInterval: TimeInterval = 0.2 // seconds
    fileprivate var meteringTimer: Timer?
    fileprivate var minPeakPower: Float = 0
    fileprivate var maxPeakPower: Float = -160
    fileprivate var minAveragePower: Float = 0
    fileprivate var maxAveragePower: Float = -160
    // trigger...
    fileprivate var triggerThreshold: Float? // (will be set dynamically) levels quieter than this will trigger end-of-speech detection
    fileprivate let triggerThresholdOffset: Float = 3 // level must be this much louder than threshold, to trigger
    fileprivate var consecutiveTriggerThresholds: Int = 0
    fileprivate let maxConsecutiveTriggerThresholds: Int = 3 // stop recording after this number of meter readings below the triggerThreshold (1 = 0.2 seconds)
    
    
    
    // MARK: - init
    
    override init() {
        super.init()
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
            // If user previously granted or denied recording permission, the block executes immediately and without displaying a recording permission alert
            // else the system displays a recording permission alert, and executes the block after the user responds to it.
            guard granted else {
                logger.log(.error, "No permission to record audio!")
                return
            }
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch let error as NSError {
                logger.log(.error, "AVAudioSession.setActive failed with error: \(error)")
            }
            // Modify Playback Mixing Behavior
            let options: AVAudioSessionCategoryOptions = .defaultToSpeaker
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: options)
            } catch let error as NSError {
                logger.log(.error, "AVAudioSession.setCategory failed with error: \(error)")
            }
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                logger.log(.error, "AVAudioSession.setActive failed with error: \(error)")
            }
            let soundName: String = "voiceRecording.wav" // temporary file name, will be given a (random) unique filename on saving
            self.audioFileURL = self.savedDataRootURL.appendingPathComponent(soundName)
            // This is as specified, and seems to work correctly
            let recordSettings: Dictionary<String, Any> = [
                AVSampleRateKey: NSNumber(value: 8000.0),
                AVEncoderBitRateKey: NSNumber(value: 16),
                AVNumberOfChannelsKey: NSNumber(value: 1), // NOTE mono
                AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.medium.rawValue),
            ]
            do {
                self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL!, settings: recordSettings)
                self.audioRecorder?.isMeteringEnabled = true
                self.audioRecorder?.delegate = self
            } catch let error as NSError {
                logger.log(.error, "avAudioPlayer failed with error: \(error.localizedDescription)")
            }
            // send notification
            DispatchQueue.main.async {
                // call UI functions with the results of the above
                // send a notification that we're ready to record
                NotificationCenter.default.post(name: Notifications.readyToRecord, object: nil, userInfo: nil)
            }
        }
    }
    
    
    
    // MARK: - Metering
    
    fileprivate func peakPower() -> Float {
        // max = 0 dB (may be exceeded)
        // min = -160 dB (near silence)
        if let recorder = audioRecorder {
            recorder.updateMeters()
            return recorder.peakPower(forChannel: 0)
        }
        return 0.0
    }
    
    fileprivate func averagePower() -> Float {
        // max = 0 dB (may be exceeded)
        // min = -160 dB (near silence)
        if let recorder = audioRecorder {
            recorder.updateMeters()
            return recorder.averagePower(forChannel: 0)
        }
        return 0.0
    }
    
    
    
    // MARK: - RECORDER
    
    func prepareToRecord() -> Bool {
        if let recorder = audioRecorder {
            recorder.prepareToRecord()
            return true
        }
        logger.log(.error, "no AVAudioRecorder")
        return false
    }
    
    func record(filename: String, completion: @escaping (URL?, RecordingMode) -> Void) -> Bool {
        // start recording
        completionClosure = completion // now we can call this from anywhere
        filenameForRecording = filename
        //logger.log(.debug, "Recorder start")


        if let recorder = audioRecorder {
            let recordingStarted = recorder.record()
            if recordingStarted {
                delayBeforeAutoStopTimer = Timer.scheduledTimer(withTimeInterval: delayBeforeAutoStop, repeats: false, block: { (timer: Timer) in
                })
                maxRecordingDurationTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false, block: { (timer: Timer) in
                    // Maximum recording duration has been reached...
                    self.endOfSpeech()
                })
                meteringTimer = Timer.scheduledTimer(withTimeInterval: meteringTimerInterval, repeats: true, block: { (timer: Timer) in
                    // get the metering values, set min, max
                    let peakPower = self.peakPower()
                    self.minPeakPower = min(self.minPeakPower, peakPower)
                    self.maxPeakPower = max(self.maxPeakPower, peakPower)
                    let averagePower = self.averagePower()
                    self.minAveragePower = min(self.minAveragePower, averagePower)
                    self.maxAveragePower = max(self.maxAveragePower, averagePower)
                    // check for end-of-speech?
                    let checkEndOfSpeech = !(self.delayBeforeAutoStopTimer?.isValid ?? false)
                    var belowThreshold = false
                    if checkEndOfSpeech {
                        // calculate threshold...
                        if self.triggerThreshold == nil {
                            self.triggerThreshold = self.minAveragePower + self.triggerThresholdOffset
                        } else {
                            if averagePower < self.triggerThreshold! {
                                belowThreshold = true
                                self.consecutiveTriggerThresholds += 1
                                if self.consecutiveTriggerThresholds > self.maxConsecutiveTriggerThresholds {
                                    // end-point detected!
                                    self.endOfSpeech()
                                    self.consecutiveTriggerThresholds = 0
                                }
                            } else {
                                self.consecutiveTriggerThresholds = 0
                            }
                        }
                    }
                    // Used during testing
                    // show metering...
                    var result = "minPeak: \(self.minPeakPower)\n"
                    result.append("maxPeak: \(self.maxPeakPower)\n")
                    result.append("minAverage: \(self.minAveragePower)\n")
                    result.append("maxAverage: \(self.maxAveragePower)\n\n")
                    result.append("peak: \(peakPower)\n")
                    result.append("average: \(averagePower)\n\n")
                    if belowThreshold {
                        result.append("consecutiveTriggerThresholds: \(self.consecutiveTriggerThresholds)\n")
                    }
                    self.delegate?.didUpdateMetering(result: result)
                })
            }
            return recordingStarted
        }
        logger.log(.error, "no AVAudioRecorder")
        return false
    }
    
    func stop() {
        // stop recording
        //logger.log(.debug, "stop()")
        invalidateTimers()
        if let recorder = audioRecorder {
            recorder.stop()
        } else {
            logger.log(.error, "no AVAudioRecorder")
        }
        // Pass back the results...
        if let closure = self.completionClosure {
            var completionURL: URL? = nil
            // do we have a recording?
            if let currentURL = audioFileURL,
                FileManager.default.fileExists(atPath: currentURL.path),
                let filename = filenameForRecording,
                let renamedURL = renameRecording(to: filename) {
                completionURL = renamedURL
            }
            closure(completionURL, .ready)
            self.completionClosure = nil
            self.filenameForRecording = nil
        }
    }
    
    func renameRecording(to name: String) -> URL? {
        if let currentURL = audioFileURL {
            let newSoundName: String = name + ".wav"
            let rootURL = currentURL.deletingLastPathComponent()
            let newURL = rootURL.appendingPathComponent(newSoundName)
            // if newURL already exists, delete it
            if FileManager.default.fileExists(atPath: newURL.path) {
                do {
                    try FileManager.default.removeItem(at: newURL)
                } catch let error as NSError {
                    logger.log(.error, "\(error.localizedDescription)")
                    return nil
                }
            }
            do {
                try FileManager.default.moveItem(at: currentURL, to: newURL)
                //logger.log(.debug, "Renamed \(currentURL.lastPathComponent) To \(newURL.lastPathComponent)")
                return newURL
            } catch let error as NSError {
                logger.log(.error, "\(error.localizedDescription), \n\trenaming \n\t\t\(currentURL) to \n\t\t\(newURL)")
            }
        }
        return nil
    }

    func deleteRecordings() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: savedDataRootURL,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for url in contents {
                if url.pathExtension == "wav" {
                    do {
                        try FileManager.default.removeItem(at: url)
                    } catch {
                        logger.log(.debug, "Couldn't delete url: \(url)")
                    }
                }
            }
        } catch {
            logger.log(.error, "Couldn't get directory contents")
        }
    }
}



// MARK: - end-of-speech detection
extension AudioRecorder {
    
    fileprivate func endOfSpeech() {
        delegate?.didDetectEndOfSpeech() // tell our delegate
    }
    
    fileprivate func invalidateTimers() {
        delayBeforeAutoStopTimer?.invalidate()
        maxRecordingDurationTimer?.invalidate()
        meteringTimer?.invalidate()
    }
}



// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        //logger.log(.debug, "Finished Recording")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            logger.log(.debug, "Error - Audio Record Decode: \(error.localizedDescription)")
        }
    }
}

// MARK: - AudioRecorderDelegate
// audioRecorder can be it's own delegate
extension AudioRecorder: AudioRecorderDelegate {
    
    func didDetectEndOfSpeech() {
        stop()
    }
    
    func didUpdateMetering(result: String) {
        //logger.log(.debug, "\(result)")
    }
}

















