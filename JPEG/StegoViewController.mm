//
//  StegoViewController.m
//  JPEG
//
//  Created by MacLaptop on 2019/1/25.
//  Copyright © 2019 MCUCSIE. All rights reserved.
//

#import <iostream>
#import "Embedder.h"
#import "Extractor.h"
#import "StegoViewController.h"
using namespace std;

#pragma mark- Property declaration
@interface StegoViewController ()

@property (weak) IBOutlet NSTextField *tfCoverPath;
@property (weak) IBOutlet NSTextField *tfMessagePath;
@property (weak) IBOutlet NSTextField *tfStegoPath;
@property (weak, nonatomic) NSOpenPanel *opPanel;

@end

/*******************************************************************************************************/

@implementation StegoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

/*******************************************************************************************************/
#pragma mark- Use open panel to pick image

- (IBAction)selectFile:(NSButton *)sender {
    self.opPanel = [NSOpenPanel openPanel];
    
    // This method displays the panel and returns immediately.
    // The completion handler is called when the user selects an
    // item or cancels the panel.
    __weak StegoViewController *weak_self = self;
    
    [self.opPanel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL*  theDoc = [[weak_self.opPanel URLs] objectAtIndex:0];
            
            NSLog(@"%@", theDoc);
            switch (sender.tag) {
                case 0:
                    [weak_self.tfCoverPath setStringValue:theDoc.path];
                    break;
                case 1:
                    [weak_self.tfMessagePath setStringValue:theDoc.path];
                    break;
                case 2:
                    [weak_self.tfStegoPath setStringValue:theDoc.path];
                    break;
            }
        }
    }];
    
}

/*******************************************************************************************************/
#pragma mark- Embedding Message

- (IBAction)embeddingMessage:(NSButton *)sender {
    if ([self.tfCoverPath.stringValue.lastPathComponent  isEqual: @"Cover Media Path:"]) {
        cout << "Please select a Cover Media" << endl;
        return ;
    }
    if ([self.tfMessagePath.stringValue.lastPathComponent isEqualToString:@"Message File Path:"]) {
        cout << "Please select a message file" << endl;
        return ;
    }
    
    NSString *coverPath = self.tfCoverPath.stringValue;
    NSString *messagePath = self.tfMessagePath.stringValue;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Embedder *embeder = [[Embedder alloc] init];
        [embeder embeddingMessage: messagePath
                          withCover: coverPath];
    });
    
}

/*******************************************************************************************************/
#pragma mark- Extractting Message

- (IBAction)extracttingMessage:(NSButton *)sender {
    if ([self.tfStegoPath.stringValue.lastPathComponent isEqualToString:@"Stego Media Path:"]) {
        cout << "Please select a stego image" << endl;
        return ;
    }
    
    NSString *stegoPath = self.tfStegoPath.stringValue;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Extractor *extracter = [[Extractor alloc] init];
        [extracter extracttingMessageFrom: stegoPath];
    });
}

@end
