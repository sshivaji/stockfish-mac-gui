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


#import <Cocoa/Cocoa.h>

@class BoardController;
@class ChessPosition;

@interface SetupR64WindowController : NSWindowController {
  IBOutlet id blackOoCheckbox;
  IBOutlet id blackOooCheckbox;
  IBOutlet id pieceChoiceMatrix;
  IBOutlet id setupBoardView;
  IBOutlet id sideToMoveCheckbox;
  IBOutlet id whiteOoCheckbox;
  IBOutlet id whiteOooCheckbox;

  NSString *initialFEN;
  BoardController *boardController;
  //  float sideLength;
  //  NSPoint squareCentres[64];
  ChessPosition *position;
  int selectedPiece;
}

-(id)initWithBoardController:(BoardController *)bc FEN:(NSString *)fen;
-(int)pieceAtSquare:(int)squareIndex;
-(NSImage *)pieceImage:(int)piece;
-(IBAction)cancelButtonPressed:(id)sender;
-(IBAction)castleRightsChanged:(id)sender;
-(IBAction)clearBoardButtonPressed:(id)sender;
-(IBAction)okButtonPressed:(id)sender;
-(IBAction)resetButtonPressed:(id)sender;
-(IBAction)selectedPieceChanged:(id)sender;
-(IBAction)sideToMoveChanged:(id)sender;
-(void)mouseDownAtSquare:(int)squareIndex;

@end
