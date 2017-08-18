//
//  AppDelegate.m
//  JPEG
//
//  Created by MCUCSIE on 8/19/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface AppDelegate ()

@property (strong, nonatomic) NSWindowController *mainController;

@end

@implementation AppDelegate

- (IBAction)newWindow:(id)sender {
    NSWindowController *applicationController = [[[NSApplication sharedApplication] mainWindow] windowController];

    if (applicationController == nil) {

        applicationController = [[NSStoryboard storyboardWithName:@"Main"
                                                   bundle:[NSBundle mainBundle]]
                         instantiateControllerWithIdentifier:@"MainView"];
        self.mainController = applicationController;
    }

    [self.mainController showWindow: self];

}

@end
