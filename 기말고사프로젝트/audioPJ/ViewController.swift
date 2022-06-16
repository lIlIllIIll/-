//
//  ViewController.swift
//  audioPJ
//
//  Created by 윤수민 on 2022/06/16.
//

import UIKit
import AVFoundation // 오다오 재생을 위한 헤더 파일
import MobileCoreServices // 다양한 타입들을 정의해 놓은 헤더 파일

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate { // AVAudioPlayerDelegate 선언
    
    @IBOutlet var imgView: UIImageView!
    
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    
    var captureImage: UIImage!
    
    var videoURL: URL!
    
    var flagImageSave = false
    
    
    var audioPlayer : AVAudioPlayer!    // AVAudioPlayer 인스턴스 변수
    
    var audioFile : URL!    // 재생할 오디오의 파일명 변수
    
    let MAX_VOLUME : Float = 10.0   // 최대 볼륨 실수형 상수
    
    var progressTimer : Timer!  // 타이머를 위한 변수
    
    let timePlayerSelector: Selector = #selector(ViewController.updatePlayTime)
    //재생 타이머를 위한 상수
    let timeRecordSelector:Selector = #selector(ViewController.updateRecordTime)
    //녹음 타이머를 위한 상수
    
    // 재생 바 변수 생성
    @IBOutlet var pvProgressPlay: UIProgressView!
    // 시작시간, 종료시간 변수 생성
    @IBOutlet var lblCurrentTime: UILabel!
    @IBOutlet var lblEndTime: UILabel!
    // 시작, 일시정지, 정지 버튼 변수 생성
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    // 볼륨 슬라이더 변수 생성
    @IBOutlet var slVolume: UISlider!
    
    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var lblRecordTime: UILabel!
    
    var audioRecorder : AVAudioRecorder! // AVAudioRecorder 인스턴스를 추가
    var isRecordMode = false    // 현재 "녹음 모드"라는 것을 isRecordMode를 추가합니다
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        selectAudioFile()
        if !isRecordMode {
            // if문의 조건이 "!isRecordMode"이므로 녹음 모드가 아닐 때이므로 재생모드를 뜻함 그러므로 initPlay 함수를 호출
            initPlay()
            btnRecord.isEnabled = false // Record버튼과 재생시간을 비활성화
            lblRecordTime.isEnabled = false
        } else {
            initRecord() // 조건에 해당하지 않는 경우 녹음 모드일 때 initRecord 함수 호출
        }
    }
    
    func selectAudioFile() {
        if !isRecordMode {
            audioFile = Bundle.main.url(forResource: "vancouver", withExtension: "mp3")
            // 재생 모드일 떄는 노래 파일 선택"
        } else {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
            // 녹음 모드일 때는 새 파일인 "recordFile.m4a"파일 생성
        }
    }
    
    func initRecord() { // 녹음을 위한 초기화
        let recordSettings = [  // 녹음 설정
            AVFormatIDKey : NSNumber(value: kAudioFormatAppleLossless as UInt32),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        
        audioRecorder.delegate = self // audioRecorder의 델리게이트를 self로 설정
        
        slVolume.value = 1.0    // 볼륨 슬라이더의 값을 1로 설정
        audioPlayer.volume = slVolume.value // audioPlayer의 볼륨도 슬라이더 값과 동일한 1.0으로 지정
        lblEndTime.text = convertNSTimeInterval2String(0) // 총 재생 시간을 0으로 변경
        lblCurrentTime.text = convertNSTimeInterval2String(0) // 현재 재생 시간을 0으로 변경
        setPlayButtons(false, pause: false, stop: false) // 시작, 일시정지, 중지 버튼 비활성화
        
        let session = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(" Error-setCategory : \(error)")
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print(" Error-setActive : \(error)")
        }
    }
    
    func initPlay() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay: \(error)")
        }
    
        slVolume.maximumValue = MAX_VOLUME // 슬라이더의 최대 볼륨을 상수 MAX_VOLUME의 쵀대인 10.0으로 초기화
        slVolume.value = 1.0    // 슬라이더의 볼륨을 1.0으로 초기화
        pvProgressPlay.progress = 0 // 프로그래스 뷰의 ㅈ니행을 0으로 초기화
        
        audioPlayer.delegate = self // audioPlayer의 delegate를 self로 지정
        audioPlayer.prepareToPlay() // prepareToPlay 실행
        audioPlayer.volume = slVolume.value // audioPlayerDML 볼륨을 앞에서 초기화한 슬라이더의 뷸륨값 1.0으로 초기화
        lblEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        lblCurrentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(true, pause: false, stop: false)
    }
    
    func setPlayButtons(_ play:Bool, pause:Bool, stop:Bool) {   // 오디오 재생, 일시정지, 정지 간략화
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
    }
    
    func convertNSTimeInterval2String(_ time:TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }

    @IBAction func btnPlayAudio(_ sender: UIButton) { // 오디오 재생
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: true)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
    
    @objc func updatePlayTime() { // updatePlayerTIme 함수 생성
        lblCurrentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }
    
    @IBAction func btnPauseAudio(_ sender: UIButton) {  // 오디오 일시정지
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
    }
    
    @IBAction func btnStopAudio(_ sender: UIButton) {   // 오디오 정지
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        lblCurrentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate()
    }
    
    @IBAction func slChangeVolume(_ sender: UISlider) { // 볼륨 조절
        audioPlayer.volume = slVolume.value
    }
    
    // 오디오 재생이 끝나면 맨 처음 상태로 돌아가는 함수
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate()
        setPlayButtons(true, pause: false, stop: false)
    }
    
    
    @IBAction func swRecordMode(_ sender: UISwitch) {
        if sender.isOn {
            audioPlayer.stop()
            audioPlayer.currentTime=0
            lblRecordTime!.text = convertNSTimeInterval2String(0)
            isRecordMode = true
            btnRecord.isEnabled = true
            lblRecordTime.isEnabled = true
        } else {
            isRecordMode = false
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
            lblRecordTime.text = convertNSTimeInterval2String(0)
        }
        selectAudioFile()
        if !isRecordMode {
            initPlay()
        } else {
            initRecord()
        }
    }
    
    @IBAction func btnRecord(_ sender: UIButton) { // 녹음 버튼
        if (sender as AnyObject).titleLabel?.text == "Record" {
            audioRecorder.record()
            (sender as AnyObject).setTitle("Stop", for: UIControl.State())
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        } else {
            audioRecorder.stop()
            progressTimer.invalidate()
            (sender as AnyObject).setTitle("Record", for: UIControl.State())
            btnPlay.isEnabled = true
            initPlay()
            setPlayButtons(false, pause: false, stop: false) // 녹음 시작 후 정지시 play이 활성화 되는 오류를 막기 위해 추가

        }
    }
    
    @objc func updateRecordTime() {
        lblRecordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }
    
    
    @IBAction func btnCaptureImageFromCamera(_ sender: UIButton) {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            flagImageSave = true
            
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
        else {
            myAlert("Camera inaccessable", message: "카메라에 사용에 대한 권한이 없습니다.")
        }
    }
    
    @IBAction func btnLoadImageFromLibary(_ sender: UIButton) {
        if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            flagImageSave = false
            
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = true
            
            present(imagePicker, animated: true, completion: nil)
        }
        else {
            myAlert("Photo album inaccessable", message: "사진첩에 사용에 대한 권한이 없습니다.")
        }
    }
    
    @IBAction func btnRecordVideoFromCamera(_ sender: UIButton) {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            flagImageSave = true
            
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
        else {
            myAlert("Camera inaccessable", message: "카메라에 사용에 대한 권한이 없습니다.")
        }
    }
    
    @IBAction func btnLoadVideoFromLibrary(_ sender: UIButton) {
        if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            flagImageSave = false
            
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
        else {
            myAlert("Photo album inaccessable", message: "사진첩에 사용에 대한 권한이 없습니다.")
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! NSString
        
        if mediaType.isEqual(to: kUTTypeImage as NSString as String) {
            captureImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            
            if flagImageSave {
                UIImageWriteToSavedPhotosAlbum(captureImage, self, nil, nil)
                
            }
            
            imgView.image = captureImage
        }
        else if mediaType.isEqual(to: kUTTypeMovie as NSString as String) {
            if flagImageSave {
                videoURL = (info[UIImagePickerController.InfoKey.mediaURL] as! URL)
                
                UISaveVideoAtPathToSavedPhotosAlbum(videoURL.relativePath,self, nil, nil)
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func myAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}

