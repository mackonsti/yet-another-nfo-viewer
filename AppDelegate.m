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

	if ([nfoOpenPanel runModal] == NSFileHandlingPanelOKButton)
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
	NSFont *nfoFont = [NSFont fontWithName:@"ProFontWindows" size:16.0];

	// Remove trailing CR/LF
	if ([nfoContents hasSuffix:@"\n"] == YES)
	{
		nfoContents = [NSMutableString stringWithString:[nfoContents substringToIndex:([nfoContents length] - 2)]];
		myLog(@"Removed trailing CR/LF");
	}

	// First prepare text contents
	[nfoTextView setFont:nfoFont];
	[nfoTextView selectAll:self];
	[nfoTextView replaceCharactersInRange:[nfoTextView selectedRange] withString:nfoContents];
	//
	// Instead of using:
	// [nfoTextView setString:nfoContents];

	// We do not want text wrapped
	[nfoTextView setHorizontallyResizable:YES];
	[nfoTextView setVerticallyResizable:YES];
	[nfoTextView setAutoresizingMask:NSViewNotSizable];

	[nfoTextView setBackgroundColor:[NSColor whiteColor]];
	[nfoTextView setTextColor:[NSColor blackColor]];
	[nfoTextView display];

	// Finally calculate the window size for specific font size
	[self sizeForStringDrawingApple:nfoContents withFont:nfoFont];
	// Window is also shown by calling the Method above

	// Set final window details AFTER sizing window
	[nfoWindow center];
	[nfoWindow setShowsResizeIndicator:YES];
	[nfoWindow setTitle:[[nfoURL path] lastPathComponent]];

	// We can now show the window and FORCE redrawing
	[nfoWindow makeKeyAndOrderFront:self];
	[nfoWindow display];
}



-(void)sizeForStringDrawingApple: (NSString *)aString withFont:(NSFont *)aFont
{
	// Tip found at: http://www.cocoabuilder.com/archive/cocoa/153626-text-height-for-printing-fixed-width.html
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
	myLog(@"Available visible dimensions: %.0fx%.0f", visibleScreen.size.width, visibleScreen.size.height);

	// Check display sizes accordingly
	NSRect nfoFrameSize; nfoFrameSize.origin.x = 0; nfoFrameSize.origin.y = 0;

	if (myWidth < visibleScreen.size.width)
	{
		nfoFrameSize.size.width = (myWidth + 10);  // Compensate for vertical scroll-bar
	} else {
		nfoFrameSize.size.width = (visibleScreen.size.width - kHorizontalWindowPadding);
	}
	if (myHeight < visibleScreen.size.height)
	{
		nfoFrameSize.size.height = myHeight;
	} else {
		nfoFrameSize.size.height = (visibleScreen.size.height - kVerticalWindowPadding);
	}

	[nfoWindow setFrame:nfoFrameSize display:YES];
	[nfoWindow setMinSize:NSMakeSize(nfoFrameSize.size.width, (nfoFrameSize.size.height / 2))];
	// Users don't like this
	//
	// [nfoWindow setMaxSize:NSMakeSize(nfoFrameSize.size.width, FLT_MAX)];
	return;
}


-(BOOL)loadFontFromResource: (NSString *)fontname
{
	// Taken from: http://www.cocoadev.com/index.pl?UsingCustomFontsInYourCocoaApplications
	//
	NSString *fontsFolder;

	if ((fontsFolder = [[NSBundle mainBundle] resourcePath]))
	{
		NSURL *fontsURL;

		if ((fontsURL = [NSURL fileURLWithPath:fontsFolder]))
		{
			OSStatus status;
			FSRef fsRef;

			(void)CFURLGetFSRef((CFURLRef)fontsURL, &fsRef);
			status = ATSFontActivateFromFileReference(&fsRef, kATSFontContextLocal, kATSFontFormatUnspecified, NULL, kATSOptionFlagsDefault, NULL);

			if (status != noErr)
			{
				myLog(@"Failed to activate font from resource!");
				return NO;
			}
		}
	}

	if (fontname != nil)
	{
		NSFontManager *fontManager = [NSFontManager sharedFontManager];
		BOOL fontFound = [[fontManager availableFonts] containsObject:fontname];

		if (!fontFound)
		{
			myLog(@"Required font not found: %@", fontname);
			return NO;
		}
	}

	return YES;
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

	// Load font from resource
	[self loadFontFromResource:@"ProFontWindows"];
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


//	-(BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)theApplication
//	{
//		myLog(@"Application should terminate after last window closed");
//		[NSApp terminate:self];
//		return YES;
//	}


-(void)dealloc
{
	// Free memory (with loading order)
	[nfoWindow release];
	[super dealloc];
}

@end
