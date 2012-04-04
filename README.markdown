# atmos2-cocoa

This is the Cocoa client for Atmos2 platform.

This library is currently under development, and this README will include more information as it gets closer to something usable.

Meanwhile, take a look at [atmos2-js](http://documentup.com/vojto/atmos2/), the JavaScript implementation of Atmos2.

## Installation

Set up CocoaPods for your project.

Add the following line to your [Podfile](http://cocoapods.org/).

    dependency 'Atmos2', {:git => 'git@github.com:vojto/atmos2-cocoa.git', :branch => 'master'}

Run `pod install`.

## Set up synchronizer
    
    self.sync = [[ATSynchronizer alloc] initWithAppContext:self.managedObjectContext];
    [sync setBaseURL:@"http://localhost:6001"];

## Set up routing

Create a new property list file called `Routes.plist`. Insert equivalent of the following JSON:

    {Project: {index: "get /index"}}

Load the new file.

    [self.sync loadRoutesFromResource:@"Routes"];

## Fetching objects

To retrieve objects from the remote server, use the following method:

    [self.sync fetchEntity:@"Project"];