//
//  KDDragAndDropManager.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

//MARK:- KDDraggable Protocol
@objc protocol KDDraggable {
  func canDragAtPoint(point: CGPoint) -> Bool
  func representationImageAtPoint(point: CGPoint) -> UIView?
  func dataItemAtPoint(point: CGPoint) -> AnyObject?
  func dragDataItem(item: AnyObject)
  optional func startDraggingAtPoint(point: CGPoint)
  optional func stopDragging()
}

//MARK:- KDDroppable Protocol
@objc protocol KDDroppable {
  func canDropAtRect(rect: CGRect) -> Bool
  func willMoveItem(item: AnyObject, inRect rect: CGRect)
  func didMoveItem(item: AnyObject, inRect rect: CGRect)
  func didMoveOutItem(item: AnyObject)
  func dropDataItem(item: AnyObject, atRect: CGRect)
}

//MARK:- KDDragAndDropManagerBundle
struct KDDragAndDropManagerBundle {
  var offset: CGPoint = CGPointZero
  var sourceDraggableView: UIView
  var overDroppableView: UIView?
  var representationImageView: UIView
  var dataItem: AnyObject
}

//MARK:- UIGestureRecognizerDelegate
class KDDragAndDropManager: NSObject, UIGestureRecognizerDelegate {

  private var canvas: UIView = UIView()
  private var views: [UIView] = []
  private var longPressGestureRecogniser = UILongPressGestureRecognizer()

  var bundle: KDDragAndDropManagerBundle?

  init(canvas: UIView, collectionViews: [UIView]) {
    super.init()

    self.canvas = canvas

    longPressGestureRecogniser.delegate = self
    longPressGestureRecogniser.minimumPressDuration = 0.3
    longPressGestureRecogniser.addTarget(self, action: "updateForLongPress:")

    self.canvas.addGestureRecognizer(longPressGestureRecogniser)
    views = collectionViews
  }

  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
    shouldReceiveTouch touch: UITouch) -> Bool {
      for view in self.views.filter({ v -> Bool in v is KDDraggable}) {
        guard let draggable = view as? KDDraggable else {
          continue
        }

        let touchPointInView = touch.locationInView(view)

        if let representation = draggable.representationImageAtPoint(touchPointInView) where
          draggable.canDragAtPoint(touchPointInView) {
            representation.frame = self.canvas.convertRect(representation.frame, fromView: view)
            representation.alpha = 0.7

            let pointOnCanvas = touch.locationInView(self.canvas)
            let offset = CGPoint(x: pointOnCanvas.x - representation.frame.origin.x,
              y: pointOnCanvas.y - representation.frame.origin.y)

            guard let dataItem = draggable.dataItemAtPoint(touchPointInView) else {
              continue
            }

            self.bundle = KDDragAndDropManagerBundle(
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

  func updateForLongPress(recogniser: UILongPressGestureRecognizer) {
    guard let bundle = bundle, sourceDraggable = bundle.sourceDraggableView as? KDDraggable else {
      return
    }

    switch recogniser.state {
    case .Began :
      recognizerTouchBegan(recogniser, bundle: bundle, sourceDraggable: sourceDraggable)
    case .Changed :
      recognizerTouchChanged(recogniser, bundle: bundle)
    case .Ended :
      recognizerTouchEnded(recogniser, bundle: bundle, sourceDraggable: sourceDraggable)
    default:
      break
    }
  }
}

//MARK:- Helpers
extension KDDragAndDropManager {

  //MARK: Touch delegate private helpers
  private func recognizerTouchBegan(recogniser: UILongPressGestureRecognizer,
    bundle: KDDragAndDropManagerBundle, sourceDraggable: KDDraggable) {
      let pointOnSourceDraggable = recogniser.locationInView(bundle.sourceDraggableView)
      canvas.addSubview(bundle.representationImageView)
      sourceDraggable.startDraggingAtPoint?(pointOnSourceDraggable)
  }

  /* INTERSECTION VIEW
  *                 ┌────────┐   ┌────────────┐
  *                 │       ┌┼───│Intersection│
  *                 │       ││   └────────────┘
  *                 │   ▼───┘│
  * ████████████████│████████│████████████████
  * ████████████████└────────┘████████████████
  * ██████████████████████████████████████████
  */
  private func recognizerTouchChanged(recogniser: UILongPressGestureRecognizer,
    bundle: KDDragAndDropManagerBundle) {
      let pointOnCanvas = recogniser.locationInView(recogniser.view)
      // Update the frame of the representation image
      var repImgFrame = bundle.representationImageView.frame
      repImgFrame.origin =
        CGPoint(x: pointOnCanvas.x - bundle.offset.x, y: pointOnCanvas.y - bundle.offset.y)
      bundle.representationImageView.frame = repImgFrame

      var overlappingArea: CGFloat = 0.0
      var mainOverView: UIView?

      for view in self.views.filter({ v -> Bool in v is KDDroppable }) {
        let viewFrameOnCanvas = self.convertRectToCanvas(view.frame, fromView: view)

        let intersectionNew =
        CGRectIntersection(bundle.representationImageView.frame, viewFrameOnCanvas).size

        if (intersectionNew.width * intersectionNew.height) > overlappingArea {
          overlappingArea = intersectionNew.width * intersectionNew.width
          mainOverView = view
        }
      }

      guard let droppable = mainOverView as? KDDroppable else { return }

      let rect = self.canvas.convertRect(bundle.representationImageView.frame, toView: mainOverView)

      if droppable.canDropAtRect(rect) {
        if mainOverView != bundle.overDroppableView { // if it is the first time we are entering
          if let droppable = bundle.overDroppableView as? KDDroppable {
            droppable.didMoveOutItem(bundle.dataItem)
          }
          droppable.willMoveItem(bundle.dataItem, inRect: rect)
        }

        // set the view the dragged element is over
        self.bundle!.overDroppableView = mainOverView

        droppable.didMoveItem(bundle.dataItem, inRect: rect)
      }
  }

  private func recognizerTouchEnded(recogniser: UILongPressGestureRecognizer,
    bundle: KDDragAndDropManagerBundle, sourceDraggable: KDDraggable) {
      print("Touch ended viewTag: \(bundle.overDroppableView?.tag ?? -1)")

      if let droppable = bundle.overDroppableView as? KDDroppable where
        bundle.sourceDraggableView != bundle.overDroppableView {
          sourceDraggable.dragDataItem(bundle.dataItem)

          let rect = self.canvas.convertRect(bundle.representationImageView.frame,
            toView: bundle.overDroppableView)

          droppable.dropDataItem(bundle.dataItem, atRect: rect)
      }

      bundle.representationImageView.removeFromSuperview()
      sourceDraggable.stopDragging?()
  }

  // MARK: Generic Helper Methods
  func convertRectToCanvas(rect: CGRect, fromView view: UIView) -> CGRect {
    var tmpRect = rect
    var tmpView = view

    while tmpView != self.canvas {
      if let superView = tmpView.superview {
        tmpRect.origin.x += superView.frame.origin.x
        tmpRect.origin.y += superView.frame.origin.y
        tmpView = superView
        continue
      }
      break
    }

    return tmpRect
  }
}
