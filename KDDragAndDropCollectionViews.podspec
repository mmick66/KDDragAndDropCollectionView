Pod::Spec.new do |s|

  s.name         = "KDDragAndDropCollectionViews"
  s.version      = "1.2"
  s.summary      = "Dragging & Dropping data across multiple UICollectionViews"

  s.homepage     = "https://github.com/mmick66/KDDragAndDropCollectionView"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = "Michael Michailidis"

  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/mmick66/KDDragAndDropCollectionView.git", :tag => s.version }

  s.source_files = "Classes/*.swift"

end