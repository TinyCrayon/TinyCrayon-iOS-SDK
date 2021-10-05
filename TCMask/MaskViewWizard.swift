//
//  MaskViewWizard.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 5/25/16.
//
//

import UIKit

class MaskViewWizard : NSObject {
    unowned var controller: MaskViewController
    var view: UIView
    
    init(controller: MaskViewController) {
        self.controller = controller
        self.view = UIView(frame: controller.view.frame)
        super.init()
        
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        controller.view.addSubview(view)
        view.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.addGestureRecognizer(tapGesture)
        
        initMaskWizard()
    }
    
    func present() {
        view.alpha = 0
        view.isHidden = false
        UIView.animate(withDuration: 0.5, animations:{
            self.view.alpha = 1
            }, completion: {
                success in
        })
    }
    
    func makeTransition() {
//        if (status == nil) {
//            return
//        }
//        
//        switch status! {
//        case .mask:
//            break
//        case .hairBrush:
//            adjustHairBrushWizard()
//            break
//        }
    }
    
    func initMaskWizard() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.75)
        
        let container = UIView(frame: view.bounds)
        let hints = [(controller.localized("Tips-Draw"), "gesture_tap"), (controller.localized("Tips-Zoom"), "gesture_pinch"), (controller.localized("Tips-Move"), "gesture_twofingertap")]
        
        var top: CGFloat = 0
        for (text, imgName) in hints {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: container.width, height: 30))
            label.center = container.center
            label.text = text
            label.top = top
            label.textAlignment = NSTextAlignment.center
            label.textColor = UIColor.white
            label.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth]
            container.addSubview(label)
            
            let image = UIImage(named: imgName, in: Bundle(for: type(of: self)), compatibleWith: nil)!.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            let imageView = UIImageView(image: image)
            imageView.tintColor = UIColor.white
            imageView.center = container.center
            imageView.top = label.bottom
            imageView.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin]
            container.addSubview(imageView)
            
            top = imageView.bottom + 20
        }
        
//        let linkButton = UIButton(frame: CGRect(x: 0, y: 0, width: 150, height: 50))
//        let linkButtonTitle = NSAttributedString(string:"view tutorial", attributes:
//            [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue, NSForegroundColorAttributeName: UIColor(red: 0.5, green: 0.5, blue: 1, alpha: 1)])
//        linkButton.setAttributedTitle(linkButtonTitle, for: UIControlState())
//        linkButton.top = top
//        linkButton.left =  (container.width - linkButton.width) / 2
//        linkButton.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleLeftMargin, UIViewAutoresizing.flexibleRightMargin]
//        linkButton.addTarget(self, action: #selector(MaskViewWizard.viewTutorialButtonTapped(_:)), for: UIControlEvents.touchUpInside)
//        container.addSubview(linkButton)
        
        container.height = container.subviews.last!.bottom
        container.center = view.center
        container.autoresizingMask = [UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleWidth]

        self.view.addSubview(container)
        
    }
    
    func presentHairBrushWizard() {
        let title = UILabel(frame: CGRect(x: 0, y: self.view.height / 6, width: self.view.width, height: 30))
        title.text = "Select hair and fur using hair brush"
        title.textAlignment = NSTextAlignment.center
        title.textColor = UIColor.white
        title.autoresizingMask = [UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleWidth]
        view.addSubview(title)
        
        let paintHint = UILabel(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        paintHint.text = "Paint on edges to make selections"
        view.addSubview(paintHint)
        
        let cleanHint = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 50))
        cleanHint.text = "Draw on edges to clean unwanted region"
        view.addSubview(cleanHint)
        
        let autoHint = UILabel(frame: CGRect(x: 0, y: 0, width: 140, height: 50))
        autoHint.text = "Color along edges to make auto selection"
        view.addSubview(autoHint)
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, animations:{
            self.view.alpha = 0
            }, completion: {
                success -> () in
                self.view.isHidden = true
        })
    }
    
    func viewTutorialButtonTapped(_ sender: UIButton) {
//        let urlString = self.status == MaskViewWizardType.mask ? "https://d2iufzlyjlomo7.cloudfront.net/tutorial_masking.html" : "https://d2iufzlyjlomo7.cloudfront.net/tutorial_hairbrush.html"
//        let webViewController = WebViewController(nibName: "WebViewController", bundle: nil)
//        webViewController.setup(urlString)
//        controller.present(webViewController, animated: true, completion: {
//        })
    }
}
