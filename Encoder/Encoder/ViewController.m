//
//  ViewController.m
//  Encoder
//
//  Created by MCUCSIE on 7/8/18.
//  Copyright © 2018 MCUCSIE. All rights reserved.
//

#import "NSImage+cplusplus.h"
#import "ViewController.h"
using namespace std;

@interface ViewController ()
@property (weak) IBOutlet NSImageView *ivCanvas;
@end

@implementation ViewController

#define Canvas_Col 8
#define Canvas_Row 8

- (void)viewDidLoad {
    [super viewDidLoad];
//    Byte *cColors = malloc(3 * Canvas_Row * Canvas_Col * sizeof(Byte));
//    Byte *bY = malloc(Canvas_Row * Canvas_Col * sizeof(Byte));
//    Byte *bCb = malloc(Canvas_Row * Canvas_Col * sizeof(Byte));
//    Byte *bCr = malloc(Canvas_Row * Canvas_Col * sizeof(Byte));
//
//    int iY, iCb, iCr;
//    int iR, iG, iB;
//    for (int i = 0; i < Canvas_Row; i++)
//        for (int j = 0; j < Canvas_Col; j++) {
//            cColors[i * Canvas_Col * 3 + j * 3] = 255;
//            cColors[i * Canvas_Col * 3 + j * 3 +1] = 0;
//            cColors[i * Canvas_Col * 3 + j * 3 +2] = 0;
//
//            iR = cColors[i * Canvas_Col * 3 + j * 3];
//            iG = cColors[i * Canvas_Col * 3 + j * 3 + 1];
//            iB = cColors[i * Canvas_Col * 3 + j * 3 + 2];
//
//            iY = 0.2990 * (iR - iG) + iG + 0.1140 * (iB - iG);
//            iCb = 0.5643 * (iB - iY);
//            iCr = 0.7133 * (iR - iY);
//
//            bY[i * Canvas_Col + j] = iY;
//            bCb[i * Canvas_Col + j] = iCb;
//            bCr[i * Canvas_Col + j] = iCr;
//        }
//
//    self.ivCanvas.image = [NSImage imageWithData: cColors
//                                             row: Canvas_Row
//                                       andColumn: Canvas_Col
//                                      colorspace: ColorSpaceRGB];

    Byte *bTest = malloc(8 * 8 * sizeof(Byte));
    for (int i = 0; i < 64; i++)
        bTest[i] = i;

    for (int i = 0; i < 8; i++, cout << endl)
        for (int j = 0; j < 8; j++)
             cout << bTest[i * 8 + j] << " ";

}

/*******************************************************************************************************/

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

/*******************************************************************************************************/
#pragma mark - JPEG Encoder Functions

- (int)fourierAtX:(int)x Y:(int)y withBlock:(Byte *)block {
    double dAns = 0;
    double dCu, dCv;

    for (int v = 0; v < 8; v++)
        for (int u = 0; u < 8; u++) {
            dCu = (u == 0)? (1 / sqrt(2)) : 1;
            dCv = (v == 0)? (1 / sqrt(2)) : 1;
            dAns += (2 * dCu * dCv / 8 * block[v * 8 + u]
                     * cos(((2 * x + 1) * u * M_PI) / 16) * cos(((2 * y + 1) * v * M_PI) / 16));
        }
    return  dAns;
}

/*******************************************************************************************************/

- (void)DCT:(Byte *)block {
    Byte *bTemp = malloc(8 * 8 * sizeof(Byte));
    for (int i = 0; i < 64; i++)
        bTemp[i] = (block[i] -128);

    for (int y = 0; y < 8; y++)
        for (int x = 0; x < 8; x++)
            block[y * 8 + x] = [self fourierAtX:x Y:y withBlock:bTemp];

    free(bTemp);
}

/*******************************************************************************************************/

int iQuantizationTables[2][64] = {
    {16, 11, 10, 16, 24, 40, 51, 61,
    12, 12, 14, 19, 26, 58, 60, 55,
    14, 13, 16, 24, 40, 57, 69, 56,
    14, 17, 22, 29, 51, 87, 80, 82,
    18, 22, 37, 56, 68, 109, 103, 77,
    24, 35, 55, 64, 81, 104, 113, 92,
    99, 64, 78, 87, 103, 121, 120, 101,
    72, 92, 95, 98, 112, 100, 103, 99},

    {17, 18, 24, 47, 99, 99, 99, 99,
    18, 21, 26, 66, 99, 99, 99, 99,
    24, 26, 56, 99, 99, 99, 99, 99,
    47, 66, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99}
};

int ZigZagArray[64] = {
    0,   1,   5,  6,   14,  15,  27,  28,
    2,   4,   7,  13,  16,  26,  29,  42,
    3,   8,  12,  17,  25,  30,  41,  43,
    9,   11, 18,  24,  31,  40,  44,  53,
    10,  19, 23,  32,  39,  45,  52,  54,
    20,  22, 33,  38,  46,  51,  55,  60,
    21,  34, 37,  47,  50,  56,  59,  61,
    35,  36, 48,  49,  57,  58,  62,  63
};

- (void)zigZag:(Byte *)block andQuantization:(int)Tqi {
    Byte *bTemp = malloc(8 * 8 * sizeof(Byte));
    for (int i = 0; i < 64; i++)
        bTemp[i] = block[i];

    for (int i = 0; i < 64; i++)
        block[i] = bTemp[ZigZagArray[i]] / iQuantizationTables[Tqi][i];

    free(bTemp);
}

/*******************************************************************************************************/


@end
