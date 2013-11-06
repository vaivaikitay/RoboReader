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

#import <QuartzCore/QuartzCore.h>
#import "RoboContentView.h"
#import "CGPDFDocument.h"
#import "RoboConstants.h"
#import "RoboPDFModel.h"
#import "RoboPDFController.h"

#define ZOOM_LEVELS 3

@implementation RoboContentView {
    BOOL flag1ZoomedLoaded;
    BOOL flag2ZoomedLoaded;
}


- (void)updateMinimumMaximumZoom {
    
	theScrollView.minimumZoomScale = 1.0f;
    
	theScrollView.maximumZoomScale = ZOOM_LEVELS;
}


- (id)initWithFrame:(CGRect)frame page:(NSUInteger)page orientation:(BOOL)isLandscape {
    
    
	if ((self = [super initWithFrame:frame]))
	{

        noTiledLayer = YES;
        pageNumber = page;
        _isLandscape = isLandscape;
        
        if (page == 0)
            page = 1;
        
		self.autoresizesSubviews = YES;
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor blackColor];
        
		theScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        
		theScrollView.scrollsToTop = NO;
		theScrollView.delaysContentTouches = NO;
		theScrollView.showsVerticalScrollIndicator = NO;
		theScrollView.showsHorizontalScrollIndicator = NO;
		theScrollView.backgroundColor = [UIColor blackColor];
		theScrollView.userInteractionEnabled = YES;
		theScrollView.autoresizesSubviews = NO;
		theScrollView.bouncesZoom = YES;
		theScrollView.delegate = self;
        theScrollView.directionalLockEnabled = YES;
        
        theContainerView = [[UIView alloc] initWithFrame:self.bounds];
        theContainerView.autoresizesSubviews = NO;
        theContainerView.userInteractionEnabled = NO;
        theContainerView.contentMode = UIViewContentModeRedraw;
        theContainerView.autoresizingMask = UIViewAutoresizingNone;
        theContainerView.backgroundColor = [UIColor blackColor];
        
        //portrait
        if (!isLandscape) {
            
            theContentViewImagePDF = [[UIImageView alloc] init];
            
            pageNumberTextField =  [[UITextField alloc] initWithFrame:self.bounds];
            [pageNumberTextField setText:[NSString stringWithFormat:@"%i", page]];
            [pageNumberTextField setTextColor:[UIColor whiteColor]];
            [pageNumberTextField setTextAlignment:NSTextAlignmentCenter];
            [pageNumberTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [pageNumberTextField setFont:[UIFont fontWithName:@"Helvetica-Bold" size:75]];
            [theContainerView addSubview:pageNumberTextField];
            
        }
        //landscape
        else {
            
            if (page <= 1) {
                
                theContentViewImagePDF = [[UIImageView alloc] init];
                [theContentViewImagePDF setBackgroundColor:[UIColor blackColor]];
                
                CGRect landsFrame = CGRectMake(CGRectGetWidth(frame) / 2, 0, CGRectGetWidth(frame) / 2, CGRectGetHeight(frame));
                
                theContentViewImage2PDF = [[UIImageView alloc] init];
                pageNumberTextField2 =  [[UITextField alloc] initWithFrame:landsFrame];
                [pageNumberTextField2 setText:[NSString stringWithFormat:@"%i", page]];
                [pageNumberTextField2 setTextColor:[UIColor whiteColor]];
                [pageNumberTextField2 setTextAlignment:NSTextAlignmentCenter];
                [pageNumberTextField2 setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
                [pageNumberTextField2 setFont:[UIFont fontWithName:@"Helvetica-Bold" size:75]];
                [theContainerView addSubview:pageNumberTextField2];
                
            }
            else {
                
                CGRect landsFrame = CGRectMake(0, 0, CGRectGetWidth(frame) / 2, CGRectGetHeight(frame));
                
                theContentViewImagePDF = [[UIImageView alloc] init];
                
                pageNumberTextField =  [[UITextField alloc] initWithFrame:landsFrame];
                [pageNumberTextField setText:[NSString stringWithFormat:@"%i", page]];
                [pageNumberTextField setTextColor:[UIColor whiteColor]];
                [pageNumberTextField setTextAlignment:NSTextAlignmentCenter];
                [pageNumberTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
                [pageNumberTextField setFont:[UIFont fontWithName:@"Helvetica-Bold" size:75]];
                [theContainerView addSubview:pageNumberTextField];
                
                
                theContentViewImage2PDF = [[UIImageView alloc] init];
                if (page != [RoboPDFModel instance].numberOfPages) {
                    
                    landsFrame.origin.x = CGRectGetWidth(self.frame) / 2;
                    pageNumberTextField2 =  [[UITextField alloc] initWithFrame:landsFrame];
                    [pageNumberTextField2 setText:[NSString stringWithFormat:@"%i", page + 1]];
                    [pageNumberTextField2 setTextColor:[UIColor whiteColor]];
                    [pageNumberTextField2 setTextAlignment:NSTextAlignmentCenter];
                    [pageNumberTextField2 setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
                    [pageNumberTextField2 setFont:[UIFont fontWithName:@"Helvetica-Bold" size:75]];
                    [theContainerView addSubview:pageNumberTextField2];
                    
                }
            }
        }
        
		if (theContentViewImagePDF != nil) {
            
            
            [theContainerView addSubview:theContentViewImagePDF];
            
            if(( isLandscape) && (theContentViewImage2PDF != NULL)){ // Landscape
                
                [theContainerView addSubview:theContentViewImage2PDF];
                
            }
            
            theScrollView.contentSize = theContainerView.bounds.size;
            [theScrollView setFrame:theContainerView.frame];
            
			[theScrollView addSubview:theContainerView];
            
			[self updateMinimumMaximumZoom];
            
			theScrollView.zoomScale = theScrollView.minimumZoomScale;
		}
        
		[self addSubview:theScrollView];
        
		[theScrollView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
        
		self.tag = page;
        
        flag1Loaded = NO;
        flag1ZoomedLoaded = NO;
        flag2Loaded = NO;
        flag2ZoomedLoaded = NO;
        
    }
    
    
	return self;
}


- (void)pageContentLoadingComplete:(UIImage *)pageBarImage rightSide:(BOOL)rightSide zoomed:(BOOL)zoomed{
    
    dispatch_async(dispatch_get_main_queue(), ^{


        if (rightSide) {


            if (!flag2Loaded || !flag2ZoomedLoaded) {

                if (!flag2Loaded)
                    theContentViewImage2PDF.alpha = 0;

                if (zoomed)
                    flag2ZoomedLoaded = YES;

                flag2Loaded = YES;

                [pageNumberTextField2 removeFromSuperview];
                pageNumberTextField2 = nil;

                CGRect pdfSize2 = [RoboPDFModel getPdfRectsWithSize:pageBarImage.size isLands:_isLandscape]; pdfSize2.origin.x = CGRectGetWidth(self.frame) / 2;
                [theContentViewImage2PDF setFrame:pdfSize2];
                [theContentViewImage2PDF setImage:pageBarImage];

                [UIView animateWithDuration:0.3 delay:0.0
                                    options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                                 animations:^(void)
                 {
                     theContentViewImage2PDF.alpha = 1.0f;
                 }
                                 completion:nil
                 ];
            }
            
        }
        else {
            
            if (!flag1Loaded || !flag1ZoomedLoaded) {

                if (!flag1Loaded)
                    theContentViewImagePDF.alpha = 0;

                if (zoomed)
                    flag1ZoomedLoaded = YES;

                flag1Loaded = YES;

                [pageNumberTextField removeFromSuperview];
                pageNumberTextField = nil;
                
                [theContentViewImagePDF setFrame:[RoboPDFModel getPdfRectsWithSize:pageBarImage.size isLands:_isLandscape]];
                [theContentViewImagePDF setImage:pageBarImage];

                [UIView animateWithDuration:0.3 delay:0.0
                                    options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                                 animations:^(void)
                 {
                     theContentViewImagePDF.alpha = 1.0f;
                     
                 }
                                 completion:nil
                 ];
            }
            
        }
    });
    
    
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {


    return theContainerView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {

    if (noTiledLayer) {
        noTiledLayer = NO;
        [_delegate getZoomedPages:pageNumber isLands:_isLandscape zoomIn:YES];

    }

}

- (void)dealloc {

    [theScrollView removeObserver:self forKeyPath:@"frame"];

    theScrollView = nil;

    theContainerView = nil;

    theContentViewImagePDF = nil;

    theContentViewImage2PDF = nil;

}

@end

