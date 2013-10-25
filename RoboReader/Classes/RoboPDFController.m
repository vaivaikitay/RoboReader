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

#import "RoboPDFController.h"
#import "PDFPageConverter.h"
#import "CGPDFDocument.h"
#import "RoboConstants.h"


#define MAX_DPI 300.0f

@implementation RoboPDFController

- (id)initWithDocument:(RoboDocument *)document {

#ifdef HARDCORX
	NSLog(@"%s", __FUNCTION__);
#endif
    if (self = [super init]) {

        thePDFDocRef = CGPDFDocumentCreateX((__bridge CFURLRef) document.fileURL, document.password);

        pdfFileURL = document.fileURL;
        pdfPassword = document.password;

        _resetPdfDoc = NO;
        isRetina = [RoboConstants instance].retinaDisplay;

        viewQueue = [[NSOperationQueue alloc] init];
        [viewQueue setMaxConcurrentOperationCount:8];
        
        opDict = [[NSMutableDictionary alloc] init];
        pagesQueue = [[NSOperationQueue alloc] init];
        [pagesQueue setMaxConcurrentOperationCount:2];
        pagebarQueue = [[NSOperationQueue alloc] init];
        [pagebarQueue setMaxConcurrentOperationCount:2];

        loadedPages = [[NSMutableSet alloc] init];
        _didRotate = NO;
        running = YES;

    }
    return self;
}

- (void)setPdfPage:(CGPDFPageRef)newPage {
    if (onePDFPageRef != newPage) {
        CGPDFPageRelease(onePDFPageRef);
        onePDFPageRef = CGPDFPageRetain(newPage);
    }
}

- (CGRect)getFirstPdfPageRect {

    @synchronized (self) {
        if (running) {
            if (_resetPdfDoc) {
                CGPDFDocumentRelease(thePDFDocRef);
                thePDFDocRef = CGPDFDocumentCreateX((__bridge CFURLRef) (pdfFileURL), pdfPassword);
                _resetPdfDoc = NO;
            }
            [self setPdfPage:CGPDFDocumentGetPage(thePDFDocRef, 1)];
            if (onePDFPageRef != NULL) {

                CGRect pageRect = CGPDFPageGetBoxRect(onePDFPageRef, kCGPDFCropBox);

                return pageRect;
            }
            else {

                NSLog(@"Error while loading pdf page number: %i", 1);

            }
        }
    }


    return CGRectZero;

}


- (void)addGettingPageBarImageToQueue:(int)i {
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [self getPageBarImageIfNeeded:i];
    }];
    [op setQueuePriority:NSOperationQueuePriorityVeryLow];
    [pagebarQueue addOperation:op];

}

- (void)getPageBarImageIfNeeded:(int)i {
#ifdef HARDCORX
	NSLog(@"%s", __FUNCTION__);
#endif

    if ([self.pagebarDelegate isNeedLoad:i]) {
        @synchronized (self) {
            if (running) {
                if (_resetPdfDoc) {
                    CGPDFDocumentRelease(thePDFDocRef);
                    thePDFDocRef = CGPDFDocumentCreateX((__bridge CFURLRef) (pdfFileURL), pdfPassword);
                    _resetPdfDoc = NO;
                }
                [self setPdfPage:CGPDFDocumentGetPage(thePDFDocRef, i)];
                if (onePDFPageRef != NULL) {

                    UIImage *pagebarImage;
                    if (_isSmall) {
                        if (isRetina)
                            pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:150.0f];
                        else
                            pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:150.0f];
                    } else {
                        if (isRetina)
                            pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:20.0f];
                        else
                            pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:14.0f];
                    }
                    if (running)
                        [_pagebarDelegate pagebarImageLoadingComplete:pagebarImage page:i];
                }
                else {

                    NSLog(@"Error while loading pdf page number: %i", i);

                }
            }
        }
    }
}

- (void)stopMashina {

    running = NO;

    [viewQueue cancelAllOperations];
    [viewQueue waitUntilAllOperationsAreFinished];

    [pagesQueue cancelAllOperations];
    [pagesQueue waitUntilAllOperationsAreFinished];

    [pagebarQueue cancelAllOperations];
    [pagebarQueue waitUntilAllOperationsAreFinished];

    CGPDFPageRelease(onePDFPageRef);
    CGPDFDocumentRelease(thePDFDocRef);

    onePDFPageRef = nil;
    thePDFDocRef = nil;

}


- (void)getPagesContentFromPage:(int)minValue toPage:(int)maxVal isLands:(BOOL)isLands {
    
    [pagesQueue cancelAllOperations];

    NSOperation *pagesOp = [NSBlockOperation blockOperationWithBlock:^{


        if (_didRotate) {
            _didRotate = NO;
            [viewQueue cancelAllOperations];
            [loadedPages removeAllObjects];
        }

        int maxValue = maxVal;

        if (isLands) {
            for (NSNumber *key in [loadedPages allObjects]) {


                NSOperation *renderOperation = opDict[key];

                if ([key intValue] == _currentPage || [key intValue] == _currentPage + 1) {

                    [renderOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];

                }
                else if ((_currentPage - [key intValue] >= 3) || ([key intValue] - _currentPage >= 4)) {

                    [renderOperation cancel];
                    [loadedPages removeObject:key];

                }
                else {
                    [renderOperation setQueuePriority:NSOperationQueuePriorityNormal];
                }
            }
        }
        else {
            for (NSNumber *key in [loadedPages allObjects]) {
                NSOperation *renderOperation = opDict[key];
                if ([key intValue] == _currentPage) {
                    [renderOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
                }
                else if (abs([key intValue] - _currentPage) >= 2) {
                    [loadedPages removeObject:key];
                    [renderOperation cancel];
                }
                else {
                    [renderOperation setQueuePriority:NSOperationQueuePriorityNormal];
                }
            }
        }
        if (isLands)
            maxValue++;
        for (int page = minValue; page <= maxValue; page++) {

            NSString *key = [NSString stringWithFormat:@"%i", page];
            if (![loadedPages containsObject:key]) {
                [loadedPages addObject:key];
                NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
                    [self getOnePageContent:page isLands:isLands];
                }];
                if ((isLands && page == _currentPage + 1) || page == _currentPage)
                    [op setQueuePriority:NSOperationQueuePriorityVeryHigh];
                else
                    [op setQueuePriority:NSOperationQueuePriorityNormal];
                [viewQueue addOperation:op];
                opDict[key] = op;
            }
        }
    }];
    [pagesOp setQueuePriority:NSOperationQueuePriorityHigh];
    [pagesQueue addOperation:pagesOp];

}

- (void)getOnePageContent:(int)page isLands:(int)isLands {
#ifdef HARDCORX
	NSLog(@"%s", __FUNCTION__);
#endif

    @synchronized (self) {
        if (running) {

            BOOL rightSide;
            if (isLands) {
                if (page >= 1)
                    rightSide = page % 2;
                else
                    rightSide = NO;
            }
            else {
                rightSide = NO;
            }

            if (_resetPdfDoc) {
                CGPDFDocumentRelease(thePDFDocRef);
                thePDFDocRef = CGPDFDocumentCreateX((__bridge CFURLRef) (pdfFileURL), pdfPassword);
                _resetPdfDoc = NO;

            }
            [self setPdfPage:CGPDFDocumentGetPage(thePDFDocRef, page)]; // Get page
            if (onePDFPageRef != NULL) { // Check for non-NULL CGPDFPageRef
                UIImage *pagebarImage;
                if (isLands) {
                    if (isRetina) {
                        pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:MAX_DPI * 0.5];
                    }
                    else {
                        pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:MAX_DPI * 0.25];
                    }
                }
                else {
                    if (isRetina) {
                        pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:MAX_DPI * 0.6];
                    }
                    else {
                        pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:MAX_DPI * 0.3];
                    }
                }

                if (running)
                    [_viewDelegate pageContentLoadingComplete:page pageBarImage:pagebarImage rightSide:rightSide zoomed:NO];

            }
            else {
                NSLog(@"Error while loading pdf page number: %i", page);
                //  return nil;
            }
        }
    }
}

- (void)getZoomedPageContent:(int)page isLands:(int)isLands {
#ifdef HARDCORX
	NSLog(@"%s", __FUNCTION__);
#endif


    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        BOOL rightSide;
        if (isLands) {
            if (page >= 1)
                rightSide = page % 2;
            else
                rightSide = NO;
        }
        else {
            rightSide = NO;
        }

        if ((isLands && ((page - _currentPage) <= 3 || (_currentPage - page) >= 2)) || (!isLands && abs(page - _currentPage) <= 1)) {
            @synchronized (self) {
                if (_resetPdfDoc) {
                    CGPDFDocumentRelease(thePDFDocRef);
                    thePDFDocRef = CGPDFDocumentCreateX((__bridge CFURLRef) (pdfFileURL), pdfPassword);
                    _resetPdfDoc = NO;

                }

                [self setPdfPage:CGPDFDocumentGetPage(thePDFDocRef, page)];
                if (onePDFPageRef != NULL) {

                    UIImage *pagebarImage;

                    if (isLands) {
                        if (isRetina) {
                            pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:MAX_DPI * 0.8];
                        }
                        else {
                            pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:MAX_DPI * 0.5];
                        }
                    }
                    else {
                        if (isRetina) {
                            pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:MAX_DPI];
                        }
                        else {
                            pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:MAX_DPI * 0.6];
                        }
                    }

                    if ((isLands && ((page - _currentPage) <= 3 || (_currentPage - page) >= 2)) || (!isLands && abs(page - _currentPage) <= 1)) if (running)
                        [_viewDelegate pageContentLoadingComplete:page pageBarImage:pagebarImage rightSide:rightSide zoomed:YES];

                }
                else {
                    NSLog(@"Error while loading pdf page number: %i", page);
                    //  return nil;
                }

            }
        }
    });

}

/*
- (void)renderPage:(int)page withScale:(float)scale {
#ifdef HARDCORX
	NSLog(@"%s", __FUNCTION__);
#endif
    CGPDFPageRef onePDFPageRef = CGPDFDocumentGetPage([RoboPDFDocRef instance:nil].thePDFDocRef, page);
    [PDFPageRenderer renderPage:onePDFPageRef inContext:UIGraphicsGetCurrentContext()  atPoint:CGPointMake(0, 0) withZoom:scale*100.0f];
}


- (UIImage *)getPageContentImmediately:(int)page {
#ifdef HARDCORX
	NSLog(@"%s", __FUNCTION__);
#endif
    CGPDFPageRef onePDFPageRef = CGPDFDocumentGetPage([RoboPDFDocRef instance:nil].thePDFDocRef, page); // Get page
    if (onePDFPageRef != NULL) { // Check for non-NULL CGPDFPageRef
        UIImage *pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:500];
       
        
         return pagebarImage;
    }
    else {
        NSLog(@"Error while loading pdf page number: %i", page);
          return nil;
    }

}


- (RoboContentPage *)getTiledPage:(int)page {
#ifdef HARDCORX
	NSLog(@"%s", __FUNCTION__);
#endif
    CGPDFPageRef onePDFPageRef = CGPDFDocumentGetPage([RoboPDFDocRef instance:nil].thePDFDocRef, page);
    return [[RoboContentPage alloc] initWithPageRef:onePDFPageRef viewRect:[RoboPDFInfo instance].pdfRect];
}
 */

- (void)dealloc {

    //dispatch_release(backgroundQueueViews);
}


@end
