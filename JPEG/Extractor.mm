//
//  Extracter.m
//  JPEG
//
//  Created by MacLaptop on 2019/1/25.
//  Copyright © 2019 MCUCSIE. All rights reserved.
//

#import "AppDelegate.h"
#import <iostream>
#import <string>
#import "reader.h"
#import "huffman.h"
#import "NSImage+cplusplus.h"
#import "Extractor.h"

/*******************************************************************************************************/
#pragma mark- Global variables
extern set<unsigned char> setMarkers;
static DefineNumberOfLine defineNumberOfLine;
static HuffmanTreeNode *htnHuffmanTreeRoot[2][2] = { nil };
static int iQuantizationTables[4][64];
static int iLowerBoundOfCategory[2][12];

/*******************************************************************************************************/

@implementation Extractor

- (instancetype)init {
    if (self = [super init]) {
        [self categoryLowerBound];
    }
    return self;
}

/*******************************************************************************************************/
#define MessageMaxSize 32

static int iRi;
static bool bEOI;
static unsigned int uiMessageSize;
static int iSizeMask;
static int iMessageMask;
static unsigned char ucMessage;
static fstream fout;

/*******************************************************************************************************/
#pragma mark- Extractting funciton
- (void)extracttingMessageFrom:(NSString *)stegoPath {
    [self reset];
    
    // Declare fstream object to read binary data
    fstream fStego;
    fStego.open([stegoPath UTF8String], fstream::in | fstream::out | fstream::binary);
    fStego.unsetf(fstream::skipws);
    
    uiMessageSize = 0;
    iSizeMask = 0;
    iMessageMask = 0;
    ucMessage = 0;
    
    fout.open("/Users/maclaptop/Desktop/Message.txt", fstream::out | fstream::binary);
    if (fout.fail()) cout << "Create new file failed!" << endl;
    
    unsigned char ucMarker;
    ucMarker = [self interpretMarkersWithStream:fStego];
    if (ucMarker != SOI) { cout << "Not supported file format!" << endl; fout.close(); return; }
    
    bEOI = false;
    iRi = 0;
    bool bIsSupport = true;
    while (!bEOI && bIsSupport) {
        ucMarker = [self interpretMarkersWithStream:fStego];
        
        if (ucMarker >= 0xE0 && ucMarker <= 0xEF)
            [self applicationHeaderHandler: fStego marker: ucMarker];
        
        
        switch (ucMarker) {
            case SOF1: case SOF2: case SOF3: case SOF5: case SOF6: case SOF7:
            case SOF9: case SOF10: case SOF11: case SOF13: case SOF14: case SOF15: {
                bIsSupport = false;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"sorry we don't support this kind jpg format";
                    [alert runModal];
                });
            }
                break;
                
            case SOF0:
                [self frameHeaderHandler: fStego];
                break;
                
            case DHT:
                [self huffmanHeaderHandler: fStego];
                break;
                
            case DAC: {
                ArithmeticTable arithmeticTable;
                fStego >> arithmeticTable;
            }
                break;
                
            case SOS:
                [self decodeScanWithFstream:fStego];
                break;
                
            case DQT:
                [self quantizationTableHeaderHandler: fStego];
                break;
                
            case DNL:
                fStego >> defineNumberOfLine;
                break;
                
            case DRI:
                [self restartIntervalHeaderHandler: fStego];
                break;
                
            case COM: {
                CommentSegment commentSegment;
                fStego >> commentSegment;
            }
                break;
                
            case EOI:
                bEOI = true;
                break;
                
            default:
                break;
        }
    }
    fout.close();
}

/*******************************************************************************************************/

#pragma mark- Application Header Handler
- (void)applicationHeaderHandler:(fstream&)fs marker:(unsigned char)marker{
    Application application;
    application.marker = marker;
    fs >> application;
}

/*******************************************************************************************************/

#pragma mark- Huffman Header Handler
- (void)huffmanHeaderHandler:(fstream&)fs {
    HuffmanHeader huffmanHeader;
    fs >> huffmanHeader;
    
    vector<HuffmanParameter> huffmanParameter = huffmanHeader.huffmanParameters;
    
    for (int j = 0; j < huffmanParameter.size(); j++)
        htnHuffmanTreeRoot[huffmanParameter[j].Tc][huffmanParameter[j].Th] = [self generateHuffmanTableWithParameter:huffmanParameter[j]];
    
}

/*******************************************************************************************************/

#pragma mark- QuantizationTable Header Handler
- (void)quantizationTableHeaderHandler:(fstream&)fs {
    QuantizationHeader quantizationHeader;
    fs >> quantizationHeader;
    
    vector<QuantizationParameter> parameters = quantizationHeader.quantizationParameters;
    
    for (int i = 0; i < parameters.size(); i++) {
        
        //Get Qk
        for (int j = 0; j < 64; j++)
            iQuantizationTables[parameters[i].Tq][j] = parameters[i].Qk[j];
    }
}

/*******************************************************************************************************/

#pragma mark- Restart Interval Header Handler
- (void)restartIntervalHeaderHandler:(fstream&)fs {
    RestartInterval restartInterval;
    fs >> restartInterval;
    iRi = restartInterval.Ri;
}

/*******************************************************************************************************/

static ComponentOfJPEG components[3];

#pragma mark- Frame Header Handler
- (void)frameHeaderHandler:(fstream&)fs {
    FrameHeader frameHeader;
    fs >> frameHeader;
    
    //Get Ci, Hi, Vi, Tqi
    vector<ComponentParameter> componentParameters = frameHeader.componentParameters;
    
    int X, Y, Ci, Hi, Vi, Tqi;
    ComponentOfJPEG::Himax = 0;
    ComponentOfJPEG::Vimax = 0;
    for (int j = 0; j < componentParameters.size(); j++) {
        X = frameHeader.X;
        Y = frameHeader.Y;
        Ci = componentParameters[j].Ci -1;
        Hi = componentParameters[j].Hi;
        Vi = componentParameters[j].Vi;
        Tqi = componentParameters[j].Tqi;
        if (Hi > ComponentOfJPEG::Himax) ComponentOfJPEG::Himax = Hi;
        if (Vi > ComponentOfJPEG::Vimax) ComponentOfJPEG::Vimax = Vi;
        components[Ci].X = X;
        components[Ci].Y = Y;
        components[Ci].Hi = Hi;
        components[Ci].Vi = Vi;
        components[Ci].iTqi = Tqi;
        components[Ci].iPreDC = 0;
    }
    
}

/*******************************************************************************************************/


static unsigned char ucRemain, ucNext;
static int iRemainPosition;
static long lEmbeddingBitsCount;

/*******************************************************************************************************/

- (void)decodeScanWithFstream:(fstream&)fs {
    ScanHeader scanHeader;
    fs >> scanHeader;
    
    vector<ScanComponentParameter> scanComponents = scanHeader.scanComponentParameters;
    
    int MCUI = ceil((double)components[0].Y * components[0].Vi / (components[0].Vi * components[0].Vimax * 8));
    int MCUJ = ceil((double)components[0].X * components[0].Hi / (components[0].Hi * components[0].Himax * 8));
    for (int i = 0; i < scanHeader.Ns; i++) {
        components[i].iID = i + 1;
        components[i].iTdj = scanComponents[i].Tdj;
        components[i].iTaj = scanComponents[i].Taj;
        components[i].Y = MCUI * components[i].Vi * 8;
        components[i].X = MCUJ * components[i].Hi * 8;
        components[i].data = new int*[components[i].Y];
        for (int j = 0; j < components[i].Y; j++) components[i][j] = new int[components[i].X];
    }
    int iCurrentI;
    int iCurrentJ;
    Block block;
    unsigned char ucRST;
    iRemainPosition = -1;
    lEmbeddingBitsCount = 0;
    
    for (int i = 0; i < MCUI; i++) {
        for (int j = 0; j < MCUJ; j++) {
            for (int k = 0; k < scanHeader.Ns; k++) {
                for (int m = 0; m < components[k].Vi; m++) {
                    for (int n = 0; n < components[k].Hi; n++) {
                        iCurrentI = i * components[k].Vi * 8 + m * 8;
                        iCurrentJ = j * components[k].Hi * 8 + n * 8;
                        [self getBlock: fs block: block component: components[k]];
                        for (int x = 0; x < 8; x++)
                            for (int y = 0; y < 8; y++)
                                components[k][iCurrentI + x][iCurrentJ + y] = block[x * 8 + y];
                    }
                }
            }
            if (iRi && (i * MCUJ + j + 1) != MCUI * MCUJ
                && (i * MCUJ + j + 1) % iRi == 0) {
                iRemainPosition = -1;
                components[0].iPreDC = 0;
                components[1].iPreDC = 0;
                components[2].iPreDC = 0;
                fs >> ucRST >> ucRST;
            }
        }
    }
    cout << "Finished..." << endl;
    cout << "Message size: " << uiMessageSize << endl;
}

/*******************************************************************************************************/

- (int)clip:(int)value {
    return ((value < 0) ? 0 : (value > 255) ? 255 : value);
}

/*******************************************************************************************************/

- (void)getBlock:(fstream&)fs block:(Block&)block component:(ComponentOfJPEG&)component {
    int iSample;
    int iNextAC = 0;
    int iTdj = component.iTdj;
    int iTaj = component.iTaj;
    
    for (int i = 0; i < 64; i++) block[i] = 0;
    
    // Decode DC
    [self getSample: fs Tc: 0 Th: iTdj nextAC: iNextAC sample: iSample component: component];
    block[0] = iSample;
    
    // Decode AC
    while (iNextAC < 63) {
        [self getSample:fs Tc: 1 Th: iTaj nextAC: iNextAC sample: iSample component: component];
        block[iNextAC] = iSample;
    }
    //    cout << "*************************************************\n";
    [self deZigZag:block andDequantization: component.iTqi];
    [self IDCT: block];
}

/*******************************************************************************************************/
static int iLSB;

- (void)getSample:(fstream&)fs Tc:(int)Tc Th:(int)Th nextAC:(int &)iNextAC
           sample:(int &)sample component:(ComponentOfJPEG&)component {
    int iCurrentBit;
    int iPorN;
    int iOffset = 0;
    HuffmanTreeNode *htnCurrenNode = htnHuffmanTreeRoot[Tc][Th];
    // Find Code and get Category
    while (htnCurrenNode->iCategory == -1) {
        iCurrentBit = [self getNextBit: fs];
        if (iCurrentBit == 0) htnCurrenNode = htnCurrenNode->htnZeroSubtree;
        else htnCurrenNode = htnCurrenNode->htnOneSubtree;
    }
    int iCategory = htnCurrenNode->iCategory;
    
    // DC situation
    if (Tc == 0) {
        if (iCategory == 0) { sample = component.iPreDC; return; }
        iPorN = [self getNextBit: fs];
        for (int i = 0; i < iCategory -1; i++) {
            iCurrentBit = [self getNextBit: fs];
            iOffset = (iOffset << 1) | iCurrentBit;
        }
        sample = component.iPreDC + iLowerBoundOfCategory[iPorN][iCategory] + iOffset;
        component.iPreDC = sample;
        return;
    }
    
    // AC situation
    if (iCategory == 0) { iNextAC = 63; sample = 0; return; }
    int iRunLength = (iCategory >> 4);
    iCategory = (iCategory & 0x0F);
    
    iNextAC = iRunLength ? iNextAC + iRunLength +1 : iNextAC +1;
    if (iCategory == 0) { sample = 0; return; }
    iPorN = [self getNextBit: fs];
    iLSB = iPorN;
    for (int i = 0; i < iCategory -1; i++) {
        iCurrentBit = [self getNextBit: fs];
        iLSB = iCurrentBit;
        iOffset = (iOffset << 1) | iCurrentBit;
    }
    
    NSMenuItem *miCurrenMethod = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).miCurrentMethod;
    switch (miCurrenMethod.tag) {
        case 1:
            [self firstMethodNeedCategory: iCategory];
            break;
        case 2:
            [self secondMethodNeedCategory: iCategory andNextAC: iNextAC];
            break;
        default:
            [self reddyMethod];
            break;
    }
    
    sample = iLowerBoundOfCategory[iPorN][iCategory] + iOffset;
}

/*******************************************************************************************************/

- (void)categoryLowerBound {
    iLowerBoundOfCategory[0][0] = 0;
    iLowerBoundOfCategory[1][0] = 0;
    
    for (int i = 1; i < 12; i++) {
        iLowerBoundOfCategory[0][i] = -1 * pow(2,i) + 1;
        iLowerBoundOfCategory[1][i] = pow(2,i-1);
    }
}

/*******************************************************************************************************/

static int iInvZigZagArray[64] = {
    0,   1,   5,  6,   14,  15,  27,  28,
    2,   4,   7,  13,  16,  26,  29,  42,
    3,   8,  12,  17,  25,  30,  41,  43,
    9,   11, 18,  24,  31,  40,  44,  53,
    10,  19, 23,  32,  39,  45,  52,  54,
    20,  22, 33,  38,  46,  51,  55,  60,
    21,  34, 37,  47,  50,  56,  59,  61,
    35,  36, 48,  49,  57,  58,  62,  63
};

- (void)deZigZag:(Block &)block andDequantization:(int)Tqi {
    Block temp;
    for (int i = 0; i < 64; i++)
        temp[i] = block[i] * iQuantizationTables[Tqi][i];
    
    for (int i = 0; i < 64; i++)
        block[i] = temp[iInvZigZagArray[i]];
    
}

/*******************************************************************************************************/
- (int)inv_FourierAtX:(int)x Y:(int)y withBlock:(Block)block {
    double dAns = 0;
    double dCu, dCv;
    
    for (int v = 0; v < 8; v++)
        for (int u = 0; u < 8; u++) {
            dCu = (u == 0)? (1 / sqrt(2)) : 1;
            dCv = (v == 0)? (1 / sqrt(2)) : 1;
            dAns += (dCu * dCv * block[v * 8 + u]
                     * cos(((2 * x + 1) * u * M_PI) / 16) * cos(((2 * y + 1) * v * M_PI) / 16));
        }
    dAns = int(dAns / 4) +128;
    if (dAns < 0) return 0;
    if (dAns > 255) return 255;
    
    return  dAns;
}

- (void)IDCT:(Block &)block {
    Block temp;
    for (int i = 0; i < 64; i++)
        temp[i] = block[i];
    
    for (int y = 0; y < 8; y++)
        for (int x = 0; x < 8; x++)
            block[y * 8 + x] = [self inv_FourierAtX:x Y:y withBlock:temp];
    
}

/*******************************************************************************************************/

- (int)getNextBit:(fstream&)fs {
    
    if (iRemainPosition == -1) {
        iRemainPosition = 7;
        fs >> ucRemain;
        
        if (ucRemain == 0xFF)
            fs >> ucNext;
    }
    
    return ((ucRemain >> iRemainPosition--) & 0x1);
}

/*******************************************************************************************************/
static int iHUFFSIZE[256];
static int iHUFFCODE[256];
static int iEHUFFCODE[256];
static int iEHUFFSIZE[256];
static int iEHUFFCODEBIT[256][16];

/*******************************************************************************************************/

- (HuffmanTreeNode *)generateHuffmanTableWithParameter:(HuffmanParameter)parameter {
    HuffmanTreeNode *huffmanTable = NULL;
    
    int iCodeLength, iCodeValue;
    string sCodeWord;
    
    // initial global variable
    for (int k = 0; k < 256; k++) { iHUFFSIZE[k] = iEHUFFSIZE[k] = 0; }
    
    // C1 procedure
    generateSizeTable(parameter.Li, iHUFFSIZE);
    
    // C2 procedure
    generateCodeTable(iHUFFSIZE, iHUFFCODE);
    
    // C3 procedure
    generateEHUFFCODEandEHUFFSIZE(iHUFFSIZE, iHUFFCODE, parameter.Vij, iEHUFFCODE, iEHUFFSIZE);
    
    // transform huffman code from dec to binary
    for (int k = 0;k < 256; k++){
        iCodeLength = iEHUFFSIZE[k];
        iCodeValue = iEHUFFCODE[k];
        for (int i= iCodeLength-1; i >= 0; i--){
            iEHUFFCODEBIT[k][i] = iCodeValue % 2;
            iCodeValue = iCodeValue / 2;
        }
    }
    
    huffmanTable = constructHuffmanTree(iEHUFFSIZE, iEHUFFCODEBIT);
    return huffmanTable;
}

/*******************************************************************************************************/

- (unsigned char)interpretMarkersWithStream:(fstream&)fs {
    unsigned char ucFF, ucMarker;
    
    fs >> ucFF;
    
    while (fs >> ucMarker) {
        
        if (ucFF != 0xFF) {
            ucFF = ucMarker;
            continue;
        }
        
        if (setMarkers.count(ucMarker))
            break;
        
        if (ucMarker >= 0xE0 && ucMarker <= 0xEF)
            break;
        
        ucFF = ucMarker;
    }
    
    return ucMarker;
}

/*******************************************************************************************************/

- (void)reset {
    for (int i = 0; i < 3; i++) {
        if (components[i].data != nil) {
            for (int row = 0; row < components[i].Y; row++)
                delete [] components[i][row];
            delete [] components[i].data;
            
            components[i].data = nil;
        }
    }
    
    for (int i = 0; i < 2; i++) for (int j = 0; j < 2; j++) {
        if (htnHuffmanTreeRoot[i][j] != nil) {
            delete htnHuffmanTreeRoot[i][j];
            htnHuffmanTreeRoot[i][j] = nil;
        }
    }
}

/*******************************************************************************************************/
#pragma mark- Stego methods

- (void)reddyMethod {
    // Find message size
    if (iSizeMask < MessageMaxSize) {
        uiMessageSize = (uiMessageSize << 1 ) | iLSB;//((ucRemain >> (iRemainPosition +1)) & 0x1);
        iSizeMask++;
    }
    // Find message
    else if (uiMessageSize > 0) {
        ucMessage = (ucMessage << 1) | iLSB;
        iMessageMask++;
        if (iMessageMask > 7) {
            fout << ucMessage;
            ucMessage = 0;
            iMessageMask = 0;
        }
        uiMessageSize--;
    }
}

/*******************************************************************************************************/

- (void)firstMethodNeedCategory:(int)iCategory {
    if (iCategory != 1) {
        [self reddyMethod];
    }
}

/*******************************************************************************************************/

- (void)secondMethodNeedCategory:(int)iCategory andNextAC:(int)iNextAC {
    // range for obique row
    static const int iRange[2][15] = {{0, 1, 3, 6, 10, 15, 21, 28, 36, 43, 49, 54, 58, 61, 63},
                                      {0, 2, 5, 9, 14, 20, 27, 35, 42, 48, 53, 57, 60, 62, 63}};

    if (iCategory != 1 && iNextAC >= iRange[0][1] && iNextAC <= iRange[1][3]) {
        [self reddyMethod];
    }
}

@end
