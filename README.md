## Drag and Drop Views 

This is an implementation of a dragging and dropping action across UICollectionViews. 

### Tutorial 

Full tutorial [can be found here](http://karmadust.com/drag-and-drop-between-uicollectionviews/).

### Quick Guide

The data source of the collection views must implement 

```Swift
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
func collectionView(collectionView: UICollectionView, moveDataItemFromIndexPath from: NSIndexPath, toIndexPath to : NSIndexPath) -> Void {
    
    let fromDataItem: DataItem = data[collectionView.tag][from.item]
    data[collectionView.tag].removeAtIndex(from.item)
    data[collectionView.tag].insert(fromDataItem, atIndex: to.item)
    
}
func collectionView(collectionView: UICollectionView, indexPathForDataItem dataItem: AnyObject) -> NSIndexPath? {
    
    if let candidate : DataItem = dataItem as? DataItem {
        
        for item : DataItem in data[collectionView.tag] {
            if candidate  == item {
                
                let position = find(data[collectionView.tag], item)! // ! if we are inside the condition we are guaranteed a position
                let indexPath = NSIndexPath(forItem: position, inSection: 0)
                return indexPath
            }
        }
    }
    return nil
}
```
