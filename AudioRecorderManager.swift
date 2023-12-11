//
//  AudioRecorderManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/7/15.
//

import UIKit
import AVFoundation

class AudioRecorderManager: NSObject {
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var callback: ((_ data: NSData, _ duration: Double)-> ())?
    
    static let `default`: AudioRecorderManager = {
        return AudioRecorderManager()
    }()
    
    public func recording(callback: @escaping ((_ data: NSData, _ duration: Double) -> ())) {
        self.callback = callback
        // MARK: 配置Session+申请权限
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            recordingSession.requestRecordPermission() { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        // MARK: 创建录制按钮
                        self?.startRecording()
                    } else {
                        log.info("用户未允许")
                    }
                }
            }
        } catch {
            log.info("录音创建失败")
        }
    }
    
    private func startRecording() {
        // MARK: 1-配置录音保存的地址
        // MARK: 2-一些配置
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM), //音频格式
            AVSampleRateKey: 44100, //采样率
            AVLinearPCMBitDepthKey: 16,//采样位数
            AVNumberOfChannelsKey: 2, //通道数
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue //录音质量
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: URL(string: filePath)!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()

            // MARK: 3-开始录音
            if audioRecorder?.record() == true {
                log.info("开始录音")
            } else {
                log.info("录音失败")
            }
        } catch {
            stopRecording()
        }
    }

    //播放
    func play() {
        //设置外放模式，不然录音会用听筒模式播放，就很小声
        if recordingSession.category != AVAudioSession.Category.playback {
            do{
                try recordingSession.setCategory(AVAudioSession.Category.playback)
            } catch{
                log.info("外放模式设置失败")
            }
        }
        do {
            player = try AVAudioPlayer(contentsOf: URL(string: filePath)!)
            log.info("歌曲长度：\(player!.duration)")
            player!.play()
        } catch let err {
            log.info("播放失败:\(err.localizedDescription)")
        }
    }
    
    // 1-用户按下按钮停止录音和2-录音失败都调用此函数，分别传入true和false
    public func stopRecording() {
        if audioRecorder?.isRecording == false { return }
        audioRecorder?.stop()
        audioRecorder = nil
        do {
            player = try AVAudioPlayer(contentsOf: URL(string: filePath)!)
            LameTool.audio(toMP3: filePath) { [weak self] filePath, data in
                self?.filePath = filePath
                self?.callback?(data as NSData, self?.player?.duration ?? 0)
            }
        } catch {
            log.info(error)
        }
    }

    public func deleteRecordingFile(){
        if FileManager.default.fileExists(atPath: self.filePath){
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                log.info("文件移除失败")
            }
        }
    }
    
    private lazy var filePath: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        return paths + "/\(Date.todayTimestamp)" + ".caf"
    }()
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    // 录音意外中断（手机来电等）的时候
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
        }
    }
}
