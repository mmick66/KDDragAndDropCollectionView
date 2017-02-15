//
//  KDDragAndDropCollectionView.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit



@objc protocol KDDragAndDropCollectionViewDataSource : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, indexPathForDataItem dataItem: AnyObject) -> IndexPath?
    func collectionView(_ collectionView: UICollectionView, dataItemForIndexPath indexPath: IndexPath) -> AnyObject
    
    func collectionView(_ collectionView: UICollectionView, moveDataItemFromIndexPath from: IndexPath, toIndexPath to : IndexPath) -> Void
    func collectionView(_ collectionView: UICollectionView, insertDataItem dataItem : AnyObject, atIndexPath indexPath: IndexPath) -> Void
    func collectionView(_ collectionView: UICollectionView, deleteDataItemAtIndexPath indexPath: IndexPath) -> Void
    
}

class KDDragAndDropCollectionView: UICollectionView, KDDraggable, KDDroppable {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var draggingPathOfCellBeingDragged : IndexPath?
    
    var iDataSource : UICollectionViewDataSource?
    var iDelegate : UICollectionViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    
    }
    

    // MARK : KDDraggable
    func canDragAtPoint(_ point : CGPoint) -> Bool {
        
        if self.dataSource is KDDragAndDropCollectionViewDataSource {
            return self.indexPathForItem(at: point) != nil
        }
        return false
        
    }
    
    func representationImageAtPoint(_ point : CGPoint) -> UIView? {
        
        guard let indexPath = self.indexPathForItem(at: point) else {
            return nil
        }
        
        guard let cell = self.cellForItem(at: indexPath) else {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, cell.isOpaque, 0)
        cell.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let imageView = UIImageView(image: image)
        imageView.frame = cell.frame
        
        return imageView
    }
    
    func dataItemAtPoint(_ point : CGPoint) -> AnyObject? {
        
        guard let indexPath = self.indexPathForItem(at: point) else {
            return nil
        }
        
        guard let dragDropDS = self.dataSource as? KDDragAndDropCollectionViewDataSource else {
            return nil
        }
        
        return dragDropDS.collectionView(self, dataItemForIndexPath: indexPath)
    }
    
    
    
    func startDraggingAtPoint(_ point : CGPoint) -> Void {
        
        self.draggingPathOfCellBeingDragged = self.indexPathForItem(at: point)
        
        self.reloadData()
        
    }
    
    func stopDragging() -> Void {
        
        if let idx = self.draggingPathOfCellBeingDragged {
            if let cell = self.cellForItem(at: idx) {
                cell.isHidden = false
            }
        }
        
        self.draggingPathOfCellBeingDragged = nil
        
        self.reloadData()
        
    }
    
    func dragDataItem(_ item : AnyObject) -> Void {
        
        guard let dragDropDataSource = self.dataSource as? KDDragAndDropCollectionViewDataSource else {
            return
        }
        
        guard let existngIndexPath = dragDropDataSource.collectionView(self, indexPathForDataItem: item) else {
            return
            
        }
        
        dragDropDataSource.collectionView(self, deleteDataItemAtIndexPath: existngIndexPath)
        
        self.animating = true
        
        self.performBatchUpdates({ () -> Void in
            
            self.deleteItems(at: [existngIndexPath])
            
        }, completion: { complete -> Void in
            
            self.animating = false
            
            self.reloadData()
            
        })
        
    }
    
    // MARK : KDDroppable

    func canDropAtRect(_ rect : CGRect) -> Bool {
        
        return (self.indexPathForCellOverlappingRect(rect) != nil)
    }
    
    func indexPathForCellOverlappingRect( _ rect : CGRect) -> IndexPath? {
        
        var overlappingArea : CGFloat = 0.0
        var cellCandidate : UICollectionViewCell?
        

        let visibleCells = self.visibleCells
        if visibleCells.count == 0 {
            return IndexPath(row: 0, section: 0)
        }
        
        if  isHorizontal && rect.origin.x > self.contentSize.width ||
            !isHorizontal && rect.origin.y > self.contentSize.height {
                
            return IndexPath(row: visibleCells.count - 1, section: 0)
        }
        
        
        for visible in visibleCells {
            
            let intersection = visible.frame.intersection(rect)
            
            if (intersection.width * intersection.height) > overlappingArea {
                
                overlappingArea = intersection.width * intersection.height
                
                cellCandidate = visible
            }
            
        }
        
        if let cellRetrieved = cellCandidate {
            
            return self.indexPath(for: cellRetrieved)
        }
        
        return nil
    }
    
    
    fileprivate var currentInRect : CGRect?
    func willMoveItem(_ item : AnyObject, inRect rect : CGRect) -> Void {
        
        let dragDropDataSource = self.dataSource as! KDDragAndDropCollectionViewDataSource // its guaranteed to have a data source
        
        if let _ = dragDropDataSource.collectionView(self, indexPathForDataItem: item) { // if data item exists
            return
        }
        
        if let indexPath = self.indexPathForCellOverlappingRect(rect) {
            
            dragDropDataSource.collectionView(self, insertDataItem: item, atIndexPath: indexPath)
            
            self.draggingPathOfCellBeingDragged = indexPath
            
            self.animating = true
            
            self.performBatchUpdates({ () -> Void in
                
                    self.insertItems(at: [indexPath])
                
                }, completion: { complete -> Void in
                    
                    self.animating = false
                    
                    // if in the meantime we have let go
                    if self.draggingPathOfCellBeingDragged == nil {
                      
                        self.reloadData()
                    }
                    
                    
                })
            
        }
        
        currentInRect = rect
        
    }
    
    var isHorizontal : Bool {
        return (self.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection == .horizontal
    }
    
    var animating: Bool = false
    
    var paging : Bool = false
    func checkForEdgesAndScroll(_ rect : CGRect) -> Void {
        
        if paging == true {
            return
        }
        
        let currentRect : CGRect = CGRect(x: self.contentOffset.x, y: self.contentOffset.y, width: self.bounds.size.width, height: self.bounds.size.height)
        var rectForNextScroll : CGRect = currentRect
        
        if isHorizontal {
            
            let leftBoundary = CGRect(x: -30.0, y: 0.0, width: 30.0, height: self.frame.size.height)
            let rightBoundary = CGRect(x: self.frame.size.width, y: 0.0, width: 30.0, height: self.frame.size.height)
            
            if rect.intersects(leftBoundary) == true {
                rectForNextScroll.origin.x -= self.bounds.size.width * 0.5
                if rectForNextScroll.origin.x < 0 {
                    rectForNextScroll.origin.x = 0
                }
            }
            else if rect.intersects(rightBoundary) == true {
                rectForNextScroll.origin.x += self.bounds.size.width * 0.5
                if rectForNextScroll.origin.x > self.contentSize.width - self.bounds.size.width {
                    rectForNextScroll.origin.x = self.contentSize.width - self.bounds.size.width
                }
            }
            
        } else { // is vertical
            
            let topBoundary = CGRect(x: 0.0, y: -30.0, width: self.frame.size.width, height: 30.0)
            let bottomBoundary = CGRect(x: 0.0, y: self.frame.size.height, width: self.frame.size.width, height: 30.0)
            
            if rect.intersects(topBoundary) == true {
                
            }
            else if rect.intersects(bottomBoundary) == true {
                
            }
        }
        
        // check to see if a change in rectForNextScroll has been made
        if currentRect.equalTo(rectForNextScroll) == false {
            self.paging = true
            self.scrollRectToVisible(rectForNextScroll, animated: true)
            
            let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.paging = false
            }
            
        }
        
    }
    
    func didMoveItem(_ item : AnyObject, inRect rect : CGRect) -> Void {
        
        let dragDropDS = self.dataSource as! KDDragAndDropCollectionViewDataSource // guaranteed to have a ds
        
        if  let existingIndexPath = dragDropDS.collectionView(self, indexPathForDataItem: item),
            let indexPath = self.indexPathForCellOverlappingRect(rect) {
   
                if indexPath.item != existingIndexPath.item {
                    
                    dragDropDS.collectionView(self, moveDataItemFromIndexPath: existingIndexPath, toIndexPath: indexPath)
                    
                    self.animating = true
                    
                    self.performBatchUpdates({ () -> Void in
                        
                            self.moveItem(at: existingIndexPath, to: indexPath)
                        
                        }, completion: { (finished) -> Void in
                            
                            self.animating = false
                            
                            self.reloadData()
                            
                        })
                    
                    self.draggingPathOfCellBeingDragged = indexPath
                    
                }
        }
        
        // Check Paging
        
        var normalizedRect = rect
        normalizedRect.origin.x -= self.contentOffset.x
        normalizedRect.origin.y -= self.contentOffset.y
        
        currentInRect = normalizedRect
        
        
        self.checkForEdgesAndScroll(normalizedRect)
        
        
    }
    
    func didMoveOutItem(_ item : AnyObject) -> Void {
        
        guard let dragDropDataSource = self.dataSource as? KDDragAndDropCollectionViewDataSource,
              let existngIndexPath = dragDropDataSource.collectionView(self, indexPathForDataItem: item) else {
            
            return
        }
        
        dragDropDataSource.collectionView(self, deleteDataItemAtIndexPath: existngIndexPath)
        
        self.animating = true
        
        self.performBatchUpdates({ () -> Void in
            
            self.deleteItems(at: [existngIndexPath])
            
            }, completion: { (finished) -> Void in
                
                self.animating = false;
                
                self.reloadData()
                
            })
        
        
        if let idx = self.draggingPathOfCellBeingDragged {
            if let cell = self.cellForItem(at: idx) {
                cell.isHidden = false
            }
        }
        
        self.draggingPathOfCellBeingDragged = nil
        
        currentInRect = nil
    }
    
    
    func dropDataItem(_ item : AnyObject, atRect : CGRect) -> Void {
        
        // show hidden cell
        if  let index = draggingPathOfCellBeingDragged,
            let cell = self.cellForItem(at: index), cell.isHidden == true {
            
            cell.alpha = 1.0
            cell.isHidden = false
            
            
            
        }
    
        currentInRect = nil
        
        self.draggingPathOfCellBeingDragged = nil
        
        self.reloadData()
        
    }
    
    
}
