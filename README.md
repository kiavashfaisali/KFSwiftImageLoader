# KFSwiftImageLoader

KFSwiftImageLoader is an extremely high-performance, lightweight, and energy-efficient pure Swift async web image loader with memory and disk caching for iOS and  Watch.

This is the world's first  Watch-optimized async image loader with WKInterfaceImage extensions and intelligent automatic cache handling via WKInterfaceDevice.

Please also check out [KFWatchKitAnimations](https://github.com/kiavashfaisali/KFWatchKitAnimations) for a great way to record beautiful 60 FPS animations for  Watch by recording animations from the iOS Simulator.

Note:
-----
## Features
* WKInterfaceImage, UIImageView, UIButton, and MKAnnotationView extensions for asynchronous web image loading.
* Memory and disk cache to prevent downloading images every time a request is made or when the app relaunches, with automatic cache management to optimize resource use.
* Energy efficiency by sending only one HTTP/HTTPS request for image downloads from multiple sources that reference the same URL string, registering them as observers for the request.
* Maximum peformance by utilizing the latest and greatest of modern technologies such as Swift 5.1, URLSession, and GCD.

## KFSwiftImageLoader Requirements
* Xcode 11.0+
* iOS 12.0+
* watchOS 6.0+

## CocoaPods
To ensure you stay up-to-date with the latest version of KFSwiftImageLoader, it is recommended that you use CocoaPods.

Optimized for CocoaPods 1.8.4+, so you will need to run the following command first:
``` bash
sudo gem install cocoapods
```

Add the following to your Podfile
``` bash
platform :ios, '12.0'

pod 'KFSwiftImageLoader', '~> 4.0'
```

You will need to import KFSwiftImageLoader everywhere you wish to use it:
``` swift
import KFSwiftImageLoader
```

## Example Usage
### UIImageView
``` swift
imageView.loadImage(urlString: urlString)
```

Yes, it really is that easy. It just works.
In the above example, the inputs "placeholder" and "completion" were ignored, so they default to nil.
We can include them in the following way:
``` swift
imageView.loadImage(urlString: urlString, placeholder: UIImage(named: "KiavashFaisali")) {
    (success, error) in
    
    // 'success' is a 'Bool' indicating success or failure.
    // 'error' is an 'Error?' containing the error (if any) when 'success' is 'false'.
}
```

For flexibility, there are several different methods for loading images.
Below are the method signatures for all of them:
``` swift
func loadImage(_ urlString: String,
               placeholder: UIImage? = nil,
                completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)

func loadImage(_ url: URL,
         placeholder: UIImage? = nil,
          completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)

func loadImage(_ request: URLRequest,
             placeholder: UIImage? = nil,
              completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
```

### WKInterfaceImage
``` swift
func loadImage(_ urlString: urlString,
           placeholderName: String? = nil,
                completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
```

The main difference with the UIImageView extension is the parameter "placeholderName", which requires the placeholder image to be bundled with the  Watch app for performance reasons.

### UIButton
``` swift
button.loadImage(urlString)
```

Again, KFSwiftImageLoader makes it very easy to load images.
In this case, the button uses mostly the same method signature as UIImageView, but it includes two more optional parameters: "isBackground" and "controlState".

``` swift
func loadImage(_ urlString: String,
               placeholder: UIImage? = nil,
              controlState: UIControlState = .normal,
              isBackground: Bool = false,
                completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
```

"controlState" takes a UIControlState value that is required when setting images for buttons.
"isBackground" simply indicates whether or not the button should use "setBackgroundImage:for:" or "setImage:for:" for image loading.

### MKAnnotationView
``` swift
annotationView.loadImage(urlString)
```

The methods in the MKAnnotationView extension are exactly the same as those in the UIImageView extension.

### KFImageCacheManager
``` swift
// Disable the fade animation.
// The default value is 0.1.
KFImageCacheManager.shared.fadeAnimationDuration = 0.0

// Set a custom timeout interval for the image requests.
// The default value is 60.0.
KFImageCacheManager.shared.timeoutIntervalForRequest = 15.0

// Set a custom request cache policy for the image requests as well as the session's configuration.
// The default value is .returnCacheDataElseLoad.
KFImageCacheManager.shared.requestCachePolicy = .useProtocolCachePolicy

// Disable file system caching by adjusting the max age of the disk cache and the request cache policy.
// The default value is 60 * 60 * 24 * 7 = 604800 seconds (1 week).
KFImageCacheManager.shared.diskCacheMaxAge = 0
KFImageCacheManager.shared.requestCachePolicy = .reloadIgnoringLocalCacheData
```

## Sample App
Please take a look at the sample app under the Example folder for a clear idea of how to use KFSwiftImageLoader to load images in iOS and  Watch.

## Contact Information
Kiavash Faisali
- https://github.com/kiavashfaisali
- kiavashfaisali@outlook.com

## License
KFSwiftImageLoader is available under the MIT license.

Copyright (c) 2019 Kiavash Faisali

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
