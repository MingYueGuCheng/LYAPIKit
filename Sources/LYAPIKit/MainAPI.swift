//
//  MainAPI.swift
//  DLAPIKit
//
//  Created by 似水灵修 on 2020/4/4.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

public class MainAPI: NSObject {
    /// 获取Key Window
    @objc public static var keyWindow: UIWindow? {
        return UIApplication.shared.windows.reversed().first {
            return $0.isKeyWindow && ($0.screen === UIScreen.main) && (!$0.isHidden && $0.alpha > 0);
        }
    }
    
    /// 获取当前显示的ViewController，忽略"特殊视图控制器"
    @objc public static var currentVC: UIViewController? {
        return currentVC()
    }
    
    /// 获取当前显示的ViewController，不忽略"特殊视图控制器"
    @objc public static var currentVCOnDisplay: UIViewController? {
        return currentVC(ignoreSpecial: false)
    }
    
    /// 获取当前显示的ViewController
    /// - Parameter ignoreSpecial: 忽略"特殊视图控制器"
    /// - Returns: 控制器
    public static func currentVC(ignoreSpecial: Bool = true) -> UIViewController? {
        var currentVisibleVC = keyWindow?.rootViewController
        while let presentedVC = currentVisibleVC?.presentedViewController {
            if ignoreSpecial {
                if ignore(viewController: presentedVC) {
                    return currentVisibleVC
                } else {
                    currentVisibleVC = presentedVC
                }
            } else {
                currentVisibleVC = presentedVC
            }
        }
        if let tabBarVC = currentVisibleVC as? UITabBarController {
            if let count = tabBarVC.viewControllers?.count, count < 6 {
                currentVisibleVC = tabBarVC.selectedViewController
            } else {
                if tabBarVC.selectedIndex < 4 {
                    currentVisibleVC = tabBarVC.selectedViewController
                } else {
                    if tabBarVC.moreNavigationController.viewControllers.count > 0 {
                        currentVisibleVC = tabBarVC.moreNavigationController.viewControllers.last
                    }
                }
            }
        }
        if let navVC = currentVisibleVC as? UINavigationController {
            currentVisibleVC = navVC.topViewController
        }
        return currentVisibleVC
    }
    
    private static func ignore(viewController: UIViewController) -> Bool {
        let ignoreClass = [UIAlertController.self]
        return ignoreClass.first { viewController.isKind(of: $0) } != nil
    }
    
    /// 切换【根控制器UITabBarController】选项视图，并关闭弹出视图
    /// - Parameter index: selected index
    @objc public static func tabBarSelected(_ index: Int) {
        guard let tabBarVC = keyWindow?.rootViewController as? UITabBarController else {
            return
        }
        guard 0 <= index, let count = tabBarVC.viewControllers?.count, index < count else {
            return
        }
        if tabBarVC.presentedViewController != nil {
            tabBarVC.dismiss(animated: false, completion: nil)
        }
        tabBarVC.navigationController?.popToRootViewController(animated: false)
        
        let selNavVC = tabBarVC.selectedViewController as? UINavigationController
        tabBarVC.selectedIndex = index
        selNavVC?.popToRootViewController(animated: false)
    }
    
    /// 离开当前页面
    /// - Parameters:
    ///   - page: 当前页面
    ///   - animated: 动画
    ///   - completion: 回调
    @objc public static func leaveCurrent(_ page: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        if let navVC = page.navigationController, navVC.viewControllers.count >= 2,
            let isEqual = navVC.topViewController?.isEqual(page), isEqual {
            navVC.popViewController(animated: animated)
            completion?()
        } else if let presentingVC = page.presentingViewController {
            presentingVC.dismiss(animated: animated) { completion?() }
        } else {
            completion?()
        }
    }
    
    private static func open(scheme: String?, handler: ((_ success: Bool) -> Void)? = nil) {
        if let url = url(from: scheme), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { handler?($0) }
            } else {
                let flag = UIApplication.shared.openURL(url)
                handler?(flag)
            }
        } else {
            handler?(false)
        }
    }
    
    /// 打电话
    /// - Parameters:
    ///   - phone: 电话号码
    ///   - completion: 回调
    @objc public static func call(phone: String?, completion: ((_ success: Bool) -> Void)? = nil) {
        open(scheme: "tell://" + (phone ?? ""), handler: completion)
    }
    
    /// 通过系统打开Scheme
    /// - Parameters:
    ///   - scheme: scheme
    ///   - completion: 回调
    @objc public static func open(scheme: String?, completion: ((_ success: Bool) -> Void)? = nil) {
        open(scheme: scheme, handler: completion)
    }
    
    private static func url(from str: String?) -> URL? {
        guard let str = str, str.count > 0 else {
            return nil
        }
        return URL(string: str)
    }
}
