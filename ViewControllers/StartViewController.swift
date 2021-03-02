//
//  MainViewController.swift
//  K2Consult
//
//  Created by Сергей Никитин on 01.11.2020.
//  Copyright © 2020 Snik2003. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let window = UIApplication.shared.windows.first
        
        if let navController = storyboard.instantiateViewController(withIdentifier: "StartNavigationController") as? UINavigationController,
           let mainVC  = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
            
            navController.setViewControllers([mainVC], animated: false)
            window?.rootViewController = navController
            window?.makeKeyAndVisible()
        }
    }
}
