# Drag and Drop Collection Views 

Written for Swift 4.0, it is an implementation of Dragging and Dropping data across multiple UICollectionViews. 

![Drag and Drop Illustration](https://github.com/mmick66/KDDragAndDropCollectionView/blob/master/Resources/header.png?raw=true "Drag and Drop")

Try it on [Appetize.io!](https://appetize.io/embed/exaf5fdj5auryhu174ta69t1gm?device=iphone5s&scale=75&orientation=portrait&osVersion=9.3)

[![Language](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)](https://swift.org)
[![Licence](https://img.shields.io/dub/l/vibe-d.svg?maxAge=2592000)](https://opensource.org/licenses/MIT)
[![CocoaPods](https://img.shields.io/cocoapods/v/KDCalendar.svg?style=flat)](https://cocoapods.org/pods/KDDragAndDropCollectionViews)
[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/vsouza/awesome-ios)

## Requirements

* iOS 8.0+
* XCode 9.0+
* Swift 4.0 +

## Installation

#### Cocoa Pods
```
pod 'KDDragAndDropCollectionViews', '~> 1.5.1'
```
#### Manual

Add the files in `Classes/` to your project.

## Quick Guide

Make the UICollectionView of interest a `KDDragAndDropCollectionView`

![XCode Interface Builder Screen](https://github.com/mmick66/KDDragAndDropCollectionView/blob/master/Resources/Screenshot.Installation.png?raw=true)

Then set a class as dataSource implementing the `KDDragAndDropCollectionViewDataSource` protocol.

```Swift
class ViewController: UIViewController, KDDragAndDropCollectionViewDataSource {

    @IBOutlet weak var firstCollectionView: KDDragAndDropCollectionView!
    @IBOutlet weak var secondCollectionView: KDDragAndDropCollectionView!
    @IBOutlet weak var thirdCollectionView: KDDragAndDropCollectionView!
    
    var data : [[DataItem]] = [[DataItem]]() // just for this example
    
    var dragAndDropManager : KDDragAndDropManager?
    
    override func viewDidLoad() {
        let all = [firstCollectionView, secondCollectionView, thirdCollectionView]
        self.dragAndDropManager = KDDragAndDropManager(canvas: self.view, collectionViews: all)
    }
}
```

The only responsibility of the user code is to manage the data that the collection view cells are representing. The data source of the collection views must implement the `KDDragAndDropCollectionViewDataSource` protocol.

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

func collectionView(_ collectionView: UICollectionView, indexPathForDataItem dataItem: AnyObject) -> IndexPath? {

    guard let candidate = dataItem as? DataItem else { return nil }
    
    for (i,item) in data[collectionView.tag].enumerated() {
        if candidate != item { continue }
        return IndexPath(item: i, section: 0)
    }
    return nil
}
```

## Advanced Use

#### Prevent specific Items from being Dragged and/or Dropped

For a finer tuning on what items are draggable and which ones are not we can implement the following function from the `KDDragAndDropCollectionViewDataSource` protocol

```Swift
func collectionView(_ collectionView: UICollectionView, cellIsDraggableAtIndexPath indexPath: IndexPath) -> Bool {
    return indexPath.row % 2 == 0
}
```


#### Data Items and Equatable

In the example code included in this project, I have created a `DataItem` class to represent the data displayed by the collection view.

```Swift
class DataItem : Equatable {
    var indexes: String
    var colour: UIColor
    init(indexes: String, colour: UIColor = UIColor.clear) {
        self.indexes    = indexes
        self.colour     = colour
    }
    static func ==(lhs: DataItem, rhs: DataItem) -> Bool {
        return lhs.indexes == rhs.indexes && lhs.colour == rhs.colour
    }
}
```

In the course of development you will be making your own types that must comform to the `Equatable` protocol as above. Each data item must be **uniquely idenfyiable** so be careful when creating cells that can have duplicate display values as for example a ["Scrabble"](https://en.wikipedia.org/wiki/Scrabble) type game where the same letter appears more than once. In cases like these, a simple identifier will do to implement the equality.
