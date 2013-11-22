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
#import <MessageUI/MessageUI.h>

#import "RoboDocument.h"
#import "RoboContentView.h"
#import "RoboMainToolbar.h"
#import "RoboMainPagebar.h"
#import "RoboConstants.h"


@class RoboViewController;
@class RoboMainToolbar;

@protocol RoboViewControllerDelegate <NSObject>

@optional

- (void)dismissRoboViewController:(RoboViewController *)viewController;

@end

@interface RoboViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate,
        RoboMainToolbarDelegate, RoboMainPagebarDelegate, PDFControllerDelegateToView, RoboContentViewDelegate> {
@private

    RoboDocument *document;

    UIScrollView *theScrollView;
    RoboPDFController *pdfController;
    RoboPDFController *smallPdfController;


    RoboMainPagebar *mainPagebar;
    RoboMainToolbar *mainToolbar;

    NSMutableDictionary *contentViews;
    NSMutableSet *loadedPages;

    int startPageNumber;

    BOOL isLandscape;
    BOOL didRotate;
    BOOL barsHiddenFlag;

    UIButton *leftButton;
    UIButton *rightButton;

}

@property(nonatomic, unsafe_unretained, readwrite) id <RoboViewControllerDelegate> delegate;

- (id)initWithRoboDocument:(RoboDocument *)object;
//- (id)initWithRoboDocument:(RoboDocument *)object small_document:(RoboDocument *)small_object;

@end
