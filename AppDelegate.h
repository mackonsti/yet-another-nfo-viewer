//
//  MyNFOViewerAppDelegate.h
//  MyNFOViewer
//
//  Created by MacKonsti on 04/08/2011.
//  Copyright 2011 MacKonsti. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	NSWindow *nfoWindow;
	NSTextView *nfoTextView;
	BOOL hasDroppedFile;
}

-(void)openNFOFile;
-(NSStringEncoding)nfoEncoding;

-(void)showNFOContentsWindow:(NSURL *)nfoURL;
-(void)sizeForStringDrawingApple:(NSString *)aString withFont:(NSFont *)aFont;

@property (assign) IBOutlet NSWindow *nfoWindow;
@property (assign) IBOutlet NSTextView *nfoTextView;

@end


// Tip found at: http://stackoverflow.com/questions/969130/nslog-tips-and-tricks
//
#ifndef RELEASE_MODE
#define myLog( s, ... ) NSLog( @"<%@ (%d)>\t%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define myLog( s, ... )
#endif


// Macro found at: http://www.wilshipley.com/blog/2005/10/pimp-my-code-interlude-free-code.html
//
static inline BOOL IsEmpty(id thing)
{
	return thing == nil
	|| [thing isKindOfClass:[NSNull class]]
	|| ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)] && [(NSArray *)thing count] == 0);
}
