
[![Build Status](https://travis-ci.org/vaivaikitay/RoboReader.png?branch=master)](https://travis-ci.org/vaivaikitay/RoboReader)

With a couple of lines of code you can create a PDF view controller. This framework is very fast and easy to use.

## Sample usage

``` objective-c

// Add RoboReader files to your project; import "RoboViewController.h"

// Create a RoboDocument instance for the PDF file you want to display.

NSString *path = [[NSBundle mainBundle] PathForResource:@"YourPdf" withExtension:@"pdf"]; 

RoboDocument *document = [[RoboDocument alloc] initWithFilePath:url password:@"YourPdfPassword_or_nil"]


//Create a RoboViewController instance and present it as a child view controller.

RoboViewController *r = [[RoboViewController alloc] initWithDocument:document];

```

## Credits

RoboReader was created by [Mikhail Viceman](https://github.com/vaivaikitay) in the development of  [Digital Edition platform] (http://digitaled.ru) [Copyright (c) REDMADROBOT] (http://redmadrobot.ru).


## Creators

[Mikhail Viceman](https://github.com/vaivaikitay)
[@vaivaikitay](https://twitter.com/vaivaikitay)



## License

RoboReader is available under the MIT license. See the LICENSE file for more info.
