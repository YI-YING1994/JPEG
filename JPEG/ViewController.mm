//
//  ViewController.m
//  JPEG
//
//  Created by MCUCSIE on 8/19/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//

#import <iostream>
#import <unordered_map>
#import "huffman.h"
#import "reader.h"
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
unordered_map<int, unsigned char> huffmanTables[2][2];


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

            [self.ivTest setImage:[[NSImage alloc] initWithContentsOfURL:theDoc]];

            [self decodeImageWithFileURL: theDoc];

            DQTViewController *DQTViewController = [self.parentViewController childViewControllers][1] ;
            NSTextView *tvDQT = DQTViewController.tvDQT;

            DHTViewController *DHTViewController = [self.parentViewController childViewControllers][2] ;
            NSTextView *tvDHT = DHTViewController.tvDHT;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tvSOF setString:[NSString stringWithFormat:@"FFc0 SOF Marker Count:%lu%@",
                                       frameHeaders.size(),
                                       self.mdContent[@0xc0]]];

                [tvDHT setString:[NSString stringWithFormat:@"FFc4 DHT Marker Count:%lu%@",
                                  huffmanHeaders.size(),
                                  self.mdContent[@0xc4]]];

                [self.tvSOS setString:[NSString stringWithFormat:@"FFda SOS Marker Count:%lu%@",
                                       scanHeaders.size(),
                                       self.mdContent[@0xda]]];

                [tvDQT setString:[NSString stringWithFormat:@"FFdb DQT Marker Count:%lu%@",
                                  quantizationHeaders.size(),
                                  self.mdContent[@0xdb]]];

                [self.tvDRI setString:[NSString stringWithFormat:@"FFdd DRI Marker Count:%lu%@",
                                       restartIntervals.size(),
                                       self.mdContent[@0xdd]]];

                [self.app setStringValue:[NSString stringWithFormat:@"App Marker Count: %lu",
                                          applications.size()]];
                [self.app sizeToFit];

                [self.comment setStringValue:[NSString stringWithFormat:@"Comment Marker Count: %lu",
                                          applications.size()]];
                [self.comment sizeToFit];

            });
        }
        
    }];
}

/*******************************************************************************************************/
#pragma mark- Decode image functions
- (void)decodeImageWithFileURL:(NSURL *)url {
    [self reset];

    fstream fs;
    fs.open([url.path UTF8String], fstream::in | fstream::out);
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
                                           @"\r\r%d  %d  %d  %d  %d",
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
                                               @"\r%d  %d  %d  %d",
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

                //Get Lh
                self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                                         [NSString stringWithFormat:@"\r\r%d",
                                          huffmanHeader.Lh]];

                vector<HuffmanParameter> huffmanParameter = huffmanHeader.huffmanParameters;


                for (int j = 0; j < huffmanParameter.size(); j++) {

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

                    huffmanTables[huffmanParameter[j].Tc][huffmanParameter[j].Th] = [self generateHuffmanTableWithParameter:
                                                                                     huffmanParameter[j]];
                }


            }
                break;

            case DAC: {
                ArithmeticTable arithmeticTable;
                fs >> arithmeticTable;
            }
                break;

            case SOS: {
                ScanHeader scanHeader;
                fs >> scanHeader;

                scanHeaders.push_back(scanHeader);

                //Get Ls, Ns
                self.mdContent[@0xda] = [self.mdContent[@0xda] stringByAppendingString:
                                         [NSString stringWithFormat:
                                          @"\r\r%d  %d",
                                          scanHeader.Ls,
                                          scanHeader.Ns]];

                vector<ScanComponentParameter> scanComponents = scanHeader.scanComponentParameters;

                //Get Cs, Td, Ta
                for (int j = 0; j < scanComponents.size(); j++)
                    self.mdContent[@0xda] = [self.mdContent[@0xda] stringByAppendingString:
                                             [NSString stringWithFormat:
                                              @"  %d  %d  %d",
                                              scanComponents[j].Csj,
                                              scanComponents[j].Tdj,
                                              scanComponents[j].Taj]];

                //Get Ss, Se, Ah, Al
                self.mdContent[@0xda] = [self.mdContent[@0xda] stringByAppendingString:
                                         [NSString stringWithFormat:
                                          @"  %d  %d  %d  \%d",
                                          scanHeader.Ss,
                                          scanHeader.Se,
                                          scanHeader.Ah,
                                          scanHeader.Al]];


            }
                break;

            case DQT: {
                QuantizationHeader quantizationHeader;
                fs >> quantizationHeader;
                quantizationHeaders.push_back(quantizationHeader);

                //Get Lq
                self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                         [NSString stringWithFormat:
                                          @"\r\r%d",
                                          quantizationHeader.Lq]];

                vector<QuantizationParameter> parameters = quantizationHeader.quantizationParameters;

                for (int i = 0; i < parameters.size(); i++) {

                    //Get Pq, Tq
                    self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                             [NSString stringWithFormat:
                                              @"\r\r%d  %d",
                                              parameters[i].Pq,
                                              parameters[i].Tq]];

                    //Get Qk
                    for (int j = 0; j < 64; j++) {

                        if (j % 8 == 0)
                            self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                                     [NSString stringWithFormat:
                                                      @"\r%d  ",
                                                      parameters[i].Qk[j]]];
                        else
                            self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                                     [NSString stringWithFormat:
                                                      @"%d  ",
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
                                          @"\r\r%d  %d",
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

- (unordered_map<int, unsigned char>)generateHuffmanTableWithParameter:(HuffmanParameter)parameter {
    unordered_map<int, unsigned char> huffmanTable;

    int iSize = (int)parameter.Vij.size();

    int *iHUFFSIZE = new int[iSize + 1];
    int *iHUFFCODE = new int[iSize + 1];
    int *iEHUFCO = new int[iSize + 1];
    int *iEHUFVAL = new int[iSize + 1];

    iHUFFSIZE[iSize] = iHUFFCODE[iSize] = iEHUFCO[iSize] = iEHUFVAL[iSize] = 0;

    int iLastK = generateSizeTable(parameter.Li, iHUFFSIZE);

    generateCodeTable(iHUFFSIZE, iHUFFCODE);

    generateEHUFCOandEHUFSI(iHUFFSIZE, iHUFFCODE, parameter.Vij, iEHUFCO, iEHUFVAL, iLastK);

    for (int i = 0; i < iSize; i++)
        huffmanTable[iEHUFCO[i]] = iEHUFVAL[i];

    delete[] iHUFFSIZE;
    delete[] iHUFFCODE;
    delete[] iEHUFCO;
    delete[] iEHUFVAL;

    return huffmanTable;
}

/*******************************************************************************************************/

- (unsigned char)interpretMarkersWithStream:(fstream&) fs {
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
