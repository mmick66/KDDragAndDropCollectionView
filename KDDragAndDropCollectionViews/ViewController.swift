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
        
        let colorOne = UIColor(red: 53.0/255.0, green: 102.0/255.0, blue: 149.0/255.0, alpha: 1.0)
        let colorTwo = UIColor(red: 177.0/255.0, green: 88.0/255.0, blue: 39.0/255.0, alpha: 1.0)
        let colorFour = UIColor(red: 138.0/255.0, green: 149.0/255.0, blue: 86.0/255.0, alpha: 1.0)
        
        let colors : [UIColor] = [colorOne, colorTwo, colorFour]
        
        for i in 0...2 {
            
            var array = [AnyObject]()
            
            for j in 0...20 {
                
                let color = colors[i]
                
                array.append(color)
                
            }
            
            data.append(array)
        }
        
    }

    
    // MARK : UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[collectionView.tag].count
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as ColorCell
        
        if let color = data[collectionView.tag][indexPath.item] as? UIColor {
            
            cell.label.text = String(indexPath.item)
            cell.backgroundColor = color
        }
        
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

