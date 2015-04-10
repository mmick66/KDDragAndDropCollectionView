//
//  ViewController.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

class ViewController: UIViewController, KDDragAndDropCollectionViewDataSource {

    
    var data : [[AnyObject]] = [[AnyObject]]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        data[0] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        data[1] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        data[2] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    }

    
    
    // MARK : UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[collectionView.tag].count
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
        return cell
    }

    // MARK : KDDragAndDropCollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, dataItemForIndexPath indexPath: NSIndexPath) -> AnyObject {
        return data[collectionView.tag][indexPath.item]
    }
    func collectionView(collectionView: UICollectionView, insertDataItem dataItem : AnyObject, atIndexPath indexPath: NSIndexPath) -> Void {
        
        data[collectionView.tag].insert(dataItem, atIndex: indexPath.item)
        
    }
    func collectionView(collectionView: UICollectionView, deleteDataItemAtIndexPath indexPath : NSIndexPath) -> Void {
        data[collectionView.tag].removeAtIndex(indexPath.item)
    }

}

