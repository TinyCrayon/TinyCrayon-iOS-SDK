//
//  The MIT License
//
//  Copyright (C) 2016 TinyCrayon.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import UIKit
import TCMask

class ViewController: UIViewController, TCMaskViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        if (imageView.image == nil) {
            presentTCMaskView()
        }
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        presentTCMaskView()
    }
    
    func presentTCMaskView() {
        let image = UIImage(named: "Balloon.JPEG")!
        let maskView = TCMaskView(image: image)
        maskView.delegate = self
        
        // Change status bar style
        maskView.statusBarStyle = UIStatusBarStyle.lightContent
        
        // Change UI components style
        maskView.topBar.backgroundColor = UIColor(white: 0.1, alpha: 1)
        maskView.topBar.tintColor = UIColor.white
        
        maskView.imageView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        
        maskView.bottomBar.backgroundColor = UIColor(white: 0.1, alpha: 1)
        maskView.bottomBar.tintColor = UIColor.white
        maskView.bottomBar.textColor = UIColor.white
        
        maskView.settingView.backgroundColor = UIColor(white: 0.8, alpha: 0.9)
        maskView.settingView.textColor = UIColor(white: 0.33, alpha: 1)
        
        // Create a customized view mode with gray scale image
        let grayScaleImage = image.convertToGrayScaleNoAlpha()
        let viewMode = TCMaskViewMode(foregroundImage: grayScaleImage, backgroundImage: nil, isInverted: true)
        
        // set customized viewMode to be the only view mode in TCMaskView
        maskView.viewModes = [viewMode]
        
        maskView.presentFrom(rootViewController: self, animated: true)
    }
    
    func tcMaskViewDidComplete(mask: TCMask, image: UIImage) {
        imageView.image = mask.cutout(image: image, resize: true)
    }
}

extension UIImage {
    func convertToGrayScaleNoAlpha() -> UIImage {
        let colorSpace = CGColorSpaceCreateDeviceGray();
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        context?.draw(self.cgImage!, in: CGRect(origin: CGPoint(), size: size))
        return UIImage(cgImage: context!.makeImage()!)
    }
}

