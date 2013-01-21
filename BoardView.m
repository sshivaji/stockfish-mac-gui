/*
  Stockfish, a OS X GUI for the UCI chess engine with the same name.
  Copyright (C) 2004-2011 Marco Costalba, Joona Kiiski, Tord Romstad

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#import "BoardView.h"
#import "BoardController.h"
#import "MoveAnimation.h"
#import "position.h"

#define min(x,y) (((x) < (y))? (x) : (y))

@implementation BoardView

static BOOL ImagesLoaded = NO;
static NSImage *PieceImages[16];

static void loadImages(void) {
  PieceImages[0] = [[NSImage imageNamed: @"WPawn"] retain];
  PieceImages[1] = [[NSImage imageNamed: @"WKnight"] retain];
  PieceImages[2] = [[NSImage imageNamed: @"WBishop"] retain];
  PieceImages[3] = [[NSImage imageNamed: @"WRook"] retain];
  PieceImages[4] = [[NSImage imageNamed: @"WQueen"] retain];
  PieceImages[5] = [[NSImage imageNamed: @"WKing"] retain];
  PieceImages[8] = [[NSImage imageNamed: @"BPawn"] retain];
  PieceImages[9] = [[NSImage imageNamed: @"BKnight"] retain];
  PieceImages[10] = [[NSImage imageNamed: @"BBishop"] retain];
  PieceImages[11] = [[NSImage imageNamed: @"BRook"] retain];
  PieceImages[12] = [[NSImage imageNamed: @"BQueen"] retain];
  PieceImages[13] = [[NSImage imageNamed: @"BKing"] retain];
  ImagesLoaded = YES;
};

+(void)initialize {
  init();
  [super initialize];
}

-(id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect]) != nil) {
    // Add initialization code here
    highlightSquares[0] = -1;
    if(!ImagesLoaded) loadImages();
  }
  // tournamentMode = NO;
  highlightBoard = NO;

  animation = [[MoveAnimation alloc] init];
  [animation setDelegate: self];
  [animation setFrameRate: 60.0];
  
  return self;
}

-(NSImage *)pieceImage:(int) piece {
  return PieceImages[piece-1];
}

-(BOOL)isHighlighted:(int)sqIndex {
  int i;
  for(i = 0; highlightSquares[i] >= 0; i++)
    if(highlightSquares[i] == sqIndex) return YES;
  return NO;
}

-(void)drawRect:(NSRect)rect {
  NSRect bounds = [self bounds], r;
  // NSColor *squareColors[2];
  float frameSize = 10.0;
  float width = bounds.size.width - 2*frameSize;
  float height = bounds.size.height - 2*frameSize;
  float sqSize = min(width / 8.0, height / 8.0);
  float xMin = (width - 8*sqSize) / 2 + frameSize;
  float yMin = (height - 8*sqSize) / 2 + frameSize;
  int file, rank, square, piece;

  if(![animation isAnimating]) {
    [self reloadSquareColors];
    /*
    squareColors[0] =
      [NSUnarchiver unarchiveObjectWithData:
		      [[NSUserDefaults standardUserDefaults]
			objectForKey: @"Light Square Color"]];
    squareColors[1] =
      [NSUnarchiver unarchiveObjectWithData:
		      [[NSUserDefaults standardUserDefaults]
			objectForKey: @"Dark Square Color"]];
    */
  }
  sideLength = sqSize;
  
  for(rank = 0; rank < 8; rank++) 
    for(file = 0; file < 8; file++) {
      r.origin.x = xMin + file*sqSize;
      r.origin.y = yMin + rank*sqSize;
      r.size.width = r.size.height = sqSize;
      [squareColors[(rank + file + 1) % 2] set];
      [NSBezierPath fillRect: r];
      
      square = file + rank * 8;
      if([self isHighlighted: square] && ![animation isAnimating]) {
	[[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.3] 
	  set];
	[NSBezierPath fillRect: r];
      }
	
      squareCentres[square].x = r.origin.x + sqSize * 0.5;
      squareCentres[square].y = r.origin.y + sqSize * 0.5;
      piece = [controller pieceAtSquare: square];
      if(piece != EMPTY
	 && !([animation isAnimating] && [animation from] == square)) {
	NSRect r1, r2;

	r1.origin.x = xMin + file*sideLength + sideLength/20.0;
	r1.origin.y = yMin + rank*sideLength + sideLength/20.0;
	r1.size.width = sideLength * 0.9;
	r1.size.height = sideLength * 0.9;

	r2.origin.x = 0.0; r2.origin.y = 0.0;
	r2.size.width = r2.size.height = 64.0;
	
	[[self pieceImage: piece] drawInRect: r1 fromRect:r2
				  operation: NSCompositeSourceOver
				  fraction: 1.0];
      }
    }

  if([animation isAnimating]) {
    NSAnimationProgress progress = [animation currentProgress];
    int f = [animation from], t = [animation to];
    int ff = f%8, fr = f/8, tf = t%8, tr = t/8;
    int piece;
    NSRect r1, r2;

    r1.origin.x = xMin + (ff+(tf-ff)*progress)*sideLength + sideLength/20.0;
    r1.origin.y = yMin + (fr+(tr-fr)*progress)*sideLength + sideLength/20.0;
    r1.size.width = sideLength * 0.9;
    r1.size.height = sideLength * 0.9;

    r2.origin.x = 0.0; r2.origin.y = 0.0;
    r2.size.width = r2.size.height = 64.0;

    piece = [controller pieceAtSquare: f];
    [[self pieceImage: piece] drawInRect: r1 fromRect:r2
			      operation: NSCompositeSourceOver
			      fraction: 1.0];
  }
    
  if(highlightBoard) {
    NSMutableAttributedString *s = 
      [[NSMutableAttributedString alloc] 
	initWithString: @"Please adjust my time if necessary"];
    [[NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.4] set];
    [NSBezierPath fillRect: bounds];
    [s addAttribute: NSFontAttributeName
       value: [NSFont userFontOfSize: 22]
       range: NSMakeRange(0, [s length])];
    [s addAttribute: NSForegroundColorAttributeName
       value: [NSColor greenColor]
       range: NSMakeRange(0, [s length])];
    [s drawInRect: bounds];
  }
}

-(void)mouseDown:(NSEvent *)theEvent {
  int i;
  NSPoint point;
  point = [self convertPoint: [theEvent locationInWindow] fromView: NO];
  for(i = 0; i < 64; i++) 
    if((point.x - squareCentres[i].x)*(point.x - squareCentres[i].x) +
       (point.y - squareCentres[i].y)*(point.y - squareCentres[i].y) < 
       sideLength * sideLength * 0.25) {
      [controller destinationSquaresFrom: i storeIn: highlightSquares];
      break;
    }
  if(highlightSquares[0] >= 0) {
    mouseDownSquare = i;
    [self setNeedsDisplay: YES];
  }
  if(highlightBoard) {
    highlightBoard = NO;
    [self setNeedsDisplay: YES];
  }
}

-(void)mouseUp:(NSEvent *)theEvent {
  if(highlightSquares[0] >= 0) {
    int i;
    NSPoint point;
    point = [self convertPoint: [theEvent locationInWindow] fromView: NO];
    for(i = 0; i < 64; i++) 
      if((point.x - squareCentres[i].x)*(point.x - squareCentres[i].x) +
	 (point.y - squareCentres[i].y)*(point.y - squareCentres[i].y) < 
	 sideLength * sideLength * 0.25) {
	mouseUpSquare = i;
      }
    if([self isHighlighted: mouseUpSquare]) 
      [controller madeMoveFrom: mouseDownSquare to: mouseUpSquare];
    highlightSquares[0] = -1;
    [self setNeedsDisplay: YES];
  }
}

-(int)mouseDownSquare {
  return mouseDownSquare;
}

-(int)mouseUpSquare {
  return mouseDownSquare;
}

-(BOOL)acceptsFirstResponder {
  return YES;
}

-(void)keyDown:(NSEvent *)theEvent {
  int keyCode = [theEvent keyCode];
  int flags = [theEvent modifierFlags];
  if(keyCode == 123) // Left arrow
    [controller takeBack: nil];
  else if(keyCode == 124) // Right arrow
    [controller stepForward: nil];
  else if(keyCode == 125) { // Down arrow
    if(flags & NSShiftKeyMask) 
      [controller moveVariationDown: nil];
    else if(flags & NSControlKeyMask)
      [controller decreaseWhiteTime];
    else if(flags & NSAlternateKeyMask)
      [controller decreaseBlackTime];
    else
      [controller nextVariation: nil];
  }
  else if(keyCode == 126) { // Up arrow
    if(flags & NSShiftKeyMask) 
      [controller moveVariationUp: nil];
    else if(flags & NSControlKeyMask)
      [controller increaseWhiteTime];
    else if(flags & NSAlternateKeyMask)
      [controller increaseBlackTime];
    else
      [controller previousVariation: nil];
  }
  else if(keyCode == 17 && flags == 917795) { // Option+Control+Shift+T
    [controller toggleTournamentMode];
  }
  else {
    NSLog(@"keyCode = %d, flags = %d", keyCode, flags);
  }
  //  else NSLog(@"keyCode = %d", keyCode);
}

-(void)highlightBoard {
  if(YES /*tournamentMode*/) {
    highlightBoard = YES;
    [self setNeedsDisplay: YES];
  }
}


-(void)saveBoardAsPNG:(NSString *)filename {
  NSBitmapImageRep *rep;
  NSData *data;
  
  [self lockFocus];
  rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: [self bounds]];
  [self unlockFocus];

  data = [rep representationUsingType: NSPNGFileType properties: nil];
  [data writeToFile: filename atomically: NO];
}


-(void)animateMoveFrom:(int)fromSq to:(int)toSq time:(NSTimeInterval)time {
  [animation setDuration: time];
  [animation startAnimationFrom: fromSq to: toSq];
}


-(void)reloadSquareColors {
  if(squareColors[0]) [squareColors[0] release];
  if(squareColors[1]) [squareColors[1] release];
  squareColors[0] =
    [[NSUnarchiver unarchiveObjectWithData:
		     [[NSUserDefaults standardUserDefaults]
		       objectForKey: @"Light Square Color"]]
      retain];
  squareColors[1] =
    [[NSUnarchiver unarchiveObjectWithData:
		    [[NSUserDefaults standardUserDefaults]
		      objectForKey: @"Dark Square Color"]]
      retain];
}


-(void) dealloc {
  [animation release];
  [squareColors[0] release];
  [squareColors[1] release];
  [super dealloc];
}


@end
