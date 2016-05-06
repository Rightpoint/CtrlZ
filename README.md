# CtrlZ

[![CI Status](http://img.shields.io/travis/Raizlabs/CtrlZ.svg?style=flat)](https://travis-ci.org/Raizlabs/CtrlZ)
[![Version](https://img.shields.io/cocoapods/v/CtrlZ.svg?style=flat)](http://cocoadocs.org/docsets/CtrlZ)
[![License](https://img.shields.io/cocoapods/l/CtrlZ.svg?style=flat)](http://cocoadocs.org/docsets/CtrlZ)
[![Platform](https://img.shields.io/cocoapods/p/CtrlZ.svg?style=flat)](http://cocoadocs.org/docsets/CtrlZ)

## Important Notice

This repository is slated for deletion.  Please find other solutions.  

## Usage

To run the example project, clone the repo, and open Example/Client/CtrlZ-Example.xcworkspace.

To play around with changing the strings you will need to change kCRZHostAddress in CRZAppDelegate to your IP address. (To find your IP address, enter `ipconfig getifaddr en0` in Terminal.) After that, simply navigate to Example/Server/ in Terminal and enter `python -m SimpleHTTPServer`. You can now modify the strings in `appStrings.json` and watch them update in the example app.

## Installation

CtrlZ is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "CtrlZ"

## Author

Spencer Poff, spencer@raizlabs.com

## License

CtrlZ is available under the MIT license. See the LICENSE file for more info.

