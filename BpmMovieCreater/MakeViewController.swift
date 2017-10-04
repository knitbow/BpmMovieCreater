//
//  MakeViewController.swift
//  BpmMovieCreater
//
//  Created by なおや on 2017/09/16.
//  Copyright © 2017年 なおや. All rights reserved.
//

import UIKit
import MediaPlayer
import Photos
import GPUImage

class MakeViewController: UIViewController {
  
  let movieCreator = MovieCreator()
  var compMovieURL = URL(string:"")
  let queue = DispatchQueue.main
  
  
  // Bpm
  @IBOutlet weak var bpmLabel: UILabel!
  // ジャケット画像
  @IBOutlet weak var musicImage: UIImageView!
  // アーティスト名
  @IBOutlet weak var artistLabel: UILabel!
  // 曲名
  @IBOutlet weak var songLabel: UILabel!
  // 曲の長さ
  @IBOutlet weak var lengthLabel: UILabel!
  // プレイヤー用のproperty
  var audioPlayer:AVAudioPlayer?
  // メディアピッカー
  let mediaPicker: MPMediaPickerController = MPMediaPickerController(mediaTypes: .music)
  // プレイヤー
  var player = MPMusicPlayerController()
  // テンポの長さ
  var tempoLength = Double()
  // 素材枚数
  var sozaiAmount = Int()
  // 写真配列
  var imageArray: [UIImage] = [UIImage]()
  // １枚めの画像かどうか
  var isFirstTap = true
  // 初めてムービーを作成するかどうか
  var isFirstMovie = true
  // フィルター
  var filterImage = UIImage()
  
  // 動画URL
  var movieURL = URL(string:"")
  // 画像動画URL
  var picMovieURL = URL(string:"")
  // 結合動画URL
  var mergeMovieURL = URL(string:"")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    player = MPMusicPlayerController.applicationMusicPlayer()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  
  // musicボタン押下時
  @IBAction func musicPick(_ sender: Any) {
    mediaPicker.allowsPickingMultipleItems = false
    mediaPicker.delegate = self
    present(mediaPicker, animated: true, completion: nil)
  }
  
  // movieボタン押下
  @IBAction func movieBtn(_ sender: Any) {
    
    // FPS
    self.movieCreator.time = Int(1)

    // カメラロールの画像を取得する。
    let fetchOptions = PHFetchOptions();
    
    var date:NSDate = NSDate();
    date = NSDate(timeIntervalSinceNow: -60*24*60*60);//1 month ago
    
    fetchOptions.predicate = NSPredicate(format: "creationDate > %@", date);
    fetchOptions.sortDescriptors =  [NSSortDescriptor(key: "creationDate", ascending: false)];
    let assets = PHAsset.fetchAssets(with: fetchOptions)
    print(assets.debugDescription);
    
    var i = 0
    assets.enumerateObjects({ obj, idx, stop in
      autoreleasepool {
        
        // 素材の数だけ回れば終わり
        if i == self.sozaiAmount {
          return
        }
        
        let asset:PHAsset = obj as PHAsset;
        
        // 動画編集処理
        if asset.mediaType == .video {
          
          i = i + 1
          // URLの取得
          self.movieURL = self.getURL(ofPhotoWith: asset)

          // 初期の場合、次のオブジェクト
          if self.isFirstMovie {
            self.isFirstMovie = false
            self.mergeMovieURL = self.movieURL
            return
          }
          
          // 動画のマージを行う
          self.mergeMovieURL = self.mergeMovie(firstMoviePathUrl: self.mergeMovieURL as! NSURL, secondMoviePathUrl: self.movieURL as! NSURL)
          
          return
        }
        
        // 画像編集処理
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .exact
        requestOptions.deliveryMode = .highQualityFormat
        
        // this one is key
        requestOptions.isSynchronous = true
        
        // imageを取得
        PHImageManager.default().requestImage(for: asset , targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: requestOptions, resultHandler: { (pickedImage, info) in
          
          // フィルター定義
          let toonFilter = MonochromeFilter()
          self.filterImage = pickedImage!.filterWithOperation(toonFilter)
          
        })
        
        // 縦の写真は取り込まない
        if self.filterImage.size.width <= self.filterImage.size.height {
          return
        }
        
        // リサイズ処理(1920)
        let reSize = self.resizeUIImageByWidth(image: self.filterImage, width: 1920)
        // フレーム分ループ（1秒60回）画像拡大処理 debug中 30に戻すこと
        for j in 0..<Int(1 * self.tempoLength) {
         autoreleasepool {
            let width = Double(reSize.size.width) * (1 + ((Double(j)+1)/100))
            let height = Double(reSize.size.height) * (1 + ((Double(j)+1)/100))
            let editSize = reSize.ResizeÜIImage(width: CGFloat(width), height: CGFloat(height))
            
            // 切り抜き処理
            let cropRect  = CGRect(
              x:CGFloat(((editSize?.size.width)! - CGFloat(1920)) / 2),
              y:CGFloat(((editSize?.size.height)! - CGFloat(1080)) / 2),
              width:1920, height:1080)
            let cropRef   = (editSize?.cgImage)!.cropping(to: cropRect)
            let cropImage = UIImage(cgImage: cropRef!)
            
            //１枚目の画像だけセットアップを含む
            if self.isFirstTap {
              self.movieCreator.createFirst(image: cropImage, size: reSize.size)
              self.isFirstTap = false
            }else{
              self.movieCreator.createSecond(image: cropImage)
            }
          }
        }
        
        // ライブラリへの保存
        let semaphore = DispatchSemaphore(value: 0)
        self.movieCreator.finished { (url) in
          self.picMovieURL = url
          semaphore.signal()
        }
        semaphore.wait()

        // 動画のマージを行う
        self.mergeMovieURL = self.mergeMovie(firstMoviePathUrl: self.mergeMovieURL as! NSURL, secondMoviePathUrl: self.picMovieURL as! NSURL)
        i = i + 1
      }
    });
    
//    // ライブラリへの保存
//    var movieURL = URL(string:"")
//    let semaphore = DispatchSemaphore(value: 0)
//    self.movieCreator.finished { (url) in
//      movieURL = url
//      semaphore.signal()
//    }
//    semaphore.wait()

    // 音声と動画のマージ
    self.mergeAudio(audioURL: self.audioPlayer!.url! as NSURL, moviePathUrl: self.mergeMovieURL! as NSURL) { (url) in
      self.compMovieURL = url
    }

    let alertController = UIAlertController(title: "完了", message: "カメラロールに保存しました", preferredStyle: .actionSheet)
    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    dismiss(animated: true,completion: nil)
    alertController.addAction(defaultAction)
    present(alertController, animated: true, completion: nil)

  }
    
  func getURL(ofPhotoWith mPhasset: PHAsset) -> URL{


    let options: PHVideoRequestOptions = PHVideoRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.version = .original
    var urlStr2 = URL(string:"")

    let semaphore = DispatchSemaphore(value: 0)
    PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
      
      if let tokenStr = info?["PHImageFileSandboxExtensionTokenKey"] as? String {
        let tokenKeys = tokenStr.components(separatedBy: ";")
        let urlStr = tokenKeys.filter { $0.contains("/private/var/mobile/Media") }.first
        urlStr2 = URL(string:urlStr!)
        if let urlStr = urlStr {
          if let url = URL(string: urlStr) {
            print(url.lastPathComponent)
            print(url.pathExtension)
          }
        }
      }
      defer {semaphore.signal() }
    })
    semaphore.wait(timeout: DispatchTime.distantFuture)
    return urlStr2!

  }
  
  /**
   * 横幅を指定してUIImageをリサイズする
   * @params image: 対象の画像
   * @params width: 基準となる横幅
   * @return 横幅をwidthに、縦幅はアスペクト比を保持したサイズにリサイズしたUIImage
   */
  func resizeUIImageByWidth(image: UIImage, width: Double) -> UIImage {
    // オリジナル画像のサイズから、アスペクト比を計算
    let aspectRate = image.size.height / image.size.width
    // リサイズ後のWidthをアスペクト比を元に、リサイズ後のサイズを取得
    let resizedSize = CGSize(width: width, height: width * Double(aspectRate))
    // リサイズ後のUIImageを生成して返却
    UIGraphicsBeginImageContext(resizedSize)
    image.draw(in: CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resizedImage!
  }
  
  //リサイズが必要なら
  func resizeImage(image:UIImage,contentSize:CGSize) -> UIImage{
    // リサイズ処理
    let origWidth  = Int(image.size.width)
    let origHeight = Int(image.size.height)
    var resizeWidth:Int = 0, resizeHeight:Int = 0
    if (origWidth < origHeight) {
      resizeWidth = Int(contentSize.width)
      resizeHeight = origHeight * resizeWidth / origWidth
    } else {
      resizeHeight = Int(contentSize.height)
      resizeWidth = origWidth * resizeHeight / origHeight
    }
    
    let resizeSize = CGSize(width:CGFloat(resizeWidth), height:CGFloat(resizeHeight))
    UIGraphicsBeginImageContext(resizeSize)
    
    image.draw(in: CGRect(x:0,y: 0,width: CGFloat(resizeWidth), height:CGFloat(resizeHeight)))
    
    let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    // 切り抜き処理
    
    let cropRect  = CGRect(
      x:CGFloat((resizeWidth - Int(contentSize.width)) / 2),
      y:CGFloat((resizeHeight - Int(contentSize.height)) / 2),
      width:contentSize.width, height:contentSize.height)
    let cropRef   = (resizeImage?.cgImage)!.cropping(to: cropRect)
    let cropImage = UIImage(cgImage: cropRef!)
    
    return cropImage
  }
  
  // 動画と動画のマージ
  func mergeMovie(firstMoviePathUrl: NSURL, secondMoviePathUrl: NSURL) -> URL {
    
    // Compositionを生成
    let mutableComposition: AVMutableComposition = AVMutableComposition()
    
    // AVAssetをURLから取得
    let videoAssetFirst = AVAsset(url: firstMoviePathUrl as URL)
    let videoAssetSecond = AVAsset(url: secondMoviePathUrl as URL)
    
    // AVAssetから動画のAVAssetTrackをそれぞれ取得
    let videoTrackFirst = videoAssetFirst.tracks(withMediaType: AVMediaTypeVideo)[0]
    let videoTrackSecond = videoAssetSecond.tracks(withMediaType: AVMediaTypeVideo)[0]
    
    // 動画合成用のAVMutableCompositionTrackを生成
    let compositionVideoTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    // 動画をトラックに追加
    do {
      try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoTrackFirst.timeRange.duration), of: videoTrackFirst, at: kCMTimeZero)
    } catch {
      fatalError("videoTrack error")
    }
    do {
      try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoTrackSecond.timeRange.duration), of: videoTrackSecond, at: kCMTimeZero)
    } catch {
      fatalError("videoTrack error")
    }
    
    // First合成命令用オブジェクトを生成
    let mutableVideoCompositionInstructionFirst = AVMutableVideoCompositionInstruction()
    mutableVideoCompositionInstructionFirst.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrackFirst.timeRange.duration)
    mutableVideoCompositionInstructionFirst.backgroundColor = UIColor.red.cgColor
    
    // Second合成命令用オブジェクトを生成
    let mutableVideoCompositionInstructionSecond = AVMutableVideoCompositionInstruction()
    mutableVideoCompositionInstructionSecond.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrackSecond.timeRange.duration)
    mutableVideoCompositionInstructionSecond.backgroundColor = UIColor.red.cgColor
    
    // AVMutableVideoCompositionを生成
    let mutableVideoComposition = AVMutableVideoComposition.init()
    mutableVideoComposition.instructions = [mutableVideoCompositionInstructionFirst, mutableVideoCompositionInstructionSecond]
    
    // 動画の回転情報を取得する
    let transform1 = videoTrackFirst.preferredTransform;
    let isVideoAssetPortrait = ( transform1.a == 0 &&
      transform1.d == 0 &&
      (transform1.b == 1.0 || transform1.b == -1.0) &&
      (transform1.c == 1.0 || transform1.c == -1.0));
    
    // 動画のサイズ設定
    var naturalSizeFirst = CGSize()
    var naturalSizeSecond = CGSize()
    if (isVideoAssetPortrait) {
      naturalSizeFirst = CGSize(width: videoTrackFirst.naturalSize.height, height: videoTrackFirst.naturalSize.width);
      naturalSizeSecond = CGSize(width: videoTrackSecond.naturalSize.height, height: videoTrackSecond.naturalSize.width);
      
    }else {
      naturalSizeFirst = videoTrackFirst.naturalSize;
      naturalSizeSecond = videoTrackSecond.naturalSize;
    }
    let renderWidth  = max(naturalSizeFirst.width, naturalSizeSecond.width)
    let renderHeight = max(naturalSizeFirst.height, naturalSizeSecond.height)
    
    // 書き出す動画のサイズ設定
    mutableVideoComposition.renderSize = CGSize(width: renderWidth, height: renderHeight);
    // 書き出す動画のフレームレート（30FPS）
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    // AVMutableCompositionを元にExporterの生成
    let assetExportSession: AVAssetExportSession = AVAssetExportSession(asset: mutableComposition, presetName: AVAssetExportPreset1920x1080)!
    let composedMovieDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0];
    let composedMoviePath      = NSString(format:"%@/%@", composedMovieDirectory, "test.mp4");
    
    // すでに合成動画が存在していたら消す
    let fileManager = FileManager.default;
    if (fileManager.fileExists(atPath: composedMoviePath as String)) {
      do {
        try fileManager.removeItem(atPath: composedMoviePath as String)
      } catch {
        fatalError("removeItem file")
      }
    }
    
    // 保存設定
    let composedMovieUrl = NSURL(fileURLWithPath:composedMoviePath as String);
    assetExportSession.outputFileType              = AVFileTypeQuickTimeMovie;
    assetExportSession.outputURL                   = composedMovieUrl as URL;
    assetExportSession.shouldOptimizeForNetworkUse = true;
    
    // エクスポート
    assetExportSession.exportAsynchronously(completionHandler: {() -> Void in
      switch assetExportSession.status {
      case .completed:
        print("Crop Success! Url -> \(composedMovieUrl)")
      case .failed, .cancelled:
        print("error = \(String(describing: assetExportSession.error))")
      default:
        print("error = \(String(describing: assetExportSession.error))")
      }
    })
    
    return composedMovieUrl as URL
    
  }
  
  // 音声と動画をマージする
  func mergeAudio(audioURL: NSURL, moviePathUrl: NSURL, _ completion:@escaping (URL)->()){
    
    // Compositionを生成
    let mutableComposition = AVMutableComposition()
    
    // AVAssetをURLから取得
    let videoAsset = AVAsset(url: moviePathUrl as URL)
    let audioAsset = AVAsset(url: audioURL as URL)
    
    // AVAssetから動画・音声のAVAssetTrackをそれぞれ取得
    let videoTrack = videoAsset.tracks(withMediaType: AVMediaTypeVideo)[0]
    let audioTrack = audioAsset.tracks(withMediaType: AVMediaTypeAudio)[0]
    
    // 動画合成用のAVMutableCompositionTrackを生成
    let compositionVideoTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
    let compositionAudioTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
    
    // 動画をトラックに追加
    do {
      try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration), of: videoTrack, at: kCMTimeZero)
    } catch {
      fatalError("videoTrack error")
    }
    
    // 音声をトラックに追加
    do {
      try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioTrack.timeRange.duration), of: audioTrack, at: kCMTimeZero)
    } catch {
      fatalError("audioTrack error")
    }
    
    // 合成命令用オブジェクトを生成
    let mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
    mutableVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration)
    mutableVideoCompositionInstruction.backgroundColor = UIColor.red.cgColor
    
    // AVMutableVideoCompositionを生成
    let mutableVideoComposition = AVMutableVideoComposition.init()
    mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
    
    // 動画の回転情報を取得する
    let transform1 = videoTrack.preferredTransform;
    let isVideoAssetPortrait = ( transform1.a == 0 &&
      transform1.d == 0 &&
      (transform1.b == 1.0 || transform1.b == -1.0) &&
      (transform1.c == 1.0 || transform1.c == -1.0));
    
    // 動画のサイズ設定
    var naturalSize = CGSize()
    if (isVideoAssetPortrait) {
      naturalSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width);
    }else {
      naturalSize = videoTrack.naturalSize;
    }
    let renderWidth  = naturalSize.width
    let renderHeight = naturalSize.height
    
    // 書き出す動画のサイズ設定
    mutableVideoComposition.renderSize = CGSize(width: renderWidth, height: renderHeight);
    // 書き出す動画のフレームレート（30FPS）
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    // AVMutableCompositionを元にExporterの生成
    let assetExportSession = AVAssetExportSession(asset: mutableComposition, presetName: AVAssetExportPreset1920x1080)!
    let composedMovieDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0];
    let composedMoviePath      = NSString(format:"%@/%@", composedMovieDirectory, "test.mp4");
    
    // すでに合成動画が存在していたら消す
    let fileManager = FileManager.default;
    if (fileManager.fileExists(atPath: composedMoviePath as String)) {
      do {
        try fileManager.removeItem(atPath: composedMoviePath as String)
      } catch {
        fatalError("removeItem file")
      }
    }
    
    // 保存設定
    let composedMovieUrl = NSURL(fileURLWithPath:composedMoviePath as String);
    assetExportSession.outputFileType              = AVFileTypeQuickTimeMovie;
    assetExportSession.outputURL                   = composedMovieUrl as URL;
    assetExportSession.shouldOptimizeForNetworkUse = true;
    
    // エクスポート
    assetExportSession.exportAsynchronously(completionHandler: {() -> Void in
      switch assetExportSession.status {
      case .completed:
        print("Crop Success! Url -> \(composedMovieUrl)")
        DispatchQueue.main.async(execute: {
          PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL:composedMovieUrl as URL)
          }, completionHandler: { (success, err) in
            if success == true {
              print("保存成功！")
            } else {
              print("保存失敗！ \(String(describing: err)) \(String(describing: err?.localizedDescription))")
            }
          })
        })
        
      case .failed, .cancelled:
        print("error = \(String(describing: assetExportSession.error))")
      default:
        print("error = \(String(describing: assetExportSession.error))")
      }
    })
    
    completion(composedMovieUrl as URL)
    
  }
  

  
}

extension UIImage{
  
  // Resizeするクラスメソッド.
  func ResizeÜIImage(width : CGFloat, height : CGFloat)-> UIImage!{
    
    // 指定された画像の大きさのコンテキストを用意.
    UIGraphicsBeginImageContext(CGSize(width: width, height: height))
    
    // コンテキストに自身に設定された画像を描画する.
    self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
    
    // コンテキストからUIImageを作る.
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    
    // コンテキストを閉じる.
    UIGraphicsEndImageContext()
    
    return newImage
  }
  
  // 比率だけ指定する場合
  func resize(ratio: CGFloat) -> UIImage {
    let resizedSize = CGSize(width: Int(self.size.width * ratio), height: Int(self.size.height * ratio))
    UIGraphicsBeginImageContextWithOptions(resizedSize, false, 2)
    draw(in: CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resizedImage!
  }
  
}



// メディアピッカーデリゲート
extension MakeViewController: MPMediaPickerControllerDelegate {
  
  // メディアアイテムピッカーでアイテムを選択完了したときに呼び出される
  func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems
    mediaItemCollection: MPMediaItemCollection) {
    
    // 選択した曲情報がmediaItemCollectionに入っているので、これをplayerにセット。
    player.setQueue(with: mediaItemCollection)
    
    guard let asset = mediaItemCollection.items.first,
      let url = asset.assetURL else {return}
    
    // audioPlayerを作成
    do {
      // itemのassetURLからプレイヤーを作成する
      audioPlayer = try AVAudioPlayer(contentsOf: url)
    } catch  {
      // エラー発生してプレイヤー作成失敗
      audioPlayer = nil
      // 戻る
      return
    }

    // BPM取得処理
    _ = BPMAnalyzer.core.getBpmFrom(url, completion: {[weak self] (bpm) in
      self?.bpmLabel.text = bpm
      
      // テンポによる計算(5秒程度になるように計算)
      let i = 0.0
      switch Double(bpm)! {
      case 50..<60:
        self?.tempoLength = 60 / Double(bpm)! * (5 - i)
      case 60..<70:
        self?.tempoLength = 60 / Double(bpm)! * (5 - i)
      case 70..<80:
        self?.tempoLength = 60 / Double(bpm)! * (6 - i)
      case 80..<90:
        self?.tempoLength = 60 / Double(bpm)! * (7 - i)
      case 90..<100:
        self?.tempoLength = 60 / Double(bpm)! * (8 - i)
      case 100..<110:
        self?.tempoLength = 60 / Double(bpm)! * (9 - i)
      case 110..<120:
        self?.tempoLength = 60 / Double(bpm)! * (10 - i)
      case 120..<130:
        self?.tempoLength = 60 / Double(bpm)! * (10 - i)
      case 130..<140:
        self?.tempoLength = 60 / Double(bpm)! * (11 - i)
      case 140..<150:
        self?.tempoLength = 60 / Double(bpm)! * (12 - i)
      case 150..<160:
        self?.tempoLength = 60 / Double(bpm)! * (13 - i)
      case 160..<170:
        self?.tempoLength = 60 / Double(bpm)! * (14 - i)
      case 170..<180:
        self?.tempoLength = 60 / Double(bpm)! * (15 - i)
      case 180..<190:
        self?.tempoLength = 60 / Double(bpm)! * (15 - i)
      case 190..<200:
        self?.tempoLength = 60 / Double(bpm)! * (16 - i)
      case 200..<210:
        self?.tempoLength = 60 / Double(bpm)! * (17 - i)
      default:
        self?.tempoLength = 60 / Double(bpm)! * (18 - i)
      }
      
      // テンポの設定
      self?.bpmLabel.numberOfLines = 2
      self?.bpmLabel.text = "BPM：" + bpm + "¥nテンポ秒数：" + String(describing: self?.tempoLength)
      self?.bpmLabel.sizeToFit()

      self?.mediaPicker.dismiss(animated: true, completion: nil)
    })

    // 音楽情報取得
    updateSongInformationUI(mediaItem: mediaItemCollection.representativeItem!)
    
  }
  
  //選択がキャンセルされた場合に呼ばれる
  func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
    // ピッカーを閉じ、破棄する
    dismiss(animated: true, completion: nil)
  }
  
  /// 曲情報を表示する
  func updateSongInformationUI(mediaItem: MPMediaItem) {

    // 曲情報表示
    // (a ?? b は、a != nil ? a! : b を示す演算子です)
    // (aがnilの場合にはbとなります)
    artistLabel.text = mediaItem.artist ?? "不明なアーティスト"
    songLabel.text = mediaItem.title ?? "不明な曲"
    
    // 曲の長さ設定
    lengthLabel.text = mediaItem.playbackDuration.description
    
    // 素材が何枚必要か計算
    guard !((mediaItem.playbackDuration / tempoLength).isNaN || (mediaItem.playbackDuration / tempoLength).isInfinite) else {
      return // or do some error handling
    }
    self.sozaiAmount = Int(round(mediaItem.playbackDuration / tempoLength))
    
    // アートワーク表示
    if let artwork = mediaItem.artwork {
      let image = artwork.image(at: musicImage.bounds.size)
      musicImage.image = image
    } else {
      // アートワークがないとき
      // (今回は灰色表示としました)
      musicImage.image = nil
      musicImage.backgroundColor = UIColor.gray
    }
    
  }
  
}

