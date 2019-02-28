/*
 * KDDragAndDropCollectionView.swift
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

public protocol KDDragAndDropCollectionViewDataSource : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, indexPathForDataItem dataItem: AnyObject) -> IndexPath?
    func collectionView(_ collectionView: UICollectionView, dataItemForIndexPath indexPath: IndexPath) -> AnyObject
    
    func collectionView(_ collectionView: UICollectionView, moveDataItemFromIndexPath from: IndexPath, toIndexPath to : IndexPath) -> Void
    func collectionView(_ collectionView: UICollectionView, insertDataItem dataItem : AnyObject, atIndexPath indexPath: IndexPath) -> Void
    func collectionView(_ collectionView: UICollectionView, deleteDataItemAtIndexPath indexPath: IndexPath) -> Void
    
    /* optional */ func collectionView(_ collectionView: UICollectionView, cellIsDraggableAtIndexPath indexPath: IndexPath) -> Bool
    /* optional */ func collectionView(_ collectionView: UICollectionView, cellIsDroppableAtIndexPath indexPath: IndexPath) -> Bool
    
    /* optional */ func collectionView(_ collectionView: UICollectionView, stylingRepresentationView: UIView) -> UIView?
}

extension KDDragAndDropCollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, stylingRepresentationView: UIView) -> UIView? {
        return nil
    }
    func collectionView(_ collectionView: UICollectionView, cellIsDraggableAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, cellIsDroppableAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
}

open class KDDragAndDropCollectionView: UICollectionView, KDDraggable, KDDroppable {
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public var draggingPathOfCellBeingDragged : IndexPath?
    
    var iDataSource : UICollectionViewDataSource?
    var iDelegate : UICollectionViewDelegate?
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    
    // MARK : KDDraggable
    public func canDragAtPoint(_ point : CGPoint) -> Bool {
        if let dataSource = self.dataSource as? KDDragAndDropCollectionViewDataSource,
            let indexPathOfPoint = self.indexPathForItem(at: point) {
            return dataSource.collectionView(self, cellIsDraggableAtIndexPath: indexPathOfPoint)
        }
        
        return false
    }
    
    public func representationImageAtPoint(_ point : CGPoint) -> UIView? {
        
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
    
    public func stylingRepresentationView(_ view: UIView) -> UIView? {
        guard let dataSource = self.dataSource as? KDDragAndDropCollectionViewDataSource else {
            return nil
        }
        return dataSource.collectionView(self, stylingRepresentationView: view)
    }
    
    public func dataItemAtPoint(_ point : CGPoint) -> AnyObject? {
        
        guard let indexPath = self.indexPathForItem(at: point) else {
            return nil
        }
        
        guard let dragDropDS = self.dataSource as? KDDragAndDropCollectionViewDataSource else {
            return nil
        }
        
        return dragDropDS.collectionView(self, dataItemForIndexPath: indexPath)
    }
    
    
    
    public func startDraggingAtPoint(_ point : CGPoint) -> Void {
        
        self.draggingPathOfCellBeingDragged = self.indexPathForItem(at: point)
        
        self.reloadData()
        
    }
    
    public func stopDragging() -> Void {
        
        if let idx = self.draggingPathOfCellBeingDragged {
            if let cell = self.cellForItem(at: idx) {
                cell.isHidden = false
            }
        }
        
        self.draggingPathOfCellBeingDragged = nil
        
        self.reloadData()
        
    }
    
    public func dragDataItem(_ item : AnyObject) -> Void {
        
        guard let dragDropDataSource = self.dataSource as? KDDragAndDropCollectionViewDataSource else {
            return
        }
        
        guard let existngIndexPath = dragDropDataSource.collectionView(self, indexPathForDataItem: item) else {
            return
            
        }
        
        dragDropDataSource.collectionView(self, deleteDataItemAtIndexPath: existngIndexPath)
        
        if self.animating {
            self.deleteItems(at: [existngIndexPath])
        }
        else {
            
            self.animating = true
            self.performBatchUpdates({ () -> Void in
                self.deleteItems(at: [existngIndexPath])
            }, completion: { complete -> Void in
                self.animating = false
                self.reloadData()
            })
        }
        
    }
    
    // MARK : KDDroppable
    
    public func canDropAtRect(_ rect : CGRect) -> Bool {
        
        return (self.indexPathForCellOverlappingRect(rect) != nil)
    }
    
    public func indexPathForCellOverlappingRect( _ rect : CGRect) -> IndexPath? {
        
        var overlappingArea : CGFloat = 0.0
        var cellCandidate : UICollectionViewCell?
        let dataSource = self.dataSource as? KDDragAndDropCollectionViewDataSource
        
        
        let visibleCells = self.visibleCells
        if visibleCells.count == 0 {
            return IndexPath(row: 0, section: 0)
        }
        
        if  isHorizontal && rect.origin.x > self.contentSize.width ||
            !isHorizontal && rect.origin.y > self.contentSize.height {
            
            if dataSource?.collectionView(self, cellIsDroppableAtIndexPath: IndexPath(row: visibleCells.count - 1, section: 0)) == true {
                return IndexPath(row: visibleCells.count - 1, section: 0)
            }
            return nil
        }
        
        
        for visible in visibleCells {
            
            let intersection = visible.frame.intersection(rect)
            
            if (intersection.width * intersection.height) > overlappingArea {
                
                overlappingArea = intersection.width * intersection.height
                
                cellCandidate = visible
            }
            
        }
        
        if let cellRetrieved = cellCandidate, let indexPath = self.indexPath(for: cellRetrieved), dataSource?.collectionView(self, cellIsDroppableAtIndexPath: indexPath) == true {
            
            return self.indexPath(for: cellRetrieved)
        }
        
        return nil
    }
    
    
    fileprivate var currentInRect : CGRect?
    public func willMoveItem(_ item : AnyObject, inRect rect : CGRect) -> Void {
        
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
    
    public var isHorizontal : Bool {
        return (self.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection == .horizontal
    }
    
    public var animating: Bool = false
    
    public var paging : Bool = false
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
                rectForNextScroll.origin.y -= self.bounds.size.height * 0.5
                if rectForNextScroll.origin.y < 0 {
                    rectForNextScroll.origin.y = 0
                }
            }
            else if rect.intersects(bottomBoundary) == true {
                rectForNextScroll.origin.y += self.bounds.size.height * 0.5
                if rectForNextScroll.origin.y > self.contentSize.height - self.bounds.size.height {
                    rectForNextScroll.origin.y = self.contentSize.height - self.bounds.size.height
                }
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
    
    public func didMoveItem(_ item : AnyObject, inRect rect : CGRect) -> Void {
        
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
    
    public func didMoveOutItem(_ item : AnyObject) -> Void {
        
        guard let dragDropDataSource = self.dataSource as? KDDragAndDropCollectionViewDataSource,
            let existngIndexPath = dragDropDataSource.collectionView(self, indexPathForDataItem: item) else {
                
                return
        }
        
        dragDropDataSource.collectionView(self, deleteDataItemAtIndexPath: existngIndexPath)
        
        if self.animating {
            self.deleteItems(at: [existngIndexPath])
        }
        else {
            self.animating = true
            self.performBatchUpdates({ () -> Void in
                self.deleteItems(at: [existngIndexPath])
            }, completion: { (finished) -> Void in
                self.animating = false;
                self.reloadData()
            })
            
        }
        
        if let idx = self.draggingPathOfCellBeingDragged {
            if let cell = self.cellForItem(at: idx) {
                cell.isHidden = false
            }
        }
        
        self.draggingPathOfCellBeingDragged = nil
        
        currentInRect = nil
    }
    
    
    public func dropDataItem(_ item : AnyObject, atRect : CGRect) -> Void {
        
        // show hidden cell
        if  let index = draggingPathOfCellBeingDragged,
            let cell = self.cellForItem(at: index), cell.isHidden == true {
            
            cell.alpha = 1
            cell.isHidden = false
            
        }
        
        currentInRect = nil
        
        self.draggingPathOfCellBeingDragged = nil
        
        self.reloadData()
        
    }
    
    
}
