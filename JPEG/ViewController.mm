//
//  ViewController.m
//  JPEG
//
//  Created by MCUCSIE on 8/19/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//

#import <iostream>
#import "reader.h"
#import "ViewController.h"
#import "DQTViewController.h"
#import "DHTViewController.h"

extern set<unsigned char> setMarkers;

vector<FrameHeader> frameHeaders;
vector<ScanHeader> scanHeaders;
vector<QuantizationTable> quantizationTables;

int iHeaderCount[256];

NSSet *setValidHeader = [NSSet setWithObjects:
                         @0xD8, // SOI
                         @0xC0, // SOF
                         @0xC4, // DHT
                         @0xDA, // SOS
                         @0xDB, // DQT
                         @0xDD, // DRI
                         @0xD0, // RST
                         @0xD1, // RST
                         @0xD2, // RST
                         @0xD3, // RST
                         @0xD4, // RST
                         @0xD5, // RST
                         @0xD6, // RST
                         @0xD7, // RST
                         @0xE1, // APP
                         @0xD9, // EOI
                         nil];



@interface ViewController()

@property (strong, nonatomic) NSMutableDictionary *mdContent;
@property (weak, nonatomic) NSOpenPanel *opPanel;
@property (weak) IBOutlet NSImageView *ivTest;

@property (unsafe_unretained) IBOutlet NSTextView *tvSOF;
@property (unsafe_unretained) IBOutlet NSTextView *tvSOS;
@property (unsafe_unretained) IBOutlet NSTextView *tvDRI;

@property (weak) IBOutlet NSTextField *tfFFD8;
@property (weak) IBOutlet NSTextField *tfFFD9;
@property (weak) IBOutlet NSTextField *tfFFD0;
@property (weak) IBOutlet NSTextField *tfFFD1;
@property (weak) IBOutlet NSTextField *tfFFD2;
@property (weak) IBOutlet NSTextField *tfFFD3;
@property (weak) IBOutlet NSTextField *tfFFD4;
@property (weak) IBOutlet NSTextField *tfFFD5;
@property (weak) IBOutlet NSTextField *tfFFD6;
@property (weak) IBOutlet NSTextField *tfFFD7;
@property (weak) IBOutlet NSTextField *tfFFF8;
@property (weak) IBOutlet NSTextField *tfFFFA;
@property (weak) IBOutlet NSTextField *tfFFE1;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMenuItem *miFile = [[[NSApplication sharedApplication] mainMenu] itemWithTitle: @"File"];
    NSMenuItem *miOpen = [[miFile submenu] itemWithTitle: @"Open…"];

    [miOpen setTarget: self];
    [miOpen setAction: @selector(pickAnImage)];

}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    NSWindowController *applicationController = [[[NSApplication sharedApplication] mainWindow] windowController];

    if (applicationController == nil || self.opPanel != nil)
        return NO;

    return YES;
}

- (void)pickAnImage {

    for (int i = 0; i < 256; i++)
        iHeaderCount[i] = 0;

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

#warning remove
            fstream fs;
            fs.open([theDoc.path UTF8String], fstream::in | fstream::out);
            fs.unsetf(fstream::skipws);

            unsigned char cMarker;
            cMarker = [self interpretMarkersWithStream:fs];

            if (cMarker != SOI) return;

            while ((cMarker = [self interpretMarkersWithStream:fs]) && cMarker != EOI) {

                switch (cMarker) {
                    case SOF: {
                        FrameHeader frameHeader;
                        fs >> frameHeader;
                        frameHeaders.push_back(frameHeader);

                        //Get LF, P, Y, X, Nf
                        self.mdContent[@0xc0] =  [self.mdContent[@0xc0] stringByAppendingString:
                                                  [NSString stringWithFormat:
                                                   @"\r\rLF:%d  P:%d  Y:%d  X:%d  Nf:%d",
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
                                                       @" C%d:%d  H%d:%d  V%d:%d  Tq%d:%d",
                                                       j, components[j].Ci,
                                                       j, components[j].Hi,
                                                       j, components[j].Vi,
                                                       j, components[j].Tqi]];
                    }
                        break;

                    case SOS: {
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
                      for (int j = 0; j < scanComponents.size(); j++)
                          self.mdContent[@0xda] = [self.mdContent[@0xda] stringByAppendingString:
                                                   [NSString stringWithFormat:
                                                    @"  Cs%d:%d  Td%d:%d  Ta%d:%d",
                                                    j+1, scanComponents[j].Csj,
                                                    j+1, scanComponents[j].Tdj,
                                                    j+1, scanComponents[j].Taj]];

                      //Get Ss, Se, Ah, Al
                      self.mdContent[@0xda] = [self.mdContent[@0xda] stringByAppendingString:
                                               [NSString stringWithFormat:
                                                @"  Ss:%d  Se:%d  Ah:%d  Al:%d",
                                                scanHeader.Ss,
                                                scanHeader.Se,
                                                scanHeader.Ah,
                                                scanHeader.Al]];


                    }
                        break;

                    case DQT: {
                        QuantizationTable quantizationTable;
                        fs >> quantizationTable;
                        quantizationTables.push_back(quantizationTable);

                        //Get Lq
                        self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                                 [NSString stringWithFormat:
                                                  @"\r\rLq:%d",
                                                  quantizationTable.Lq]];

                        vector<QuantizationParameter> parameters = quantizationTable.quantizationParameters;

                        for (int i = 0; i < parameters.size(); i++) {

                            //Get Pq, Tq
                            self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                                     [NSString stringWithFormat:
                                                      @"\r\rPq:%d  Tq:%d\r",
                                                      parameters[i].Pq,
                                                      parameters[i].Tq]];

                            //Get Qk
                            for (int j = 0; j < 64; j++) {

                                self.mdContent[@0xdb] = [self.mdContent[@0xdb] stringByAppendingString:
                                                         [NSString stringWithFormat:
                                                          @"Q%d:%d  ",
                                                          j, parameters[i].Qk[j]]];
                            }
                            
                        }
                        
                    }
                        break;
                    default:
                        break;
                }
            }

            NSData *ndImage = [NSData dataWithContentsOfURL:theDoc];

            Byte *bData = (Byte *)[ndImage bytes];

            NSUInteger n = ndImage.length;

            int iCount = 0;
            for (NSUInteger i = 1; i < n; i++) {
                if (bData[i - 1] != 0xff)
                    continue;

                if ([setValidHeader containsObject:[NSNumber numberWithUnsignedChar:bData[i]]]) {

                    int iLen = (bData[i+1] << 8) | (bData[i+2]);
                    bool bSkip = true;

                    switch (bData[i]) {

                        case 0xc4: {

                            //Get Lh
                            self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                                                 [NSString stringWithFormat:@"\r\rLh:%d", iLen]];

                            int iPtr = (int)i + 2; //use a point to read data
                            static int iLi[16];
                            int iTemp;
                            while ((iPtr - i) < iLen) {

                                //Get Tc, Th
                                self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                                                     [NSString stringWithFormat:
                                                      @"\r\rTc:%d  Th:%d",
                                                      bData[iPtr+1] >> 4,
                                                      bData[iPtr+1] & 0x0f]];
                                iPtr++;

                                //Get Li
                                for (int j = 1; j <= 16; j++) {
                                    iLi[j -1] = bData[iPtr +j];

                                    self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                                                         [NSString stringWithFormat:
                                                          @"  L%d:%d",
                                                          j, bData[iPtr +j]]];
                                }

                                self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:@"\r"];

                                iPtr += 16;

                                //Get V(i,j)
                                for (int j = 0; j < 16; j++) {
                                    iTemp = iLi[j];

                                    for (int k = 1; k <= iTemp; k++)
                                        self.mdContent[@0xc4] = [self.mdContent[@0xc4] stringByAppendingString:
                                                             [NSString stringWithFormat:
                                                              @"V(%d,%d):%d  ",
                                                              j +1, k, bData[iPtr +k]]];
                                    iPtr += iTemp;
                                }

                            }
                        }
                            break;

                        case 0xdb:
                            break;

                        case 0xdd: {

                            //Get Lr, Ri
                            self.mdContent[@0xdd] = [self.mdContent[@0xdd] stringByAppendingString:
                                                 [NSString stringWithFormat:
                                                  @"\r\rLr:%d  Ri:%d",
                                                  iLen,
                                                  (bData[i +3] << 8) | (bData[i +4])]];

                        }
                            break;

                        case 0xe1:
                            break;

                        default:
                            bSkip = false;
                            break;
                    }

                    iHeaderCount[bData[i]]++;

                    iCount++;

                    //                    if (bSkip)
                    //                        i += iLen -1;
                }

            }


            DQTViewController *DQTViewController = [self.parentViewController childViewControllers][1] ;
            NSTextView *tvDQT = DQTViewController.tvDQT;

            DHTViewController *DHTViewController = [self.parentViewController childViewControllers][2] ;
            NSTextView *tvDHT = DHTViewController.tvDHT;

            [tvDHT setString:[NSString stringWithFormat:@"FFc4 Marker Count:%d%@", iHeaderCount[0xc4], self.mdContent[@0xc4]]];

            [tvDQT setString:[NSString stringWithFormat:@"FFdb Marker Count:%d%@", iHeaderCount[0xdb], self.mdContent[@0xdb]]];

            [self.tvSOF setString:[NSString stringWithFormat:@"FFc0 Marker Count:%d%@", iHeaderCount[0xc0], self.mdContent[@0xc0]]];

            [self.tvSOS setString:[NSString stringWithFormat:@"FFda Marker Count:%d%@", iHeaderCount[0xda], self.mdContent[@0xda]]];

            [self.tvDRI setString:[NSString stringWithFormat:@"FFdd Marker Count:%d%@", iHeaderCount[0xdd], self.mdContent[@0xdd]]];

            [self.tfFFD8 setStringValue:[NSString stringWithFormat:@"FFD8 Marker Count:%d", iHeaderCount[0xd8]]];
            [self.tfFFD8 sizeToFit];

            [self.tfFFD9 setStringValue:[NSString stringWithFormat:@"FFD9 Marker Count:%d", iHeaderCount[0xd9]]];
            [self.tfFFD9 sizeToFit];

            [self.tfFFD0 setStringValue:[NSString stringWithFormat:@"FFD0 Marker Count:%d", iHeaderCount[0xd0]]];
            [self.tfFFD0 sizeToFit];

            [self.tfFFD1 setStringValue:[NSString stringWithFormat:@"FFD1 Marker Count:%d", iHeaderCount[0xd1]]];
            [self.tfFFD1 sizeToFit];

            [self.tfFFD2 setStringValue:[NSString stringWithFormat:@"FFD2 Marker Count:%d", iHeaderCount[0xd2]]];
            [self.tfFFD2 sizeToFit];

            [self.tfFFD3 setStringValue:[NSString stringWithFormat:@"FFD3 Marker Count:%d", iHeaderCount[0xd3]]];
            [self.tfFFD3 sizeToFit];

            [self.tfFFD4 setStringValue:[NSString stringWithFormat:@"FFD4 Marker Count:%d", iHeaderCount[0xd4]]];
            [self.tfFFD4 sizeToFit];

            [self.tfFFD5 setStringValue:[NSString stringWithFormat:@"FFD5 Marker Count:%d", iHeaderCount[0xd5]]];
            [self.tfFFD5 sizeToFit];

            [self.tfFFD6 setStringValue:[NSString stringWithFormat:@"FFD6 Marker Count:%d", iHeaderCount[0xd6]]];
            [self.tfFFD6 sizeToFit];

            [self.tfFFD7 setStringValue:[NSString stringWithFormat:@"FFD7 Marker Count:%d", iHeaderCount[0xd7]]];
            [self.tfFFD7 sizeToFit];

            [self.tfFFF8 setStringValue:[NSString stringWithFormat:@"FFF8 Marker Count:%d", iHeaderCount[0xf8]]];
            [self.tfFFF8 sizeToFit];
            
            [self.tfFFFA setStringValue:[NSString stringWithFormat:@"FFFA Marker Count:%d", iHeaderCount[0xfa]]];
            [self.tfFFFA sizeToFit];
            
            [self.tfFFE1 setStringValue:[NSString stringWithFormat:@"FFE1 Marker Count:%d", iHeaderCount[0xe1]]];
            [self.tfFFE1 sizeToFit];
            
            NSLog(@"%d", iCount);
            
            
            
        }
        
    }];
}

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

        cFF = cMarker;
    }

    return cMarker;
}

@end
