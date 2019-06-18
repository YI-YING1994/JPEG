//
//  AppDelegate.m
//  JPEG
//
//  Created by MCUCSIE on 8/19/17.
//  Copyright © 2017 MCUCSIE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

#define DefaultMethod 2

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

- (IBAction)chooseMethod:(NSMenuItem *)sender {
    [self.miCurrentMethod setState: NSControlStateValueOff];
    [sender setState: NSControlStateValueOn];
    self.miCurrentMethod = sender;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSMenuItem *miMethod = [[[NSApplication sharedApplication] mainMenu] itemWithTitle: @"Method"];
    NSMenuItem *miReddyMethod = [[miMethod submenu] itemWithTag: DefaultMethod];
    self.miCurrentMethod = miReddyMethod;
    [self.miCurrentMethod setState: NSControlStateValueOn];
}

@end
