//
//  main.m
//  cd to ...
//
//  Created by James Tuley on 10/9/19.
//  Copyright © 2019 Jay Tuley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import <unistd.h>

#import "Finder.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        FinderApplication* finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.Finder"];

        FinderItem *target = [(NSArray*)[[finder selection] get] firstObject];
        FinderFinderWindow* findWin = [[finder FinderWindows] objectAtLocation:@1];
        findWin = [[finder FinderWindows] objectWithID:[NSNumber numberWithInteger: findWin.id]];
        bool selected = true;
        if (target == nil){
            target = [[findWin target] get];
            selected = false;
        }

        NSDictionary* itemProperties = [target properties];
        id originalItem = [itemProperties objectForKey:@"originalItem"];
        if (originalItem != nil && originalItem != [NSNull null]){
            target = originalItem;
        }

        NSString* fileUrl = [target URL];
        if(fileUrl != nil && ![fileUrl hasSuffix:@"/"] && selected){
            fileUrl = [fileUrl stringByDeletingLastPathComponent];
        }

        NSURL* url = [NSURL URLWithString:fileUrl];
        if (url != nil){
            NSString *dirPath = [url path];
            NSString *arg = [@"--working-directory=" stringByAppendingString:dirPath];

            // Check if Ghostty is already running
            NSArray *running = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.mitchellh.ghostty"];

            if ([running count] == 0) {
                // First launch: use open -na for a clean start (no visible cd command)
                NSTask *task = [[NSTask alloc] init];
                [task setLaunchPath:@"/usr/bin/open"];
                [task setArguments:@[@"-na", @"Ghostty.app", @"--args",
                                     [@"--working-directory=" stringByAppendingString:dirPath]]];
                [task launch];
            } else {
                // Already running: open new tab via AppleScript, paste cd command, then clear screen
                // Requires accessibility permissions for System Events.

                // Save clipboard
                NSPasteboard *pb = [NSPasteboard generalPasteboard];
                NSString *oldString = [pb stringForType:NSPasteboardTypeString];

                // Build command: cd + clear screen (hide the cd command from view)
                NSString *cdCommand = [NSString stringWithFormat:@"cd '%@' && clear", dirPath];
                [pb clearContents];
                [pb setString:cdCommand forType:NSPasteboardTypeString];

                NSString *script =
                    @"tell application \"Ghostty\" to activate\n"
                     "delay 0.2\n"
                     "tell application \"System Events\" to keystroke \"t\" using command down\n"
                     "delay 0.5\n"
                     "tell application \"System Events\" to keystroke \"v\" using command down\n"
                     "delay 0.1\n"
                     "tell application \"System Events\" to key code 36";
                NSDictionary *error = nil;
                NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
                [appleScript executeAndReturnError:&error];
                if (error) {
                    NSLog(@"AppleScript error: %@", error);
                }

                // Restore clipboard
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSPasteboard *pb = [NSPasteboard generalPasteboard];
                    [pb clearContents];
                    if (oldString) {
                        [pb setString:oldString forType:NSPasteboardTypeString];
                    }
                });
            }
        }
    }
}
