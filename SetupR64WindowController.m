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


#import "BoardController.h"
#import "ChessPosition.h"
#import "SetupR64BoardView.h"
#import "SetupR64WindowController.h"

@implementation SetupR64WindowController

static BOOL ImagesLoaded = NO;
static NSImage *PieceImages[16];

static void loadImages(void) {
  PieceImages[0] = [[NSImage imageNamed: @"WPawn32"] retain];
  PieceImages[1] = [[NSImage imageNamed: @"WKnight32"] retain];
  PieceImages[2] = [[NSImage imageNamed: @"WBishop32"] retain];
  PieceImages[3] = [[NSImage imageNamed: @"WRook32"] retain];
  PieceImages[4] = [[NSImage imageNamed: @"WQueen32"] retain];
  PieceImages[5] = [[NSImage imageNamed: @"WKing32"] retain];
  PieceImages[8] = [[NSImage imageNamed: @"BPawn32"] retain];
  PieceImages[9] = [[NSImage imageNamed: @"BKnight32"] retain];
  PieceImages[10] = [[NSImage imageNamed: @"BBishop32"] retain];
  PieceImages[11] = [[NSImage imageNamed: @"BRook32"] retain];
  PieceImages[12] = [[NSImage imageNamed: @"BQueen32"] retain];
  PieceImages[13] = [[NSImage imageNamed: @"BKing32"] retain];
  ImagesLoaded = YES;
};

+(void)initialize {
  loadImages();
}

-(id)initWithBoardController:(BoardController *)bc FEN:(NSString *)fen {
  self = [super initWithWindowNibName: @"Setup"];
  boardController = bc;
  initialFEN = [fen retain];
  position = [[ChessPosition alloc] initWithFEN: initialFEN];
  return self;
}

-(void)windowDidLoad {
  int piece;

  [setupBoardView setController: self];
  for(piece = 0; piece < 6; piece++) {
    [[pieceChoiceMatrix cellAtRow: piece column: 0]
      setImage: PieceImages[5 - piece]];
    [[pieceChoiceMatrix cellAtRow: piece column: 1]
      setImage: PieceImages[13 - piece]];
  }
  [sideToMoveCheckbox setState: [position whiteToMove]];
  [whiteOoCheckbox setState: [position whiteCanCastleKingside]];
  [whiteOooCheckbox setState: [position whiteCanCastleQueenside]];
  [blackOoCheckbox setState: [position blackCanCastleKingside]];
  [blackOooCheckbox setState: [position blackCanCastleQueenside]];
}
    
-(int)pieceAtSquare:(int)squareIndex {
  return [position pieceAtSquare: squareIndex];
}

-(NSImage *)pieceImage:(int)piece {
  return PieceImages[piece-1];
}

-(IBAction)cancelButtonPressed:(id)sender {
  [[self window] close];
}

-(IBAction)okButtonPressed:(id)sender {
  [boardController setCurrentPositionFromFEN: [position FENString]];
  [[self window] close];
}

-(IBAction)castleRightsChanged:(id)sender {
}

-(IBAction)clearBoardButtonPressed:(id)sender {
  [position release];
  position = [[ChessPosition alloc] initWithFEN: @"8/8/8/8/8/8/8/8 w - -"];
  [sideToMoveCheckbox setState: 1];
  [whiteOoCheckbox setState: 0];
  [whiteOooCheckbox setState: 0];
  [blackOoCheckbox setState: 0];
  [blackOooCheckbox setState: 0];
  [setupBoardView setNeedsDisplay: YES];
}

-(IBAction)resetButtonPressed:(id)sender {
  [position release];
  position = [[ChessPosition alloc] initWithFEN: initialFEN];
  [sideToMoveCheckbox setState: [position whiteToMove]];
  [whiteOoCheckbox setState: [position whiteCanCastleKingside]];
  [whiteOooCheckbox setState: [position whiteCanCastleQueenside]];
  [blackOoCheckbox setState: [position blackCanCastleKingside]];
  [blackOooCheckbox setState: [position blackCanCastleQueenside]];
  [setupBoardView setNeedsDisplay: YES];
}

-(IBAction)selectedPieceChanged:(id)sender {
  int tag = [sender selectedTag];
  selectedPiece = (tag % 2 == 0)? 6 - tag / 2 : 14 - (tag - 1) / 2;
}

-(IBAction)sideToMoveChanged:(id)sender {
}

-(void)mouseDownAtSquare:(int)squareIndex {
  if([position pieceAtSquare: squareIndex] == EMPTY)
    [position putPiece: selectedPiece atSquare: squareIndex];
  else
    [position removePieceAtSquare: squareIndex];
  [setupBoardView setNeedsDisplay: YES];
}

-(void)dealloc {
  [ChessPosition release];
  [initialFEN release];
  [super dealloc];
}

@end
