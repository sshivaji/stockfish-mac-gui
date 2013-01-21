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


#import "ChessPosition.h"
#import "SetupR64WindowController.h"
#import "SetupR64BoardView.h"

@implementation SetupR64BoardView

-(id)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect]) != nil) {
    // Add initialization code here
  }
  return self;
}

-(void)drawRect:(NSRect)rect {
  NSRect bounds = [self bounds], r;
  NSColor *squareColors[2];
  float frameSize = 8.0;
  float width = bounds.size.width - 2*frameSize;
  float height = bounds.size.height - 2*frameSize;
  float sqSize = Min(width / 8.0, height / 8.0);
  float xMin = (width - 8*sqSize) / 2 + frameSize;
  float yMin = (height - 8*sqSize) / 2 + frameSize;
  int file, rank, square, piece;

  squareColors[0] =
    [NSUnarchiver unarchiveObjectWithData:
		    [[NSUserDefaults standardUserDefaults]
		      objectForKey: @"Light Square Color"]];
  squareColors[1] =
    [NSUnarchiver unarchiveObjectWithData:
		    [[NSUserDefaults standardUserDefaults]
		      objectForKey: @"Dark Square Color"]];

  sideLength = sqSize;
  for(rank = 0; rank < 8; rank++) 
    for(file = 0; file < 8; file++) {
      r.origin.x = xMin + file*sqSize;
      r.origin.y = yMin + rank*sqSize;
      r.size.width = r.size.height = sqSize;
      [squareColors[(rank + file + 1) % 2] set];
      [NSBezierPath fillRect: r];
      
      square = file + rank * 8;
      squareCentres[square].x = r.origin.x + sqSize * 0.5;
      squareCentres[square].y = r.origin.y + sqSize * 0.5;
      piece = [controller pieceAtSquare: square];
      if(piece != EMPTY) {
	NSRect r1, r2;
	r1.origin.x = xMin + file*sideLength + sideLength/20.0;
	r1.origin.y = yMin + rank*sideLength + sideLength/20.0;
	r1.size.width = sideLength * 0.9;
	r1.size.height = sideLength * 0.9;
	r2.origin.x = 0.0; r2.origin.y = 0.0;
	r2.size.width = r2.size.height = 34.0;
	[[controller pieceImage: piece] drawInRect: r1 fromRect:r2
					operation: NSCompositeSourceOver
					fraction: 1.0];
      }
    }
}

-(void)setController:(SetupR64WindowController *)c {
  controller = c;
}

-(void)mouseDown:(NSEvent *)theEvent {
  int i;
  NSPoint point;
  point = [self convertPoint: [theEvent locationInWindow] fromView: NO];
  for(i = 0; i < 64; i++)
    if((point.x - squareCentres[i].x)*(point.x - squareCentres[i].x) +
       (point.y - squareCentres[i].y)*(point.y - squareCentres[i].y) < 
       sideLength * sideLength * 0.25) {
      [controller mouseDownAtSquare: i];
      break;
    }
}

@end
