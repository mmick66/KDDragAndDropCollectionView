## Drag and Drop Views 

Written is Swift 2.0, this is an implementation of Dragging and Dropping data across multiple UICollectionViews. 

![Drag and Drop Illustration](http://s27.postimg.org/geseg5j03/image.png "Drag and Drop")

Video Demo: [Here](https://d2p1e9awn3tn6.cloudfront.net/mJEJDs5J9X.mp4)

### Quick Guide

1. The only file that is really needed is *KDDragAndDropManager.swift*, so please add that to the project.
2. With this alone you will need to implement what happens to a UIView (or subclass) yourself, so also add *KDDragAndDropCollectionView.swift* that implements it on a UICollectionView. Remember that the project is open for adding drag and drop to all kinds of views but seperate implementations are needed. 
3. The only responsibility of the user code is to manage the data that the collection view cells are representing.  The data source of the collection views must implement 

```Swift
protocol KDDragAndDropCollectionViewDataSource : UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, indexPathForDataItem dataItem: AnyObject) -> NSIndexPath?
    func collectionView(collectionView: UICollectionView, dataItemForIndexPath indexPath: NSIndexPath) -> AnyObject
    
    func collectionView(collectionView: UICollectionView, moveDataItemFromIndexPath from: NSIndexPath, toIndexPath to : NSIndexPath) -> Void
    func collectionView(collectionView: UICollectionView, insertDataItem dataItem : AnyObject, atIndexPath indexPath: NSIndexPath) -> Void
    func collectionView(collectionView: UICollectionView, deleteDataItemAtIndexPath indexPath: NSIndexPath) -> Void
    
}
```

In the example we have 3 UICollectionViews distinguishable by their tags (bad practice, I know... but it's only an example ;-) and a data array holding 3 arrays respectively. In a case like this, an implementation of the above could be:

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
                
                let position = data[collectionView.tag].indexOf(item)! // ! if we are inside the condition we are guaranteed a position
                let indexPath = NSIndexPath(forItem: position, inSection: 0)
                return indexPath
            }
        }
    }
    return nil
}
```

### Make your Own 

If you want to dig deeper into the logic that was followed, a full tutorial on how it was built can be found at the [karmadust blog](http://karmadust.com/drag-and-drop-between-uicollectionviews/).

### License 

The MIT License (MIT)

Copyright (c) 2015 Karmadust Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
