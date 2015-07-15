# Developing for the iOS SDK

This short document provides an overview of the organization of the iOS SDK, and considerations to take into account when developing or distributing it.

## Overall Organization

This SDK is organized into the following subfolders:

* **bin/** - The output directory for the SDK distributable .zip file.
* **build/** - contains `ant` scripts for building a `.zip` of the SDK suitable for distribution to customers.  To build the zip, open a terminal, change to this directory, and run 'ant' from the command line.
* **DerivedData/** - The directory containing the intermediate build files (whether building in Xcode or using the ant script).
* **Doxygen/** - contains the `doxygen` script and assets (e.g., images and HTML templates) that can be used to build the reference docs that are included with the SDK distribution.
* **samples/** - applications that demonstrate usage of Splyt.  As of this writing, the only sample is `Bubble Pop!`.
* **Splyt.xcworkspace** - Workspace used for SDK development.  Note that there is no dependency between the Splyt and bubblepop projects.  Hence, the development process is:
  * Make changes to the SDK
  * Iteratively build the `Splyt` scheme to check that the framework builds successfully
  * When ready to test, switch to the `SplytUniversal` scheme and build it.  This will build a **universal** or **fat** framework which includes support for targeting both iOS devices as well as the simulator and copy the output to the appropriate directory in `Bubble Pop!`
  * Build `Bubble Pop!` and Run
* **src/** - contains the source code for the Splyt SDK.

## Notes on Xcode Development 

The **Splyt** project contains two targets: 

* **Splyt** - builds the `Splyt.framework`.
* **SplytUniversal** - runs a script that builds a **universal** or **fat** Splyt.framework from the command line and copies it into the appropriate Frameworks directory in the `bubblepop` project which depends on it

When performing internal development, open the workspace `Splyt.xcworkspace`.  Once open, select the `Splyt` scheme and use this scheme to build the `Splyt.framework` as necessary.  Once you're ready to test your changes, switch to the `SplytUniversal` scheme and build it, then switch to the `bubblepop` scheme and build and run the `Bubble Pop!` test app.

## Testing Changes to the iOS SDK

If you make changes to the iOS SDK, make sure you perform some testing to make sure our ability to distribute an SDK hasn't been affected:

1. Open a Terminal window and go to the *sdk-root*`/build` subfolder.  Run `ant` and make sure you're still able to build a `.zip` of the SDK successfully.
2. In the *sdk-root*/`bin` directory, unzip the SDK distribution created in the previous step.
3. Open *sdk-root*/`bin/splyt-ios-<hash>/samples/bubbblepop.xcodeproj` and make sure you can do a clean build and run it successfully.