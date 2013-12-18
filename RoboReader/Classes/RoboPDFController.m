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
// THE SOFTWARE.NNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RoboPDFController.h"
#import "PDFPageConverter.h"
#import "CGPDFDocument.h"
#import "PDFPageRenderer.h"
#import "RoboConstants.h"
#import "RoboPDFModel.h"



@implementation RoboPDFController

- (id)initWithDocument:(RoboDocument *)document  {

    if (self = [super init]) {

        thePDFDocRef = CGPDFDocumentCreateX((__bridge CFURLRef)document.fileURL, document.password);

        pdfFileURL = document.fileURL;
        pdfPassword = document.password;

        isRetina = YES;
        isRetina = [RoboConstants instance].retinaDisplay;

        _viewQueue = [[NSOperationQueue alloc] init];
        [_viewQueue setMaxConcurrentOperationCount:8];
        _opDict = [[NSMutableDictionary alloc] init];
        pagesQueue = [[NSOperationQueue alloc] init];
        [pagesQueue setMaxConcurrentOperationCount:1];
        pagebarQueue = [[NSOperationQueue alloc] init];
        [pagebarQueue setMaxConcurrentOperationCount:2];
                
        _loadedPages = [[NSMutableSet alloc] init];

        resetPdfDoc = NO;
        isRunning = YES;

        pagesDict = [[NSMutableDictionary alloc] init];

    }
    return self;
}





/*
- (void)checkIfResetPdfAndSetPage:(int)pageNum {
    @synchronized(self) {


            CGPDFPageRelease(onePDFPageRef);
            onePDFPageRef = CGPDFDocumentGetPage(thePDFDocRef, pageNum);


    }

}
 */

- (void)getPageBarImages:(int)pages{

    NSMutableArray *opArray = [[NSMutableArray alloc] init];
    for (int i = 1; i <= pages; i++) {

        NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{

            [self getPageBarImageIfNeeded:i];//Aydar

        }];
        [op setQueuePriority:NSOperationQueuePriorityVeryLow];
        [opArray addObject:op];

    }

    [pagebarQueue addOperations:opArray waitUntilFinished:NO];

}


- (void)addGettingPageBarImageToQueue:(int)i {
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [self getPageBarImageIfNeeded:i];
    }];
    [op setQueuePriority:NSOperationQueuePriorityVeryLow];
    [pagebarQueue addOperation:op];

}

- (void)getPageBarImageIfNeeded:(int)i {


    if ([self.pagebarDelegate isNeedLoad: i]) {

            CGPDFPageRef onePDFPageRef = [self setPdfPage:i];

            if (onePDFPageRef) {

                UIImage *pagebarImage;

                if (isRetina)
                    pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:20.0f];
                else
                    pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:14.0f];

            [_pagebarDelegate pagebarImageLoadingComplete:pagebarImage page:i];




            }
            else {

                NSLog(@"Error while loading pdf page number: %i", i);

            }
    }
}


- (CGPDFPageRef)setPdfPage:(int)page {

    @synchronized (self) {

        if (!isRunning)
            return NULL;


        if (resetPdfDoc)
            [self performSelectorOnMainThread:@selector(releasePdfPointer) withObject:nil waitUntilDone:YES];

        PDFPageRefObject *onePageRef = pagesDict[@(page)];

        if (onePageRef == nil)
            onePageRef = [[PDFPageRefObject alloc] init];

        onePageRef.pageRef =  CGPDFPageRetain(CGPDFDocumentGetPage(thePDFDocRef, page));

        return onePageRef.pageRef;
    }


}




- (void)releasePdfPointer {

    NSLog(@"release world");

    [pagesDict removeAllObjects];

    CGPDFDocumentRelease(thePDFDocRef);

    thePDFDocRef = nil;

    thePDFDocRef = CGPDFDocumentCreateX((__bridge CFURLRef)pdfFileURL, pdfPassword);

    resetPdfDoc = NO;

}

- (void)cleanMemory {

    resetPdfDoc = YES;

}

- (void)stopMashina {

    isRunning = NO;

    [_viewQueue cancelAllOperations];
    [_viewQueue waitUntilAllOperationsAreFinished];

    [pagesQueue cancelAllOperations];
    [pagesQueue waitUntilAllOperationsAreFinished];

    [pagebarQueue cancelAllOperations];
    [pagebarQueue waitUntilAllOperationsAreFinished];

    CGPDFDocumentRelease(thePDFDocRef);

    thePDFDocRef = nil;

}


- (void)getPagesContentFromPage:(int)minValue toPage:(int)maxVal isLands:(BOOL)isLands {

        [pagesQueue cancelAllOperations];
        
        if (minValue < 1)
            minValue = 1;
        
        NSOperation *pagesOp = [NSBlockOperation blockOperationWithBlock:^{

            for (int page = minValue; page <= maxVal; page++) {
                
                NSString *key = [NSString stringWithFormat:@"%i", page];
                
                if (![_loadedPages containsObject:key]) {
                    
                    [_loadedPages addObject:key];

                    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
                        [self getOnePageContent:page isLands:isLands];
                    }];

                    if ((isLands &&  page == _currentPage+1) ||  page == _currentPage)
                        [op setQueuePriority:NSOperationQueuePriorityHigh];
                    else
                        [op setQueuePriority:NSOperationQueuePriorityNormal];

                    [_viewQueue addOperation:op];

                    _opDict[key] = op;
                }
            }
            
        }];
        
        [pagesOp setQueuePriority:NSOperationQueuePriorityVeryHigh];
        [pagesQueue addOperation:pagesOp];
}


- (CGRect)getFirstPdfPageRect {




        CGPDFPageRef onePDFPageRef = [self setPdfPage:1];

        if (onePDFPageRef) {
            
            // pdfPageRect.origin.x = 0;
            // pdfPageRect.origin.y = 0;


            return CGPDFPageGetBoxRect(onePDFPageRef, kCGPDFCropBox);
            
        }
        else {
            
            NSLog(@"Error while loading pdf page number: %i", 1);
            //  return nil;
            
        }
    

    
    return CGRectZero;

}

- (void)getOnePageContent:(int)page isLands:(BOOL)isLands {
    
    if ( (isLands && ((page - _currentPage) <= 3 || (_currentPage - page) >= 2)) || (!isLands && abs(page - _currentPage) <= 1)) {
        
        BOOL rightSide;

        rightSide = isLands ? page % 2 : NO;

        CGPDFPageRef onePDFPageRef=  [self setPdfPage:page];

        if (onePDFPageRef) {

            UIImage *pagebarImage;

            if (isLands) {
                pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:isRetina ? MAX_DPI * 0.5 : MAX_DPI * 0.25];
            }
            else {
                pagebarImage = [PDFPageConverter convertPDFPageToImage:onePDFPageRef withResolution:isRetina ? MAX_DPI * 0.6 : MAX_DPI * 0.3];
            }

            if ( (isLands && ((page - _currentPage) <= 3 || (_currentPage - page) >= 2)) || (!isLands && abs(page - _currentPage) <= 1))  {

                [_viewDelegate pageContentLoadingComplete:page pageBarImage:pagebarImage rightSide:rightSide];

                [self getZoomedPageContent:page isLands:isLands];

            }




        }
        else {

            NSLog(@"Error while loading pdf page number: %i", page);
            //  return nil;

        }

    }
    
    
}

- (void)getZoomedPageContent:(int)page isLands:(int)isLands {


    dispatch_async(dispatch_get_main_queue(), ^{


        if (page >= 1  &&  ( (isLands && ((page - _currentPage) <= 3 || (_currentPage - page) >= 2)) || (!isLands && abs(page - _currentPage) <= 1)) ) {

            BOOL rightSide;

            rightSide = isLands ? page % 2 : NO;



            CGPDFPageRef onePDFPageRef=  [self setPdfPage:page];

            if (onePDFPageRef) {

                CGRect pageRect = CGPDFPageGetBoxRect(onePDFPageRef, kCGPDFCropBox);
                CGRect pageResizedRect = [RoboPDFModel getPdfRectsWithSize:pageRect.size isLands:isLands];

                float scale =  pageResizedRect.size.height / pageRect.size.height;

                RoboPDFView *pdfView = [[RoboPDFView alloc] initWithFrame:pageResizedRect onePDFPageRef:onePDFPageRef scale:scale];
                pdfView.backgroundColor = [UIColor clearColor];

                if (( (isLands && ((page - _currentPage) <= 3 || (_currentPage - page) >= 2)) || (!isLands && abs(page - _currentPage) <= 1)) )
                    [_viewDelegate pdfViewLoadingComplete:page pdfView:pdfView rightSide:rightSide];

            }
            else {

                NSLog(@"Error while loading pdf page number: %i", page);
                //  return nil;

            }

        }

    });

    //[op setQueuePriority:NSOperationQueuePriorityVeryHigh];
   // [_viewQueue addOperation:op];

}


@end


@implementation RoboPDFView

- (id)initWithFrame:(CGRect)frame onePDFPageRef:(CGPDFPageRef)onePDFPageRef scale:(CGFloat)scale
{
    self = [super initWithFrame:frame];
    if (self) {

        _scale = scale;
        _onePDFPageRef = onePDFPageRef;
        
        CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
        
        tiledLayer.levelsOfDetail = ZOOM_OUT_LEVELS + ZOOM_IN_LEVELS + 1;
        tiledLayer.levelsOfDetailBias = ZOOM_IN_LEVELS;
        tiledLayer.tileSize = CGSizeMake(512.0, 512.0);
        
    }
    return self;
}

+ (Class)layerClass
{
	return [CATiledLayer class];
}

-(void)drawRect:(CGRect)r {
    
}

-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{


    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
    CGContextFillRect(context, self.bounds);

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextScaleCTM(context, _scale, _scale);

    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetRenderingIntent(context, kCGRenderingIntentDefault);


    CGContextDrawPDFPage(context, _onePDFPageRef);

    CGContextRestoreGState(context);


}


- (void)dealloc {

    ((CATiledLayer *)[self layer]).contents=nil;
    ((CATiledLayer *)[self layer]).delegate = nil;
    [self.layer removeFromSuperlayer];

}

@end


@implementation PDFPageRefObject


@end