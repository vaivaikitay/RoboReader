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
    
    
    if (!isLands) {
        // set sizes for portrait pdf - it will save processor time -
        // but each pdf page must be the same size
        CGFloat widthPortrNew; CGFloat heightPortrNew;
        CGFloat originPortrX; CGFloat originPortrY;
        heightPortrNew = 1024.0f;
        widthPortrNew = 1024.0f * onePageSize.width / onePageSize.height;
        if (widthPortrNew > 768.0f) {
            widthPortrNew = 768.0f;
            heightPortrNew = 768.0f * onePageSize.height / onePageSize.width;
            originPortrX = 0;
            originPortrY = (1024.0f - heightPortrNew) / 2.0f;
        }
        else {
            originPortrX = (768.0f - widthPortrNew) / 2.0f;
            originPortrY = 0;
        }
        return CGRectMake(originPortrX, originPortrY, widthPortrNew, heightPortrNew);
    }
    else {
        // set sizes for landscapes pdf
        CGFloat widthLandsNew; CGFloat heightLandsNew;
        CGFloat originLandsX; CGFloat originLandsY;
        widthLandsNew = 512.0f;
        heightLandsNew = 512.0f * onePageSize.height / onePageSize.width;
        if (heightLandsNew > 768.0f) {
            
            heightLandsNew = 768.0f;
            widthLandsNew = 768.0f * onePageSize.width / onePageSize.height;
            originLandsX = 512.0f - widthLandsNew;
            originLandsY = 0;
        }
        else {
            originLandsX = 0;
            originLandsY = (768.0f - heightLandsNew) / 2.0f;
        }
        return CGRectMake(originLandsX, originLandsY, widthLandsNew, heightLandsNew);
    }
}



@end
