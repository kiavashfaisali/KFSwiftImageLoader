# KFSwiftImageLoader

KFSwiftImageLoader is an extremely high-performance, lightweight, and energy-efficient pure Swift async web image loader with memory and disk caching for iOS and  Watch.

This is the world's first  Watch-optimized async image loader with WKInterfaceImage extensions and intelligent automatic cache handling via WKInterfaceDevice.

Please also check out [KFWatchKitAnimations](https://github.com/kiavashfaisali/KFWatchKitAnimations) for a great way to record beautiful 60 FPS animations for  Watch by recording animations from the iOS Simulator.

## Features
* WKInterfaceImage, UIImageView, UIButton, and MKAnnotationView extensions for asynchronous web image loading.
* Memory and disk cache to prevent downloading images every time a request is made or when the app relaunches, with automatic cache management to optimize resource use.
* Energy efficiency by sending only one HTTP/HTTPS request for image downloads from multiple sources that reference the same URL string, registering them as observers for the request.
* Maximum peformance by utilizing the latest and greatest of modern technologies such as Swift 2.0, NSURLSession, and GCD.

## KFSwiftImageLoader Requirements
* Xcode 7.0+
* iOS 8.2+

## CocoaPods
To ensure you stay up-to-date with the latest version of KFSwiftImageLoader, it is recommended that you use CocoaPods.

Since CocoaPods 0.36+ brings Swift support, you will need to run the following command first:
``` bash
sudo gem install cocoapods
```

Add the following to your Podfile
``` bash
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.2'
use_frameworks!
pod 'KFSwiftImageLoader', '~> 2.0'
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
``` swift
imageView.loadImageFromURLString(urlString, placeholderImage: UIImage(named: "KiavashFaisali")) {
    (finished, error) in
    
    // finished is a Bool indicating success or failure.
    // error is an implicitly unwrapped Optional NSError containing the error (if any) when finished is false.
}
```

For flexibility, there are several different methods for loading images.
Below are the method signatures for all of them:
``` swift
func loadImageFromURLString(string: String, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError?) -> Void)? = nil)

func loadImageFromURL(url: NSURL, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError?) -> Void)? = nil)

func loadImageFromRequest(request: NSURLRequest, placeholderImage: UIImage? = nil, completion: ((finished: Bool, error: NSError?) -> Void)? = nil)
```

### WKInterfaceImage
``` swift
interfaceImage.loadImageFromURLString(urlString, placeholderImageName: "KiavashFaisali", shouldUseDeviceCache: true) {
    (finished, error) in
    
    // Completion handler called.
}
```

The main difference with the UIImageView extension is the parameter "shouldUseDeviceCache", which defaults to false if it is not explicitly set to true in the method.

"shouldUseDeviceCache" is a Bool indicating whether or not to use the  Watch's device cache for dramatically improved performance. This should only be considered for images that are likely to be loaded more than once throughout the lifetime of the app.

The magic here is that KFSwiftImageLoader will automatically and intelligently manage the  Watch's device cache. Should the image data be larger than the cache's size (5 MB), KFSwiftImageLoader will fallback to transmitting the data from the iPhone app's cache or downloading the image and transmitting the downloaded data, depending on what's available.

### UIButton
``` swift
button.loadImageFromURLString(urlString)
```

Again, KFSwiftImageLoader makes it very easy to load images.
In this case, the button uses mostly the same method signature as UIImageView, but it includes two more optional parameters: "isBackgroundImage" and "forState":

``` swift
func loadImageFromURLString(string: String, placeholderImage: UIImage? = nil, forState controlState: UIControlState = .Normal, isBackgroundImage: Bool = false, completion: ((finished: Bool, error: NSError?) -> Void)? = nil)
```

"forState" takes a UIControlState value that is required when setting images for buttons.
"isBackgroundImage" simply indicates whether or not the button should use "setBackgroundImage:forState:" or "setImage:forState:" for image loading.

### MKAnnotationView
``` swift
annotationView.loadImageFromURLString(string)
```

The methods in the MKAnnotationView extension are exactly the same as those in the UIImageView extension.

### KFImageCacheManager
``` swift
// Disable the fade animation.
// The default value is 0.1.
KFImageCacheManager.sharedInstance.fadeAnimationDuration = 0.0

// Set a custom timeout interval for the image requests.
// The default value is 60.0.
KFImageCacheManager.sharedInstance.timeoutIntervalForRequest = 15.0

// Set a custom request cache policy for the image requests as well as the session's configuration.
// The default value is .ReturnCacheDataElseLoad.
KFImageCacheManager.sharedInstance.requestCachePolicy = .UseProtocolCachePolicy

// Disable file system caching by adjusting the max age of the disk cache and the request cache policy.
// The default value is 60 * 60 * 24 * 7 = 604800 seconds (1 week).
KFImageCacheManager.sharedInstance.diskCacheMaxAge = 0
KFImageCacheManager.sharedInstance.requestCachePolicy = .ReloadIgnoringLocalCacheData
```

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
