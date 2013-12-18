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


#import <Foundation/Foundation.h>
#import "RoboDocument.h"


@interface PDFPageRefObject : NSObject


@property (nonatomic) CGPDFPageRef pageRef;

@end

@interface RoboPDFView : UIView {
    CGPDFPageRef _onePDFPageRef;
    float _scale;
}

- (id)initWithFrame:(CGRect)frame onePDFPageRef:(CGPDFPageRef)onePDFPageRef scale:(CGFloat)scale;

@property (nonatomic) CGPDFPageRef onePDFPageRef;
@property (nonatomic) float scale;

@end

@protocol PDFControllerDelegateToPagebar <NSObject>
@required
- (void)pagebarImageLoadingComplete:(UIImage *)pageBarImage page:(int)page;

- (BOOL) isNeedLoad: (int) i;
@end

@protocol PDFControllerDelegateToView <NSObject>
@required
- (void)reloadCurrentPage;
- (void)pdfViewLoadingComplete:(int)page pdfView:(RoboPDFView *)pdfView rightSide:(BOOL)rightSide;

- (void)pageContentLoadingComplete:(int)page pageBarImage:(UIImage *)pageBarImage rightSide:(BOOL)rightSide;
@end


@interface RoboPDFController : NSObject {
@private

    NSOperationQueue *pagesQueue;
    NSOperationQueue *pagebarQueue;

    NSMutableDictionary *pagesDict;

    CGPDFDocumentRef thePDFDocRef;

    BOOL isRetina;
    BOOL isRunning;

    NSString *pdfPassword;
    NSURL *pdfFileURL;


    BOOL resetPdfDoc;

}
- (id)initWithDocument:(RoboDocument *)document;

- (CGRect)getFirstPdfPageRect;

- (void)stopMashina;
- (void)cleanMemory;
- (void)getPageBarImages:(int)pages;

//- (void)getZoomedPageContent:(int)page isLands:(int)isLands;
- (void)getPagesContentFromPage:(int)minValue toPage:(int)maxValue isLands:(BOOL)isLands;

- (void)addGettingPageBarImageToQueue:(int)i;

@property (nonatomic, unsafe_unretained) id <PDFControllerDelegateToPagebar> pagebarDelegate;
@property (nonatomic, unsafe_unretained) id <PDFControllerDelegateToView> viewDelegate;
@property (strong, nonatomic) NSOperationQueue *viewQueue;
@property (strong, nonatomic) NSMutableDictionary *opDict;
@property (strong, nonatomic) NSMutableSet *loadedPages;
@property (nonatomic) int currentPage;

@end

