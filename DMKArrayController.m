
/*
     File: DMKArrayController.m
 Abstract: An array controller subclass to manage a collection of text snippets, including support for drag and drop.
 
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

#import "DMKArrayController.h"
#import "EditController.h"
#import "MyDocument.h"
#import "Step.h"


NSString *MovedRowsUTI = @"com.yourcompany.demomonkey.movedrows";

@implementation DMKArrayController


@synthesize tableView, windowController;


#pragma mark -
#pragma mark Pasteboard / drag and drop support

- (void)awakeFromNib {
    // Register the table view for drag and drop.
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:StepUTI, MovedRowsUTI, NSStringPboardType, nil]];
    [tableView setAllowsMultipleSelection:YES];
    [tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}


- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    /*
     Take ownership of the pasteboard, then:
     * Write the currently-selected steps directly;
     * Archive the selection index set and write the archive to the pasteboard as the data for the moved rows type.  The index set is used in tableView:acceptDrop:row:dropOperation: if there is a reorder operation within a table view.
     */
    [pboard clearContents];
    
    // Write the current steps.
    [pboard writeObjects:[[self arrangedObjects] objectsAtIndexes:rowIndexes]];

    // Add rows array for a local move.
    [pboard addTypes:[NSArray arrayWithObject:MovedRowsUTI] owner:self];        
    NSData *rowIndexesData = [NSArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:rowIndexesData forType:MovedRowsUTI];        
    
    return YES;
}



- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    
    NSDragOperation dragOp = NSDragOperationCopy;
    
    // If drag source is self, it's a move.
    if ([info draggingSource] == tableView) {
        dragOp =  NSDragOperationMove;
    }
    
    // Put the object at, not over, the current row (contrast NSTableViewDropOn).
    if ([[self arrangedObjects] count] > 0) {
        [aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
    }
    return dragOp;
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    
    if (row < 0) {
        row = 0;
    }
    /*
     If the dragging source is our table view, look for the moved rows type for a reorder operation.
     */
    if ([info draggingSource] == tableView) {
        
        NSData *rowsData = [[info draggingPasteboard] dataForType:MovedRowsUTI];
        NSIndexSet  *indexSet = [NSUnarchiver unarchiveObjectWithData:rowsData];        
        [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
        
        /*
         Set the selected rows to those that were just moved.  Work out what moved where to determine proper selection.
         */
        NSInteger rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
        NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
        indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [self setSelectionIndexes:indexSet];
        
        return YES;
    }
    
    /*
     If the dragging source is something other than our table view, create new steps from whatever's on the pasteboard and add them.
     */
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *newSteps = [[info draggingPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[Step class]] options:options];
    if (newSteps == nil) {
        return NO;
    }

    NSRange insertionRange = NSMakeRange(row, [newSteps count]);
    NSIndexSet *insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:insertionRange];
    [self insertObjects:newSteps atArrangedObjectIndexes:insertionIndexes];
    return YES;
}


#pragma mark -
#pragma mark New objects

- (id)newObject {
    // Configure a new object.
    Step *newObject = [super newObject];
    NSUInteger row = [[self arrangedObjects] count];
    newObject.tableSummary = [NSString stringWithFormat:@"Step %d", (row +1)];
    newObject.undoManager = [[windowController document] undoManager];
    return newObject;
}


- (void)add:sender {
    // Add a new object, then select its row.
    Step *newObject = [super newObject];
    NSUInteger row = [[self arrangedObjects] count];
    [self insertObject:newObject atArrangedObjectIndex:row];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [tableView editColumn:0 row:row withEvent:nil select:YES];
    [newObject release];
}


#pragma mark -
#pragma mark Reorder operation

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet toIndex:(NSUInteger)insertIndex {
    
    NSArray *objects = [self arrangedObjects];
    NSInteger idx = [indexSet lastIndex];
    
    NSInteger aboveInsertIndexCount = 0;
    id object = nil;
    NSInteger removeIndex;
    
    while (NSNotFound != idx) {
        if (idx >= insertIndex) {
            removeIndex = idx + aboveInsertIndexCount;
            aboveInsertIndexCount += 1;
        }
        else {
            removeIndex = idx;
            insertIndex -= 1;
        }
        object = [[objects objectAtIndex:removeIndex] retain];
        [self removeObjectAtArrangedObjectIndex:removeIndex];
        [self insertObject:object atArrangedObjectIndex:insertIndex];
        [object release];
        idx = [indexSet indexLessThanIndex:idx];
    }
}


- (NSInteger)rowsAboveRow:(NSInteger)row inIndexSet:(NSIndexSet *)indexSet {
    
    NSUInteger currentIndex = [indexSet firstIndex];
    NSInteger i = 0;
    while (currentIndex != NSNotFound) {
        if (currentIndex < row) { i++; }
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}


@end

