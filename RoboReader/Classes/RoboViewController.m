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

#import "RoboViewController.h"
#import "RoboPDFModel.h"

@implementation RoboViewController


@synthesize delegate;

- (void)showDocument {


    [self updateScrollViewContentSize];

    startPageNumber = [document.currentPage intValue];
//    if (startPageNumber <= 1)
//        startPageNumber = 2;

//    [self showDocumentPage:1 fastScroll:NO];


//    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        [self.view setAlpha:0.0];
//    }                completion:^(BOOL finished) {
//        [self showDocumentPage:startPageNumber fastScroll:NO];
//        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//            [self.view setAlpha:1.0];
//        }                completion:nil];
//
//    }];

    [self showDocumentPage:startPageNumber fastScroll:NO];

    document.lastOpen = [NSDate date];

}

- (void)updateScrollViewContentSize {


    int count = [document.pageCount intValue];
    if (count == 0)
        count = 1;

    CGFloat contentHeight = theScrollView.bounds.size.height;

    CGFloat contentWidth;
    if (isLandscape)
        contentWidth = 1024.0f * (count / 2 + 1);
    else
        contentWidth = 768.0f * count;

    theScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);

}


- (void)pageContentLoadingComplete:(int)page pageBarImage:(UIImage *)pageBarImage rightSide:(BOOL)rightSide zoomed:(BOOL)zoomed {

    int fullPageNum = page;
    if (rightSide) {
        if (fullPageNum % 2)
            fullPageNum -= 1;
    }
    NSString *key;
    if (rightSide && fullPageNum == 0)
        key = @"1";
    else
        key = [NSString stringWithFormat:@"%i", fullPageNum];
    RoboContentView *contentView = contentViews[key];
    if (contentView) {
        [contentView pageContentLoadingComplete:pageBarImage rightSide:rightSide zoomed:zoomed];
    }
}

- (void)getZoomedPages:(int)pageNum isLands:(BOOL)isLands  zoomIn:(BOOL)zoomIn; {

    [pdfController getZoomedPageContent:pageNum isLands:isLands];
    if (isLands && pageNum != 1)
        [pdfController getZoomedPageContent:pageNum + 1 isLands:isLands];
}


- (void)showDocumentPage:(int)page fastScroll:(BOOL)fastScroll {

    if ((page < 1) || (page > [document.pageCount intValue]))
        return;

    int minValue;
    int maxValue;

    if (isLandscape) {

        if (page != 1 && page % 2)
            page -= 1;

        minValue = (page - 2);
        maxValue = (page + 2);


        if (page == 1) {

            minValue = 0;
            maxValue = 2;

        }
        if (page == 2) {

            minValue = 0;
            maxValue = 4;
        }

    }
    else {

        minValue = (page - 1);
        maxValue = (page + 1);

        if (page == 1) {

            minValue = 1;
            maxValue = 2;
        }

    }

    pdfController.currentPage = page;
    CGRect viewRect = CGRectZero;
    viewRect.size = theScrollView.bounds.size;
    if (isLandscape)
        viewRect.origin.x = viewRect.size.width * minValue / 2;
    else
        viewRect.origin.x = viewRect.size.width * (minValue - 1);

    // if rotated => kill all content
    // else - free memory of unnecessary content

    if (didRotate) {

        didRotate = NO;

        for (NSString *key in loadedPages) {
            RoboContentView *contentView = contentViews[key];
            [contentView removeFromSuperview];
            [contentViews removeObjectForKey:key];

        }
        [loadedPages removeAllObjects];
        [self updateScrollViewContentSize];

    }
    else {

        if (isLandscape) {
            for (NSString *key in [loadedPages allObjects]) {
                if ((page - [key intValue] > 2) || ([key intValue] - page > 3)) {
                    RoboContentView *contentView = contentViews[key];
                    [contentView removeFromSuperview];
                    [contentViews removeObjectForKey:key];
                    [loadedPages removeObject:key];

                }
            }
        }
        else {
            for (NSString *key in [loadedPages allObjects]) {
                if (abs([key intValue] - page) > 1) {
                    RoboContentView *contentView = contentViews[key];
                    [contentView removeFromSuperview];
                    [contentViews removeObjectForKey:key];
                    [loadedPages removeObject:key];

                }
            }
        }

    }

    for (int number = minValue; number <= maxValue; number++) {

        NSString *key;
        if (isLandscape && number == 0)
            key = @"1";
        else
            key = [NSString stringWithFormat:@"%i", number];

        RoboContentView *contentView = contentViews[key];
        if (!contentView) {

            contentView = [[RoboContentView alloc] initWithFrame:viewRect page:number orientation:isLandscape];

            contentView.delegate = self;

            [theScrollView addSubview:contentView];
            contentViews[key] = contentView;

            [loadedPages addObject:key];
        }

        viewRect.origin.x += viewRect.size.width;
        if (isLandscape)
            number++;

    }

    [pdfController getPagesContentFromPage:minValue toPage:maxValue isLands:isLandscape];

    if (!fastScroll) {
        if (isLandscape)
            theScrollView.contentOffset = CGPointMake(viewRect.size.width * (page / 2), 0);
        else
            theScrollView.contentOffset = CGPointMake(viewRect.size.width * (page - 1), 0);
    }


    if ([document.currentPage intValue] != page) {
        document.currentPage = @(page);
    }

}


- (id)initWithRoboDocument:(RoboDocument *)object small_document:(RoboDocument *)small_object {


    id robo = nil; // RoboViewController object

    if ((object != nil) && ([object isKindOfClass:[RoboDocument class]])) {
        if ((self = [super initWithNibName:nil bundle:nil])) // Designated initializer
        {
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

            [notificationCenter addObserver:self selector:@selector(applicationWill:) name:UIApplicationWillTerminateNotification object:nil];

            [notificationCenter addObserver:self selector:@selector(applicationWill:) name:UIApplicationWillResignActiveNotification object:nil];

            [object updateProperties];

            document = object;

            small_document = small_object;

            robo = self;
        }
    }

    return robo;
}


- (void)hideBars {
    if (!barsHiddenFlag) {
        [UIView animateWithDuration:0.1 delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^(void) {
                             [[UIApplication sharedApplication] setStatusBarHidden:YES];
                         }
                         completion:nil
        ];
        [mainToolbar hideToolbar];
        [mainPagebar hidePagebar];
        barsHiddenFlag = YES;
    }

}

- (void)showBars {
    if (barsHiddenFlag) {
        [UIView animateWithDuration:0.1 delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^(void) {
                             [[UIApplication sharedApplication] setStatusBarHidden:NO];
                         }
                         completion:nil
        ];
        [mainToolbar showToolbar];
        [mainPagebar showPagebar];
        barsHiddenFlag = NO;
    }
}

- (void)nextPage:(id)sender {

    [self hideBars];
    CGPoint newContOffset = theScrollView.contentOffset;
    if (isLandscape) {
        newContOffset.x += 1024.0f;
    }
    else {
        newContOffset.x += 768.0f;
    }
    if (newContOffset.x < theScrollView.contentSize.width) {
        [UIView animateWithDuration:0.5f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [theScrollView setContentOffset:newContOffset];
        }                completion:^(BOOL finished) {
        }];

    }
}

- (void)prevPage:(id)sender {

    [self hideBars];
    CGPoint newContOffset = theScrollView.contentOffset;
    if (isLandscape) {
        newContOffset.x -= 1024.0f;
    }
    else {
        newContOffset.x -= 768.0f;
    }
    if (newContOffset.x >= 0) {
        [UIView animateWithDuration:0.5f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [theScrollView setContentOffset:newContOffset];
        }                completion:^(BOOL finished) {
        }];
    }
}

- (void)viewDidLoad {
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

    [super viewDidLoad];

    NSAssert(!(document == nil), @"RoboDocument == nil");

    CGRect viewRect = self.view.bounds;


    self.view.backgroundColor = [UIColor blackColor];

    [RoboPDFModel instance].numberOfPages = [document.pageCount intValue];

    pdfController = [[RoboPDFController alloc] initWithDocument:document];
    pdfController.viewDelegate = self;
    pdfController.fileURL = document.fileURL;
    pdfController.password = document.password;

    if (small_document != nil) {
        smallPdfController = [[RoboPDFController alloc] initWithDocument:small_document];
        smallPdfController.viewDelegate = self;
        smallPdfController.isSmall = YES;
    }

    [[UIApplication sharedApplication] setStatusBarHidden:YES];


    contentViews = [[NSMutableDictionary alloc] init];
    loadedPages = [[NSMutableSet alloc] init];


    theScrollView = [[UIScrollView alloc] initWithFrame:viewRect]; // All

    theScrollView.scrollsToTop = NO;
    theScrollView.pagingEnabled = YES;
    //theScrollView.delaysContentTouches = NO;
    theScrollView.showsVerticalScrollIndicator = NO;
    theScrollView.showsHorizontalScrollIndicator = NO;
    theScrollView.contentMode = UIViewContentModeRedraw;
    theScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    theScrollView.backgroundColor = [UIColor clearColor];
    theScrollView.userInteractionEnabled = YES;
    theScrollView.autoresizesSubviews = NO;
    theScrollView.delegate = self;

    [self.view addSubview:theScrollView];

    CGRect toolbarRect = viewRect;
    toolbarRect.size.height = READER_TOOLBAR_HEIGHT;
    toolbarRect.origin.y = 20.0f;
    NSString *toolbarTitle = (self.title == nil) ? [document.fileName stringByDeletingPathExtension] : self.title;

    mainToolbar = [[RoboMainToolbar alloc] initWithFrame:toolbarRect title:toolbarTitle];

    mainToolbar.delegate = self;

    [self.view addSubview:mainToolbar];

    CGRect pagebarRect = viewRect;
    pagebarRect.size.height = PAGEBAR_HEIGHT;
    pagebarRect.origin.y = (viewRect.size.height - PAGEBAR_HEIGHT);

    if (smallPdfController != nil) {
        mainPagebar = [[RoboMainPagebar alloc] initWithFrame:pagebarRect document:document pdfController:smallPdfController];
    } else {
        mainPagebar = [[RoboMainPagebar alloc] initWithFrame:pagebarRect document:document pdfController:pdfController];
    }
    mainPagebar.delegate = self;
    [self.view addSubview:mainPagebar];

    UITapGestureRecognizer *singleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapOne.numberOfTouchesRequired = 1;
    singleTapOne.numberOfTapsRequired = 1;
    singleTapOne.delegate = self;


    [self.view addGestureRecognizer:singleTapOne];


    leftButton = [[UIButton alloc] init];
    [leftButton addTarget:self action:@selector(prevPage:) forControlEvents:UIControlEventTouchDown];
    [self.view insertSubview:leftButton aboveSubview:theScrollView];

    rightButton = [[UIButton alloc] init];
    [rightButton addTarget:self action:@selector(nextPage:) forControlEvents:UIControlEventTouchDown];
    [self.view insertSubview:rightButton aboveSubview:theScrollView];

    [self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0];

    barsHiddenFlag = YES;

}


- (void)viewDidAppear:(BOOL)animated {
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

    [super viewDidAppear:animated];

    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
        isLandscape = YES;
    else
        isLandscape = NO;

    [self showDocument];

}

- (void)viewWillDisappear:(BOOL)animated {
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

    [super viewWillDisappear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:NO];

}


- (void)viewDidUnload {

    mainToolbar = nil;

    mainPagebar = nil;

    theScrollView = nil;


    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
#ifdef DEBUGX
	NSLog(@"%s (%d)", __FUNCTION__, interfaceOrientation);
#endif

    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
#ifdef DEBUGX
	NSLog(@"%s %@ (%d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), toInterfaceOrientation);
#endif

    if (UIDeviceOrientationIsLandscape(toInterfaceOrientation))
        isLandscape = YES;
    else
        isLandscape = NO;

    didRotate = YES;
    pdfController.didRotate = YES;

}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
#ifdef DEBUGX
	NSLog(@"%s %@ (%d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), interfaceOrientation);
#endif
    if (UIDeviceOrientationIsLandscape(interfaceOrientation)) {

        if (![[UIApplication sharedApplication] isStatusBarHidden]) {

            [self.view setBounds:CGRectMake(0, 0, 1024.0f, 768.0f)];
            [self.view setFrame:CGRectMake(0, -20.0f, 1024.0f, 768.0f)];

        }

        [leftButton setFrame:CGRectMake(0, 0, 66.0f, 768.0f)];
        [rightButton setFrame:CGRectMake(958.0f, 0, 66.0f, 768.0f)];

    }
    else {
        if (![[UIApplication sharedApplication] isStatusBarHidden]) {

            [self.view setBounds:CGRectMake(0, 0, 768.0f, 1024.0f)];
            [self.view setFrame:CGRectMake(0, -20.0f, 768.0f, 1024.0f)];

        }
        [leftButton setFrame:CGRectMake(0, 0, 66.0f, 1024.0f)];
        [rightButton setFrame:CGRectMake(702.0f, 0, 66.0f, 1024.0f)];

    }

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
#ifdef DEBUGX
	NSLog(@"%s %@ (%d to %d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), fromInterfaceOrientation, self.interfaceOrientation);
#endif

    [self showDocumentPage:[document.currentPage intValue] fastScroll:NO];

}

- (void)didReceiveMemoryWarning {


    [super didReceiveMemoryWarning];

    pdfController.resetPdfDoc = YES;

    if (smallPdfController) {
        smallPdfController.resetPdfDoc = YES;
    }

}

- (void)dealloc {

    [pdfController stopMashina];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    mainToolbar = nil;
    mainPagebar = nil;

    theScrollView = nil;

    document = nil;


}


- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {

    [self hideBars];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if (!didRotate) {

        CGFloat pageWidth;
        int currentPage = [document.currentPage intValue];
        int page;
        if (isLandscape) {
            pageWidth = 512.0f;
            page = floor((theScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
            if (currentPage != page && currentPage != page + 1 && currentPage != page - 1)
                [self showDocumentPage:page fastScroll:YES];
        }
        else {
            pageWidth = 768.0f;
            page = floor((theScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 2;
            if (currentPage != page)
                [self showDocumentPage:page fastScroll:YES];
        }

    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch {

    if ([touch.view isKindOfClass:[UIScrollView class]]) return YES;

    return NO;
}


- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {


    if (barsHiddenFlag) {
        [self showBars];
    }
    else {
        [self hideBars];
    }

}


- (void)dismissButtonTapped {


    [document saveRoboDocument];

    if ([delegate respondsToSelector:@selector(dismissRoboViewController:)] == YES) {
        [delegate dismissRoboViewController:self];
    }
    else {
        NSAssert(NO, @"Delegate must respond to -dismissRoboViewController:");
    }

}


- (void)openPage:(int)page {


    [self showDocumentPage:page fastScroll:NO];
}


- (void)applicationWill:(NSNotification *)notification {


    [document saveRoboDocument]; // Save any RoboDocument object changes

}

@end
