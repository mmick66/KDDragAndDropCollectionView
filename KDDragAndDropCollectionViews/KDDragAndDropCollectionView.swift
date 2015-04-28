//
//  KDDragAndDropCollectionView.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

@objc protocol KDDragAndDropCollectionViewDataSource : UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, indexPathForDataItem dataItem: AnyObject) -> NSIndexPath?
    func collectionView(collectionView: UICollectionView, dataItemForIndexPath indexPath: NSIndexPath) -> AnyObject
    
    func collectionView(collectionView: UICollectionView, moveDataItemFromIndexPath from: NSIndexPath, toIndexPath to : NSIndexPath) -> Void
    func collectionView(collectionView: UICollectionView, insertDataItem dataItem : AnyObject, atIndexPath indexPath: NSIndexPath) -> Void
    func collectionView(collectionView: UICollectionView, deleteDataItemAtIndexPath indexPath: NSIndexPath) -> Void
    
}

class KDDragAndDropCollectionView: UICollectionView, KDDraggable, KDDroppable {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var draggingPathOfCellBeingDragged : NSIndexPath?
    
    var iDataSource : UICollectionViewDataSource?
    var iDelegate : UICollectionViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.setup()
    }
    
    private let PagingAreaWidth : CGFloat = 30.0
    enum FrameEdge {
        case Top
        case Bottom
        case Left
        case Right
    }
    private var pagingAreas : [FrameEdge:CGRect] = [FrameEdge:CGRect]()
    func setup() -> Void {
        if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            if flowLayout.scrollDirection == .Horizontal {
                pagingAreas[.Left] = CGRect(x: -(PagingAreaWidth), y: 0.0, width: PagingAreaWidth, height: self.frame.size.height)
                pagingAreas[.Right] = CGRect(x: self.frame.size.width, y: 0.0, width: PagingAreaWidth, height: self.frame.size.height)
            }
            else {
                pagingAreas[.Top] = CGRect(x: 0.0, y: -(PagingAreaWidth), width: self.frame.size.width, height: PagingAreaWidth)
                pagingAreas[.Bottom] = CGRect(x: 0.0, y: self.frame.size.height, width: self.frame.size.width, height: PagingAreaWidth)
            }
        }
    }

    // MARK : KDDraggable
    func canDragAtPoint(point : CGPoint) -> Bool {
        
        return self.dataSource != nil && self.dataSource is KDDragAndDropCollectionViewDataSource && self.indexPathForItemAtPoint(point) != nil
    }
    
    func representationImageAtPoint(point : CGPoint) -> UIView? {
        
        var imageView : UIView?
        
        if let indexPath = self.indexPathForItemAtPoint(point) {
            
            let cell = self.cellForItemAtIndexPath(indexPath)!
            
            imageView = cell.snapshotViewAfterScreenUpdates(true)
            
            imageView?.frame = cell.frame
        }
        
        return imageView
    }
    
    func dataItemAtPoint(point : CGPoint) -> AnyObject? {
        
        var dataItem : AnyObject?
        
        if let indexPath = self.indexPathForItemAtPoint(point) {
            
            if let dragDropDS : KDDragAndDropCollectionViewDataSource = self.dataSource as? KDDragAndDropCollectionViewDataSource {
                
                dataItem = dragDropDS.collectionView(self, dataItemForIndexPath: indexPath)
                
            }
            
        }
        return dataItem
    }
    
    
    
    func startDraggingAtPoint(point : CGPoint) -> Void {
        
        self.draggingPathOfCellBeingDragged = self.indexPathForItemAtPoint(point)
        
        self.reloadData()
        
    }
    
    func stopDragging() -> Void {
        
        if let idx = self.draggingPathOfCellBeingDragged {
            if let cell = self.cellForItemAtIndexPath(idx) {
                cell.hidden = false
            }
        }
        
        self.draggingPathOfCellBeingDragged = nil
        
        self.reloadData()
        
    }
    
    func dragDataItem(item : AnyObject) -> Void {
        
        if let dragDropDS = self.dataSource as? KDDragAndDropCollectionViewDataSource {
            
            if let existngIndexPath = dragDropDS.collectionView(self, indexPathForDataItem: item) {
                
                dragDropDS.collectionView(self, deleteDataItemAtIndexPath: existngIndexPath)
                
                
                self.deleteItemsAtIndexPaths([existngIndexPath])
                
            }
            
        }
        
    }
    
    // MARK : KDDroppable

    func canDropAtRect(rect : CGRect) -> Bool {
        return true
    }
    
    func indexPathForCellOverlappingRect( rect : CGRect) -> NSIndexPath? {
        
        var overlappingArea : CGFloat = 0.0
        
        var cellCandidate : UICollectionViewCell?
        
        for visible in self.visibleCells() as! [UICollectionViewCell] {
            
            let intersection = CGRectIntersection(visible.frame, rect)
            
            if (intersection.width * intersection.height) > overlappingArea {
                
                overlappingArea = intersection.width * intersection.width
                
                cellCandidate = visible
            }
            
        }
        
        if let cellRetrieved = cellCandidate {
            
            return self.indexPathForCell(cellRetrieved)
        }
        
        return nil
    }
    
    
    private var currentInRect : CGRect?
    func willMoveItem(item : AnyObject, inRect rect : CGRect) -> Void {
        
        let dragDropDS = self.dataSource as! KDDragAndDropCollectionViewDataSource // guaranteed to have a ds
        
        if let existingIndexPath = dragDropDS.collectionView(self, indexPathForDataItem: item) {
            return
        }
        
        if let indexPath = self.indexPathForCellOverlappingRect(rect) {
            
            dragDropDS.collectionView(self, insertDataItem: item, atIndexPath: indexPath)
            
            self.draggingPathOfCellBeingDragged = indexPath
            
            self.insertItemsAtIndexPaths([indexPath])
            
        }
        
        currentInRect = rect
        
    }
    
    var paging : Bool = false
    func checkForEdgesAndScroll(rect : CGRect) -> Void {
        
        if paging == true {
            return
        }
        
        for (edge, edgeRect) in pagingAreas {
            
            if CGRectIntersectsRect(edgeRect, rect) {
                
                var nextBounds = self.bounds
                
                switch(edge) {
                    
                case .Top:
                    nextBounds.origin.y += nextBounds.size.width
                    if nextBounds.origin.y < 0.0 {
                        nextBounds.origin.y = 0.0
                    }
                    
                case .Bottom:
                    nextBounds.origin.y -= nextBounds.size.width
                    let maxY = self.contentSize.height - self.frame.size.height
                    if nextBounds.origin.y > maxY {
                        nextBounds.origin.y = maxY
                    }
                    
                case .Left:
                    nextBounds.origin.x -= nextBounds.size.width
                    if nextBounds.origin.x < 0.0 {
                        nextBounds.origin.x = 0.0
                    }
                    
                case .Right:
                    nextBounds.origin.x += nextBounds.size.width
                    let maxX = self.contentSize.width - self.frame.size.width
                    if nextBounds.origin.x > maxX {
                        nextBounds.origin.x = maxX
                    }
                }
                
                
                if CGRectEqualToRect(nextBounds, self.bounds) == false {
                    
                    paging = true
                    
                    println("nextBounds: \(edge) \(nextBounds)")
                    
                    
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
                    dispatch_after(delayTime, dispatch_get_main_queue(), {
                        
                        println("false")
                        self.paging = false
                        if let cir = self.currentInRect {
                            self.checkForEdgesAndScroll(cir)
                        }
                        
                    });
                    
                    
                    self.scrollRectToVisible(nextBounds, animated: true)
                    
                    
                    
                }  // if CGRectEqualToRect(nextBou
                
                return
                
            }
            
        }
        
    }
    
    func didMoveItem(item : AnyObject, inRect rect : CGRect) -> Void {
        
        let dragDropDS = self.dataSource as! KDDragAndDropCollectionViewDataSource // guaranteed to have a ds
        
        if let existingIndexPath = dragDropDS.collectionView(self, indexPathForDataItem: item),
               indexPath = self.indexPathForCellOverlappingRect(rect) {
   
                if indexPath.item != existingIndexPath.item {
                    
                    dragDropDS.collectionView(self, moveDataItemFromIndexPath: existingIndexPath, toIndexPath: indexPath)
                    
                    self.moveItemAtIndexPath(existingIndexPath, toIndexPath: indexPath)
                    
                    self.draggingPathOfCellBeingDragged = indexPath
                    
                }
        }
        
        // Check Paging
        
        currentInRect = rect
        
        // self.checkForEdgesAndScroll(rect)
    }
    
    func didMoveOutItem(item : AnyObject) -> Void {
        currentInRect = nil
    }
    func dropDataItem(item : AnyObject, atRect : CGRect) -> Void {
        
        
        
        
        self.draggingPathOfCellBeingDragged = nil
        
        currentInRect = nil
        
        self.reloadData()
        
    }
    
    
    
}
