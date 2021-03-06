# Zucchini

[![Build Status](https://api.travis-ci.org/zucchini-src/zucchini.png)](http://travis-ci.org/zucchini-src/zucchini)
[![Coverage Status](https://coveralls.io/repos/zucchini-src/zucchini/badge.png)](https://coveralls.io/r/zucchini-src/zucchini)
[![Gem Version](https://badge.fury.io/rb/zucchini-ios.png)](http://badge.fury.io/rb/zucchini-ios)

## Requirements

 1. Mac OS X 10.6 or newer
 2. XCode 4.2 or newer
 3. Ruby 1.9.3 or newer
 4. A few command line tools which can be installed with [homebrew](http://brew.sh/):

```
brew update && brew install imagemagick node
npm install -g coffee-script
```

## Start using Zucchini

```
gem install zucchini-ios
```

Using Zucchini doesn't involve making any modifications to your application code.
You might as well keep your Zucchini tests in a separate project.

Start by creating a project scaffold:

```
zucchini generate --project /path/to/my_project
```

Create a feature scaffold for your first feature:

```
zucchini generate --feature /path/to/my_project/features/my_feature
```

Start hacking by modifying `features/my_feature/feature.zucchini` and `features/support/screens/welcome.coffee`.

Alternatively, check out the [zucchini-demo](https://github.com/zucchini-src/zucchini-demo) project featuring an easy to explore Zucchini setup around Apple's CoreDataBooks sample.

## Running on the device

Add your device to `features/support/config.yml`.

The [udidetect](https://github.com/vaskas/udidetect) utility comes in handy if you plan to add devices from time to time: `udidetect -z`.

```
ZUCCHINI_DEVICE="My Device" zucchini run /path/to/my_feature
```

## Running on the iOS Simulator

We encourage you to run your Zucchini features on real hardware. However you can also run them on the iOS Simulator.

First off, modify your `features/support/config.yml` to include the path to your compiled app, e.g.

```
app: ./Build/Products/Debug-iphonesimulator/CoreDataBooks.app
```

Secondly, add an `iOS Simulator` entry to the devices section (no UDID needed) and make sure you provide the actual value for 'screen' based on your iOS Simulator settings:

```
devices:
  iOS Simulator:
    screen: low_ios5
```

Alternatively, you can specify the app path in the device section:

```
devices:
  iOS Simulator:
    screen: low_ios5
    app: ./Build/Products/Debug-iphonesimulator/CoreDataBooks.app
  iPad2:
    screen: ipad_ios5
    app: ./Build/Products/Debug-iphoneos/CoreDataBooks.app
```

If you do not want to hard-code the app path in your config files, you can use the environment variable `ZUCCHINI_APP`:

```
ZUCCHINI_APP="/path/to/app" zucchini...
```

Run Zucchini and watch the simulator go!

```
ZUCCHINI_DEVICE="iOS Simulator" zucchini run /path/to/my_feature
```

## See also

```
zucchini --help
zucchini run --help
zucchini generate --help
```
