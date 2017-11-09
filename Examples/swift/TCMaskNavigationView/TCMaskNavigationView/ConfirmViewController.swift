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

class ConfirmViewController : UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage!
    
    override func viewDidLoad() {
        imageView.image = image
        
        // reset imageView's frame to put it in the center
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
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
}
