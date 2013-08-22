
/*
     File: Step.m
 Abstract: A model object to represent a code step in a presentation.
 The class conforms to the NSCoding, NSPasteboardReading, and NSPasteboardWriting protocols so that instances can be used with archives and written to and read from a pasteboard.
 
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

#import "Step.h"


@implementation Step

@synthesize tableSummary, body, tooltip, undoManager;


#pragma mark -
#pragma mark Archiving

static NSString *BodyKey = @"Body";
static NSString *ToolTipKey = @"ToolTip";
static NSString *TableSummaryKey = @"TableSummary";


- (id)initWithCoder:(NSCoder *)coder {
    
    if (self = [super init]) {
        body = [[coder decodeObjectForKey:BodyKey] retain];    
        tooltip = [[coder decodeObjectForKey:ToolTipKey] retain];    
        tableSummary = [[coder decodeObjectForKey:TableSummaryKey] retain];    
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:body forKey:BodyKey];
    [encoder encodeObject:tooltip forKey:ToolTipKey];
    [encoder encodeObject:tableSummary forKey:TableSummaryKey];
}


#pragma mark -
#pragma mark Pasteboard support

NSString *StepUTI = @"com.yourcompany.demomonkey.step";

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    static NSArray *writableTypes = nil;
    
    if (!writableTypes) {
        writableTypes = [[NSArray alloc] initWithObjects:StepUTI, NSPasteboardTypeString, nil];
    }
    return writableTypes;
}


- (id)pasteboardPropertyListForType:(NSString *)type {
    
    if ([type isEqualToString:StepUTI]) {
        return [NSKeyedArchiver archivedDataWithRootObject:self];
    }
    if ([type isEqualToString:NSPasteboardTypeString]) {
        return [self description];
    }
    return nil;
}


+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    
    static NSArray *readableTypes = nil;
    if (!readableTypes) {
        readableTypes = [[NSArray alloc] initWithObjects:StepUTI, NSPasteboardTypeString, nil];
    }
    return readableTypes;
}


+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pboard {
    if ([type isEqualToString:StepUTI]) {
        /*
         This means you don't need to implement code for this type in initWithPasteboardPropertyList:ofType: -- initWithCoder: is invoked instead.
         */
        return NSPasteboardReadingAsKeyedArchive;
    }
    if ([type isEqualToString:NSPasteboardTypeString]) {
        return NSPasteboardReadingAsString;
    }
    return 0;
}


- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    
    self = [self init];
    if (self) {
        if ([type isEqualToString:NSPasteboardTypeString]) {
            [body release];
            body = [propertyList copy];
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}



- (NSString *)description {
    NSString *description = body;
    if (!description) {
        description = @"No body";
    }
    return description;
}


#pragma mark -
#pragma mark Set accessors

- (void)setBody:(NSString *)newBody {
    if (body != newBody) {
        [undoManager registerUndoWithTarget:self selector:@selector(setBody:) object:body];
        [body release];
        body = [newBody retain];
    }
}

- (void)setTableSummary:(NSString *)newTableSummary {
    if (tableSummary != newTableSummary) {
        [undoManager registerUndoWithTarget:self selector:@selector(setTableSummary:) object:tableSummary];
        [tableSummary release];
        tableSummary = [newTableSummary retain];
    }
}

- (void)setTooltip:(NSString *)newTooltip {
    if (tooltip != newTooltip) {
        [undoManager registerUndoWithTarget:self selector:@selector(setTooltip:) object:tooltip];
        [tooltip release];
        tooltip = [newTooltip retain];
    }
}


#pragma mark -
#pragma mark Object lifecycle

-(id)init {
    self = [super init];
    if (self) {    
        body = @"";
        tooltip = @"";
        tableSummary = @"New Step";
    }
    return self;
}


- (void)dealloc {
    [body release];
    [tooltip release];
    [tableSummary release];
    [super dealloc];
}


@end
