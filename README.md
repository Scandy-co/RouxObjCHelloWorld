# Using ScandyCore.framework for iOS (iPhone X)
## ScandyCore License
Contact us to get a license to use ScandyCore. Then put the license string (without quotation marks) into file named ScandyCoreLicense.txt, and save it with UTF-8 encoding. In your project go to `Build Phases` -> `Copy Bundle Resources`, and add ScandyCoreLicense.txt to the list. 

In your application read the contents of the file into a string. Use the pointer to the ScandyCore object to call `setLicense`, passing the license string as an argument. If the return from this call is `SUCCESS`, everything is good; otherwise, you will receive the status `INVALID_LICENSE`, and you will not be able to use ScandyCore's functionality until you provide a valid license.

## Including ScandyCore in Your Project
It's as simple as adding your path to `ScandyCore.framework` in `Framework Search Paths` and `ScandyCore.framework/Headers` in `Header Search Paths` in Xcode. 

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
ScandyCoreManager.scandyCorePtr->startScanning();
...
```

## ScandyCoreManager
We provide a `ScandyCoreManager` which contains a pointer to `ScandyCore` and another to `ScandyCoreCameraDelegate`. The `ScandyCore` object allows you to setup scan configurations, start scanning, stop scanning, generate mesh, and save the mesh. `ScandyCoreCameraDelegate` is used to manage the iPhone X's TrueDepth camera. 

Both of these objects are created automatically when `ScandyCoreManager` tries to access either of them for the first time. The ideal way to initialize them is to set the ScandyCore license before doing anything else.

```
ScandyCoreManager.scandyCorePtr->setLicense(licenseCString);
```

## Order is important
Setting up the TrueDepth camera and ScandyCore must happen in a certain order. 

Before we set up the scanner we must be sure we have access to the TrueDepth camera.

```
// Tell ScandyCoreCameraDelegate we want TrueDepth
[ScandyCoreManager.scandyCameraDelegate setDeviceTypes:@[AVCaptureDeviceTypeBuiltInTrueDepthCamera]];

// Request for the camera to start
[ScandyCoreManager.scandyCameraDelegate startCamera:AVCaptureDevicePositionFront]
```

`startCamera` will ask the user to grant permission to the camera and return `AVCamSetupResultSuccess` if permission was indeed granted and `AVCamSetupResultCameraNotAuthorized` if denied. It is also possible to receive `AVCamSetupResultSessionConfigurationFailed` if the `AVCaptureDeviceInput` was not successfully created.

Once the TrueDepth camera is started the next step is to call:

```
ScandyCoreManager.scandyCorePtr->initializeScanner(scandy::core::ScannerType::TRUE_DEPTH);
```

After the scanner is initialized, we can either start the preview or configure the scanning parameters like scan size, scan offset, etc. The order of these actions is not important except that the must happen after `initializeScanner`.

From there we are ready to start the scanning process.

```
ScandyCoreManager.scandyCorePtr->startScanning();
```

**NOTE: Scan configurations must be finalized before calling this beacuse they cannot be changed during scanning.**  

## 

