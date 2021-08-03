//
//  AppDelegate.swift
//  brandi
//
//  Created by Yongun Lim on 2021/07/29.
//

import UIKit
import RxKakaoSDKCommon

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        RxKakaoSDKCommon.initSDK(appKey: "3060e80c4a930b3f6e2911ac67bf828a")
        return true
    }
}

