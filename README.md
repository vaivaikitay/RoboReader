[![Build Status](https://travis-ci.org/AFNetworking/AFNetworking.png?branch=master)](https://travis-ci.org/AFNetworking/AFNetworking)

With a couple of lines of code you can create a PDF view controller. This framework is very fast and easy to use.


![Mind Blown](https://raw.github.com/videlalvaro/gifsockets/master/doc/mybrain.gif)

Sample usage

Add RoboReader files to your project; import "RoboViewController.h"

Create a RoboDocument instance for the PDF file you want to display. NSString *path = [[NSBundle mainBundle] PathForResource:@"YourPdf" withExtension:@"pdf"]; RoboDocument *document = [[RoboDocument alloc] initWithFilePath:url password:@"YourPdfPassword_or_nil"]
Create a RoboViewController instance and present it as a child view controller. RoboViewController *r = [[RoboViewController alloc] initWithDocument:document];


## Credits

RoboReader was created by [Mikhail Viceman](https://github.com/vaivaikitay) in the development of  [Digital Edition platform (Copyright (c) REDMADROBOT)](http://digitaled.ru).


### Creators

[Mikhail Viceman](https://github.com/vaivaikitay)
[@vaivaikitay](https://twitter.com/vaivaikitay)



## License

RoboReader is available under the MIT license. See the LICENSE file for more info.
