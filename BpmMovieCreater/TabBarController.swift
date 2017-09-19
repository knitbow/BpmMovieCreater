//
//  TabBarController.swift
//  BpmMovieCreater
//
//  Created by なおや on 2017/09/16.
//  Copyright © 2017年 なおや. All rights reserved.
//

import UIKit
import Font_Awesome_Swift
class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
      
      // タブボタン設定
      self.tabBar.items![0].setFAIcon(icon: .FAHistory, size: nil, textColor: .lightGray, backgroundColor: .black, selectedTextColor: .white, selectedBackgroundColor: .black)
      self.tabBar.items![1].setFAIcon(icon: .FACameraRetro, size: nil, textColor: .lightGray, backgroundColor: .black, selectedTextColor: .white, selectedBackgroundColor: .black)
      self.tabBar.items![2].setFAIcon(icon: .FAInfoCircle, size: nil, textColor: .lightGray, backgroundColor: .black, selectedTextColor: .white, selectedBackgroundColor: .black)
      self.tabBar.items![3].setFAIcon(icon: .FABars, size: nil, textColor: .lightGray, backgroundColor: .black, selectedTextColor: .white, selectedBackgroundColor: .black)
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

}
