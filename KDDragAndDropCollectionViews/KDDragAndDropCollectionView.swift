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
    
    var animatingTransition : Bool = false
    
    
    var draggingPathOfCellBeingDragged : NSIndexPath?
    
    var iDataSource : UICollectionViewDataSource?
    var iDelegate : UICollectionViewDelegate?

    // MARK : KDDraggable
    func canDragAtPoint(point : CGPoint) -> Bool {
        
        // only checking whether the index path exists (we are not touching in between cells)
        return (self.indexPathForItemAtPoint(point) != nil)
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
            
            if let dragDropDS : KDDragAndDropCollectionViewDataSource = self.dataSource? as? KDDragAndDropCollectionViewDataSource {
                
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
        
        self.draggingPathOfCellBeingDragged = nil
        
        if self.animatingTransition == false {
           self.reloadData()
        }
        
        
    }
    
    func dragDataItem(item : AnyObject) -> Void {
        
        if let dragDropDS = self.dataSource? as? KDDragAndDropCollectionViewDataSource {
            
            if let existngIndexPath = dragDropDS.collectionView(self, indexPathForDataItem: item) {
                
                dragDropDS.collectionView(self, deleteDataItemAtIndexPath: existngIndexPath)
                
                self.animatingTransition = true
                
                self.performBatchUpdates({ () -> Void in
                    self.deleteItemsAtIndexPaths([existngIndexPath])
                }, completion: { finished -> Void in
                    self.animatingTransition = false
                    self.reloadData()
                })
                
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
        
        for visible in self.visibleCells() as [UICollectionViewCell] {
            
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
    
    func willMoveItem(item : AnyObject, inRect rect : CGRect) -> Void {
        
        if let dragDropDS = self.dataSource? as? KDDragAndDropCollectionViewDataSource {
            
            if let existingIndexPath = dragDropDS.collectionView(self, indexPathForDataItem: item) {
                return
            }
            
            if let indexPath = self.indexPathForCellOverlappingRect(rect) {
               
                dragDropDS.collectionView(self, insertDataItem: item, atIndexPath: indexPath)
                
                self.animatingTransition = true
            
                self.draggingPathOfCellBeingDragged = indexPath
                
                self.performBatchUpdates({ () -> Void in
                    
               
                    self.insertItemsAtIndexPaths([indexPath])
                    

                    }, completion: { finished -> Void in
                        
                        self.animatingTransition = false
                        self.reloadData()
                
                })
                
                
                
            }
            
        }
        
    }
    func didMoveItem(item : AnyObject, inRect rect : CGRect) -> Void {
        
        if let dragDropDS = self.dataSource? as? KDDragAndDropCollectionViewDataSource {
            
            if let existingIndexPath = dragDropDS.collectionView(self, indexPathForDataItem: item) {
              
                if let indexPath = self.indexPathForCellOverlappingRect(rect) {
                    
                    if indexPath.item != existingIndexPath.item {
                        
                        dragDropDS.collectionView(self, moveDataItemFromIndexPath: existingIndexPath, toIndexPath: indexPath)
                        
                        self.moveItemAtIndexPath(existingIndexPath, toIndexPath: indexPath)
                        
                        self.draggingPathOfCellBeingDragged = indexPath
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    func didMoveOutItem(item : AnyObject) -> Void {
        
    }
    func dropDataItem(item : AnyObject, atRect : CGRect) -> Void {
        
        self.draggingPathOfCellBeingDragged = nil
        
        if self.animatingTransition == false {
            self.reloadData()
        }
        
    }
    
    
    
}
