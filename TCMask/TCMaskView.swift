//
//  TCMaskView.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 2/18/17.
//
//

import UIKit

/**
 The module that displays a UIViewController for image masking.
 A minimum implementation to present a TCMaskview within a UIViewController class is:
 
 ```
 // Create TCMaskView, specifying the image for masking.
 let maskView = TCMaskView(image: self.image)
 
 // Present TCMaskView from current view controller.
 maskView.present(from: self, animated: true)
 ```
 */
open class TCMaskView : NSObject {
    /**
     Localization dictionary, set it before you create any `TCMaskView`.
     
     An english fallback localization will be used when no matching localization is found.
     
     To determine the matching language TinyCrayon SDK uses `NSLocale.preferredLanguages`.
     
     To add suport for a language, set a localization dictionary like so:
     
     ```
     TCMaskView.localizationDictionary =  [
        "Quick Select" : "Quick Select",
        "Hair Brush" : "Hair Brush",
        "Brush" : "Brush",
        "Add" : "Add",
        "Subtract" : "Subtract",
        "Setting" : "Setting",
        "Invert" : "Invert",
        "Brush size" : "Brush size",
        "Hardness" : "Hardness",
        "Opacity" : "Opacity",
        "Tips-Draw" : "Draw on the places to select/erase",
        "Tips-Zoom" : "Pinch to zoom in/out to refine details",
        "Tips-Move" : "Use two fingers dragging to move"
     ]
     ```
     */
    @objc public static var localizationDictionary = [String : [String : String]]()
    
    static let defaultLocalizationDictionary = [
        "Quick Select" : "Quick Select",
        "Hair Brush" : "Hair Brush",
        "Brush" : "Brush",
        "Add" : "Add",
        "Subtract" : "Subtract",
        "Setting" : "Setting",
        "Invert" : "Invert",
        "Brush size" : "Brush size",
        "Hardness" : "Hardness",
        "Opacity" : "Opacity",
        "Tips-Draw" : "Draw on the places to select/erase",
        "Tips-Zoom" : "Pinch to zoom in/out to refine details",
        "Tips-Move" : "Use two fingers dragging to move"
    ]
    
    static let defaultViewModes = [TCMaskViewMode(foregroundColor: UIColor(white: 1, alpha: 0.5), backgroundImage: nil, isInverted: true), TCMaskViewMode.transparent(), TCMaskViewMode(foregroundColor: UIColor.black, backgroundImage: nil, isInverted: true)]
    
    static func getLocalizationDict() -> [String : String] {
        for language in NSLocale.preferredLanguages {
            if let dict = localizationDictionary[language] {
                return dict
            }
        }
        for language in NSLocale.preferredLanguages {
            let languageDict = NSLocale.components(fromLocaleIdentifier: language)
            if let languageCode = languageDict["kCFLocaleLanguageCodeKey"] {
                if let dict = localizationDictionary[languageCode] {
                    return dict
                }
            }
        }
        return [String : String]()
    }
    
    let image: UIImage
    var controller: MaskViewController!
    var initialMaskValue: UInt8 = 0
    var initialMaskArray: [UInt8]!
    var initialMaskSize = CGSize()
    
    /// Initialize a TCMaskView
    @objc public init(image: UIImage) {
        self.image = image.imageWithFixedOrientation()
        self.viewModes = TCMaskView.defaultViewModes
        self.initialTool = TCMaskTool.quickSelect
        self.prefersStatusBarHidden = false
        self.statusBarStyle = UIStatusBarStyle.default
        self.topBar = TCUIView()
        self.bottomBar = TCUIView()
        self.toolMenu = TCUIView()
        self.settingView = TCUIView()
        self.imageView = TCUIView()
        
        super.init()
        initTheme()
    }
    
    /// Optional delegate object that receives exit/completion notifications from this TCMaskView.
    @objc open weak var delegate : TCMaskViewDelegate?
    
    /**
     View modes of TCMaskView, if no viewModes is provided or by default, TCMaskView will use the following view modes:
     
     ```
     viewModes[0] = TCMaskViewMode(foregroundColor: UIColor(white: 1, alpha: 0.5), backgroundImage: nil, isInverted: true);
     viewModes[1] = TCMaskViewMode.transparent()
     viewModes[2] = TCMaskViewMode(foregroundColor: UIColor.black, backgroundImage: nil, isInverted: true)
     ```
     */
    @objc open var viewModes: [TCMaskViewMode]
    
    /// Initial tool when TCMaskView is presented
    @objc open var initialTool: TCMaskTool
    
    /// True if the status bar should be hidden or false if it should be shown.
    @objc open var prefersStatusBarHidden: Bool
    
    /// The style of the device’s status bar.
    @objc open var statusBarStyle: UIStatusBarStyle
    
    /// Top bar of TCMaskView
    @objc open var topBar: TCUIView
    
    /// Bottom bar of TCMaskView
    @objc open var bottomBar: TCUIView
    
    /// Tool panel of TCMaskView
    @objc open var toolMenu: TCUIView
    
    /// Setting view of TCMaskView
    @objc open var settingView: TCUIView
    
    /// Image view of TCMaskView
    @objc open var imageView: TCUIView
    
    /// Test devices in development
    @objc open var testDevices = [String]()
    
    /// Initial state of TCMaskView
    @objc open var initialState = TCMaskViewState.add
    
    /**
     Presents the TCMaskView controller modally, which takes over the entire screen until the user closes or completes it.
     
     Set rootViewController to the current view controller at the time this method is called.
     
     **Delegates:**
     
     tcMaskViewDidExit: is called before TCMaskView is about to exit
     
     tcMaskViewDidComplete: is called before TCMaskView is about to complete
     
     - parameter rootViewController: The root view controller from which TCMaskView controller is presented
     - parameter animated: Specify true to animate the transition or false if you do not want the transition to be animated.
     */
    @objc open func presentFrom(rootViewController: UIViewController, animated: Bool) {
        controller = MaskViewController(nibName: "MaskViewController", bundle: Bundle(identifier: "com.TinyCrayon.TCMask"))
        controller.setupImage(image)
        controller.isInNavigationViewController = false
        controller.modalPresentationStyle = .fullScreen
        
        setupMaskViewController(controller)
        rootViewController.present(controller, animated: animated, completion: nil)
    }
    
    /**
     Pushes a TCMaskView controller onto the navigationController’s stack and updates the display.
     
     TCMaskView becomes the top view controller on the navigation stack. Pushing a view controller causes its view to be embedded in the navigation interface. If the animated parameter is true, the view is animated into position; otherwise, the view is simply displayed in its final location.
     
     In addition to displaying the view associated with the new view controller at the top of the stack, this method also updates the navigation bar and tool bar accordingly. For information on how the navigation bar is updated, see Updating the Navigation Bar.
     
     **Delegates:**
     
     tcMaskViewDidExit: is called before TCMaskView is about to exit
     
     tcMaskViewDidComplete: is called before TCMaskView is about to complete
     
     tcMaskViewWillPushViewController: is called before navigation controller is about to accomplish TCMaskView and process to the next UIViewController
     
     - parameter navigationController: UINavigationController onto which TCMaskView is pushed
     - parameter animated: Specify true to animate the transition or false if you do not want the transition to be animated.
     */
    @objc open func presentFrom(navigationController: UINavigationController, animated: Bool) {
        controller = MaskViewController(nibName: "MaskViewController", bundle: Bundle(identifier: "com.TinyCrayon.TCMask"))
        controller.setupImage(image)
        
        controller.isInNavigationViewController = true
        
        setupMaskViewController(controller)
        navigationController.pushViewController(controller, animated: animated)
    }
    
    /**
     Set the initial mask value of TCMaksView.
     
     - parameter mask: Initial mask value, the entire initial mask will be filled with this value
     */
    @objc open func setInitialMaskWithValue(_ mask: UInt8) {
        initialMaskArray = nil
        initialMaskValue = mask
    }
    
    /**
     Set the initial mask value of TCMaksView.
     
     - parameter mask: Initial mask value, mask length should match TCMaskView image size (mask.count == image.size.width * image.size.height)
     */
    @objc open func setInitialMaskWithArray(_ mask: [UInt8]) {
        assert(mask.count > 0, "setInitialMask: inital mask array is empty")
        setInitialMask(mask, size: image.size)
    }
    
    /**
     Set the initial mask value of TCMaksView.
     
     - parameter mask: Initial mask value
     - parameter size: Size of mask, mask length should match size (mask.count == size.width * size.height), if size is not the same as image size, the initial mask will be scalled to fit image size.
     */
    @objc open func setInitialMask(_ mask: [UInt8], size: CGSize) {
        assert(Int(size.width * size.height) == mask.count, "setInitialMask: mask length \(mask.count) does not match size \(size)")
        initialMaskArray = mask
        initialMaskSize = size
    }
    
    func setupMaskViewController(_ controller: MaskViewController) {
        
        // setup view modes
        controller.viewModes.removeAll()
        if viewModes.count == 0 {
            controller.viewModes = TCMaskView.defaultViewModes
        }
        else {
            for mode in self.viewModes {
                controller.viewModes.append(mode.clone())
            }
        }
        controller.viewModeIdx = 0
        
        // deep copy UI settings
        var settings = UISettings()
        settings.prefersStatusBarHidden = self.prefersStatusBarHidden
        settings.statusBarStyle = self.statusBarStyle
        settings.topBar = self.topBar.clone()
        settings.imageView = self.imageView.clone()
        settings.bottomBar = self.bottomBar.clone()
        settings.toolMenu = self.toolMenu.clone()
        settings.settingView = self.settingView.clone()
        controller.uiSettings = settings
        
        // setup initial params
        controller.initialMaskValue = initialMaskValue
        controller.initialMaskArray = initialMaskArray
        controller.initialMaskSize = initialMaskSize
        controller.initialToolType = initialTool
        controller.initialState = initialState
        
        // setup delegate
        controller.delegate = self.delegate
        
        // setup test devices
        controller.testDevices = self.testDevices
        
        // setup localization
        controller.localizationDict = TCMaskView.getLocalizationDict()
    }
    
    func initTheme() {
        self.statusBarStyle = UIStatusBarStyle.default
        
        topBar.backgroundColor = UIColor.white
        topBar.tintColor = UIColor(white: 84/255, alpha: 1)
        
        imageView.backgroundColor = UIColor(white: 21/255, alpha: 1)
        
        toolMenu.backgroundColor = UIColor(red: 87/255, green: 100/255, blue: 116/255, alpha: 1)
        toolMenu.tintColor = UIColor.white
        toolMenu.highlightedColor = UIColor(red: 197/255, green: 164/255, blue: 126/255, alpha: 1)
        toolMenu.textColor = UIColor.white
        
        bottomBar.backgroundColor = UIColor.white
        bottomBar.tintColor = UIColor(white: 84/255, alpha: 1)
        bottomBar.textColor = UIColor(white: 84/255, alpha: 1)
        bottomBar.highlightedColor = UIColor(red: 75/255, green: 126/255, blue: 194/255, alpha: 1)
        
        settingView.backgroundColor = UIColor(white: 54/255, alpha: 0.9)
        settingView.tintColor = UIColor.lightGray
        settingView.textColor = UIColor.white
    }
}
