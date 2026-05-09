//
//  main.m
//  cd to ...
//
//  Created by James Tuley on 10/9/19.
//  Copyright © 2019 Jay Tuley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>

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

            // Launch Ghostty with --working-directory via open -na
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/usr/bin/open"];
            [task setArguments:@[@"-na", @"Ghostty.app", @"--args", [@"--working-directory=" stringByAppendingString:dirPath]]];
            [task launch];
        }
    }
}
