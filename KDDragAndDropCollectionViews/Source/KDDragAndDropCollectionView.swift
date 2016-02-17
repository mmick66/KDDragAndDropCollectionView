//
//  KDDragAndDropCollectionView.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

//MARK:- KDDragAndDropCollectionViewDataSource Protocol
@objc protocol KDDragAndDropCollectionViewDataSource: UICollectionViewDataSource {

  func collectionView(collectionView: UICollectionView,
    indexPathForDataItem dataItem: AnyObject) -> NSIndexPath?

  func collectionView(collectionView: UICollectionView,
    dataItemForIndexPath indexPath: NSIndexPath) -> AnyObject

  func collectionView(collectionView: UICollectionView,
    moveDataItemFromIndexPath from: NSIndexPath, toIndexPath: NSIndexPath)

  func collectionView(collectionView: UICollectionView,
    insertDataItem dataItem: AnyObject, atIndexPath indexPath: NSIndexPath)

  func collectionView(collectionView: UICollectionView,
    deleteDataItemAtIndexPath indexPath: NSIndexPath)

}

//MARK:- UICollectionView
class KDDragAndDropCollectionView: UICollectionView {
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  var draggingPathOfCellBeingDragged: NSIndexPath?

  var iDataSource: UICollectionViewDataSource?
  var iDelegate: UICollectionViewDelegate?

  //KDDragable - Nested properties
  private var currentInRect: CGRect?

  //KDDroppable - Nested properties
  var animating: Bool = false
  var paging: Bool = false

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
    super.init(frame: frame, collectionViewLayout: layout)
  }
}

//MARK:- KDDraggable
extension KDDragAndDropCollectionView: KDDraggable {
  func canDragAtPoint(point: CGPoint) -> Bool {
    guard let _ = dataSource as? KDDragAndDropCollectionViewDataSource else {
      return false
    }
    return indexPathForItemAtPoint(point) != nil
  }

  func representationImageAtPoint(point: CGPoint) -> UIView? {
    guard let indexPath = indexPathForItemAtPoint(point),
      cell = cellForItemAtIndexPath(indexPath) else {
        return nil
    }

    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, cell.opaque, 0)
    cell.layer.renderInContext(UIGraphicsGetCurrentContext()!)

    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    let imageView = UIImageView(image: img)
    imageView.frame = cell.frame

    return imageView
  }

  func dataItemAtPoint(point: CGPoint) -> AnyObject? {
    guard let indexPath = indexPathForItemAtPoint(point),
      dragDropDS = dataSource as? KDDragAndDropCollectionViewDataSource else {
        return nil
    }

    return dragDropDS.collectionView(self, dataItemForIndexPath: indexPath)
  }

  func startDraggingAtPoint(point: CGPoint) -> Void {
    draggingPathOfCellBeingDragged = indexPathForItemAtPoint(point)
    reloadData()
  }

  func stopDragging() -> Void {
    if let idx = draggingPathOfCellBeingDragged, cell = cellForItemAtIndexPath(idx) {
      cell.hidden = false
    }

    draggingPathOfCellBeingDragged = nil
    reloadData()
  }

  func dragDataItem(item: AnyObject) -> Void {
    guard let dragDropDataSource = dataSource as? KDDragAndDropCollectionViewDataSource,
      existngIndexPath = dragDropDataSource.collectionView(self, indexPathForDataItem: item) else {
        reloadData()
        return
    }

    dragDropDataSource.collectionView(self, deleteDataItemAtIndexPath: existngIndexPath)

    animating = true

    performBatchUpdates({ _ in
      self.deleteItemsAtIndexPaths([existngIndexPath])
      },
      completion: { complete in
        self.animating = false
        self.reloadData()
    })
  }
}

//MARK:- KDDroppable
extension KDDragAndDropCollectionView: KDDroppable {
  func canDropAtRect(rect: CGRect) -> Bool {
    return (indexPathForCellOverlappingRect(rect) != nil)
  }

  func indexPathForCellOverlappingRect( rect: CGRect) -> NSIndexPath? {
    var overlappingArea: CGFloat = 0.0
    var cellCandidate: UICollectionViewCell?

    let visibleCells = self.visibleCells()

    guard visibleCells.count > 0 else {
      return NSIndexPath(forRow: 0, inSection: 0)
    }

    guard !(isHorizontal && rect.origin.x > contentSize.width) ||
      !(!isHorizontal && rect.origin.y > contentSize.height) else {
        return NSIndexPath(forRow: visibleCells.count - 1, inSection: 0)
    }

    for visible in visibleCells {
      let intersection = CGRectIntersection(visible.frame, rect)

      if (intersection.width * intersection.height) > overlappingArea {
        overlappingArea = intersection.width * intersection.width
        cellCandidate = visible
      }
    }

    guard let cellRetrieved = cellCandidate else {
      return nil
    }

    return indexPathForCell(cellRetrieved)
  }


  func willMoveItem(item: AnyObject, inRect rect: CGRect) -> Void {
    guard let dragDropDataSource = dataSource as? KDDragAndDropCollectionViewDataSource else {
      return
    }

    if let _ = dragDropDataSource.collectionView(self, indexPathForDataItem: item) {
      // if data item exists
      return
    }

    guard let indexPath = self.indexPathForCellOverlappingRect(rect) else {
      return
    }

    dragDropDataSource.collectionView(self, insertDataItem: item, atIndexPath: indexPath)

    draggingPathOfCellBeingDragged = indexPath

    animating = true

    performBatchUpdates({ _ in
      self.insertItemsAtIndexPaths([indexPath])
      },
      completion: { complete in
        self.animating = false

        // if in the meantime we have let go
        if self.draggingPathOfCellBeingDragged == nil {

          self.reloadData()
        }
    })

    currentInRect = rect
  }

  var isHorizontal: Bool {
    return (collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection == .Horizontal
  }

  func checkForEdgesAndScroll(rect: CGRect) {
    guard !paging else {
      return
    }

    let currentRect: CGRect = CGRect(x: contentOffset.x, y: contentOffset.y,
      width: bounds.size.width, height: bounds.size.height)

    var rectForNextScroll: CGRect = currentRect

    if isHorizontal {
      rectForNextScroll = rectForNextScrollHorizontal(rect, current: currentRect)
    } else {
      rectForNextScroll = rectForNextScrollVertical(rect, current: currentRect)
    }

    checkChangInRectForNextScroll(rectForNextScroll, currentRect: currentRect)
  }

  private func rectForNextScrollHorizontal(original: CGRect, current: CGRect) -> CGRect {
    var rectForNextScroll = current
    let leftBoundary = CGRect(x: -30.0, y: 0.0, width: 30.0, height: frame.size.height)
    let rightBoundary = CGRect(x: frame.size.width, y: 0.0,
      width: 30.0, height: frame.size.height)

    if CGRectIntersectsRect(original, leftBoundary) {
      rectForNextScroll.origin.x -= bounds.size.width * 0.5
      if rectForNextScroll.origin.x < 0 {
        rectForNextScroll.origin.x = 0
      }
    } else if CGRectIntersectsRect(original, rightBoundary) {
      rectForNextScroll.origin.x += bounds.size.width * 0.5
      if rectForNextScroll.origin.x > contentSize.width - bounds.size.width {
        rectForNextScroll.origin.x = contentSize.width - bounds.size.width
      }
    }
    return rectForNextScroll
  }

  private func rectForNextScrollVertical(original: CGRect, current: CGRect) -> CGRect {
    var rectForNextScroll = current
    let topBoundary = CGRect(x: 0.0, y: -30.0, width: self.frame.size.width, height: 30.0)
    let bottomBoundary = CGRect(x: 0.0, y: self.frame.size.height,
      width: self.frame.size.width, height: 30.0)

    if CGRectIntersectsRect(original, topBoundary) == true {
      rectForNextScroll.origin.y -= bounds.size.height * 0.5
      if rectForNextScroll.origin.y < 0 {
        rectForNextScroll.origin.y = 0
      }
    } else if CGRectIntersectsRect(original, bottomBoundary) {
      rectForNextScroll.origin.y += bounds.size.height * 0.5
      if rectForNextScroll.origin.y > contentSize.height - bounds.size.height {
        rectForNextScroll.origin.y = contentSize.height - bounds.size.height
      }
    }
    return rectForNextScroll
  }

  private func checkChangInRectForNextScroll(rectForNextScroll: CGRect, currentRect: CGRect) {
    // check to see if a change in rectForNextScroll has been made
    if !CGRectEqualToRect(currentRect, rectForNextScroll) {
      paging = true
      scrollRectToVisible(rectForNextScroll, animated: true)
      let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
      dispatch_after(delayTime, dispatch_get_main_queue()) {
        self.paging = false
      }
    }

  }

  func didMoveItem(item: AnyObject, inRect rect: CGRect) {
    guard let dragDropDS = dataSource as? KDDragAndDropCollectionViewDataSource,
      existingIndexPath = dragDropDS.collectionView(self, indexPathForDataItem: item),
      indexPath = indexPathForCellOverlappingRect(rect) else {
        return
    }

    if indexPath.item != existingIndexPath.item {
      dragDropDS
        .collectionView(self, moveDataItemFromIndexPath: existingIndexPath, toIndexPath: indexPath)

      animating = true

      performBatchUpdates({ _ in
        self.moveItemAtIndexPath(existingIndexPath, toIndexPath: indexPath)
        },
        completion: { finished in
          self.animating = false
          self.reloadData()
      })
      draggingPathOfCellBeingDragged = indexPath
    }

    // Check Paging
    var normalizedRect = rect
    normalizedRect.origin.x -= contentOffset.x
    normalizedRect.origin.y -= contentOffset.y

    currentInRect = normalizedRect
    checkForEdgesAndScroll(normalizedRect)
  }

  func didMoveOutItem(item: AnyObject) {
    guard let dragDropDataSource = dataSource as? KDDragAndDropCollectionViewDataSource,
      existngIndexPath = dragDropDataSource.collectionView(self, indexPathForDataItem: item) else {
        return
    }

    dragDropDataSource.collectionView(self, deleteDataItemAtIndexPath: existngIndexPath)
    animating = true

    performBatchUpdates({ _ in
      self.deleteItemsAtIndexPaths([existngIndexPath])
      },
      completion: { finished in
        self.animating = false
        self.reloadData()
    })

    if let idx = draggingPathOfCellBeingDragged, cell = cellForItemAtIndexPath(idx) {
      cell.hidden = false
    }

    draggingPathOfCellBeingDragged = nil
    currentInRect = nil
  }

  func dropDataItem(item: AnyObject, atRect: CGRect) {
    // show hidden cell
    if let index = draggingPathOfCellBeingDragged, cell = cellForItemAtIndexPath(index)
      where cell.hidden {
        cell.alpha = 1.0
        cell.hidden = false
    }

    currentInRect = nil

    draggingPathOfCellBeingDragged = nil
    reloadData()
  }
}
