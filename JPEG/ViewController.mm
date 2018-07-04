//
//  ViewController.m
//  JPEG
//
//  Created by MCUCSIE on 8/19/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//

#import <iostream>
#import <string>
#import <unordered_map>
#import "huffman.h"
#import "reader.h"
#import "NSImage+cplusplus.h"
#import "ViewController.h"
#import "DQTViewController.h"
#import "DHTViewController.h"

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
DefineNumberOfLine defineNumberOfLine;
unordered_map<string, unsigned char> huffmanTables[2][2];
int iQuantizationTables[4][64];


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
    NSMenuItem *miOpen = [[miFile submenu] itemWithTitle: @"Open…"];

    [miOpen setTarget: self];
    [miOpen setAction: @selector(pickAnImage)];

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
#pragma mark- Decode image functions
- (void)decodeImageWithFileURL:(NSURL *)url {
    [self reset];

    // Declare fstream object to read binary data
    fstream fs;
    fs.open([url.path UTF8String], fstream::in | fstream::out | fstream::binary);
    fs.unsetf(fstream::skipws);

    unsigned char cMarker;
    cMarker = [self interpretMarkersWithStream:fs];

    if (cMarker != SOI) return;

    while ((cMarker = [self interpretMarkersWithStream:fs]) && cMarker != EOI) {

        if (cMarker >= 0xE0 && cMarker <= 0xEF) {
            Application application;
            application.marker = cMarker;
            fs >> application;

            applications.push_back(application);
        }

        switch (cMarker) {
            case SOF: {
                FrameHeader frameHeader;
                fs >> frameHeader;
                frameHeaders.push_back(frameHeader);

                //Get LF, P, Y, X, Nf
                self.mdContent[@0xc0] =  [self.mdContent[@0xc0] stringByAppendingString:
                                          [NSString stringWithFormat:
                                           @"\r\rLf:%d  P:%d  X:%d  Y:%d  Nf:%d",
                                           frameHeader.Lf,
                                           frameHeader.P,
                                           frameHeader.Y,
                                           frameHeader.X,
                                           frameHeader.Nf]];

                //Get Ci, Hi, Vi, Tqi
                vector<ComponentParameter> components = frameHeader.componentParameters;

                for (int j = 0; j < components.size(); j++)
                    self.mdContent[@0xc0] =  [self.mdContent[@0xc0] stringByAppendingString:
                                              [NSString stringWithFormat:
                                               @"\rCi:%d  Hi:%d  Vi:%d  Tqi:%d",
                                               components[j].Ci,
                                               components[j].Hi,
                                               components[j].Vi,
                                               components[j].Tqi]];
            }
                break;

            case DHT: {
                HuffmanHeader huffmanHeader;
                fs >> huffmanHeader;
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
                    huffmanTables[huffmanParameter[j].Tc][huffmanParameter[j].Th] = [self generateHuffmanTableWithParameter:huffmanParameter[j]];
                }


            }
                break;

            case DAC: {
                ArithmeticTable arithmeticTable;
                fs >> arithmeticTable;
            }
                break;

            case SOS:
                [self decodeScanWithFstream:fs];
                break;

            case DQT: {
                QuantizationHeader quantizationHeader;
                fs >> quantizationHeader;
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
                break;

            case DNL:
                fs >> defineNumberOfLine;
                break;

            case DRI: {
                RestartInterval restartInterval;
                fs >> restartInterval;
                restartIntervals.push_back(restartInterval);

                //Get Lr, Ri
                self.mdContent[@0xdd] = [self.mdContent[@0xdd] stringByAppendingString:
                                         [NSString stringWithFormat:
                                          @"\r\rLr:%d  Ri:%d",
                                          restartInterval.Lr,
                                          restartInterval.Ri]];

            }
                break;

            case COM: {
                CommentSegment commentSegment;
                fs >> commentSegment;

                comments.push_back(commentSegment);
            }
                break;

            default:
                break;
        }
    }
}

/*******************************************************************************************************/

struct Block {
    int iSamples[64];
};

struct DataUnitsOfComponentInAMCU {
    vector<Block> dataUnits;
};

struct ComponentOfJPEG {
    int X;
    int Y;
    int H;
    int V;
    int size() { return X * Y; }
    int dataUnitsSize() { return H * V; }

    int iTdj;
    int iTaj;
    int iTqi;
    int iPreDC = 0;
    vector<DataUnitsOfComponentInAMCU> totalDataUnits;
};

vector<ComponentOfJPEG> components;
unsigned char ucRemain, ucNext;
int iRemainPosition;
int iPreDC;

/*******************************************************************************************************/

- (void)decodeScanWithFstream:(fstream&)fs {
    ScanHeader scanHeader;
    fs >> scanHeader;

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


    vector<ComponentOfJPEG> componentsInAScan;
    int X;
    int Y;
    int Ri = (restartIntervals.size()) ? restartIntervals.back().Ri : 1;
    int Csj, Tdj, Taj;
    int Hi, Vi, Tqi;


    for (int i = 0; i < scanHeader.Ns; i++) {
        ComponentOfJPEG component;
        X = frameHeaders[0].X;
        Y = frameHeaders[0].Y;
        Csj = scanComponents[i].Csj;
        Tdj = scanComponents[i].Tdj;
        Taj = scanComponents[i].Taj;
        Hi = frameHeaders[0].componentParameters[Csj - 1].Hi;
        Vi = frameHeaders[0].componentParameters[Csj - 1].Vi;
        Tqi = frameHeaders[0].componentParameters[Csj - 1].Tqi;

        X = (X % 8 == 0) ? X / 8 : (X + 8 - X % 8) / 8;
        Y = (Y % 8 == 0) ? Y / 8 : (Y + 8 - Y % 8) / 8;
        X = (X % Hi == 0) ? X / Hi : (X + Hi - X % Hi) / Hi;
        Y = (Y % Vi == 0) ? Y / Vi : (Y + Vi - Y % Vi) / Vi;

        component.X = X;
        component.Y = Y;
        component.H = Hi;
        component.V = Vi;
        component.iTdj = Tdj;
        component.iTaj = Taj;
        component.iTqi = Tqi;
        componentsInAScan.push_back(component);
        cout << "Tdj: " << Tdj << " Taj: " << Taj << endl;
    }

    bool bIsFinished = false;
    int iMCUCount = 1, iCount = 1;
    iRemainPosition = -1;
    unsigned char ucRST;

    while (true) {
        if (iMCUCount % Ri == 1)
            iMCUCount = 1;

        iMCUCount++;
        cout << "MCU: " << iCount++ << endl;

        for (int i = 0; i < scanHeader.Ns; i++) {
            DataUnitsOfComponentInAMCU dataUnitsOfComponentInAMCU;

            cout << "component start : " << i << " tellg: " << fs.tellg() << endl;
            while (dataUnitsOfComponentInAMCU.dataUnits.size() < componentsInAScan[i].dataUnitsSize())
                dataUnitsOfComponentInAMCU.dataUnits.push_back([self getBlock:fs
                                                                    component:componentsInAScan[i]]);

            componentsInAScan[i].totalDataUnits.push_back(dataUnitsOfComponentInAMCU);

            if (componentsInAScan[i].totalDataUnits.size() == componentsInAScan[i].size())
                bIsFinished = true;
        }

        if (bIsFinished) break;

        if (iMCUCount == Ri+1) {
            cout << "tellg: " << fs.tellg() << endl;
            cout << hex << (int)ucRemain << " " << (int)ucNext << " iRemain: " << dec << iRemainPosition << endl;

            iRemainPosition = -1;
            fs >> ucRST >> ucRST;
            componentsInAScan[0].iPreDC = 0;
            componentsInAScan[1].iPreDC = 0;
            componentsInAScan[2].iPreDC = 0;
        }

    }

    cout << "Finished..." << endl;

    Byte *data = [self transformComponentToByteArray:componentsInAScan[0]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ivTest setImage:[NSImage imageWithData:data row: componentsInAScan[0].X * 8 andColumn: componentsInAScan[0].Y * 8]];
    });

    for (int i = 0; i < scanHeader.Ns; i++)
        components.push_back(componentsInAScan[i]);

}

/*******************************************************************************************************/

- (Byte *)transformComponentToByteArray:(ComponentOfJPEG)component {
    Byte *data = (Byte *)malloc(component.X * component.Y * 64);

    for (int x = 0; x < component.X; x++)
        for (int y = 0; y < component.Y; y++, cout << endl)
            for (int i = 0; i < 8; i++, cout << endl)
                for (int j = 0; j < 8; j++)
                    cout << component.totalDataUnits[x * component.Y + y].dataUnits[0].iSamples[i * 8 + j] << "\t";


    for (int x = 0; x < component.X; x++)
        for (int y = 0; y < component.Y; y++)
            for (int i = 0; i < 8; i++)
                for (int j = 0; j < 8; j++)
                    data[i * 8 * component.Y + x * 64 * component.Y + j + y * 8] =
                    component.totalDataUnits[x * component.Y + y].dataUnits[0].iSamples[i * 8 + j];
    return data;
}

/*******************************************************************************************************/

- (Block)getBlock:(fstream&)fs component:(ComponentOfJPEG&)component {
    Block block;

    int iSampleCount = 0;
    int iTaj = component.iTaj;
    int iTdj = component.iTdj;
    vector<int> samples;

    while (iSampleCount < 64) {
        if (iSampleCount == 0) {
            iPreDC = component.iPreDC;
            [self getSamples:fs Tc:0 Th:iTdj samples:samples];
            component.iPreDC = iPreDC;
        }
        else
            [self getSamples:fs Tc:1 Th:iTaj samples:samples];

        if (samples.size() == 0) {
            while (iSampleCount < 64)
                block.iSamples[iSampleCount++] = 0;
            break;
        }

        for (int i = 0; i < samples.size(); i++)
            block.iSamples[iSampleCount++] = samples[i];
    }

    [self deZigZag:block andDequantization:component.iTqi];
    [self IDCT:block];

    //    for (int i = 0; i < 8; i++, cout << endl)
    //        for (int j = 0; j < 8; j++)
    //            cout << block.iSamples[i * 8 +j] << "\t";


    return block;
}

/*******************************************************************************************************/

- (void)getSamples:(fstream&)fs Tc:(int)Tc Th:(int)Th samples:(vector<int>&)samples {

    string sCode = "";
    samples.clear();

    // Find Code and get Category
    while (true) {
        if (iRemainPosition == -1)
            [self remainInit:fs];

        sCode += to_string((ucRemain >> iRemainPosition--) & 0x1);
        if (huffmanTables[Tc][Th].count(sCode))
            break;
    }

    unsigned char ucCategory = huffmanTables[Tc][Th][sCode];

    bool bSign = false;
    int iExtraBit = (!Tc) ? ucCategory : ucCategory & 0xF;
    int iOffSet = 0;

    if (iExtraBit) {
        if (iRemainPosition == -1)
            [self remainInit:fs];
        bSign = (ucRemain >> iRemainPosition--) & 0x1;
    }
    while (iExtraBit -1 > 0) {
        if (iRemainPosition == -1)
            [self remainInit:fs];
        iOffSet = ((ucRemain >> iRemainPosition--) & 0x1) + (iOffSet << 1);
        iExtraBit--;
    }

    iExtraBit = (!Tc) ? ucCategory : ucCategory & 0xF;

    if (iExtraBit)
        iOffSet = bSign ? iOffSet + pow(2, iExtraBit - 1) : iOffSet - pow(2, iExtraBit) + 1;

    if (Tc) {
        int iRunLength = ucCategory >> 4;

        //        cout << "RunLength: " << iRunLength << " AC: " << iOffSet << endl;

        if (iRunLength == 0 && iOffSet == 0)
            return ;

        for (int i = 0; i < iRunLength; i++)
            samples.push_back(0);
    } else {
        iOffSet += iPreDC;
        iPreDC = iOffSet;

        //        cout << "DC: " << iOffSet << endl;
    }

    samples.push_back(iOffSet);
}

/*******************************************************************************************************/

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

- (void)deZigZag:(Block &)block andDequantization:(int)Tqi {
    Block temp;
    for (int i = 0; i < 64; i++)
        temp.iSamples[i] = block.iSamples[i];

    for (int i = 0; i < 64; i++)
        block.iSamples[i] = temp.iSamples[ZigZagArray[i]] * iQuantizationTables[Tqi][i];

}

/*******************************************************************************************************/
- (int)fourierAtX:(int)x Y:(int)y withBlock:(Block)block {
    double dAns = 0;
    double dCu, dCv;

    for (int v = 0; v < 8; v++)
        for (int u = 0; u < 8; u++) {
            dCu = (u == 0)? (1 / sqrt(2)) : 1;
            dCv = (v == 0)? (1 / sqrt(2)) : 1;
            dAns += (dCu * dCv * block.iSamples[v * 8 + u]
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
        temp.iSamples[i] = block.iSamples[i];

    for (int y = 0; y < 8; y++)
        for (int x = 0; x < 8; x++)
            block.iSamples[y * 8 + x] = [self fourierAtX:x Y:y withBlock:temp];

}

/*******************************************************************************************************/

- (void)remainInit:(fstream&)fs {

    iRemainPosition = 7;
    fs >> ucRemain;

    if (ucRemain == 0xFF)
        fs >> ucNext;
}

/*******************************************************************************************************/

- (unordered_map<string, unsigned char>)generateHuffmanTableWithParameter:(HuffmanParameter)parameter {
    unordered_map<string, unsigned char> huffmanTable;

    int iSize = (int)parameter.Vij.size();

    int *iHUFFSIZE = new int[iSize + 1];
    int *iHUFFCODE = new int[iSize + 1];
    string *sEHUFCO = new string[iSize + 1];
    int *iEHUFVAL = new int[iSize + 1];

    iHUFFSIZE[iSize] = iHUFFCODE[iSize] = iEHUFVAL[iSize] = 0;
    sEHUFCO[iSize] = "";

    int iLastK = generateSizeTable(parameter.Li, iHUFFSIZE);

    generateCodeTable(iHUFFSIZE, iHUFFCODE);

    generateEHUFCOandEHUFSI(iHUFFSIZE, iHUFFCODE, parameter.Vij, sEHUFCO, iEHUFVAL, iLastK);

    for (int i = 0; i < iSize; i++)
        huffmanTable[sEHUFCO[i]] = iEHUFVAL[i];

    self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                             [NSString stringWithFormat:@"\r\r%-16s\t\t%8s",
                             "Category", "Codeword"]];

    for (int i = 0; i < iSize; i++) {
        self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                                 [NSString stringWithFormat:@"\r%-40X%s",
                                  huffmanTable[sEHUFCO[i]], sEHUFCO[i].c_str()]];
    }

    delete[] iHUFFSIZE;
    delete[] iHUFFCODE;
    delete[] sEHUFCO;
    delete[] iEHUFVAL;

    return huffmanTable;
}

/*******************************************************************************************************/

- (unsigned char)interpretMarkersWithStream:(fstream&)fs {
    unsigned char cFF, cMarker;

    fs >> cFF;

    while (fs >> cMarker) {
        if (cFF != 0xFF) {
            cFF = cMarker;
            continue;
        }

        if (setMarkers.count(cMarker))
            break;

        if (cMarker >= 0xE0 && cMarker <= 0xEF)
            break;

        cFF = cMarker;
    }

    return cMarker;
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

    for (int i = 0; i < 2; i++)
        for (int j = 0; j < 2; j++)
            huffmanTables[i][j].clear();
}

@end
