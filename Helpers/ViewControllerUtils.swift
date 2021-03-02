//
//  ViewControllerUtils.swift
//  VK-total
//
//  Created by Сергей Никитин on 17.03.2018.
//  Copyright © 2018 Sergey Nikitin. All rights reserved.
//

import UIKit

class ViewControllerUtils {
    
    private static var container: UIView = UIView()
    private static var loadingView: UIView = UIView()
    private static var mainLabel: UILabel = UILabel()
    private static var detailLabel: UILabel = UILabel()
    private static var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    
    func showActivityIndicator(uiView: UIView) {
        ViewControllerUtils.container.frame = uiView.frame
        ViewControllerUtils.container.center = uiView.center
        ViewControllerUtils.container.backgroundColor = UIColor.clear
        
        let frame = CGRect(x: 0, y: 0, width: 140, height: 105)
        ViewControllerUtils.loadingView.frame = frame
        ViewControllerUtils.loadingView.center = uiView.center
        ViewControllerUtils.loadingView.backgroundColor = Constants.shared.mainColor
        ViewControllerUtils.loadingView.clipsToBounds = true
        ViewControllerUtils.loadingView.layer.cornerRadius = 6
        
        ViewControllerUtils.activityIndicator.frame = CGRect(x: frame.width/2 - 20, y: 15, width: 40, height: 40);
        ViewControllerUtils.activityIndicator.style = .large
        ViewControllerUtils.activityIndicator.color = .white
        ViewControllerUtils.activityIndicator.clipsToBounds = false
        
        ViewControllerUtils.mainLabel.text = "Подождите..."
        ViewControllerUtils.mainLabel.frame = CGRect(x: 0, y: 55, width: frame.width, height: 20)
        ViewControllerUtils.mainLabel.textColor = .white
        ViewControllerUtils.mainLabel.font = UIFont.boldSystemFont(ofSize: 16)
        ViewControllerUtils.mainLabel.textAlignment = .center
        
        ViewControllerUtils.detailLabel.text = "Получение данных"
        ViewControllerUtils.detailLabel.frame = CGRect(x: 0, y: 75, width: frame.width, height: 20)
        ViewControllerUtils.detailLabel.textColor = .white //UIColor(red: 217/255, green: 37/255, blue: 43/255, alpha: 1)
        ViewControllerUtils.detailLabel.font = UIFont.boldSystemFont(ofSize: 12)
        ViewControllerUtils.detailLabel.textAlignment = .center
        
        ViewControllerUtils.loadingView.addSubview(ViewControllerUtils.activityIndicator)
        ViewControllerUtils.loadingView.addSubview(ViewControllerUtils.mainLabel)
        ViewControllerUtils.loadingView.addSubview(ViewControllerUtils.detailLabel)
        
        ViewControllerUtils.container.addSubview(ViewControllerUtils.loadingView)
        uiView.addSubview(ViewControllerUtils.container)
        ViewControllerUtils.activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        ViewControllerUtils.activityIndicator.stopAnimating()
        ViewControllerUtils.container.removeFromSuperview()
    }
    
    func UIColorFromHex(rgbValue: UInt32, alpha: Double=1.0) -> UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red: red, green: green, blue: blue, alpha: CGFloat(alpha))
    }
}

extension UIView {
    var visibleRect: CGRect {
        guard let superview = superview else { return frame }
        return frame.intersection(superview.bounds)
    }
}
