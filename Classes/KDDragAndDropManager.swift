/*
 * KDDragAndDropManager.swift
 * Created by Michael Michailidis on 10/04/2015.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

public protocol KDDraggable {
    func canDragAtPoint(_ point : CGPoint) -> Bool
    func representationImageAtPoint(_ point : CGPoint) -> UIView?
    func stylingRepresentationView(_ view: UIView) -> UIView?
    func dataItemAtPoint(_ point : CGPoint) -> AnyObject?
    func dragDataItem(_ item : AnyObject) -> Void
    
    /* optional */ func startDraggingAtPoint(_ point : CGPoint) -> Void
    /* optional */ func stopDragging() -> Void
}

extension KDDraggable {
    public func startDraggingAtPoint(_ point : CGPoint) -> Void {}
    public func stopDragging() -> Void {}
}


public protocol KDDroppable {
    func canDropAtRect(_ rect : CGRect) -> Bool
    func willMoveItem(_ item : AnyObject, inRect rect : CGRect) -> Void
    func didMoveItem(_ item : AnyObject, inRect rect : CGRect) -> Void
    func didMoveOutItem(_ item : AnyObject) -> Void
    func dropDataItem(_ item : AnyObject, atRect : CGRect) -> Void
}

public class KDDragAndDropManager: NSObject, UIGestureRecognizerDelegate {
    
    fileprivate var canvas : UIView = UIView()
    fileprivate var views : [UIView] = []
    fileprivate var longPressGestureRecogniser = UILongPressGestureRecognizer()
    
    
    struct Bundle {
        var offset : CGPoint = CGPoint.zero
        var sourceDraggableView : UIView
        var overDroppableView : UIView?
        var representationImageView : UIView
        var dataItem : AnyObject
    }
    var bundle : Bundle?
    
    public init(canvas : UIView, collectionViews : [UIView]) {
        
        super.init()
        
        self.canvas = canvas
        
        self.longPressGestureRecogniser.delegate = self
        self.longPressGestureRecogniser.minimumPressDuration = 0.3
        self.longPressGestureRecogniser.addTarget(self, action: #selector(KDDragAndDropManager.updateForLongPress(_:)))
        self.canvas.isMultipleTouchEnabled = false
        self.canvas.addGestureRecognizer(self.longPressGestureRecogniser)
        self.views = collectionViews
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        guard gestureRecognizer.state == .possible else { return false }
        
        for view in self.views where view is KDDraggable  {
            
            let draggable = view as! KDDraggable
            
            let touchPointInView = touch.location(in: view)
            
            guard draggable.canDragAtPoint(touchPointInView) == true else { continue }
            
            guard var representation = draggable.representationImageAtPoint(touchPointInView) else { continue }
            
            representation.frame = self.canvas.convert(representation.frame, from: view)
            representation.alpha = 0.5
            if let decoredView = draggable.stylingRepresentationView(representation) {
                representation = decoredView
            }
            
            let pointOnCanvas = touch.location(in: self.canvas)
            
            let offset = CGPoint(x: pointOnCanvas.x - representation.frame.origin.x, y: pointOnCanvas.y - representation.frame.origin.y)
            
            if let dataItem: AnyObject = draggable.dataItemAtPoint(touchPointInView) {
                
                self.bundle = Bundle(
                    offset: offset,
                    sourceDraggableView: view,
                    overDroppableView : view is KDDroppable ? view : nil,
                    representationImageView: representation,
                    dataItem : dataItem
                )
                
                return true
                
            }
            
        }
        
        return false
        
    }
    
    @objc public func updateForLongPress(_ recogniser : UILongPressGestureRecognizer) -> Void {
        
        guard let bundle = self.bundle else { return }
        
        let pointOnCanvas = recogniser.location(in: recogniser.view)
        let sourceDraggable : KDDraggable = bundle.sourceDraggableView as! KDDraggable
        let pointOnSourceDraggable = recogniser.location(in: bundle.sourceDraggableView)
        
        switch recogniser.state {
            
            
        case .began :
            self.canvas.addSubview(bundle.representationImageView)
            sourceDraggable.startDraggingAtPoint(pointOnSourceDraggable)
            
        case .changed :
            
            // Update the frame of the representation image
            var repImgFrame = bundle.representationImageView.frame
            repImgFrame.origin = CGPoint(x: pointOnCanvas.x - bundle.offset.x, y: pointOnCanvas.y - bundle.offset.y);
            bundle.representationImageView.frame = repImgFrame
            
            var overlappingAreaMAX: CGFloat = 0.0
            
            var mainOverView: UIView?
            
            for view in self.views where view is KDDraggable  {
                
                let viewFrameOnCanvas = self.convertRectToCanvas(view.frame, fromView: view)
                
                
                /*                 ┌────────┐   ┌────────────┐
                 *                 │       ┌┼───│Intersection│
                 *                 │       ││   └────────────┘
                 *                 │   ▼───┘│
                 * ████████████████│████████│████████████████
                 * ████████████████└────────┘████████████████
                 * ██████████████████████████████████████████
                 */
                
                let overlappingAreaCurrent = bundle.representationImageView.frame.intersection(viewFrameOnCanvas).area
                
                if overlappingAreaCurrent > overlappingAreaMAX {
                    
                    overlappingAreaMAX = overlappingAreaCurrent
                    
                    mainOverView = view
                }
                
                
            }
            
            
            
            if let droppable = mainOverView as? KDDroppable {
                
                let rect = self.canvas.convert(bundle.representationImageView.frame, to: mainOverView)
                
                if droppable.canDropAtRect(rect) {
                    
                    if mainOverView != bundle.overDroppableView { // if it is the first time we are entering
                        
                        (bundle.overDroppableView as! KDDroppable).didMoveOutItem(bundle.dataItem)
                        droppable.willMoveItem(bundle.dataItem, inRect: rect)
                    }
                    
                    // set the view the dragged element is over
                    self.bundle!.overDroppableView = mainOverView
                    
                    droppable.didMoveItem(bundle.dataItem, inRect: rect)
                    
                }
            }
            
            
        case .ended :
            
            if bundle.sourceDraggableView != bundle.overDroppableView { // if we are actually dropping over a new view.
                
                if let droppable = bundle.overDroppableView as? KDDroppable {
                    
                    sourceDraggable.dragDataItem(bundle.dataItem)
                    
                    let rect = self.canvas.convert(bundle.representationImageView.frame, to: bundle.overDroppableView)
                    
                    droppable.dropDataItem(bundle.dataItem, atRect: rect)
                    
                }
            }
            
            bundle.representationImageView.removeFromSuperview()
            sourceDraggable.stopDragging()
            
        default:
            break
            
        }
        
    }
    
    // MARK: Helper Methods
    func convertRectToCanvas(_ rect : CGRect, fromView view : UIView) -> CGRect {
        
        var r = rect
        var v = view
        
        while v != self.canvas {
            
            guard let sv = v.superview else { break; }
            
            r.origin.x += sv.frame.origin.x
            r.origin.y += sv.frame.origin.y
            
            v = sv
        }
        
        return r
    }
    
}


extension CGRect: Comparable {
    
    public var area: CGFloat {
        return self.size.width * self.size.height
    }
    
    public static func <=(lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.area <= rhs.area
    }
    public static func <(lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.area < rhs.area
    }
    public static func >(lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.area > rhs.area
    }
    public static func >=(lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.area >= rhs.area
    }
}

