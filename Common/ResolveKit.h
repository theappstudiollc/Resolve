//
//  ResolveKit.h
//  Resolve
//
//  Created by David Mitchell
//  Copyright © 2016 The App Studio LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//	   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@import Foundation;
@import CoreData;
@import CoreResolve_ObjC; // Needed for iOS 9 support
@import CloudKit;

#if TARGET_OS_IPHONE
@import UIKit;
#if TARGET_OS_WATCH
@import WatchKit;
#else
@import MultipeerConnectivity;
#endif
#elif TARGET_OS_MAC
@import Cocoa;
@import MultipeerConnectivity;
#endif

//! Project version number for ResolveKit.
FOUNDATION_EXPORT double ResolveKitVersionNumber;

//! Project version string for ResolveKit.
FOUNDATION_EXPORT const unsigned char ResolveKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ResolveKit/PublicHeader.h>
