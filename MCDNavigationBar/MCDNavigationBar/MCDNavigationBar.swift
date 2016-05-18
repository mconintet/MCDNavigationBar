//
//  MCDNavigationBar.swift
//  MCDNavigationBar
//
//  Created by mconintet on 5/11/16.
//  Copyright © 2016 mconintet. All rights reserved.
//

import UIKit

public enum PanDirection {
    case None
    case Up
    case Down
}

@inline(__always)
func fequal(a: Double, _ b: Double) -> Bool
{
    return a - b < DBL_EPSILON
}

@inline(__always)
func fequalzero(a: Double) -> Bool
{
    return a < DBL_EPSILON
}

@inline(__always)
func flessthan(a: Double, _ b: Double) -> Bool
{
    return a < b + DBL_EPSILON
}

public let defaultFollowScrollThreshDown: Double = 500

public let defaultMinHeight: CGFloat = 0

var captureHeightToken: dispatch_once_t = 0

public class MCDNavigationBar: UINavigationBar, UIGestureRecognizerDelegate {

    var panRecognizer: UIPanGestureRecognizer?

    public var scrollView: UIScrollView? {
        willSet {
            if let s = self.scrollView {
                s.removeGestureRecognizer(self.panRecognizer!)
                s.removeObserver(self, forKeyPath: "contentOffset")

                let newToken: dispatch_once_t = 0
                captureHeightToken = newToken
            }
        }
        didSet {
            guard let s = self.scrollView else {
                return
            }
            self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MCDNavigationBar.panMonitor))
            self.panRecognizer?.delegate = self
            s.addGestureRecognizer(self.panRecognizer!)
            s.addObserver(self, forKeyPath: "contentOffset", options: [.Old, .New], context: nil)
        }
    }

    public private(set) var panDirection: PanDirection = .None

    public var minHeight = defaultMinHeight
    public private(set) var initialHeight: CGFloat = 0
    public private(set) var initialOriginY: CGFloat = 0

    var needFollow = false

    public private(set) var initialScrollViewContentOffsetY: CGFloat = 0
    public private(set) var scrollViewHideNavOffsetY: CGFloat = 0

    public private(set) var deltaYRate: CGFloat = 0.3

    public var followScrollThreshDown = defaultFollowScrollThreshDown

    var previousPanTranslation: CGPoint = CGPointZero

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }

    func panMonitor(sender: UIPanGestureRecognizer) {
        let velocity = panRecognizer!.velocityInView(self.scrollView!)

        let hide = {
            var frame = self.frame
            frame.size.height = self.minHeight
            UIView.animateWithDuration(0.2, animations: {
                self.frame = frame
            })
        }
        let show = {
            var frame = self.frame
            frame.size.height = self.initialHeight
            UIView.animateWithDuration(0.2, animations: {
                self.frame = frame
            })
        }

        if sender.state == .Began {
            dispatch_once(&captureHeightToken, {
                self.initialHeight = self.frame.size.height
                self.initialOriginY = self.frame.origin.y
                self.initialScrollViewContentOffsetY = self.scrollView!.contentOffset.y

                self.scrollViewHideNavOffsetY = self.initialHeight / self.deltaYRate
            })
        } else if panRecognizer?.state == .Ended {
            let height = self.frame.size.height
            if panDirection == .Down && abs(velocity.y) > CGFloat(followScrollThreshDown) {
                show()
            } else if height < initialHeight * 0.8 {
                if scrollView!.contentOffset.y > 0 {
                    hide()
                } else {
                    show()
                }
            } else {
                show()
            }
        }
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?,
        context: UnsafeMutablePointer<Void>)
    {
        let velocity = panRecognizer!.velocityInView(self.scrollView!)
        panDirection = velocity.y > 0 ? .Down : .Up

        if panRecognizer?.state != .Changed {
            return
        }

        guard let old = change![NSKeyValueChangeOldKey] as? NSValue else {
            return
        }
        guard let new = change![NSKeyValueChangeNewKey] as? NSValue else {
            return
        }

        let oldValue = old.CGPointValue()
        let newValue = new.CGPointValue()

        let diff = 0.8 * abs(newValue.y - oldValue.y)

        var frame = self.frame
        frame.origin.y = initialOriginY

        if velocity.y > 0 {
            if panRecognizer?.state == .Ended && velocity.y > CGFloat(followScrollThreshDown) || newValue.y < 0 {
                frame.size.height += diff
            }
        } else {
            if flessthan(Double(newValue.y), 0) && flessthan(Double(newValue.y), Double(initialScrollViewContentOffsetY)) {
                return
            }
            frame.size.height -= diff
        }

        if frame.size.height > initialHeight {
            frame.size.height = initialHeight
        } else if frame.size.height < minHeight {
            frame.size.height = minHeight
        }

        self.frame = frame
    }
}
