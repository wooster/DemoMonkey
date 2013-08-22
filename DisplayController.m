
/*
     File: DisplayController.m
 Abstract: A window controller to display the titles of the text snippets.
 
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
#import "DisplayController.h"
#import "Step.h"

@implementation DisplayController


@synthesize arrayController, tableView;


#pragma mark -
#pragma mark Services methods

-(NSString *)textForCurrentSelectionAndAdvance {
    
    NSString *string = nil;
    NSUInteger selectedRow = [arrayController selectionIndex];
    
    if (selectedRow != NSNotFound) {
        Step *step = (Step *)[[arrayController arrangedObjects] objectAtIndex:selectedRow];
        string = step.body;
        if (string == nil) {
            string = @"";
        }
        [self moveDownOneLine];
    }
    else {
        string = @"";
    }
    return string;
}


- (void)rewind {
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [tableView scrollRowToVisible:0];
}


- (void)moveUpOneLine {
    NSUInteger selectedRow = [arrayController selectionIndex];
    if ((selectedRow > 0) && (selectedRow != NSNotFound)) {
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(selectedRow -1)] byExtendingSelection:NO];
        [tableView scrollRowToVisible:(selectedRow -1)];
    }
}


- (void)moveDownOneLine {
    
    NSUInteger selectedRow = [arrayController selectionIndex];
    if (selectedRow == NSNotFound) {
        return;
    }
    selectedRow++;
    if (selectedRow < [[arrayController arrangedObjects] count]) {
        [arrayController setSelectionIndex:selectedRow];    
        [tableView scrollRowToVisible:selectedRow];
    }
}


#pragma mark -
#pragma mark Table view delegate methods

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    
    // If user defaults allows tooltips, then return the step's tooltip.
    
    if ([[[[NSUserDefaultsController sharedUserDefaultsController]
        values] valueForKey:DMKDisplayToolTipsKey] boolValue]) {
        Step *step = (Step *)[[arrayController arrangedObjects] objectAtIndex:row];
        return step.tooltip;
    }
    return nil;
}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
    
    // For convenience, automatically write the row to the pasteboard then make sure the next row is displayed, ready for the next selection.
    BOOL ok = [self writeRow:rowIndex toPasteboard:[NSPasteboard generalPasteboard]];
    if (ok && (rowIndex < [[arrayController arrangedObjects] count] -1)) {
        [self performSelector:@selector(scrollTableViewToRow:) withObject:[NSNumber numberWithInteger:(rowIndex+1)] afterDelay:0.1];
    }
    return ok;
}


- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    
    // Don't write anything if more than one row is selected.
    if ([rowIndexes count] != 1) {
        return NO;
    }
    
    NSInteger row = [rowIndexes firstIndex];
    if (row < [[arrayController arrangedObjects] count] -1) {
        [self performSelector:@selector(scrollTableViewToRow:) withObject:[NSNumber numberWithInteger:(row+1)] afterDelay:0.1];
    }
    return [self writeRow:row toPasteboard:pboard];
}


#pragma mark -
#pragma mark Table view drag and drop

/*
 The display table view shouldn't support drag and drop or any reordering.
 */
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    return NSDragOperationNone;
}


- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    return NO;
}


#pragma mark -
#pragma mark Scroll to view

- (void)scrollTableViewToRow:(NSNumber *)row {
    [tableView scrollRowToVisible:[row integerValue]];    
}


#pragma mark -
#pragma mark Writing rows

- (BOOL)writeRow:(NSInteger)row toPasteboard:(NSPasteboard*)pboard {
    
    // For the display window, just write the selected step's body, not the complete step.
    Step *step = (Step *)[[arrayController arrangedObjects] objectAtIndex:row];
    NSString *stepBody = step.body;
    if (stepBody == nil) {
        return NO;
    }
    
    [pboard clearContents];
    [pboard writeObjects:[NSArray arrayWithObject:stepBody]];
    return YES;
}


#pragma mark -
#pragma mark Window transparency

/*
 Observe the shared user defaults controller for changes to the displayWindowAlpha preference.
 Update the window's alpha value in response.
 */

static const NSString *windowAlphaContext;

- (void)windowDidLoad {
    
    [super windowDidLoad];
    [tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    
    NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
    
    NSString *displayWindowAlphaKeyPath = [@"values." stringByAppendingString:DMKDisplayWindowAlphaKey];
    [udc addObserver:self forKeyPath:displayWindowAlphaKeyPath options:0 context:&windowAlphaContext];
    
    [[self window] setAlphaValue:[[udc valueForKeyPath:displayWindowAlphaKeyPath] floatValue]];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context != &windowAlphaContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    [[self window] setAlphaValue:[[object valueForKeyPath:[@"values." stringByAppendingString:DMKDisplayWindowAlphaKey]] floatValue]];
}



#pragma mark -
#pragma mark Object lifecycle
         
- (void) dealloc {
    NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
    [udc removeObserver:self forKeyPath:[@"values." stringByAppendingString:DMKDisplayWindowAlphaKey]];
    [super dealloc];    
}

@end
