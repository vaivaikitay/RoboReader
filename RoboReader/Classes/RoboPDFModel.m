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


#import "RoboPDFModel.h"

@implementation RoboPDFModel

+ (RoboPDFModel *)instance {

#ifdef DEBUGX
    NSLog(@"%s", __FUNCTION__);
#endif

    static RoboPDFModel *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        instance = [[self alloc] init];

    });
    return instance;

}

+ (CGRect)getPdfRectsWithSize:(CGSize)onePageSize isLands:(BOOL)isLands {
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    if (!isLands) {
        // set sizes for portrait pdf - it will save processor time -
        // but each pdf page must be the same size
        CGFloat widthPortrNew; CGFloat heightPortrNew;
        CGFloat originPortrX; CGFloat originPortrY;
        heightPortrNew = CGRectGetHeight(bounds);
        widthPortrNew = CGRectGetHeight(bounds) * onePageSize.width / onePageSize.height;
        if (widthPortrNew > CGRectGetWidth(bounds)) {
            widthPortrNew = CGRectGetWidth(bounds);
            heightPortrNew = CGRectGetWidth(bounds) * onePageSize.height / onePageSize.width;
            originPortrX = 0;
            originPortrY = (CGRectGetHeight(bounds) - heightPortrNew) / 2.0f;
        }
        else {
            originPortrX = (CGRectGetWidth(bounds) - widthPortrNew) / 2.0f;
            originPortrY = 0;
        }
        return CGRectMake(originPortrX, originPortrY, widthPortrNew, heightPortrNew);
    }
    else {
        // set sizes for landscapes pdf
        CGFloat widthLandsNew; CGFloat heightLandsNew;
        CGFloat originLandsX; CGFloat originLandsY;
        widthLandsNew = CGRectGetHeight(bounds) / 2;
        heightLandsNew = CGRectGetHeight(bounds) / 2 * onePageSize.height / onePageSize.width;
        if (heightLandsNew > CGRectGetWidth(bounds)) {
            
            heightLandsNew = CGRectGetWidth(bounds);
            widthLandsNew = CGRectGetWidth(bounds) * onePageSize.width / onePageSize.height;
            originLandsX = CGRectGetHeight(bounds) / 2 - widthLandsNew;
            originLandsY = 0;
        }
        else {
            originLandsX = 0;
            originLandsY = (CGRectGetWidth(bounds) - heightLandsNew) / 2.0f;
        }
        return CGRectMake(originLandsX, originLandsY, widthLandsNew, heightLandsNew);
    }
}



@end
