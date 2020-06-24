# Roux IOS

## Tutorial Blog Posts
For more in-depth tutorials for downloading and setting up Roux in your projects, visit 

[Getting Started with Roux, Part 1: How to Set Up the Example iOS App](https://www.scandy.co/blog/getting-started-with-roux-part-one)

[Getting Started with Roux, Part 2: How to Build a Roux iOS Project from Scratch](https://www.notion.so/Getting-Started-with-Roux-Part-2-How-to-Build-a-Roux-iOS-Project-from-Scratch-e04de262ed704957adf53b2b2be4bf70)


## Running Sample Project
### 1. Roux License
To run this example, you will need to generate a license through the [Roux Portal](http://roux.scandy.co). If you have not already, sign up as a developer to gain access to the developer dashboard. Create a new project and click the 'Download License' button.

Rename the license to `ScandyCoreLicense.txt` and move into `RouxObjCHelloWorld/`.

Open `RouxObjCHelloWorld.xcodeproj` in Xcode.

Select the `RouxObjCHelloWorld` target and add `ScandyCoreLicense.txt` to `Build Phases` -> `Copy Bundle Resources`.

### 2. Scandy Core Framework
If you haven't already, download the SDK (button can be found in the top navigation bar of the Roux Portal). Extract the `ScandyCore.zip` file and move `ScandyCore.framework` into  `RouxObjCHelloWorld/Frameworks/`.

Connect a device and build in Xcode.

## PLEASE NOTE - DO NOT BUILD FOR A SIMULATOR - SCANDY CORE IS ONLY PACKAGED TO BE RUN ON DEVICE

## Using Roux in your own project
To include Roux in your iOS project, there are a few extra steps you need to take.

### 1. Roux License
Before you can use Roux, you must call `setLicense` to validate your license.

`setLicense` searches in your bundle resources for a file named ScandyCoreLicense.txt and then reads the contents to check its expiration and if the signature is valid.

```
// ViewController.mm
// example file

- (void)viewDidLoad { 
  [super viewDidLoad]; 
  [ScandyCore setLicense]; 
}

```
### 2. Scandy Core Framework
The example app already has the `ScandyCore.framework` in `Framework Search Paths` and `ScandyCore.framework/Headers` in `Header Search Paths`. In your own project, please add your path to `ScandyCore.framework` in `Framework Search Paths` and `ScandyCore.framework/Headers/include` in `Header Search Paths` in Xcode. 

You will also need to add `GLKit.framework` and `ScandyCore.framework` in `Frameworks, Libraries, and Embedded Content`.


### 3. Importing Scandy Core
All basic functionality can be achieved by just importing the main header from the framework and including the interface header for access into the `ScandyCore` object.

```
// ViewController.h
// example file

#import <ScandyCore/ScandyCore.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController

...
// your code
...

```

## Order is important
### User Permissions
You need to include information in the `Info.plist` explaining how your app will be using your users’ data. We suggest you request permissions in a user friendly way that makes the user aware of what's going on.

Before we set up the scanner we must be sure we have access to the `TrueDepth camera`. Since Roux can be used to create volumetric video, you also need to include the `NSMicrophoneUsageDescription` key.

Right-click `Info.plist` in the Project Navigator and select Open As -> Source Code. At the end, after the `</array>` tag and before the closing `</dict>` tag, insert the following:

```
// Info.plist
// example file

<key>NSCameraUsageDescription</key> 
<string>My app uses the TrueDepth camera to capture 3D scans</string> 

<key>NSMicrophoneUsageDescription</key> 
<string>My app uses the microphone to record volumetric video</string>
```
If you do not plan on using the microphone or volumetric video, change the <string> description to say "My app does not use the microphone".
 
Once we have camera permissions, we can initialize the scanner.

### Initializing Scanner

After the scanner is initialized, we can either start the preview or configure the scanning parameters like scan size, scan offset, etc. The order of these two actions is not important except that they must happen after initializeScanner.

From there we are ready to start the scanning process.


```
// ViewController.mm
// example file

- (void)turnOnScanner {
    //checks camera permissions
    if([ScandyCore hasCameraPermission]){ 
        //Turn on v2 scanning
        [ScandyCore toggleV2Scanning:true];
        // initializes scanner
        [ScandyCore initializeScanner]; 
        [ScandyCore startPreview];

	      // set voxel size
        double resolution = .001; // == 1.0mm
        [ScandyCore setVoxelSize:resolution];
    }
}

```
Then call the function right after you call `setLicense`
```
// ViewController.mm
// example file

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [ScandyCore setLicense];
    
    [self turnOnScanner];
}
```


## Visualization
### ScandyCoreView
It is ideal to simply use or subclass the GLKView `ScandyCoreView` with your own GLKViewController. The `ScandyCoreView` creates and manages the scanning view as well as the mesh view. It includes a `resizeView` function that automatically scales the viewports to fit the frame the view is contained within. `ScandyCoreView` is also configured to translate iOS touch interactions for interacting with a mesh.

Open `main.storyboard`, expand the View Controller Scene and View Controller, and select 'View'. In the right hand Inspector Area, open the Identity inspector and select ScandyCoreView from the dropdown list labeled 'Class'.

Change `ViewController.m` to `ViewController.mm`. Roux is written in C++ which can only be used in .mm files 

Delete `SceneDelegate.m` and `SceneDelegate.h`

Right-click `info.plist`, and select Open As -> Source Code. Remove the following lines:


```
<key>UIApplicationSceneManifest</key> 	
<dict> 		
  <key>UIApplicationSupportsMultipleScenes</key> 		
  <false/> 		
  <key>UISceneConfigurations</key> 		
  <dict> 			
    <key>UIWindowSceneSessionRoleApplication</key> 			
    <array> 				
      <dict> 					
        <key>UISceneConfigurationName</key> 					
        <string>Default Configuration</string> 					<key>UISceneDelegateClassName</key> 					
        <string>SceneDelegate</string> 					
        <key>UISceneStoryboardFile</key> 					
        <string>Main</string> 				
      </dict> 			
    </array> 		
  </dict> 	
</dict>

```
In `AppDelegate.h`, add `@property (strong, nonatomic) UIWindow *window;` after `@interface…`
 
In `AppDelegate.m`, remove the two functions after `#pragma mark - UISceneSession lifecycle`

### Custom Views
If you want to create your own view, checkout the [ScandyCoreSceneKitExample](https://github.com/Scandy-co/ScandyCoreSceneKitExample/blob/master/README.md#custom-views)
