//
//  MyNFOViewerAppDelegate.m
//  MyNFOViewer
//
//  Created by MacKonsti on 04/08/2011.
//  Copyright 2011 MacKonsti. All rights reserved.
//

#import "AppDelegate.h"

/*** Local declarations ***/
#define kHorizontalWindowPadding   20.0  // in pixels
#define kVerticalWindowPadding     40.0  // in pixels

@implementation AppDelegate
@synthesize nfoWindow, nfoTextView;


/***********************************************************************************************************************************************/
/********** FILE MANAGEMENT ********************************************************************************************************************/
/***********************************************************************************************************************************************/

-(void)openNFOFile
{
	myLog(@"Opening file dialog");

	NSOpenPanel *nfoOpenPanel = [NSOpenPanel openPanel];
	NSArray *fileTypes = [NSArray arrayWithObjects:@"nfo", @"asc", @"diz", nil];

	// Setup open panel
	[nfoOpenPanel setAllowedFileTypes:fileTypes];
	[nfoOpenPanel setAllowsMultipleSelection:NO];
	[nfoOpenPanel setCanChooseFiles:YES];
	[nfoOpenPanel setResolvesAliases:YES];
	[nfoOpenPanel setMessage:NSLocalizedString(@"OPEN_SELECT_FILE", nil)];

	if ([nfoOpenPanel runModal] == NSModalResponseOK)
	{
		// Add file to "Open Recent" menu item
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[nfoOpenPanel URL]];

		// Set the file to read and display
		[self showNFOContentsWindow:[nfoOpenPanel URL]];
	}
	else
	{
		myLog(@"No NFO/ASC/DIZ file was selected");
		[NSApp terminate:self];
	}
}


-(NSStringEncoding)nfoEncoding
{
	return CFStringConvertEncodingToNSStringEncoding(CFStringConvertWindowsCodepageToEncoding(437));
}


/***********************************************************************************************************************************************/
/********** DOCUMENT HANDLING ******************************************************************************************************************/
/***********************************************************************************************************************************************/

-(void)showNFOContentsWindow:(NSURL *)nfoURL
{
	// Just close the window to avoid the flickering
	if ([nfoWindow isVisible] == YES)
	{
		[nfoWindow close];
	}

	// Read the file and process it
	NSMutableString *nfoContents = [[[NSMutableString alloc] initWithString:
									[NSString stringWithContentsOfURL:nfoURL encoding:[self nfoEncoding] error:NULL]]
									autorelease];
	myLog(@"Imported %@", nfoURL);

	// Set the default font and size
	NSFont *nfoFont = [NSFont fontWithName:@"More Perfect DOS VGA" size:16.0];

	// Remove trailing CR/LF
	if ([nfoContents hasSuffix:@"\n"] == YES)
	{
		nfoContents = [NSMutableString stringWithString:[nfoContents substringToIndex:([nfoContents length] - 2)]];
		myLog(@"Removed trailing CR/LF");
	}

	// Prepare UI contents
	[nfoTextView setFont:nfoFont];
	[nfoTextView selectAll:self];
	[nfoTextView replaceCharactersInRange:[nfoTextView selectedRange] withString:nfoContents];
	//
	// Instead of using:
	// [nfoTextView setString:nfoContents];

	// We do not want text contents wrapped
	[nfoTextView setHorizontallyResizable:YES];
	[nfoTextView setVerticallyResizable:YES];
	[nfoTextView setAutoresizingMask:NSViewNotSizable];

	[nfoTextView setBackgroundColor:[NSColor whiteColor]];
	[nfoTextView setTextColor:[NSColor blackColor]];
	// [nfoTextView display];

	// Finally calculate the window size for specific font size
	[self sizeForStringDrawingApple:nfoContents withFont:nfoFont];
	// Window is *not* yet shown by calling the Method above

	// Set final window properties AFTER sizing window
	[nfoWindow center];
	[nfoWindow setShowsResizeIndicator:NO];
	[nfoWindow setTitle:[[nfoURL path] lastPathComponent]];
	[nfoWindow setPreservesContentDuringLiveResize:YES];

	[[nfoWindow standardWindowButton:NSWindowCloseButton] setHidden:NO];
	[[nfoWindow standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
	[[nfoWindow standardWindowButton:NSWindowZoomButton] setHidden:YES];

	// We can now show the window and FORCE redrawing
	[nfoWindow makeKeyAndOrderFront:self];
	[nfoWindow display];
}



-(void)sizeForStringDrawingApple: (NSString *)aString withFont:(NSFont *)aFont
{
	// Tip found at: http://www.cocoabuilder.com/archive/cocoa/153626-text-height-for-printing-fixed-width.html
	// Apple archive: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Tasks/DrawingStrings.html
	//
	NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString:aString] autorelease];
	NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)] autorelease];
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];

	[layoutManager addTextContainer:textContainer];
	[layoutManager setTypesetterBehavior:NSTypesetterBehavior_10_2_WithCompatibility];  // Absolutely necessary for proper height!

	[textStorage addLayoutManager:layoutManager];
	[textStorage addAttribute:NSFontAttributeName value:aFont range:NSMakeRange(0,[textStorage length])];

	(void)[layoutManager glyphRangeForTextContainer:textContainer];

	float myWidth = [layoutManager usedRectForTextContainer:textContainer].size.width;
	float myHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
	myLog(@"Calculated document width=%ipx and height=%ipx", (int)myWidth, (int)myHeight);

	// Taken from: http://stackoverflow.com/questions/4982656/programmatically-get-screen-size-in-mac-os-x
	//
	NSRect visibleScreen = [[NSScreen mainScreen] visibleFrame];
	myLog(@"Available visible dimensions: %.0f x %.0f", visibleScreen.size.width, visibleScreen.size.height);

	// Check display sizes accordingly
	NSRect nfoFrameSize; nfoFrameSize.origin.x = 0; nfoFrameSize.origin.y = 0;

	if (myWidth < visibleScreen.size.width)
	{
		nfoFrameSize.size.width = (myWidth + 10);  // Compensate horizontally for vertical scroll-bar
	} else {
		nfoFrameSize.size.width = (visibleScreen.size.width - kHorizontalWindowPadding);
	}
	if (myHeight < visibleScreen.size.height)
	{
		nfoFrameSize.size.height = myHeight;
	} else {
		nfoFrameSize.size.height = (visibleScreen.size.height - kVerticalWindowPadding);
	}

	[nfoWindow setFrame:nfoFrameSize display:NO];
	[nfoWindow setMinSize:NSMakeSize(nfoFrameSize.size.width, (nfoFrameSize.size.height / 2))];

	// Some users may not like this...
	[nfoWindow setMaxSize:NSMakeSize(nfoFrameSize.size.width, FLT_MAX)];

	myLog(@"Final frame dimensions: %.0f x %.0f", nfoFrameSize.size.width, nfoFrameSize.size.height);
	return;
}


/***********************************************************************************************************************************************/
/********** SYSTEM METHOD **********************************************************************************************************************/
/***********************************************************************************************************************************************/

-(id)init
{
	self = [super init];
	if (!self) { return nil; }
	return self;
}


-(void)applicationWillFinishLaunching: (NSNotification *)aNotification
{
	myLog(@"Application started launching");

	// Initialize main variable(s)
	hasDroppedFile = NO;
}


-(void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
	myLog(@"Application finished launching");

	// Check if application started by trigger
	if (hasDroppedFile == NO)
	{
		[self openNFOFile];
	}
}


-(BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	NSURL *incomingFile = [NSURL fileURLWithPath:filename];

	myLog(@"Received %@", incomingFile);
	hasDroppedFile = YES;

	// Show these contents now
	[self showNFOContentsWindow:incomingFile];

	// Add file to "Open Recent" menu item
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:incomingFile];

	return YES;
	// Moving forward to (void)applicationDidFinishLaunching!
}


-(void)cancelOperation:(id)sender
{
	myLog(@"Cancelled operation");

	if ([nfoWindow isVisible] == YES)
	{
		myLog(@"Requesting to close window");
		[nfoWindow close];
	}
}


-(IBAction)openDocument:(id)sender
{
	myLog(@"Menu 'Open' was selected");
	[self openNFOFile];
}


//	-(IBAction)saveDocumentAs:(id)sender
//	{
//		myLog(@"Menu 'Export' was selected");
//	}


//	-(BOOL)windowShouldClose: (id)sender
//	{
//		// Tells the delegate that the user has attempted to close a window or the window has received a [performClose:] message.
//		return YES;
//	}


//	-(BOOL)windowWillClose: (id)sender
//	{
//		// Tells the delegate that the window is about to close.
//		myLog(@"The window is about to close");
//
//		// [NSApp terminate:self];
//		return YES;
//		// If this window is the NSApplication delegate, we will be transferred to 'applicationShouldTerminateAfterLastWindowClosed' later
// }


//	-(void)awakeFromNib
//	{
//		myLog(@"Window awaked from NIB");
//
//		// Set the window as the NSApplication delegate, so we can safely terminate application by visiting 'applicationShouldTerminateAfterLastWindowClosed'
//		[NSApp setDelegate:self];
//	}


-(BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)theApplication
{
	myLog(@"Application should terminate after last window closed");
	[NSApp terminate:self];
	return YES;
}


-(void)dealloc
{
	// Free memory (with loading order)
	[nfoWindow release];
	[super dealloc];
}

@end
