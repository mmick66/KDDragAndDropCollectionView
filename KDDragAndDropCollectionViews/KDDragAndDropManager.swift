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
    optional func startDraggingAtPoint(point : CGPoint) -> Void
    optional func stopDragging() -> Void
}

@objc protocol KDDroppable {
    func canDropAtRect(rect : CGRect) -> Bool
    func willMoveItemInRect(item : AnyObject, rect : CGRect) -> Void
    func didMoveItemInRect (item : AnyObject, rect : CGRect) -> Void
    func didMoveItemOut(item : AnyObject) -> Void
    func dropDataItemAtRect(item : AnyObject, rect : CGRect) -> Void
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
        
        for view in self.views {
            
            if let draggable = view as? KDDraggable {
                
                
                let touchPointInView = touch.locationInView(view)
                
                if draggable.canDragAtPoint(touchPointInView) == false {
                    return false
                }
                
                if CGRectContainsPoint(view.frame, touchPointInView) {
                    
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
                            
                        } // if let dataItem : AnyObject = ...
                        
                        
                    } // if let representation = ...
                    
                    
                } // if CGRectContainsPoint ...
                
            }
            
        }
        
        return false
        
    }
    
    
    func updateForLongPress(recogniser : UILongPressGestureRecognizer) -> Void {
        
        if let bundl = self.bundle {
            
            let pointOnCanvas = recogniser.locationInView(recogniser.view)
            let sourceDraggable : KDDraggable = bundl.sourceDraggableView as KDDraggable
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
                
                for view in self.views {
                 
                    if let droppable = view as? KDDroppable {
                        
                        let collectionViewFrameOnCanvas = self.canvas.convertRect(view.frame, fromView: view)
                        
                        // Figure out which collection view is most of the image over
                        var intersectionNew = CGRectIntersection(bundl.representationImageView.frame, collectionViewFrameOnCanvas).size
                        
                        if (intersectionNew.width * intersectionNew.height) > overlappingArea {
                            
                            overlappingArea = intersectionNew.width * intersectionNew.width
                            
                            mainOverView = view
                        }
                        
                    }
                    
                }
                
                if let droppable = mainOverView? as? KDDroppable {
                    
                    if bundl.sourceDraggableView != mainOverView {
                        
                        droppable.willMoveItemInRect(bundl.dataItem, rect: bundl.representationImageView.frame)
                        
                    }
                    
                    self.bundle!.overDroppableView = mainOverView
                    
                    droppable.didMoveItemInRect(bundl.dataItem, rect: bundl.representationImageView.frame)
                    
                }
                
               
                
                
                
            case .Ended :
                bundl.representationImageView.removeFromSuperview()
                sourceDraggable.stopDragging?()
                
            default:
                break
                
            }
            
            
        } // if let bundl = self.bundle ...
        
        
        
    }
   
}
