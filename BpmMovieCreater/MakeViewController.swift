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

class MakeViewController: UIViewController {
  
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

  // メディアピッカー
  let mediaPicker: MPMediaPickerController = MPMediaPickerController(mediaTypes: .music)
  // プレイヤー
  var player = MPMusicPlayerController()
  // テンポの長さ
  var tempoLength = Double()
  // 素材枚数
  var sozaiAmount = Int()
  
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
    //全てのカメラロールの画像を取得する。
    let fetchOptions = PHFetchOptions();
    
    var date:NSDate = NSDate();
    date = NSDate(timeIntervalSinceNow: -30*24*60*60);//1年前
    
    fetchOptions.predicate = NSPredicate(format: "creationDate > %@", date);
    fetchOptions.sortDescriptors =  [NSSortDescriptor(key: "creationDate", ascending: false)];
    var assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    print(assets.debugDescription);
    
    var i = 0
    assets.enumerateObjects({ obj, idx, stop in
      
      if(i == self.sozaiAmount){
        return
      }
      if obj is PHAsset
      {
        let asset:PHAsset = obj as PHAsset;
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .exact
        requestOptions.deliveryMode = .highQualityFormat
        
        // this one is key
        requestOptions.isSynchronous = true
        
        // imageを取得
        var imageArray: [UIImage] = [UIImage]()
        PHImageManager.default().requestImage(for: asset as! PHAsset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (pickedImage, info) in
          
          // フィルター定義
//          let toonFilter = MonochromeFilter()
//          filterImage = pickedImage!.filterWithOperation(toonFilter)
          imageArray.append(pickedImage!)
        })

      }
      i = i + 1
    });
  }

}

// メディアピッカーデリゲート
extension MakeViewController: MPMediaPickerControllerDelegate {
  
  // メディアアイテムピッカーでアイテムを選択完了したときに呼び出される
  func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems
    mediaItemCollection: MPMediaItemCollection) {
    
    // 選択した曲情報がmediaItemCollectionに入っているので、これをplayerにセット。
    player.setQueue(with: mediaItemCollection)
    
    updateSongInformationUI(mediaItem: mediaItemCollection.representativeItem!)
    
    guard let asset = mediaItemCollection.items.first,
      let url = asset.assetURL else {return}
    // BPM取得処理
    _ = BPMAnalyzer.core.getBpmFrom(url, completion: {[weak self] (bpm) in
      self?.bpmLabel.text = bpm
    
    // テンポによる計算(5秒程度になるように計算)
    switch Double(bpm)! {
      case 50..<60:
        self?.tempoLength = 60 / Double(bpm)! * 5
      case 60..<70:
        self?.tempoLength = 60 / Double(bpm)! * 5
      case 70..<80:
        self?.tempoLength = 60 / Double(bpm)! * 6
      case 80..<90:
        self?.tempoLength = 60 / Double(bpm)! * 7
      case 90..<100:
        self?.tempoLength = 60 / Double(bpm)! * 8
      case 100..<110:
        self?.tempoLength = 60 / Double(bpm)! * 9
      case 110..<120:
        self?.tempoLength = 60 / Double(bpm)! * 10
      case 120..<130:
        self?.tempoLength = 60 / Double(bpm)! * 10
      case 130..<140:
        self?.tempoLength = 60 / Double(bpm)! * 11
      case 140..<150:
        self?.tempoLength = 60 / Double(bpm)! * 12
      case 150..<160:
        self?.tempoLength = 60 / Double(bpm)! * 13
      case 160..<170:
        self?.tempoLength = 60 / Double(bpm)! * 14
      case 170..<180:
        self?.tempoLength = 60 / Double(bpm)! * 15
      case 180..<190:
        self?.tempoLength = 60 / Double(bpm)! * 15
      case 190..<200:
        self?.tempoLength = 60 / Double(bpm)! * 16
      case 200..<210:
        self?.tempoLength = 60 / Double(bpm)! * 17
      default:
        self?.tempoLength = 60 / Double(bpm)! * 18
      }
      
      // テンポの設定
      self?.bpmLabel.numberOfLines = 2
      self?.bpmLabel.text = "BPM：" + bpm + "¥nテンポ秒数：" + String(describing: self?.tempoLength)
      self?.bpmLabel.sizeToFit()
      
      self?.mediaPicker.dismiss(animated: true, completion: nil)
    })
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
    sozaiAmount = Int(round(mediaItem.playbackDuration / tempoLength))
    
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

