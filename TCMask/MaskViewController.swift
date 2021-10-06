//
//  MaskViewController.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 9/22/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

import UIKit
import TCCore

struct ToolParams {
    var add: Bool
    
    var brushSize: CGFloat
    var brushHardness: CGFloat
    var brushOpacity: CGFloat
    
    var quickSelectBrushSize: CGFloat
    var hairBrushBrushSize: CGFloat
}

struct UISettings {
    var prefersStatusBarHidden: Bool = false
    var statusBarStyle: UIStatusBarStyle!
    var topBar: TCUIView!
    var bottomBar: TCUIView!
    var toolMenu: TCUIView!
    var settingView: TCUIView!
    var settingViewTopBar: TCUIView!
    var imageView: TCUIView!
}

class MaskViewController: UIViewController, UITabBarDelegate, MaskViewDelegate, ToolDelegate {
    
    struct ToolItem {
        var type: TCMaskTool
        var name: String
        weak var menuItem: ToolMenuItem!
        weak var settingView: UIView!
    }
    
    struct SettingSliderItem {
        var text: String
        var label: UILabel
        var slider: UISlider
    }
    
    static let settingViewBaseHeight: CGFloat = 192
    
    // UI for main page
    @IBOutlet weak var maskView: MaskView!
    @IBOutlet weak var scrollView: ImageScrollView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    @IBOutlet weak var viewButtonView: UIView!
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var navBar: UIToolbar!
    
    @IBOutlet weak var settingViewLayerMask: UIView!
    @IBOutlet weak var settingView: UIView!
    @IBOutlet weak var settingCanvasView: UIView!
    @IBOutlet weak var settingCircleView: CircleView!
    
    @IBOutlet weak var quickSelectSettingView: UIView!
    @IBOutlet weak var quickSelectBrushSizeLabel: UILabel!
    @IBOutlet weak var quickSelectBrushSizeSlider: UISlider!
    
    @IBOutlet weak var hairBrushSettingView: UIView!
    @IBOutlet weak var hairBrushBrushSizeLabel: UILabel!
    @IBOutlet weak var hairBrushBrushSizeSlider: UISlider!
    
    @IBOutlet weak var brushSettingView: UIView!
    @IBOutlet weak var brushSizeLabel: UILabel!
    @IBOutlet weak var brushSizeSlider: UISlider!
    @IBOutlet weak var brushHardnessLabel: UILabel!
    @IBOutlet weak var brushHardnessSlider: UISlider!
    @IBOutlet weak var brushOpacityLabel: UILabel!
    @IBOutlet weak var brushOpacitySlider: UISlider!
    
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var redoButton: UIBarButtonItem!

    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var addButton: ToolBarItem!
    @IBOutlet weak var settingButton: ToolBarItem!
    @IBOutlet weak var invertButton: ToolBarItem!
    @IBOutlet weak var settingTriangleView: UIImageView!
    
    @IBOutlet weak var toolMenuLayerMask: UIView!
    @IBOutlet weak var toolMenu: UIView!
    @IBOutlet weak var toolBox: ToolMenuItem!
    @IBOutlet weak var hairBrushToolMenuItem: ToolMenuItem!
    @IBOutlet weak var brushToolMenuItem: ToolMenuItem!
    @IBOutlet weak var quickSelectToolMenuItem: ToolMenuItem!
    @IBOutlet weak var triangleView: UIImageView!
    
    weak var delegate : TCMaskViewDelegate?
    
    var isNavigationBarHidden = false
    
    var needToRefreshScrollView = 2
    var circleView: CircleView!
    var activityIndicator: UIActivityIndicatorView!
    
    var originalImage: UIImage!
    var image: UIImage!
    var wizard: MaskViewWizard!
    
    var isInNavigationViewController = false

    var quickSelectToolItem: ToolItem!
    var hairBrushToolItem: ToolItem!
    var brushToolItem: ToolItem!
    var toolItems = [ToolItem]()
    var settingSliderItems = [SettingSliderItem]()
    var previousToolParams: ToolParams!
    
    var toolManager = ToolManager()
    var pendingSwitchToolItem: ToolItem!
    var viewModes = [TCMaskViewMode]()
    var viewModeIdx = 0;
    
    var uiSettings = UISettings()
    var initialMaskValue: UInt8 = 0
    var initialMaskArray: [UInt8]!
    var initialMaskSize: CGSize!
    var initialToolType = TCMaskTool.quickSelect
    var initialState = TCMaskViewState.add
    var testDevices = [String]()
    
    
    var localizationDict = [String : String]()
    
    var currentToolType: TCMaskTool = .quickSelect {
        didSet {
            let previousItem = findToolItem(type: oldValue)!
            let currentItem = findToolItem(type: currentToolType)!
                
            let point = previousItem.menuItem.frame.origin
            previousItem.menuItem.frame.origin = currentItem.menuItem.frame.origin
            currentItem.menuItem.frame.origin = point
                
            toolBox.imageView.image = currentItem.menuItem.imageView.image
            toolBox.label.text = currentItem.menuItem.label.text
            toolManager.switchTool(type: currentToolType)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    deinit {
    }
    
    func setupImage(_ image: UIImage) {
        // Down scale image size if needed
        let sizeLimit: CGFloat = 2400
        if (image.size.width > sizeLimit || image.size.height > sizeLimit) {
            let scale = max(max(image.size.width / sizeLimit, image.size.height / sizeLimit),1)
            self.image = image.resize(CGSize(width: image.size.width/scale, height: image.size.height/scale))
        }
        else {
            self.image = image
        }
        
        self.originalImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // init navBar
        navBar.setShadowImage(UIImage(), forToolbarPosition: UIBarPosition.any)
        navBar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.any, barMetrics: UIBarMetrics.default)
        
        // init viewButton
        self.viewButtonView.layer.cornerRadius = min(viewButtonView.width, viewButtonView.height) / 2
        self.viewButton.layer.cornerRadius = min(viewButton.width, viewButton.height) / 2
        self.viewButton.setImage(UIImage(named: "eyewhite", in: Bundle(for: type(of: self)), compatibleWith: nil), for: UIControl.State())
        self.viewButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.viewButton.alpha = 0.5
        self.viewButton.isHidden = self.viewModes.count == 1
        
        let viewButtonTapGesture = UITapGestureRecognizer(target: self, action: #selector(viewButtonViewTapped(_:)))
        viewButtonView.addGestureRecognizer(viewButtonTapGesture)

        // init scrollView
        scrollView.zoomView = maskView
        scrollView.draggingDisabled = true
        scrollView.zoomFactor = 256
        scrollView.clipsToBounds = true
        scrollView.scrollsToTop = false
        
        // init settingView
        settingViewLayerMask.frame = self.view.bounds
        let settingLayerMaskTapGesture = UITapGestureRecognizer(target: self, action: #selector(settingLayerMaskTapped(_:)))
        settingViewLayerMask.addGestureRecognizer(settingLayerMaskTapGesture)
        self.view.addSubview(settingViewLayerMask)
        
        settingCanvasView.layer.cornerRadius = 5
        
        settingCircleView.backgroundColor = UIColor.clear
        settingCircleView.color = UIColor.green
        settingCanvasView.backgroundColor = UIColor.pngColor()
        
        for view in [quickSelectSettingView!, hairBrushSettingView!, brushSettingView!] {
            settingView.addSubview(view)
            view.backgroundColor = UIColor.clear
        }

        settingView.addSubview(quickSelectSettingView)
        settingView.addSubview(hairBrushSettingView)
        settingView.addSubview(brushSettingView)

        settingSliderItems.append(SettingSliderItem(text: localized("Brush size") + ": ", label: quickSelectBrushSizeLabel, slider: quickSelectBrushSizeSlider))
        settingSliderItems.append(SettingSliderItem(text: localized("Brush size") + ": ", label: hairBrushBrushSizeLabel, slider: hairBrushBrushSizeSlider))

        settingSliderItems.append(SettingSliderItem(text: localized("Brush size") + ": ", label: brushSizeLabel, slider: brushSizeSlider))

        settingSliderItems.append(SettingSliderItem(text: localized("Hardness") + ": ", label: brushHardnessLabel, slider: brushHardnessSlider))

        settingSliderItems.append(SettingSliderItem(text: localized("Opacity") + ": ", label: brushOpacityLabel, slider: brushOpacitySlider))

        // init circleView
        circleView = CircleView(frame: CGRect(x: 0,y: 0,width: 0,height: 0))
        circleView.backgroundColor = UIColor.clear
        circleView.isUserInteractionEnabled = false
        circleView.isHidden = true
        self.view.addSubview(circleView)
        
        // init activityIndicator view
        activityIndicator = UIActivityIndicatorView(frame: self.viewButton.frame)
        self.viewButtonView.addSubview(activityIndicator)
        activityIndicator.isHidden = true
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
        activityIndicator.layer.cornerRadius = activityIndicator.frame.size.width / 2

        // init tool bar items
        addButton.onImage = UIImage(named: "add", in: Bundle(for: type(of: self)), compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        addButton.offImage = UIImage(named: "subtract", in: Bundle(for: type(of: self)), compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        addButton.type = .flip
        addButton.on = true

        // init maskView
        maskView.scrollView = scrollView
        maskView.delegate = self
        maskView.frame.size = image.size / maskView.scaleFactor
        
        var initOpacity = initialMaskValue
        if (initialState == TCMaskViewState.subtract) {
            initOpacity = 255 - initOpacity
        }
        maskView.loadImage(self.image, viewMode: viewModes[viewModeIdx], initOpacity: initOpacity)
        if (initialMaskArray != nil) {
            if (initialMaskArray.count == maskView.opacity.count) {
                maskView.opacity = initialMaskArray
            }
            else {
                TCCore.arrayResize(&maskView.opacity, src: initialMaskArray!, dstSize: image.size, srcSize: initialMaskSize)
            }
        }
        maskView.refresh()
        
        // init tool manager
        toolManager.maskView = maskView
        toolManager.toolDelegate = self

        // Why is there extra padding at the top of my view
        // http://stackoverflow.com/questions/18880341/why-is-there-extra-padding-at-the-top-of-my-uitableview-with-style-uitableviewst

        
        settingButton.type = .state
        settingButton.action = {
            [unowned self] sender in
            self.settingButtonTapped(sender)
        }
        invertButton.action = {
            [unowned self] sender in
            self.invertButtonTapped(sender)
        }
        
        // init wizard
        wizard = MaskViewWizard(controller: self)
        
        // init tool menu
        toolMenuLayerMask.frame = self.view.bounds
        self.view.addSubview(toolMenuLayerMask)
 
        let toolMenuLayerMaskPanGesture = UILongPressGestureRecognizer(target: self, action: #selector(toolMenuLayerMaskTapped(_:)))
        toolMenuLayerMaskPanGesture.minimumPressDuration = 0
        toolMenuLayerMask.addGestureRecognizer(toolMenuLayerMaskPanGesture)
        
        let toolBoxTapGesture = UITapGestureRecognizer(target: self, action: #selector(toolBoxTapped(_:)))
        toolBox.addGestureRecognizer(toolBoxTapGesture)

        brushToolItem = ToolItem(type: .brush, name: "Brush", menuItem: brushToolMenuItem,settingView: brushSettingView)
        quickSelectToolItem = ToolItem(type: .quickSelect, name: "QuickSelect", menuItem: quickSelectToolMenuItem, settingView: quickSelectSettingView)
        hairBrushToolItem = ToolItem(type: .hairBrush, name: "HairBrush", menuItem: hairBrushToolMenuItem, settingView: hairBrushSettingView)
        
        toolItems = [brushToolItem, quickSelectToolItem, hairBrushToolItem]

        updateUISettings()
        self.currentToolType = self.initialToolType
        
        view.bringSubviewToFront(circleView)
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toolManager.switchTool(type: currentToolType)
        if (isInNavigationViewController) {
            nextButton.image = UIImage(named: "next", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        }
        else {
            nextButton.image = UIImage(named: "check", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        }
        
        isNavigationBarHidden = self.navigationController?.isNavigationBarHidden ?? true
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (self.view as! UILockableView).enableProtection()
        
        if (!UserDefaults.standard.bool(forKey: "TCMaskView_wizard_presented")) {
            UserDefaults.standard.set(true, forKey: "TCMaskView_wizard_presented")
            wizard.present()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if (needToRefreshScrollView > 0){
            self.scrollView.refresh()
            needToRefreshScrollView -= 1
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        (self.view as! UILockableView).disableProtection()
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = isNavigationBarHidden
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            needToRefreshScrollView += 1
            return
        }
        
        coordinator.animate(
            alongsideTransition: {
                // Place code here to perform animations during the rotation.
                context -> () in
                self.scrollView.resetZoomScale(true)
            }, completion: {
                // Code here will execute after the rotation has finished.
                contest -> () in
            }
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return uiSettings.statusBarStyle
    }
    
    override var prefersStatusBarHidden: Bool {
        return uiSettings.prefersStatusBarHidden
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        self.toolManager.endProcessing()
        self.toolManager.tool = nil
        
        let mask = TCMask(data: maskView.resizedOpacity(size: self.originalImage.size), size: self.originalImage.size)
        self.delegate?.tcMaskViewDidExit?(mask: mask, image: self.originalImage)
        
        if (self.isInNavigationViewController) {
            _ = self.navigationController!.popViewController(animated: true)
        }
        else {
            self.dismiss(animated: true, completion: {})
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: UIBarButtonItem) {
        toolManager.endProcessing()
        toolManager.tool = nil
        
        let mask = TCMask(data: maskView.resizedOpacity(size: self.originalImage.size), size: self.originalImage.size)
        
        if (isInNavigationViewController) {
            if let viewController = delegate?.tcMaskViewWillPushViewController?(mask: mask, image: originalImage) {
                self.navigationController!.pushViewController(viewController, animated: true)
            }
            else {
                self.navigationController!.popViewController(animated: true)
            }
        }
        else {
            self.dismiss(animated: true, completion: {})
        }
        delegate?.tcMaskViewDidComplete?(mask: mask, image: originalImage)
    }
    
    func invertButtonTapped(_ sender: ToolBarItem) {
        toolManager.invert()
        undoButton.isEnabled = toolManager.canPerformUndo()
        redoButton.isEnabled = toolManager.canPerformRedo()
    }
    
    @objc func viewButtonViewTapped(_ sender: UITapGestureRecognizer) {
        if (!self.viewButton.isHidden) {
            self.viewButtonTapped(self.viewButton)
        }
    }
    
    @IBAction func viewButtonTapped(_ sender: UIButton) {
        self.viewModeIdx = (self.viewModeIdx + 1) % self.viewModes.count
        maskView.setViewMode(viewModes[viewModeIdx])
        toolManager.tool.refresh()
    }
    
    func maskViewTouchBegan(_ maskView: MaskView, _ location: CGPoint) {
        toolManager.switchTool(type: currentToolType)
        updateCircleView()
        circleView.isHidden = false
        circleView.center = maskView.convert(location, to: self.view)
        toolManager.tool.touchBegan(location)
    }
    
    func maskViewTouchMoved(_ maskView: MaskView, _ previousLocation: CGPoint, _ location: CGPoint) {
        circleView.center = maskView.convert(location, to: self.view)
        toolManager.tool.touchMoved(previousLocation, location)
    }
    
    func maskViewTouchEnded(_ maskView: MaskView, _ previousLocation: CGPoint, _ location: CGPoint) {
        circleView.isHidden = true
        toolManager.tool.touchEnded(previousLocation, location)
    }
    
    func toolWillBeginProcessing(_ tool: Tool) {
        viewButton.isHidden = true
        
        backButton.isEnabled = false
        nextButton.isEnabled = false
        undoButton.isEnabled = false
        redoButton.isEnabled = false
    }
    
    func toolDidEndProcessing(_ tool: Tool) {
        viewButton.isHidden = self.viewModes.count == 1
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        
        backButton.isEnabled = true
        nextButton.isEnabled = true
        undoButton.isEnabled = toolManager.canPerformUndo()
        redoButton.isEnabled = toolManager.canPerformRedo()
        
        if (pendingSwitchToolItem != nil) {
            handleMenuToolSwitch(targetItem: pendingSwitchToolItem)
            pendingSwitchToolItem = nil
        }
    }
    
    func toolIsWaitingForProcessing(_ tool: Tool) {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
    
    @IBAction func undoButtonTapped(_ sender: UIBarButtonItem) {
        toolManager.undo()
        undoButton.isEnabled = toolManager.canPerformUndo()
        redoButton.isEnabled = toolManager.canPerformRedo()
    }
    
    @IBAction func redoButtonTapped(_ sender: UIBarButtonItem) {
        toolManager.redo()
        undoButton.isEnabled = toolManager.canPerformUndo()
        redoButton.isEnabled = toolManager.canPerformRedo()
    }

    @IBAction func settingButtonTapped(_ sender: ToolBarItem) {
        settingTriangleView.isHidden = false

        for item in toolItems {
            if (item.type == currentToolType) {
                item.settingView.isHidden = false
//                settingView.height = max(132, item.settingView.height) + 56
//                settingView.bottom = settingViewLayerMask.height - bottomBar.height
            }
            else {
                item.settingView.isHidden = true
            }
        }
        
        settingViewLayerMask.isHidden = false
        updateCircleView()
    }
    
    @objc func settingLayerMaskTapped(_ sender: UITapGestureRecognizer) {
        if (settingView.layer.contains(sender.location(in: settingView))) {
            return
        }
        else {
            settingButton.on = false
            settingTriangleView.isHidden = true
            settingViewLayerMask.isHidden = true
        }
    }
    
    @IBAction func settingSliderValueChanged(_ sender: UISlider) {
        let item = findSettingSliderItem(sender)!
        item.label.text = item.text + "\(Int(sender.value))"
        updateCircleView()
    }
    
    @objc func toolBoxTapped(_ sender: UITapGestureRecognizer) {
        toolMenuLayerMask.isHidden = false
    }
    
    @objc func toolMenuLayerMaskTapped(_ sender: UILongPressGestureRecognizer) {
        let touchInMenu = toolMenu.bounds.contains(sender.location(in: toolMenu))
        
        switch sender.state {
        case .began, .changed:
            guard touchInMenu else {
                for item in toolItems {
                    item.menuItem.imageView.tintColor = uiSettings.toolMenu.tintColor
                    item.menuItem.label.textColor = uiSettings.toolMenu.textColor
                }
                return
            }

            var selectedItem: ToolItem!
            
            for item in toolItems {
                let menu = item.menuItem!
                if menu.bounds.contains(sender.location(in: menu)) {
                    selectedItem = item
                }
            }

            _ = highlightToolItem(selectedItem)
            
        default:
            var selectedItem: ToolItem!
            for item in toolItems {
                let menu = item.menuItem!
                if menu.bounds.contains(sender.location(in: menu)) {
                    selectedItem = item
                    break
                }
            }
            _ = selectToolItem(selectedItem)
        }
    }
    
    func highlightToolItem(_ selectedItem: ToolItem!) -> Bool {
        guard selectedItem != nil else {
            return false
        }
        
        for item in toolItems {
            if item.type == selectedItem.type {
                item.menuItem.imageView.tintColor = uiSettings.toolMenu.highlightedColor
                item.menuItem.label.textColor = uiSettings.toolMenu.highlightedColor
            }
            else {
                item.menuItem.imageView.tintColor = uiSettings.toolMenu.tintColor
                item.menuItem.label.textColor = uiSettings.toolMenu.textColor
            }
        }
        
        return true
    }
    
    func selectToolItem(_ selectedItem: ToolItem!) -> Bool {
        if (toolManager.isInProcess() && selectedItem != nil && selectedItem.type != currentToolType) {
            pendingSwitchToolItem = selectedItem
            return false
        }
        else {
            pendingSwitchToolItem = nil
        }
        
        handleMenuToolSwitch(targetItem: selectedItem)
        return true
    }
    
    func handleMenuToolSwitch(targetItem: ToolItem!) {
        if targetItem != nil {
            currentToolType = targetItem.type
        }
        
        for item in toolItems {
            let menu = item.menuItem!
            menu.imageView.tintColor = uiSettings.toolMenu.tintColor
            menu.label.textColor = uiSettings.toolMenu.textColor
        }
        
        toolMenuLayerMask.isHidden = true
    }
    
    func getToolParams() -> ToolParams {
        return ToolParams(add: addButton.on, brushSize: CGFloat(brushSizeSlider.value), brushHardness: CGFloat(brushHardnessSlider.value) / 100, brushOpacity: CGFloat(brushOpacitySlider.value) / 100, quickSelectBrushSize: CGFloat(quickSelectBrushSizeSlider.value),hairBrushBrushSize: CGFloat(hairBrushBrushSizeSlider.value))
    }
    
    func findToolItem(type: TCMaskTool) -> ToolItem! {
        for item in toolItems {
            if item.type == type {
                return item
            }
        }
        return nil
    }
    
    func findSettingSliderItem(_ slider: UISlider) -> SettingSliderItem! {
        for item in settingSliderItems {
            if item.slider === slider {
                return item
            }
        }
        return nil
    }
    
    func localized(_ name : String) -> String {
        if let val = localizationDict[name] {
            return val
        }
        else {
            return TCMaskView.defaultLocalizationDictionary[name]!
        }
    }
    
    func updateUISettings() {
        // set top bar
        self.view.backgroundColor = uiSettings.topBar.backgroundColor
        navBar.backgroundColor = uiSettings.topBar.backgroundColor
        navBar.tintColor = uiSettings.topBar.tintColor
        
        // set image view
        self.containerView.backgroundColor = uiSettings.imageView.backgroundColor
        
        // set tool menu
        toolMenu.backgroundColor = uiSettings.toolMenu.backgroundColor
        toolBox.backgroundColor = toolMenu.backgroundColor
        for item in toolItems {
            item.menuItem.imageView.tintColor = uiSettings.toolMenu.tintColor
            item.menuItem.label.textColor = uiSettings.toolMenu.textColor
        }
        toolBox.imageView.tintColor = uiSettings.toolMenu.tintColor
        toolBox.label.textColor = uiSettings.toolMenu.textColor
        triangleView.image = triangleView.image!.withRenderingMode(.alwaysTemplate)
        triangleView.tintColor = uiSettings.toolMenu.tintColor
        
        // set setting view
        settingView.backgroundColor = uiSettings.settingView.backgroundColor
        settingTriangleView.image = settingTriangleView.image!.withRenderingMode(.alwaysTemplate)
        settingTriangleView.tintColor = settingView.backgroundColor
        for parentview in [brushSettingView, quickSelectSettingView, hairBrushSettingView] {
            for subview in parentview!.subviews {
                if let view = subview as? UISlider {
                    view.tintColor = uiSettings.settingView.tintColor
                    view.minimumTrackTintColor = view.tintColor
                    view.maximumTrackTintColor = view.tintColor
                }
                else if let view = subview as? UILabel {
                    view.textColor = uiSettings.settingView.textColor
                }
            }
        }

        // set bottom bar
        bottomBar.backgroundColor = uiSettings.bottomBar.backgroundColor
        for button in [addButton!, settingButton!, invertButton!] {
            button.color = uiSettings.bottomBar.tintColor
            button.textColor = uiSettings.bottomBar.textColor
            button.highlightedColor = uiSettings.bottomBar.highlightedColor
            button.refresh()
        }
        
        // localization
        addButton.label.text = localized("Add")
        addButton.onText = localized("Add")
        addButton.offText = localized("Subtract")
        settingButton.label.text = localized("Setting")
        invertButton.label.text = localized("Invert")
        quickSelectToolMenuItem.label.text = localized("Quick Select")
        hairBrushToolMenuItem.label.text = localized("Hair Brush")
        brushToolMenuItem.label.text = localized("Brush")
        
        if (initialState == TCMaskViewState.subtract) {
            addButton.on = false
        }
        
        for item in settingSliderItems {
            settingSliderValueChanged(item.slider)
        }
    }
    
    func updateCircleView() {
        let params = getToolParams()
        
        switch currentToolType {
        case .quickSelect:
            circleView.size = CGFloat(params.quickSelectBrushSize)
            circleView.stroke = false
            circleView.hardness = 1
            circleView.alpha = 0.5
            circleView.color = params.add ? UIColor.green : UIColor.red
        case .hairBrush:
            circleView.size = CGFloat(params.hairBrushBrushSize)
            circleView.stroke = true
            circleView.hardness = 1
            circleView.alpha = 0.5
            circleView.color = params.add ? UIColor.green : UIColor.red
        case .brush:
            circleView.size = CGFloat(params.brushSize)
            circleView.stroke = false
            circleView.hardness = CGFloat(params.brushHardness)
            circleView.alpha = 0.5 + CGFloat(params.brushOpacity) * 0.25
            circleView.color = params.add ? UIColor.green : UIColor.red
        }

        settingCircleView.size = circleView.size
        settingCircleView.color = circleView.color
        settingCircleView.stroke = circleView.stroke
        settingCircleView.hardness = circleView.hardness
        settingCircleView.alpha = circleView.alpha
        settingCircleView.center = CGPoint(x: settingCanvasView.width / 2, y: settingCanvasView.height / 2)
    }
}
