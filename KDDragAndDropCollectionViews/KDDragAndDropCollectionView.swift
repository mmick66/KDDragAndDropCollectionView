//
//  KDDragAndDropCollectionView.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

@objc protocol KDDragAndDropCollectionViewDataSource : UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, dataItemForIndexPath indexPath: NSIndexPath) -> AnyObject
    func collectionView(collectionView: UICollectionView, insertDataItem dataItem : AnyObject, atIndexPath indexPath: NSIndexPath) -> Void
    func collectionView(collectionView: UICollectionView, deleteDataItemAtIndexPath indexPath: NSIndexPath) -> Void
    
}

class KDDragAndDropCollectionView: UICollectionView, KDDraggable, KDDroppable {

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
    
    
    // MARK : KDDroppable

    func canDropAtRect(rect : CGRect) -> Bool {
        return true
    }
    func willMoveItemInRect(item : AnyObject, rect : CGRect) -> Void {
        
    }
    func didMoveItemInRect (item : AnyObject, rect : CGRect) -> Void {
        
    }
    func didMoveItemOut(item : AnyObject) -> Void {
        
    }
    func dropDataItemAtRect(item : AnyObject, rect : CGRect) -> Void {
        
    }
    
}
