# Resolve #

A 2nd-generation Xcode project template with design patterns for developing apps on Apple-based platforms using Swift

Minimum os target versions are iOS 12, macOS 13, and tvOS 12, and watchOS 4

## Purpose ##

While Apple has provided some excellent new capabilities in the latest OS's, often you need to support an app across several OS versions, or even multiple platforms. This is where Resolve and CoreResolve come in to help. It provides a consistent experience regardless of the OS version or platform.

## Structure ##

### Emphasis is on as few modules as possible, and using platform-agnostic naming to avoid unnecessary code fragmentation

To that end, Target Memberships are the preferred mechanism to share code across platforms (iOS, macOS, tvOS, watchOS).

The main components are as follows:

* [CoreResolve](https://github.com/theappstudiollc/CoreResolve): Swift Package with app-agnostic core interfaces and classes
* Resolve: app code containing apps, frameworks, and extensions
	- Should be renamed to the App name (you may duplicate and rename if you wish to build a suite of apps)
	- 4 app targets + any extensions
	- 4 framework "ResolveKit" targets + 3 test targets

### Some naming conventions

Resolve's naming conventions match the conventions of CoreResolve:

* Service: A protocol declaring some service for use by an app and its extensions
* Manager: A concrete implementation of a Service
* Configuration: A common constructor parameter for Managers, which allows them to be app and platform agnostic as much as possible

## Customizing the Template for YOU ##

In the BuildSettings for the Resolve project is a User Defined setting called `RESOLVE_BUNDLE_PREFIX`. Change this to reflect the base bundle identifier that you need (e.g. `com.yourcompany`). The default prefix of `com.$(DEVELOPMENT_TEAM).template`, while useful for samples, is not needed.

You should also use Xcode to refactor the name Project name to the name of your app, which will cascade changes to the targets as well. Assistance with this effort is possible through Sponsorships.

### Settting up CloudKit for the CoreData synchronization sample ###

CloudKit running in developer mode will configure itself for nearly all of its requirements, with few exceptions. The following manual interventions will be needed:

1) Go to the CoreData screen and tap the + button to add a single `SharedEvent` record (to initialize the schema on the remote end)
2) Log onto the CloudKit Dashboard and visit the schema page of your app's Development container
3) Go to the `SharedEvent` schema in the CloudKit Dashboard and ensure the system field `createdAt` is queryable
4) Go to the `SharedEvent` schema in the CloudKit Dashboard and ensure the system field `createdBy` is queryable
5) Go to the CloudKit screen and tap the + button, search for and add yourself as a "friend"
6) Any other iCloud accounts who performed steps 1-5 can now be added as a friend, and your phone will be notified whenever they create new SharedEvents 

## FAQ ##

* Q: I'm creating a new file. Where should it go?
* A: Use the following guidelines:
	- If it can only be used by a specific app, even across platforms, it goes in the app-specific "Resolve" target (or whatever the name of the app is)
	- If it can be used by a specific app AND one or more of its extensions, it goes in the "ResolveKit" targets
	- As always, use Target Membership to provide access to multiple platforms 
