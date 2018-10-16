# Using ScandyCore.framework for iOS (iPhone X TrueDepth)
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
If you want to create your own view, you can create and manage the internal vtk visualizer yourself through the `ScandyCore` pointer. 

```
// Creating the visualizer with initial width and height.  
ScandyCoreManager.scandyCorePtr->createVisualizer(width, height);
```

Inside the `drawInRect` function of your GLKView you need to tell the internal visualizer to render.

```
ScandyCoreManager.scandyCorePtr->getVisualizer()->render();
```

**NOTE: Custom views are not fully supported in this release, so please use ScandyCoreView for best results.**
