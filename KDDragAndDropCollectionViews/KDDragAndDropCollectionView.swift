//
//  KDDragAndDropCollectionView.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

@objc protocol KDDragAndDropCollectionViewDataSource : UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, containsDataItem dataItem: AnyObject) -> Bool
    func collectionView(collectionView: UICollectionView, dataItemForIndexPath indexPath: NSIndexPath) -> AnyObject
    
    func collectionView(collectionView: UICollectionView, moveDataItemFromIndex fromIndexPath: NSIndexPath, toIndex toIndexPath : NSIndexPath) -> Void
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
        
        self.reloadData()
        
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
        
        if let dragDropDS : KDDragAndDropCollectionViewDataSource = self.dataSource? as? KDDragAndDropCollectionViewDataSource {
            
            if dragDropDS.collectionView(self, containsDataItem: item) {
                return
            }
            
            if let indexPath = self.indexPathForCellOverlappingRect(rect) {
               
                dragDropDS.collectionView(self, insertDataItem: item, atIndexPath: indexPath)
                
                self.insertItemsAtIndexPaths([indexPath])
                
            }
            
        }
        
    }
    func didMoveItem(item : AnyObject, inRect rect : CGRect) -> Void {
        
        if let dragDropDS : KDDragAndDropCollectionViewDataSource = self.dataSource? as? KDDragAndDropCollectionViewDataSource {
            
            if dragDropDS.collectionView(self, containsDataItem: item) {
              
                if let indexPath = self.indexPathForCellOverlappingRect(rect) {
                    
                    if let draggingIndexPath = self.draggingPathOfCellBeingDragged {
                        
                        if indexPath.item != draggingIndexPath.item {
                            
                            dragDropDS.collectionView(self, moveDataItemFromIndex: draggingIndexPath, toIndex: indexPath)
                            
                            self.moveItemAtIndexPath(draggingIndexPath, toIndexPath: indexPath)
                            
                            self.draggingPathOfCellBeingDragged = indexPath
                            
                        }
                    }
                    
                }
                
            }
            
        }
        
    }
    func didMoveOutItem(item : AnyObject) -> Void {
        
    }
    func dropDataItem(item : AnyObject, atRect : CGRect) -> Void {
        
    }
    
    
    
}
