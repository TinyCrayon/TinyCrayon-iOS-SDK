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
import CoreImage
import TCMask

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TCMaskViewDelegate {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var buttonGroup: UIView!
    
    let imagePicker = UIImagePickerController()
    var image: UIImage!
    var mask: TCMask!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonGroup.isHidden = true
    }
    
    @IBAction func selectImageButtonTapped(_ sender: Any) {
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.image = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.imagePicker.dismiss(animated: false, completion: {})
        
        let maskView = TCMaskView(image: self.image)
        maskView.delegate = self
        maskView.presentFrom(rootViewController: self, animated: true)
    }
    
    func tcMaskViewDidComplete(mask: TCMask, image: UIImage) {
        self.mask = mask
        buttonGroup.isHidden = false
        
        // adjust the size of image view to make it fit the image size and put it in the center of screen
        var x:CGFloat, y:CGFloat, width:CGFloat, height:CGFloat
        if (image.size.width > image.size.height) {
            width = containerView.frame.width
            height = width * image.size.height / image.size.width
            x = 0
            y = (containerView.frame.height - height) / 2
        }
        else {
            height = containerView.frame.height
            width = height * image.size.width / image.size.height
            x = (containerView.frame.width - width) / 2
            y = 0
        }
        imageView.frame = CGRect(x: x, y: y, width: width, height: height)
        
        imageView.image = mask.cutout(image: image, resize: false)
    }
    
    @IBAction func whiteButtonTapped(_ sender: Any) {
        imageView.image = mask.blend(foregroundImage: image, backgroundImage: UIImage(color: UIColor.white, size: image.size)!)
    }
    
    @IBAction func blackButtonTapped(_ sender: Any) {
        imageView.image = mask.blend(foregroundImage: image, backgroundImage: UIImage(color: UIColor.black, size: image.size)!)
    }
    
    @IBAction func clearButtonTapped(_ sender: Any) {
        imageView.image = mask.cutout(image: image, resize: false)
    }
    
    @IBAction func grayScaleButtonTapped(_ sender: Any) {
        // Create a mask image from mask array
        let maskImage = CIImage(image: mask.rgbaImage())
        let ciImage = CIImage(image: image)
        
        // Use color filter to create a gray scale image
        let colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(ciImage , forKey: kCIInputImageKey)
        colorFilter.setValue(0, forKey: kCIInputSaturationKey)
        
        // Use blend filter to blend color image and gray scale image using mask
        let blendFilter = CIFilter(name: "CIBlendWithAlphaMask")!
        blendFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blendFilter.setValue(colorFilter.outputImage!, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        // Get the output result
        let result = blendFilter.outputImage!
        let outputImage = UIImage(ciImage: result)
        
        imageView.image = outputImage
    }
}

extension UIImage {
    // create a UIImage with solid color
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

