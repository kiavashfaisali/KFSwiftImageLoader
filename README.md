# KFSwiftImageLoader

KFSwiftImageLoader is an extremely high-performance, lightweight, and energy efficient pure Swift async web image loader with memory and disk caching for iOS and  Watch.

This is the world's first  Watch-optimized async image loader with WKInterfaceImage extensions and automatic cache handling via WKInterfaceDevice.

Please also check out [KFWatchKitAnimations](https://github.com/kiavashfaisali/KFWatchKitAnimations) for a great way to record beautiful 60 FPS animations for  Watch by recording animations from the iOS Simulator.

--= Short introduction video coming soon =--

## Features
* WKInterfaceImage, UIImageView, UIButton, and MKAnnotationView categories for asynchronous web image loading.
* Memory and disk cache to prevent dowloading images every time a request is made or when the app relaunches.
* Energy efficiency by sending only one HTTP request for image downloads and ensuring subsequent requests with the same URL are registered as observers for when the request is finished downloading to directly load the image.
* Maximum peformance by utilizing the latest and greatest of modern technologies such as Swift 1.2, NSURLSession, and GCD.

## KFSwiftImageLoader Requirements
* Xcode 6.3+
* iOS 8.2+

## CocoaPods
To ensure you stay up-to-date with the latest version of KFSwiftImageLoader, it is recommended that you use CocoaPods.

Since CocoaPods 0.36+ brings Swift support, you will need to run the following command first:
``` bash
sudo gem install cocoapods
```

Add the following to your Podfile
``` bash
platform :ios, '8.2'
pod 'KFSwiftImageLoader', '~> 1.0'
use_frameworks!
```

You will need to import KFSwiftImageLoader everywhere you wish to use it:
``` swift
import KFSwiftImageLoader
```

## Example Usage
### UIImageView
``` swift
imageView.loadImageFromURLString(urlString)
```

Yes, it really is that easy. It just works.
In the above example, the inputs "placeholderImage" and "completionHandler" were ignored, so they default to nil.
We can include them in the following way:
```swift
imageView.loadImageFromURLString(urlString, placeholderImage: UIImage(named: "KiavashFaisali")) {
    (finished, error) in
    
    // finished is a Bool indicating success or failure.
    // error is an implicitly unwrapped Optional NSError containing the error (if any) when finished is false.
}
```

For flexibility, there are several different methods for loading images.
Below are the method signatures for all of them:
``` swift
func loadImageFromURLString(string: String, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError!) -> Void)? = nil)

func loadImageFromURL(url: NSURL, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError!) -> Void)? = nil)

func loadImageFromRequest(request: NSURLRequest, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError!) -> Void)? = nil)
```

### UIButton
```swift
button.loadImageFromURLString(urlString)
```

Again, KFSwiftImageLoader makes it very easy to load images.
In this case, the button uses mostly the same method signature as UIImageView, but it includes two more optional parameters: "isBackgroundImage" and "forState".

"forState" takes a UIControlState value that is required when setting images for buttons.
"isBackgroundImage" simply indicates whether or not the button should use "setBackgroundImage:forState:" or "setImage:forState:" for image loading.

## Sample App
Please download the sample app "SwiftImageLoader" in this repository for a clear idea of how to use KFSwiftImageLoader to load images for iOS and  Watch.

## Contact Information
Kiavash Faisali
- https://github.com/kiavashfaisali
- kiavashfaisali@outlook.com

## License
KFSwiftImageLoader is available under the MIT license.

Copyright (c) 2015 Kiavash Faisali

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
