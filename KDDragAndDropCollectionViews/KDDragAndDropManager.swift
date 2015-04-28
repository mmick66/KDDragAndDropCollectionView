//
//  KDDragAndDropManager.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

@objc protocol KDDraggable {
    func canDragAtPoint(point : CGPoint) -> Bool
    func representationImageAtPoint(point : CGPoint) -> UIView?
    func dataItemAtPoint(point : CGPoint) -> AnyObject?
    func dragDataItem(item : AnyObject) -> Void
    optional func startDraggingAtPoint(point : CGPoint) -> Void
    optional func stopDragging() -> Void
}


@objc protocol KDDroppable {
    func canDropAtRect(rect : CGRect) -> Bool
    func willMoveItem(item : AnyObject, inRect rect : CGRect) -> Void
    func didMoveItem(item : AnyObject, inRect rect : CGRect) -> Void
    func didMoveOutItem(item : AnyObject) -> Void
    func dropDataItem(item : AnyObject, atRect : CGRect) -> Void
}

class KDDragAndDropManager: NSObject, UIGestureRecognizerDelegate {
    
    private var canvas : UIView = UIView()
    private var views : [UIView] = []
    private var longPressGestureRecogniser = UILongPressGestureRecognizer()
    
    
    struct Bundle {
        var offset : CGPoint = CGPointZero
        var sourceDraggableView : UIView
        var overDroppableView : UIView?
        var representationImageView : UIView
        var dataItem : AnyObject
    }
    var bundle : Bundle?
    
    init(canvas : UIView, collectionViews : [UIView]) {
        
        super.init()
        
        self.canvas = canvas
        
        self.longPressGestureRecogniser.delegate = self
        self.longPressGestureRecogniser.minimumPressDuration = 0.3
        self.longPressGestureRecogniser.addTarget(self, action: "updateForLongPress:")
        
        self.canvas.addGestureRecognizer(self.longPressGestureRecogniser)
        self.views = collectionViews
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        for view in self.views.filter({ v -> Bool in v is KDDraggable})  {
            
                let draggable = view as! KDDraggable
                
                let touchPointInView = touch.locationInView(view)
                
                if draggable.canDragAtPoint(touchPointInView) == true {
                    
                    if let representation = draggable.representationImageAtPoint(touchPointInView) {
                        
                        representation.frame = self.canvas.convertRect(representation.frame, fromView: view)
                        
                        representation.alpha = 0.7
                        
                        let pointOnCanvas = touch.locationInView(self.canvas)
                        
                        let offset = CGPointMake(pointOnCanvas.x - representation.frame.origin.x, pointOnCanvas.y - representation.frame.origin.y)
                        
                        if let dataItem : AnyObject = draggable.dataItemAtPoint(touchPointInView) {
                            
                            self.bundle = Bundle(
                                offset: offset,
                                sourceDraggableView: view,
                                overDroppableView : view is KDDroppable ? view : nil,
                                representationImageView: representation,
                                dataItem : dataItem
                            )
                            
                            return true
                    
                        } // if let dataIte...
                        
                
                    } // if let representation = dragg...
                   
           
            } // if draggable.canDragAtP...
            
        } // for view in self.views.fil...
        
        return false
        
    }
    
    
    
    
    func updateForLongPress(recogniser : UILongPressGestureRecognizer) -> Void {
        
        if let bundl = self.bundle {
            
            let pointOnCanvas = recogniser.locationInView(recogniser.view)
            let sourceDraggable : KDDraggable = bundl.sourceDraggableView as! KDDraggable
            let pointOnSourceDraggable = recogniser.locationInView(bundl.sourceDraggableView)
            
            switch recogniser.state {
                
                
            case .Began :
                self.canvas.addSubview(bundl.representationImageView)
                sourceDraggable.startDraggingAtPoint?(pointOnSourceDraggable)
                
            case .Changed :
                
                // Update the frame of the representation image
                var repImgFrame = bundl.representationImageView.frame
                repImgFrame.origin = CGPointMake(pointOnCanvas.x - bundl.offset.x, pointOnCanvas.y - bundl.offset.y);
                bundl.representationImageView.frame = repImgFrame
                
                var overlappingArea : CGFloat = 0.0
                
                var mainOverView : UIView?
                
                for view in self.views.filter({ v -> Bool in v is KDDroppable}) {
                 
                    let viewFrameOnCanvas = self.convertRectToCanvas(view.frame, fromView: view)
                    
                    // Figure out which collection view is most of the image over
                    var intersectionNew = CGRectIntersection(bundl.representationImageView.frame, viewFrameOnCanvas).size
                    
                    
                    if (intersectionNew.width * intersectionNew.height) > overlappingArea {
                        
                        overlappingArea = intersectionNew.width * intersectionNew.width
                        
                        mainOverView = view
                    }

                    
                }
                
                
                if let droppable = mainOverView as? KDDroppable {
                    
                    let rect = self.canvas.convertRect(bundl.representationImageView.frame, toView: mainOverView)
                    
                    if bundl.sourceDraggableView != mainOverView {
                        
                        droppable.willMoveItem(bundl.dataItem, inRect: rect)
                        
                        
                    }
                    
                    self.bundle!.overDroppableView = mainOverView
                    
                    droppable.didMoveItem(bundl.dataItem, inRect: rect)
                    
                }
                
               
            case .Ended :
                
                if bundl.sourceDraggableView != bundl.overDroppableView {
                    
                    if let droppable = bundl.overDroppableView as? KDDroppable {
                        
                        sourceDraggable.dragDataItem(bundl.dataItem)
                        
                        let rect = self.canvas.convertRect(bundl.representationImageView.frame, toView: bundl.overDroppableView)
                        
                        droppable.dropDataItem(bundl.dataItem, atRect: rect)
                        
                    }
                }
                
                
                bundl.representationImageView.removeFromSuperview()
                sourceDraggable.stopDragging?()
                
            default:
                break
                
            }
            
            
        } // if let bundl = self.bundle ...
        
        
        
    }
    
    // MARK: Helper Methods 
    func convertRectToCanvas(rect : CGRect, fromView view : UIView) -> CGRect {
        
        var r : CGRect = rect
        
        var v = view
        
        while v != self.canvas {
            
            if let sv = v.superview {
                
                r.origin.x += sv.frame.origin.x
                r.origin.y += sv.frame.origin.y
                
                v = sv
                
                continue
            }
            break
        }
        
        return r
    }
   
}
