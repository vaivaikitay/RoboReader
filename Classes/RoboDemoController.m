//
// Copyright (c) 2013 RoboReader ( http://brainfaq.ru/roboreader )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RoboDemoController.h"

@implementation RoboDemoController
{
    RoboViewController *roboViewController;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    UILabel *tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 220.0f, 100.0f)];

    tapLabel.text = @"PRESS...";
    tapLabel.textColor = [UIColor whiteColor];
    tapLabel.textAlignment = NSTextAlignmentCenter;
    tapLabel.backgroundColor = [UIColor clearColor];
    tapLabel.font = [UIFont systemFontOfSize:48.0f];
    tapLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    tapLabel.autoresizingMask |= UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    tapLabel.center = self.view.center;
    [self.view addSubview:tapLabel];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleTap];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return YES;

}


- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {

    NSString *password = @"";
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"f5_newspaper" ofType:@"pdf"];

    assert(filePath != nil);

    RoboDocument *document = [RoboDocument withDocumentFilePath:filePath password:password];

    if (document != nil) {
        roboViewController = [[RoboViewController alloc] initWithRoboDocument:document];

        roboViewController.delegate = self;

        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

        [self.navigationController pushViewController:roboViewController animated:YES];


    }
}


- (void)dismissRoboViewController:(RoboViewController *)viewController {

    [self.navigationController popViewControllerAnimated:YES];

}

@end
