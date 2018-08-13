//
//  PasterView.swift
//  PasterViewSample
//
//  Created by AlphaZ on 2018/8/3.
//  Copyright © 2018年 AlphaZ. All rights reserved.
//

import UIKit

enum PasterViewHandler:Int {
    case close = 0
    case rotate
    case flip
}

enum PasterViewPosition:Int {
    case topLeft = 0
    case topRight
    case bottomLeft
    case bottomRight
}

@inline(__always) func CGRectGetCenter(_ rect:CGRect) -> CGPoint {
    return CGPoint(x: rect.midX, y: rect.midY)
}

@inline(__always) func CGRectScale(_ rect:CGRect, wScale:CGFloat, hScale:CGFloat) -> CGRect {
    return CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width * wScale, height: rect.size.height * hScale)
}

@inline(__always) func CGAffineTransformGetAngle(_ t:CGAffineTransform) -> CGFloat {
    return atan2(t.b, t.a)
}

@inline(__always) func CGPointGetDistance(point1:CGPoint, point2:CGPoint) -> CGFloat {
    let fx = point2.x - point1.x
    let fy = point2.y - point1.y
    return sqrt(fx * fx + fy * fy)
}

@objc protocol PasterViewDelegate {
    @objc func PasterViewDidBeginMoving(_ PasterView: PasterView)
    @objc func PasterViewDidChangeMoving(_ PasterView: PasterView)
    @objc func PasterViewDidEndMoving(_ PasterView: PasterView)
    @objc func PasterViewDidBeginRotating(_ PasterView: PasterView)
    @objc func PasterViewDidChangeRotating(_ PasterView: PasterView)
    @objc func PasterViewDidEndRotating(_ PasterView: PasterView)
    @objc func PasterViewDidClose(_ PasterView: PasterView)
    @objc func PasterViewDidTap(_ PasterView: PasterView)
}

class PasterView: UIView {
    var delegate: PasterViewDelegate!
    var contentView:UIView!
    var enableClose:Bool = true {
        didSet {
            if self.showEditingHandlers {
                self.setEnableClose(self.enableClose)
            }
        }
    }
    var enableRotate:Bool = true{
        didSet {
            if self.showEditingHandlers {
                self.setEnableRotate(self.enableRotate)
            }
        }
    }
    var enableFlip:Bool = true
    var showEditingHandlers:Bool = true {
        didSet {
            if self.showEditingHandlers {
                self.setEnableClose(self.enableClose)
                self.setEnableRotate(self.enableRotate)
                self.setEnableFlip(self.enableFlip)
                self.contentView?.layer.borderWidth = 2
            }
            else {
                self.setEnableClose(false)
                self.setEnableRotate(false)
                self.setEnableFlip(false)
                self.contentView?.layer.borderWidth = 0
            }
        }
    }

    private var _minimumSize:NSInteger = 0
    var minimumSize:NSInteger {
        set {
            _minimumSize = max(newValue, self.defaultMinimumSize)
        }
        get {
            return _minimumSize
        }
    }
    var maxScale:CGFloat = 4
    private var _outlineBorderColor:UIColor = .white
    var outlineBorderColor:UIColor {
        set {
            _outlineBorderColor = newValue
            self.contentView?.layer.borderColor = _outlineBorderColor.cgColor
        }
        get {
            return _outlineBorderColor
        }
    }
    var userInfo:Any?

    var pinchScale:CGFloat = 1.0
    var isShouldGesture = true


    init(contentView: UIView) {
        self.defaultInset = 15
        self.defaultMinimumSize = 4 * self.defaultInset

        var frame = contentView.frame
        frame = CGRect(x: 0, y: 0, width: frame.size.width + CGFloat(self.defaultInset) * 2, height: frame.size.height + CGFloat(self.defaultInset) * 2)
        super.init(frame: frame)

        //todo @zd 放大
        let pinchGr = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureDetected(_:)))
        pinchGr.cancelsTouchesInView = false
        pinchGr.delegate = self
        self.addGestureRecognizer(pinchGr)

        let rotationGr = UIRotationGestureRecognizer(target: self, action: #selector(rotationGestureDetected(_:)))
        rotationGr.cancelsTouchesInView = false
        rotationGr.delegate = self
        self.addGestureRecognizer(rotationGr)

        //     pinchGr.require(toFail: moveGesture)
        //     pinchGr.require(toFail: tapGesture)
        //     rotationGr.require(toFail: moveGesture)
        //     rotationGr.require(toFail: tapGesture)

        self.addGestureRecognizer(self.moveGesture)
        self.addGestureRecognizer(self.tapGesture)


        self.contentView = contentView
        self.contentView.center = CGRectGetCenter(self.bounds)
        self.contentView.isUserInteractionEnabled = false
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.layer.allowsEdgeAntialiasing = true
        self.addSubview(self.contentView)

        self.setPosition(.topRight, forHandler: .close)
        self.addSubview(self.closeImageView)
        self.setPosition(.bottomRight, forHandler: .rotate)
        self.addSubview(self.rotateImageView)
        self.setPosition(.topLeft, forHandler: .flip)
        self.addSubview(self.flipImageView)

        self.showEditingHandlers = true
        self.enableClose = true
        self.enableRotate = true
        self.enableFlip = true

        self.minimumSize = self.defaultMinimumSize
        self.outlineBorderColor = .brown
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image:UIImage, forHandler handler:PasterViewHandler) {
        switch handler {
        case .close:
            self.closeImageView.image = image
        case .rotate:
            self.rotateImageView.image = image
        case .flip:
            self.flipImageView.image = image
        }
    }

    func setPosition(_ position:PasterViewPosition, forHandler handler:PasterViewHandler) {
        let origin = self.contentView.frame.origin
        let size = self.contentView.frame.size

        var handlerView:UIImageView?
        switch handler {
        case .close:
            handlerView = self.closeImageView
        case .rotate:
            handlerView = self.rotateImageView
        case .flip:
            handlerView = self.flipImageView
        }

        switch position {
        case .topLeft:
            handlerView?.center = origin
            handlerView?.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        case .topRight:
            handlerView?.center = CGPoint(x: origin.x + size.width, y: origin.y)
            handlerView?.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        case .bottomLeft:
            handlerView?.center = CGPoint(x: origin.x, y: origin.y + size.height)
            handlerView?.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        case .bottomRight:
            handlerView?.center = CGPoint(x: origin.x + size.width, y: origin.y + size.height)
            handlerView?.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        }

        handlerView?.tag = position.rawValue
    }

    func setHandlerSize(_ size:Int) {
        if size <= 0 {
            return
        }

        self.defaultInset = NSInteger(round(Float(size) / 2))
        self.defaultMinimumSize = 4 * self.defaultInset
        self.minimumSize = max(self.minimumSize, self.defaultMinimumSize)

        let originalCenter = self.center
        let originalTransform = self.transform
        var frame = self.contentView.frame
        frame = CGRect(x: 0, y: 0, width: frame.size.width + CGFloat(self.defaultInset) * 2, height: frame.size.height + CGFloat(self.defaultInset) * 2)

        self.contentView.removeFromSuperview()

        self.transform = CGAffineTransform.identity
        self.frame = frame

        self.contentView.center = CGRectGetCenter(self.bounds)
        self.addSubview(self.contentView)
        self.sendSubview(toBack: self.contentView)

        let handlerFrame = CGRect(x: 0, y: 0, width: self.defaultInset * 2, height: self.defaultInset * 2)
        self.closeImageView.frame = handlerFrame
        self.setPosition(PasterViewPosition(rawValue: self.closeImageView.tag)!, forHandler: .close)
        self.rotateImageView.frame = handlerFrame
        self.setPosition(PasterViewPosition(rawValue: self.rotateImageView.tag)!, forHandler: .rotate)
        self.flipImageView.frame = handlerFrame
        self.setPosition(PasterViewPosition(rawValue: self.flipImageView.tag)!, forHandler: .flip)

        self.center = originalCenter
        self.transform = originalTransform
    }

    var defaultInset:NSInteger
    private var defaultMinimumSize:NSInteger

    private var beginningPoint = CGPoint.zero
    private var beginningCenter = CGPoint.zero

    private var initialBounds = CGRect.zero
    private var initialDistance:CGFloat = 0
    private var deltaAngle:CGFloat = 0

    private lazy var moveGesture:UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleMoveGesture(_:)))
        pan.cancelsTouchesInView = false
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        
        return pan
    }()

    private lazy var rotateImageView:UIImageView = {
        let rotateImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.defaultInset * 2, height: self.defaultInset * 2))
        rotateImageView.contentMode = UIViewContentMode.scaleAspectFit
        rotateImageView.backgroundColor = UIColor.clear
        rotateImageView.isUserInteractionEnabled = true
        rotateImageView.addGestureRecognizer(self.rotateGesture)
        return rotateImageView
    }()
    private lazy var rotateGesture:UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleRotateGesture(_:)))
        pan.cancelsTouchesInView = false
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        return pan
    }()

    private lazy var closeImageView:UIImageView = {
        let closeImageview = UIImageView(frame: CGRect(x: 0, y: 0, width: self.defaultInset * 2, height: self.defaultInset * 2))
        closeImageview.contentMode = UIViewContentMode.scaleAspectFit
        closeImageview.backgroundColor = UIColor.clear
        closeImageview.isUserInteractionEnabled = true
        closeImageview.addGestureRecognizer(self.closeGesture)
        return closeImageview
    }()
    private lazy var closeGesture = {
        return UITapGestureRecognizer(target: self, action: #selector(handleCloseGesture(_:)))
    }()
    private lazy var flipImageView:UIImageView = {
        let flipImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.defaultInset * 2, height: self.defaultInset * 2))
        flipImageView.contentMode = UIViewContentMode.scaleAspectFit
        flipImageView.backgroundColor = UIColor.clear
        flipImageView.isUserInteractionEnabled = true
        flipImageView.addGestureRecognizer(self.flipGesture)
        return flipImageView
    }()

    private lazy var flipGesture : UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleFlipGesture(_:)))
        gesture.delegate = self
        return gesture
    }()

    private lazy var tapGesture : UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        gesture.delegate = self
        return gesture
    }()


    @objc func handleMoveGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        switch recognizer.state {
        case .began:
            self.beginningPoint = touchLocation
            self.beginningCenter = self.center
            if let delegate = self.delegate {
                delegate.PasterViewDidBeginMoving(self)
            }
        case .changed:
            self.center = CGPoint(x: self.beginningCenter.x + (touchLocation.x - self.beginningPoint.x), y: self.beginningCenter.y + (touchLocation.y - self.beginningPoint.y))
            if let delegate = self.delegate {
                delegate.PasterViewDidChangeMoving(self)
            }
        case .ended:
            self.center = CGPoint(x: self.beginningCenter.x + (touchLocation.x - self.beginningPoint.x), y: self.beginningCenter.y + (touchLocation.y - self.beginningPoint.y))
            if let delegate = self.delegate {
                delegate.PasterViewDidEndMoving(self)
            }
        default:
            break
        }
    }


    @objc func handleRotateGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        let center = self.center

        switch recognizer.state {
        case .began:
            self.deltaAngle = CGFloat(atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))) - CGAffineTransformGetAngle(self.transform)
            self.initialBounds = self.contentView.bounds
            self.initialDistance = CGPointGetDistance(point1: center, point2: touchLocation)
            if let delegate = self.delegate {
                delegate.PasterViewDidBeginRotating(self)
            }
        case .changed:
            let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
            let angleDiff = Float(self.deltaAngle) - angle
            self.transform = CGAffineTransform(rotationAngle: CGFloat(-angleDiff))

            var scale = CGPointGetDistance(point1: center, point2: touchLocation) / self.initialDistance
            let minimumScale = CGFloat(self.minimumSize) / min(self.initialBounds.size.width + CGFloat(defaultInset * 2), self.initialBounds.size.height +  CGFloat(defaultInset * 2))
            scale = max(scale, minimumScale)
            scale = min(scale, maxScale)
            self.pinchScale = scale
            let scaledBounds = CGRectScale(self.initialBounds, wScale: scale, hScale: scale)
            self.contentView.bounds = scaledBounds
            self.bounds = CGRect(x:self.bounds.origin.x , y: self.bounds.origin.y, width: self.contentView.bounds.size.width + CGFloat(self.defaultInset) * 2, height: self.contentView.bounds.size.height + CGFloat(self.defaultInset) * 2)
            self.setNeedsDisplay()

            if let delegate = self.delegate {
                delegate.PasterViewDidChangeRotating(self)
            }
        case .ended:
            if let delegate = self.delegate {
                delegate.PasterViewDidEndRotating(self)
            }
        default:
            break
        }
    }

    @objc func handleCloseGesture(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate {
            delegate.PasterViewDidClose(self)
            
        }
        
        self.removeFromSuperview()
    }

    @objc
    func handleFlipGesture(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3) {
            self.contentView.transform = self.contentView.transform.scaledBy(x: -1, y: 1)
        }
    }

    @objc
    func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate {
            delegate.PasterViewDidTap(self)
        }
    }

    private func setEnableClose(_ enableClose:Bool) {
        self.closeImageView.isHidden = !enableClose
        self.closeImageView.isUserInteractionEnabled = enableClose
    }

    private func setEnableRotate(_ enableRotate:Bool) {
        self.rotateImageView.isHidden = !enableRotate
        self.rotateImageView.isUserInteractionEnabled = enableRotate
    }

    private func setEnableFlip(_ enableFlip:Bool) {
        self.flipImageView.isHidden = !enableFlip
        self.flipImageView.isUserInteractionEnabled = enableFlip
    }

    // 缩放手势 - 手势部分
    @objc func pinchGestureDetected(_ recognizer:UIPinchGestureRecognizer) {

        switch recognizer.state {
        case .began:
            self.initialBounds = self.contentView.bounds
        case .changed:

            var scale = recognizer.scale
            let minimumScale = CGFloat(self.minimumSize) / min(self.initialBounds.size.width + CGFloat(defaultInset * 2), self.initialBounds.size.height +  CGFloat(defaultInset * 2))
            scale = max(scale, minimumScale)
            scale = min(scale, maxScale)
            //            let scaledTransform  = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
            //            var frame = initialBounds.applying(scaledTransform)
            self.pinchScale = scale
            let scaledBounds = CGRectScale(self.initialBounds, wScale: scale, hScale: scale)
            self.contentView.bounds = scaledBounds
            self.bounds = CGRect(x:self.bounds.origin.x , y: self.bounds.origin.y, width: self.contentView.bounds.size.width + CGFloat(self.defaultInset) * 2, height: self.contentView.bounds.size.height + CGFloat(self.defaultInset) * 2)
            self.setNeedsDisplay()

            if let delegate = self.delegate {
                delegate.PasterViewDidChangeRotating(self)
            }

        case .ended:
            if let delegate = self.delegate {
                delegate.PasterViewDidEndRotating(self)
            }
        default:
            break
        }

    }

    // 旋转
    @objc func rotationGestureDetected (_ recognizer:UIRotationGestureRecognizer) {

        let state = recognizer.state
        if (state == .began) || (state == .changed) {
            let effectView = self
            let rotation = recognizer.rotation
            effectView.transform = effectView.transform.rotated(by: rotation)
            recognizer.rotation = 0
        }
    }

}

extension PasterView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isMember(of: UIPanGestureRecognizer.self) {
                return true
        } else {
            return false
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }

}
