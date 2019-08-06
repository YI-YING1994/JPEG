//
//  ViewController.m
//  JPEG
//
//  Created by MCUCSIE on 8/19/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//

#import "AppDelegate.h"
#import <iostream>
#import <string>
#import "reader.h"
#import "huffman.h"
#import "NSImage+cplusplus.h"
#import "ViewController.h"
#import "DQTViewController.h"
#import "DHTViewController.h"
#import "ImageViewController.h"

/*******************************************************************************************************/
#pragma mark- Global variables
extern set<unsigned char> setMarkers;

vector<FrameHeader> frameHeaders;
vector<ScanHeader> scanHeaders;
vector<QuantizationHeader> quantizationHeaders;
vector<HuffmanHeader> huffmanHeaders;
vector<RestartInterval> restartIntervals;
vector<Application> applications;
vector<CommentSegment> comments;
static DefineNumberOfLine defineNumberOfLine;
static HuffmanTreeNode *htnHuffmanTreeRoot[2][2] = { nil };
static int iQuantizationTables[4][64];
static int iLowerBoundOfCategory[2][12];


/*******************************************************************************************************/
#pragma mark- Property declaration
@interface ViewController()

@property (strong, nonatomic) NSMutableDictionary *mdContent;
@property (weak, nonatomic) NSOpenPanel *opPanel;
@property (weak) IBOutlet NSImageView *ivTest;

@property (unsafe_unretained) IBOutlet NSTextView *tvSOF;
@property (unsafe_unretained) IBOutlet NSTextView *tvSOS;
@property (unsafe_unretained) IBOutlet NSTextView *tvDRI;
@property (weak) IBOutlet NSTextField *app;
@property (weak) IBOutlet NSTextField *comment;

@end

/*******************************************************************************************************/

@implementation ViewController
#pragma mark- ViewController life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    NSMenuItem *miFile = [[[NSApplication sharedApplication] mainMenu] itemWithTitle: @"File"];
    NSMenuItem *miOpen = [[miFile submenu] itemWithTag: 1];
    
//    NSMenuItem *miExperiment = [[[NSApplication sharedApplication] mainMenu] itemWithTitle: @"Experiment"];
//    NSMenuItem *miOpenMultiFile = [[miExperiment submenu] itemWithTag: 0];
//    NSMenuItem *miEmbeddingDataPerTenPercent = [[miExperiment submenu] itemWithTag: 2];

    [miOpen setTarget: self];
    [miOpen setAction: @selector(pickAnImage)];
//    [miOpenMultiFile setTarget: self];
//    [miOpenMultiFile setAction: @selector(openMultiFile:)];
//    [miEmbeddingDataPerTenPercent setTarget: self];
//    [miEmbeddingDataPerTenPercent setAction: @selector(embeddingDataPerTenPercent:)];
    [self categoryLowerBound];
}

/*******************************************************************************************************/
#pragma mark- Menu item validate
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    NSWindowController *applicationController = [[[NSApplication sharedApplication] mainWindow] windowController];

    if (applicationController == nil || self.opPanel != nil)
        return NO;

    return YES;
}

/*******************************************************************************************************/
#pragma mark- Use open panel to pick image
- (void)pickAnImage {

    self.mdContent = [[NSMutableDictionary alloc] initWithDictionary: @{@0xc0:@"",
                                                                        @0xc4:@"",
                                                                        @0xda:@"",
                                                                        @0xdb:@"",
                                                                        @0xdd:@""}];

    self.opPanel = [NSOpenPanel openPanel];

    // This method displays the panel and returns immediately.
    // The completion handler is called when the user selects an
    // item or cancels the panel.
    __weak ViewController *weak_self = self;

    [self.opPanel beginWithCompletionHandler:^(NSInteger result){

        if (result == NSFileHandlingPanelOKButton) {

            NSURL*  theDoc = [[weak_self.opPanel URLs] objectAtIndex:0];

            NSLog(@"%@", theDoc);

//            [weak_self.ivTest setImage:[[NSImage alloc] initWithContentsOfURL:theDoc]];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                fout.open("/Users/maclaptop/Desktop/Stego.jpg", fstream::out | fstream::binary);
                if (fout.fail()) cout << "Create new file failed!" << endl;
                [weak_self decodeImageWithFileURL: theDoc];

                DQTViewController *DQTViewController = [weak_self.parentViewController childViewControllers][1] ;
                NSTextView *tvDQT = DQTViewController.tvDQT;

                DHTViewController *DHTViewController = [weak_self.parentViewController childViewControllers][2] ;
                NSTextView *tvDHT = DHTViewController.tvDHT;

                dispatch_async(dispatch_get_main_queue(), ^{
                    [weak_self.tvSOF setString:[NSString stringWithFormat:@"FFc0 SOF Marker Count:%lu%@",
                                           frameHeaders.size(),
                                           weak_self.mdContent[@0xc0]]];

                    [tvDHT setString:[NSString stringWithFormat:@"FFc4 DHT Marker Count:%lu%@",
                                      huffmanHeaders.size(),
                                      weak_self.mdContent[@0xc4]]];

                    [weak_self.tvSOS setString:[NSString stringWithFormat:@"FFda SOS Marker Count:%lu%@",
                                           scanHeaders.size(),
                                           weak_self.mdContent[@0xda]]];

                    [tvDQT setString:[NSString stringWithFormat:@"FFdb DQT Marker Count:%lu%@",
                                      quantizationHeaders.size(),
                                      weak_self.mdContent[@0xdb]]];

                    [weak_self.tvDRI setString:[NSString stringWithFormat:@"FFdd DRI Marker Count:%lu%@",
                                           restartIntervals.size(),
                                           weak_self.mdContent[@0xdd]]];

                    [weak_self.app setStringValue:[NSString stringWithFormat:@"App Marker Count: %lu",
                                              applications.size()]];
                    [weak_self.app sizeToFit];
                    
                    [weak_self.comment setStringValue:[NSString stringWithFormat:@"Comment Marker Count: %lu",
                                                  applications.size()]];
                    [weak_self.comment sizeToFit];
                    
                });
            });
        }
        
    }];
}

/*******************************************************************************************************/

static int iRi;
static bool bEOI;
static fstream fout;

#pragma mark- Decode image functions
- (void)decodeImageWithFileURL:(NSURL *)url {
    [self reset];

    // Declare fstream object to read binary data
    fstream fs;
    fs.open([url.path UTF8String], fstream::in | fstream::out | fstream::binary);
    fs.unsetf(fstream::skipws);
    
    unsigned char ucMarker;
    ucMarker = [self interpretMarkersWithStream:fs];
    if (ucMarker != SOI) { cout << "Not supported file format!" << endl; fout.close(); return; }

    bEOI = false;
    iRi = 0;
    bool bIsSupport = true;
    while (!bEOI && bIsSupport) {
        ucMarker = [self interpretMarkersWithStream:fs];

        if (ucMarker >= 0xE0 && ucMarker <= 0xEF)
            [self applicationHeaderHandler: fs marker: ucMarker];


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
                [self frameHeaderHandler: fs];
                break;

            case DHT:
                [self huffmanHeaderHandler: fs];
                break;

            case DAC: {
                ArithmeticTable arithmeticTable;
                fs >> arithmeticTable;
                fout << arithmeticTable;
            }
                break;

            case SOS:
                [self decodeScanWithFstream:fs];
                break;

            case DQT:
                [self quantizationTableHeaderHandler: fs];
                break;

            case DNL:
                fs >> defineNumberOfLine;
                fout << defineNumberOfLine;
                break;

            case DRI:
                [self restartIntervalHeaderHandler: fs];
                break;

            case COM: {
                CommentSegment commentSegment;
                fs >> commentSegment;
                fout << commentSegment;

                comments.push_back(commentSegment);
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
    fout << application;

    applications.push_back(application);
}

/*******************************************************************************************************/

#pragma mark- Huffman Header Handler
- (void)huffmanHeaderHandler:(fstream&)fs {
    HuffmanHeader huffmanHeader;
    fs >> huffmanHeader;
    fout << huffmanHeader;
    huffmanHeaders.push_back(huffmanHeader);

    /*
     //Get Lh
     self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
     [NSString stringWithFormat:@"\r\r%d",
     huffmanHeader.Lh]];
     */

    vector<HuffmanParameter> huffmanParameter = huffmanHeader.huffmanParameters;

    for (int j = 0; j < huffmanParameter.size(); j++) {
        /*
         //Get Tc, Th
         self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
         [NSString stringWithFormat:
         @"\r\r%d  %d",
         huffmanParameter[j].Tc,
         huffmanParameter[j].Th]];

         //Get Li
         for (int k = 1; k < 17; k++) {

         self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
         [NSString stringWithFormat:
         @"  %d",
         huffmanParameter[j].Li[k]]];
         }

         self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
         [NSString stringWithFormat:
         @"\r"]];

         //Get V(i,j)
         for (int k = 0; k < huffmanParameter[j].Vij.size(); k++)
         self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
         [NSString stringWithFormat:
         @"%d  ",
         huffmanParameter[j].Vij[k]]];
         */
        htnHuffmanTreeRoot[huffmanParameter[j].Tc][huffmanParameter[j].Th] = [self generateHuffmanTableWithParameter:huffmanParameter[j]];
    }
}

/*******************************************************************************************************/

#pragma mark- QuantizationTable Header Handler
- (void)quantizationTableHeaderHandler:(fstream&)fs {
    QuantizationHeader quantizationHeader;
    fs >> quantizationHeader;
    fout << quantizationHeader;
    quantizationHeaders.push_back(quantizationHeader);

    //Get Lq
    self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                             [NSString stringWithFormat:
                              @"\r\rLq:%d",
                              quantizationHeader.Lq]];

    vector<QuantizationParameter> parameters = quantizationHeader.quantizationParameters;

    for (int i = 0; i < parameters.size(); i++) {

        //Get Pq, Tq
        self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                 [NSString stringWithFormat:
                                  @"\r\rPq:%d  Tq:%d\r\rQk:",
                                  parameters[i].Pq,
                                  parameters[i].Tq]];

        //Get Qk
        for (int j = 0; j < 64; j++) {
            iQuantizationTables[parameters[i].Tq][j] = parameters[i].Qk[j];

            if (j % 8 == 0)
                self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                         [NSString stringWithFormat:
                                          @"\r%02d\t",
                                          parameters[i].Qk[j]]];
            else
                self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                         [NSString stringWithFormat:
                                          @"%02d\t",
                                          parameters[i].Qk[j]]];
        }
    }
}

/*******************************************************************************************************/

#pragma mark- Restart Interval Header Handler
- (void)restartIntervalHeaderHandler:(fstream&)fs {
    RestartInterval restartInterval;
    fs >> restartInterval;
    fout << restartInterval;
    iRi = restartInterval.Ri;

    restartIntervals.push_back(restartInterval);

    //Get Lr, Ri
    self.mdContent[@0xdd] = [self.mdContent[@0xdd] stringByAppendingString:
                             [NSString stringWithFormat:
                              @"\r\rLr:%d  Ri:%d",
                              restartInterval.Lr,
                              restartInterval.Ri]];
}

/*******************************************************************************************************/
int ComponentOfJPEG::Himax;
int ComponentOfJPEG::Vimax;
static ComponentOfJPEG components[3];

#pragma mark- Frame Header Handler
- (void)frameHeaderHandler:(fstream&)fs {
    FrameHeader frameHeader;
    fs >> frameHeader;
    fout << frameHeader;
    frameHeaders.push_back(frameHeader);

    //Get LF, P, Y, X, Nf
    self.mdContent[@0xc0] =  [self.mdContent[@0xc0] stringByAppendingString:
                              [NSString stringWithFormat:
                               @"\r\rLf:%d  P:%d  Y:%d  X:%d  Nf:%d",
                               frameHeader.Lf,
                               frameHeader.P,
                               frameHeader.Y,
                               frameHeader.X,
                               frameHeader.Nf]];

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
        
        self.mdContent[@0xc0] =  [self.mdContent[@0xc0] stringByAppendingString:
                                  [NSString stringWithFormat:
                                   @"\rCi:%d  Hi:%d  Vi:%d  Tqi:%d",
                                   Ci +1,
                                   Hi,
                                   Vi,
                                   Tqi]];
    }

}

/*******************************************************************************************************/

static unsigned char ucRemain, ucNext;
static int iRemainPosition;
static long long llEmbeddingBitsCount;
/*******************************************************************************************************/

- (void)decodeScanWithFstream:(fstream&)fs {
    ScanHeader scanHeader;
    fs >> scanHeader;
    fout << scanHeader;

    scanHeaders.push_back(scanHeader);

    //Get Ls, Ns
    self.mdContent[@0xda] = [self.mdContent[@0xda] stringByAppendingString:
                             [NSString stringWithFormat:
                              @"\r\rLs:%d  Ns:%d",
                              scanHeader.Ls,
                              scanHeader.Ns]];

    vector<ScanComponentParameter> scanComponents = scanHeader.scanComponentParameters;

    //Get Cs, Td, Ta
    for (int j = 0; j < scanHeader.Ns; j++)
        self.mdContent[@0xda] = [self.mdContent[@0xda] stringByAppendingString:
                                 [NSString stringWithFormat:
                                  @"\rCs:%d  Td:%d  Ta:%d",
                                  scanComponents[j].Csj,
                                  scanComponents[j].Tdj,
                                  scanComponents[j].Taj]];

    //Get Ss, Se, Ah, Al
    self.mdContent[@0xda] = [self.mdContent[@0xda] stringByAppendingString:
                             [NSString stringWithFormat:
                              @"\rSs:%d  Se:%d  Ah:%d  Al:%d",
                              scanHeader.Ss,
                              scanHeader.Se,
                              scanHeader.Ah,
                              scanHeader.Al]];


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
    llEmbeddingBitsCount = 0;

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
                fs >> ucRST;
                fout << ucRST;
                
                fs >> ucRST;
                fout << ucRST;
            }
        }
    }
    cout << "Finished..." << endl;

    int row = frameHeaders[0].Y;
    int col = frameHeaders[0].X;
    cout << row << " " << col << endl;
//    cout << "Embedding limit: " << llEmbeddingLimit << endl;
    cout << "Embedding count: " << llEmbeddingBitsCount << endl;
    
    bool bIsRGB = (scanHeader.Ns > 1);
    Byte *bData = new Byte[(bIsRGB ? 3 : 1) * row * col];
    
    int iY, iCb, iCr;
    int iR, iG, iB;
    for (int i = 0; i < row; i++) {
        for (int j = 0; j < col; j++) {
            // cout << i * components[1].Vi / components[1].Vimax << endl;
            if (bIsRGB) {
                iY = components[0][i * components[0].Vi / components[0].Vimax][j * components[0].Hi / components[0].Himax];
                iCb = components[1][i * components[1].Vi / components[1].Vimax][j * components[1].Hi / components[1].Himax];
                iCr = components[2][i * components[2].Vi / components[2].Vimax][j * components[2].Hi / components[2].Himax];
                
                iR = ((298 * (iY -16) + 409 * (iCr -128) +128) >> 8);
                iG = ((298 * (iY -16) - 100 * (iCb -128) - 208 * (iCr -128) +128) >> 8);
                iB = ((298 * (iY -16) + 516 * (iCb -128) +128) >> 8);
                
                iR = [self clip: iR];
                iG = [self clip: iG];
                iB = [self clip: iB];
                
                bData[i * col * 3 + j * 3] = iR;
                bData[i * col * 3 + j * 3 +1] = iG;
                bData[i * col * 3 + j * 3 +2] = iB;
            }
            else
                bData[i * col + j] = [self clip: components[0][i][j]];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        ImageViewController *imageViewController = [self.parentViewController childViewControllers][3] ;
        NSImageView *ivImageView = imageViewController.ivResolveImage;
        [ivImageView setImage:[NSImage imageWithData:bData row: row andColumn: col colorspace: bIsRGB ? ColorSpaceRGB : ColorSpaceGray]];
    });
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

- (void)getSample:(fstream&)fs Tc:(int)Tc Th:(int)Th nextAC:(int &)iNextAC
           sample:(int &)sample component:(ComponentOfJPEG&)component {
    int iCurrentBit = 0;
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
    for (int i = 0; i < iCategory -1; i++) {
        iCurrentBit = [self getNextBit: fs];
        iOffset = (iOffset << 1) | iCurrentBit;
    }

    NSMenuItem *miCurrenMethod = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).miCurrentMethod;
    switch (miCurrenMethod.tag) {
        case 1:
            [self firstMethodNeedCategory: iCategory andCurrentBit: iCurrentBit andPorN: iPorN];
            break;
        case 2:
            break;
        default:
            [self reddyMethodNeedCategor: iCategory andCurrentBit: iCurrentBit andPorN: iPorN];
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
        fout << ucRemain;

        if (ucRemain == 0xFF) {
            fs >> ucNext;
            fout << ucNext;
        }
        
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

    // Display huffman category and code word
    self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                             [NSString stringWithFormat:@"\r\r%-16s\t\t%8s",
                             "Category", "Codeword"]];
    for (int k = 0; k < 256; k++) {
        iCodeLength = iEHUFFSIZE[k];
        if (iCodeLength != 0) {
            sCodeWord = "";
            for (int i = 0; i < iCodeLength; i++)
                sCodeWord += to_string(iEHUFFCODEBIT[k][i]);
            self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                                     [NSString stringWithFormat:@"\r%-40X%s",
                                      k, sCodeWord.c_str()]];
        }
    }

    return huffmanTable;
}

/*******************************************************************************************************/

- (unsigned char)interpretMarkersWithStream:(fstream&)fs {
    unsigned char ucFF, ucMarker;

    fs >> ucFF;
    fout << ucFF;

    while (fs >> ucMarker) {
        fout << ucMarker;
        
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
    frameHeaders.clear();
    scanHeaders.clear();
    quantizationHeaders.clear();
    huffmanHeaders.clear();
    restartIntervals.clear();
    applications.clear();
    comments.clear();
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
//#pragma mark- Experiment function
//- (IBAction)openMultiFile:(NSMenuItem *)sender {
//    NSURL *baseCoverURL = [NSURL fileURLWithPath: @"/Users/maclaptop/Google Drive/ProjectResearch/Experiment/cover"];
//    string baseStegoPath = "/Users/maclaptop/Desktop/stego/";
//    NSURL *coverURL;
//    string stegoPath;
//    static const string sImages[4] = {"/barbara.jpg", "/cameraman.jpg", "/lena.jpg", "/baboon.jpg" };
//    for (int j = 0; j < 4; j++, cout << endl) {
//        cout << sImages[j].substr(1) << ":" << endl;
//        for (int i = 1; i <= 10; i++) {
//            coverURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%i%s", i * 10, sImages[j].c_str()] relativeToURL:baseCoverURL];
//            stegoPath = baseStegoPath + to_string(i * 10) + sImages[j];
//            fout.open(stegoPath, fstream::out | fstream::binary);
//            if (fout.fail()) cout << "Create new file failed!" << endl;
//            [self decodeImageWithFileURL: coverURL];
//        }
//    }
//}

/*******************************************************************************************************/
//static long long llEmbeddingLimit;
//
//- (IBAction)embeddingDataPerTenPercent:(NSMenuItem *)sender {
//    NSURL *coverURL = [NSURL fileURLWithPath: @"/Users/maclaptop/Desktop/cover/baboon.jpg"];
//    string baseStegoPath = "/Users/maclaptop/Desktop/stego/";
//    string stegoPath;
//    static const long long llMaxCapacity[4] = {29421,6385, 19634, 51839};
//
//    for (int i = 1; i <= 10; i++) {
//        stegoPath = baseStegoPath + "baboon" + to_string(i) + ".jpg";
//        llEmbeddingLimit = llMaxCapacity[3] * i * 0.1;
//        fout.open(stegoPath, fstream::out | fstream::binary);
//        if (fout.fail()) cout << "Create new file failed!" << endl;
//        [self decodeImageWithFileURL: coverURL];
//    }
//
//}

/*******************************************************************************************************/
#pragma mark- Stego methods

- (void)reddyMethodNeedCategor:(int)iCategory andCurrentBit:(int)iCurrentBit andPorN:(int)iPorN {
//        if (llEmbeddingBitsCount >= llEmbeddingLimit) return ;
    
        // embedding message bits
        long pos = fout.tellp();
        pos = (ucRemain == 0xFF) ? pos - 2 : pos -1;
        fout.seekp(pos);
        unsigned char ucMask;
        unsigned char ucTemp;
        
        if (iCategory == 1) iCurrentBit = iPorN;
        
        if (iCurrentBit != 1) {
            // embedding bit 1
            ucMask = 1 << (iRemainPosition +1);
            ucTemp = ucRemain | ucMask;
        }
        else  {
            // embedding bit 0
            ucMask = ((1 << (iRemainPosition +1)) ^ 0xFF);
            ucTemp = ucRemain & ucMask;
        }
        fout << ucTemp;
        if (ucTemp == 0xFF) fout << (char)0x00;
        ucRemain = ucTemp;
        llEmbeddingBitsCount++;
}

/*******************************************************************************************************/

- (void)firstMethodNeedCategory:(int)iCategory andCurrentBit:(int)iCurrentBit andPorN:(int)iPorN {
//    if (llEmbeddingBitsCount > llEmbeddingLimit) return ;

    if (iCategory != 1) {
        [self reddyMethodNeedCategor: iCategory andCurrentBit: iCurrentBit andPorN: iPorN];
    }
}

/*******************************************************************************************************/

@end
