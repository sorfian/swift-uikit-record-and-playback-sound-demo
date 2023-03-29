//
//  RecordProViewController.swift
//  RecordPro
//
//  Created by Sorfian on 29/03/23.
//

import UIKit
import AVFoundation

class RecordProViewController: UIViewController {
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    
    private var timer: Timer?
    private var elapsedTimeInSecond: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func record(_ sender: UIButton) {
//        Stop the audio player before recording
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        if !audioRecorder.isRecording {
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setActive(true)
                
//                Start recording
                audioRecorder.record()
                startTimer()
                
//                Change to the pause image
                recordButton.setImage(UIImage(named: "Pause"), for: UIControl.State.normal)
            } catch  {
                print(error)
            }
        } else {
//            Pause recording
            audioRecorder.pause()
            pauseTimer()
            
//            Change to the record image
            recordButton.setImage(UIImage(named: "Record"), for: .normal)
        }
        
        stopButton.isEnabled = true
        playButton.isEnabled = false
    }
    
    @IBAction func stop(_ sender: UIButton) {
        recordButton.setImage(UIImage(named: "Record"), for: .normal)
        recordButton.isEnabled = true
        stopButton.isEnabled = false
        playButton.isEnabled = true
        
//        Stop the audio recorder
        audioRecorder.stop()
        resetTimer()
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
    }
    
    private func configure() {
        stopButton.isEnabled = false
        playButton.isEnabled = false
        
//        Get document directory, if fails just skip the rest of code
        guard let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            let alertMessage = UIAlertController(title: "Error", message: "Failed to get the document directory for recording the audio. Please try again later", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: nil)
            return
            
        }
        
//        Set the default audio file
        let audiofileURL = directoryURL.appendingPathExtension("MyAudioDemo.m4a")
        
//        Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            
//            Define the recorder setting
            let recorderSetting: [String:Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
//            Initiate an prepare the recorder
            audioRecorder = try AVAudioRecorder(url: audiofileURL, settings: recorderSetting)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
        } catch  {
            print(error)
        }
    }
    
//    MARK: - Timer Label
    func startTimer()  {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats:true, block: { timer in
            self.elapsedTimeInSecond += 1
            self.updateTimeLabel()
        })
    }
    
    func pauseTimer() {
        timer?.invalidate()
    }
    
    func resetTimer() {
        timer?.invalidate()
        elapsedTimeInSecond = 0
        updateTimeLabel()
    }
    
    func updateTimeLabel() {
        let seconds = elapsedTimeInSecond % 60
        let minutes = (elapsedTimeInSecond/60) % 60
        
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
}

extension RecordProViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let alertMessage = UIAlertController(title: "Finish Recording", message: "Successfully recorded the audio!", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: nil)
        }
        resetTimer()
    }
}


extension RecordProViewController: AVAudioPlayerDelegate {
    @IBAction func play(_ sender: UIButton) {
        if !audioRecorder.isRecording {
            guard let player = try? AVAudioPlayer(contentsOf: audioRecorder.url) else {
                print("Failed to initialize AVAudioPlayer")
                return
                
            }
            
            if let audio = audioPlayer, audio.isPlaying {
               return
            }
            
            audioPlayer = player
            audioPlayer?.delegate = self
            audioPlayer?.play()
            startTimer()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.isEnabled = false
        resetTimer()
        
        let alertMessage = UIAlertController(title: "Finish Playing", message: "Finish playing the recording!", preferredStyle: .alert)
        alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler : nil))
        present(alertMessage, animated: true, completion: nil)
    }
}
