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

public let defaultFollowScrollThreshDown: Double = 500

public let defaultMinHeight: CGFloat = 0

var captureHeightToken: dispatch_once_t = 0

public class MCDNavigationBar: UINavigationBar, UIGestureRecognizerDelegate {

    var panRecognizer: UIPanGestureRecognizer?

    public var scrollView: UIScrollView? {
        willSet {
            if let s = self.scrollView {
                s.removeGestureRecognizer(self.panRecognizer!)

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
        let translation = sender.translationInView(self.scrollView!)
        let velocity = sender.velocityInView(self.scrollView!)
        panRecognizer!.setTranslation(translation, inView: self.scrollView!)

        panDirection = velocity.y > 0 ? .Down : .Up

        if sender.state == .Began {
            dispatch_once(&captureHeightToken, {
                self.initialHeight = self.frame.size.height
                self.initialOriginY = self.frame.origin.y
                self.initialScrollViewContentOffsetY = self.scrollView!.contentOffset.y

                self.scrollViewHideNavOffsetY = self.initialHeight / self.deltaYRate
            })
        } else if sender.state == .Changed {
            if panDirection == .Up {
                needFollow = true
            } else {
                needFollow = scrollView!.contentOffset.y <= self.scrollViewHideNavOffsetY
            }

            var frame = self.frame

            let isMinHeight = frame.size.height == minHeight
            let isDirectionUp = panDirection == .Up
            let isScrollViewOverDown = scrollView!.contentOffset.y <= initialScrollViewContentOffsetY
            let isMaxHeight = frame.size.height == initialHeight
            let isDirectionDown = panDirection == .Down

            if !needFollow {
                previousPanTranslation = translation
                return
            }

            if isMinHeight && isDirectionUp || isScrollViewOverDown || isMaxHeight && isDirectionDown {
                return
            }

            let diff = translation.y - previousPanTranslation.y
            let delta = deltaYRate * abs(diff)

            if panDirection == .Up {
                frame.size.height -= delta
            } else {
                frame.size.height += delta
            }

            if frame.size.height > initialHeight {
                frame.size.height = initialHeight
            } else if frame.size.height < minHeight {
                frame.size.height = minHeight
            }

            frame.origin.y = initialOriginY
            self.frame = frame

            previousPanTranslation = translation
        } else if sender.state == .Ended {
            previousPanTranslation = CGPointZero
            needFollow = false

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

            let offsetY = scrollView!.contentOffset.y

            if panDirection == .Up {
                if offsetY < 0 && offsetY > initialScrollViewContentOffsetY {
                    show()
                } else {
                    hide()
                }
            } else if panDirection == .Down {
                if frame.size.height > initialHeight * 0.3 || abs(Double(velocity.y)) > followScrollThreshDown
                || offsetY < 0 && offsetY > initialScrollViewContentOffsetY {
                    show()
                } else {
                    hide()
                }
            }
        }
    }
}
