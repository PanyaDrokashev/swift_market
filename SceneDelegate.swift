//
//  SceneDelegate.swift
//  swift_market
//
//  Created by Даниил on 10.03.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        self.window = UIWindow(windowScene: scene)
        let coordinator = AppCoordinator()
        coordinator.start()
        self.appCoordinator = coordinator
        self.window?.rootViewController = coordinator.rootViewController
        self.window?.makeKeyAndVisible()
    }
}
