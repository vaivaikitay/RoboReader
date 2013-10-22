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

#import <UIKit/UIKit.h>
#import "RoboPDFController.h"


@class RoboMainPagebar;
@class RoboTrackControl;
@class RoboDocument;

@protocol RoboMainPagebarDelegate <NSObject>

@required // Delegate protocols

- (void)openPage:(int)page;

@end

@interface ImagesFlags : NSObject

@property(atomic) BOOL onPageBar;
@property(atomic) BOOL isRendered;

@end

@interface RoboMainPagebar : UIView <UIScrollViewDelegate, PDFControllerDelegateToPagebar> {
@private // Instance variables
    CGSize barContentSize;


    RoboDocument *document;

    RoboTrackControl *trackControl;

    UILabel *pageLabel;

    UIView *pageLabelView;

    UISlider *pagebarSlider;

    BOOL sliderValueChanged;

    NSTimer *trackTimer;

    RoboPDFController *pdfController;

    float previewPageWidth;
    int beginPage;
    int endPage;
    NSMutableArray *imagesFlags;
    float offsetCounter;
    float maxOffsetForUpdate;
    float prevOffset;
    int currentWindowSize;

    BOOL inited;
}
@property(atomic, retain) NSMutableDictionary *pagesDict;
@property(atomic, retain) NSMutableDictionary *renderedPages;

@property(nonatomic, unsafe_unretained, readwrite) id <RoboMainPagebarDelegate> delegate;

- (id)initWithFrame:(CGRect)frame document:(RoboDocument *)object pdfController:(RoboPDFController *)pdfController;

- (void)pagebarImageLoadingComplete:(UIImage *)pageBarImage page:(int)page;

- (void)hidePagebar;

- (void)showPagebar;

- (void)didReceiveMemoryWarning;

- (void)reset;

- (void)start;

@end


//
//	RoboTrackControl class interface
//

@interface RoboTrackControl : UIScrollView {
@private // Instance variables

    CGFloat _value;
    float previewPageWidth;
    int lastPage;
    UIImageView *strokeTrackImage;

}

@property(nonatomic, assign, readonly) CGFloat value;

- (id)initWithFrame:(CGRect)frame page:(int)page previewPageWidth:(float)previewPageWidth lastPage:(int)lPage;

- (void)setStrokePage:(int)page;
@end