
/*
     File: AppDelegate.m
 Abstract: Application delegate class to act as the Services provider.  Services requests are routed to the current main document. The delegate also manages the application's preferences.
 
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "AppDelegate.h"
#import "MyDocument.h"


static NSString *DMKOpenUntitledDocumentOnLaunchKey = @"openUntitledDocumentOnLaunch";
NSString *DMKDisplayWindowAlphaKey = @"displayWindowAlpha";
NSString *DMKDisplayToolTipsKey = @"displayToolTips";


@implementation AppDelegate

@synthesize preferencesController;

#pragma mark -
#pragma mark Services

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Direct service requests to self.
    [NSApp setServicesProvider:self];
}


/*
 Service items apply to the main document.
 */

- (MyDocument *)mainDocument {
    NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
    MyDocument *mainDocument = nil;
    
    if ([documents count] > 0) {
        mainDocument = [documents objectAtIndex:0];
    }
    return mainDocument;
}


- (void)getNextLine:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    MyDocument *mainDocument = [self mainDocument];
    if (mainDocument != nil) {
        NSString *text = [mainDocument textForCurrentSelectionAndAdvance];
        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObject:text]];
    }
}

- (void)rewind:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    [[self mainDocument] rewind];
}

- (void)moveDownOneLine:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    [[self mainDocument] moveDownOneLine];
}

- (void)moveUpOneLine:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    [[self mainDocument] moveUpOneLine];
}

- (void)createNewStep:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    [[self mainDocument] createNewStep:pboard userData:data error:error];
}


#pragma mark -
#pragma mark User defaults

+ (void)initialize {    
    NSMutableDictionary *initialValues = [NSMutableDictionary dictionary];
    
    [initialValues setObject:[NSNumber numberWithBool:YES] forKey:DMKOpenUntitledDocumentOnLaunchKey];
    [initialValues setObject:[NSNumber numberWithInteger:1] forKey:DMKDisplayWindowAlphaKey];
    [initialValues setObject:[NSNumber numberWithBool:YES] forKey:DMKDisplayToolTipsKey];
    
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValues];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:DMKOpenUntitledDocumentOnLaunchKey] boolValue];
}


- (IBAction)showPreferences:sender {
    if (preferencesController == nil) {
        preferencesController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];
    }
    [preferencesController showWindow:self];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [preferencesController release];
    [super dealloc];
}


@end
