//
//  ViewController.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

class DataItem : Equatable {
    
    var indexes : String = ""
    var colour : UIColor = UIColor.clearColor()
    init(indexes : String, colour : UIColor) {
        self.indexes = indexes
        self.colour = colour
    }
}

func ==(lhs: DataItem, rhs: DataItem) -> Bool {
    return lhs.indexes == rhs.indexes && lhs.colour == rhs.colour
}

class ViewController: UIViewController, KDDragAndDropCollectionViewDataSource {

    @IBOutlet weak var firstCollectionView: UICollectionView!
    @IBOutlet weak var secondCollectionView: UICollectionView!
    @IBOutlet weak var thirdCollectionView: UICollectionView!
    
    var data : [[DataItem]] = [[DataItem]]()
    
    var dragAndDropManager : KDDragAndDropManager?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let colours : [UIColor] = [
            UIColor(red: 53.0/255.0, green: 102.0/255.0, blue: 149.0/255.0, alpha: 1.0),
            UIColor(red: 177.0/255.0, green: 88.0/255.0, blue: 39.0/255.0, alpha: 1.0),
            UIColor(red: 138.0/255.0, green: 149.0/255.0, blue: 86.0/255.0, alpha: 1.0)
        ]
        
        for i in 0...2 {
            
            var items = [DataItem]()
            
            for j in 0...20 {
                
                
                let dataItem = DataItem(indexes: String(i) + ":" + String(j), colour: colours[i])
                
                items.append(dataItem)
                
            }
            
            data.append(items)
        }
        
        
        self.dragAndDropManager = KDDragAndDropManager(canvas: self.view, collectionViews: [firstCollectionView, secondCollectionView, thirdCollectionView])
        
    }

    
    // MARK : UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[collectionView.tag].count
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as ColorCell
        
        let dataItem = data[collectionView.tag][indexPath.item]
            
        cell.label.text = String(indexPath.item) + "\n\n" + dataItem.indexes
        cell.backgroundColor = dataItem.colour
        
        cell.hidden = false
        
        if let kdCollectionView = collectionView as? KDDragAndDropCollectionView {
            if let draggingPathOfCellBeingDragged = kdCollectionView.draggingPathOfCellBeingDragged {
                if draggingPathOfCellBeingDragged.item == indexPath.item {
                    cell.hidden = true
                }
            }
        }
        
        return cell
    }

    // MARK : KDDragAndDropCollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, dataItemForIndexPath indexPath: NSIndexPath) -> AnyObject {
        return data[collectionView.tag][indexPath.item]
    }
    func collectionView(collectionView: UICollectionView, insertDataItem dataItem : AnyObject, atIndexPath indexPath: NSIndexPath) -> Void {
        
        if let di = dataItem as? DataItem {
            data[collectionView.tag].insert(di, atIndex: indexPath.item)
        }
        
        
    }
    func collectionView(collectionView: UICollectionView, deleteDataItemAtIndexPath indexPath : NSIndexPath) -> Void {
        data[collectionView.tag].removeAtIndex(indexPath.item)
    }
    
    func collectionView(collectionView: UICollectionView, moveDataItemFromIndex fromIndexPath: NSIndexPath, toIndex toIndexPath : NSIndexPath) -> Void {
        
        let fromDataItem: DataItem = data[collectionView.tag][fromIndexPath.item]
        data[collectionView.tag].removeAtIndex(fromIndexPath.item)
        data[collectionView.tag].insert(fromDataItem, atIndex: toIndexPath.item)
        
    }
    
    func collectionView(collectionView: UICollectionView, containsDataItem dataItem: AnyObject) -> Bool {
        
        if let candidate = dataItem as? DataItem {
            for item in data[collectionView.tag] {
                if candidate  == item {
                    return true
                }
            }
        }
        
        return false
        
    }

}

