# Roux IOS

## Running Sample Project
### 1. Roux License
To run this example, you will need to generate a license through the [Roux Portal](http://roux.scandy.co). If you have not already, sign up as a developer to gain access to the developer dashboard. Create a new project and click the 'Download License' button.

Rename the license to `ScandyCoreLicense.txt` and move into `ScandyCoreLicense/`.

Open `RouxObjCHelloWorld.xcodeproj` in Xcode.

Select the `RouxObjCHelloWorld` target and add `ScandyCoreLicense.txt` to `Build Phases` -> `Copy Bundle Resources`.

### 2. Scandy Core Framework
If you haven't already, download the SDK (button can be found in the top navigation bar of the Roux Portal). Extract the `ScandyCore.zip` file and move `ScandyCore.framework` into  `RouxObjCHelloWorld/Frameworks/`.

Connect a device and build in Xcode.

## PLEASE NOTE - DO NOT BUILD FOR A SIMULATOR - SCANDY CORE IS ONLY PACKAGED TO BE RUN ON DEVICE

## Using Roux in your own project
To include Roux in your iOS project, there are a few extra steps you need to take.

### 1. Roux License
In your application read the contents of the `ScandyCoreLicense.txt` into a string. Use the pointer to the ScandyCore object to call `setLicense`, passing the license string as an argument. If the return from this call is `SUCCESS`, everything is good; otherwise, you will receive the status `INVALID_LICENSE`, and you will not be able to use ScandyCore's functionality until you provide a valid license.
#### Sample Code
```
  // Get license to use ScandyCore
  NSString *licensePath = [[NSBundle mainBundle] pathForResource:@"ScandyCoreLicense" ofType:@"txt"];
  NSString *licenseString = [NSString stringWithContentsOfFile:licensePath encoding:NSUTF8StringEncoding error:NULL];

  // convert license to cString
  const char* licenseCString = [licenseString cStringUsingEncoding:NSUTF8StringEncoding];

  // Get access to use ScandyCore
  ScandyCoreManager.scandyCorePtr->setLicense(licenseCString);
```
### 2. Scandy Core Framework
The example app already has the `ScandyCore.framework` in `Framework Search Paths` and `ScandyCore.framework/Headers` in `Header Search Paths`. In your own project, please add your path to `ScandyCore.framework` in `Framework Search Paths` and `ScandyCore.framework/Headers` in `Header Search Paths` in Xcode. 

### 3. Importing Scandy Core
All basic functionality can be acheived by just importing the main header from the framework and including the interface header for access into the `ScandyCore` object.

```
// MyViewController.h
// example file

#include <scandy/core/IScandyCore.h>

#import <ScandyCore/ScandyCore.h>
...
// your code
...
// must include "IScandyCore.h" to use scandyCorePtr
ScandyCoreManager.scandyCorePtr->isRunning();
...
```

## ScandyCoreManager
We provide a `ScandyCoreManager` which contains a pointer to `ScandyCore` and another to `ScandyCoreCameraDelegate`. The `ScandyCore` object allows you to setup scan configurations, start scanning, stop scanning, generate mesh, and save the mesh. `ScandyCoreCameraDelegate` is used to manage the iPhone X's TrueDepth camera. 

Both of these objects are created automatically when `ScandyCoreManager` tries to access either of them for the first time. The ideal way to initialize them is to set the ScandyCore license before doing anything else.

```
ScandyCoreManager.scandyCorePtr->setLicense(licenseCString);
```

## Order is important
Before we set up the scanner we must be sure we have access to the TrueDepth camera.

```
// Make sure we have permission, or atleast request it
[ScandyCoreManager.scandyCameraDelegate hasPermission];
```

`[ScandyCoreManager.scandyCameraDelegate hasPermission]` returns `false` if the user has denied camera permission. It returns `true` when the user has given permission or the permission dialog is being presented. We suggest you request camera permissions in a user friendly way that makes the user aware of what's going on.

Once we have camera permissions then we can initialize the scanner:

```
[ScandyCoreManager initializeScanner:scandy::core::ScannerType::TRUE_DEPTH];
```

After the scanner is initialized, we can either start the preview or configure the scanning parameters like scan size, scan offset, etc. The order of these two actions is not important except that they must happen after `initializeScanner`.

From there we are ready to start the scanning process.

```
[ScandyCoreManager startPreview];
/* Allow user to adjust scan size, noise, offset, whatever.... */
[ScandyCoreManager startScanning];
```

**NOTE: Scan configurations must be finalized before calling `startScanning` beacuse they cannot be changed during scanning.**  

## Visualization
### ScandyCoreView
It is ideal to simply use or subclass the GLKView `ScandyCoreView` with your own GLKViewController. The `ScandyCoreView` creates and manages the scanning view as well as the mesh view. It includes a `resizeView` function that automatically scales the viewports to fit the frame the view is contained within. `ScandyCoreView` is also configured to translate iOS touch interactions for interacting with a mesh.

```
// Connect our ScanView with this ViewController
ScandyCoreView *scan_view = (ScandyCoreView *)self.view;
scan_view.context = self.context;
scan_view.drawableDepthFormat = GLKViewDrawableDepthFormat16;

// Have ScandyCoreView create our visualizer
[scan_view createVisualizer];
```

### Custom Views
If you want to create your own view, checkout the [ScandyCoreSceneKitExample](https://github.com/Scandy-co/ScandyCoreSceneKitExample/blob/master/README.md#custom-views)
