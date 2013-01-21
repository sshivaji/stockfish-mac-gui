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

@class BoardView;
@class Book;
@class ChessMove;
@class CommentWindowController;
@class CustomLevelController;
@class EngineConfigController;
@class EngineController;
@class Game;
@class MatchController;
@class NewEngineMatchController;
@class SearchLogController;
@class SetupR64WindowController;

enum {COMPUTER_WHITE, COMPUTER_BLACK, BOTH, ANALYSIS, ENGINE_MATCH};
enum {BLITZ_LEVEL, FISCHER_LEVEL, OLDFASHIONED_LEVEL, CUSTOM_LEVEL};

@interface BoardController : NSObject {
  IBOutlet NSWindow *boardWindow;
  IBOutlet BoardView *boardView;
  IBOutlet NSTextView *moveListView;
  IBOutlet NSTextField *clockTextField;
  IBOutlet NSTextField *playersTextField;
  IBOutlet NSPanel *moveListWindow;
  IBOutlet NSWindow *frcSheet;
  IBOutlet NSTextField *frcIdTextField;
  IBOutlet NSWindow *pgnTagsSheet;
  IBOutlet NSTextField *eventTextField;
  IBOutlet NSTextField *siteTextField;
  IBOutlet NSTextField *dateTextField;
  IBOutlet NSTextField *roundTextField;
  IBOutlet NSTextField *whiteTextField;
  IBOutlet NSTextField *blackTextField;
  IBOutlet NSPopUpButton *resultPopup;
  IBOutlet NSWindow *promotionWindow;
  IBOutlet NSWindow *strengthSheet;
  IBOutlet NSSlider *strengthSlider;
  IBOutlet NSTextField *strengthEloTextField;
  NSTimer *timer;
  Game *game;
  Book *guiBook;
  EngineConfigController *engineConfigController;
  CommentWindowController *commentWindowController;
  SetupR64WindowController *setupController;
  NewEngineMatchController *newEngineMatchController;
  MatchController *engineMatchController;
  CustomLevelController *customLevelController;
  EngineController *ec1, *ec2;
  SearchLogController *searchLogController;
  BOOL boardIsFlipped;
  int gameMode;  // COMPUTER_WHITE, COMPUTER_BLACK, BOTH, ANALYSIS or 
                 // ENGINE_MATCH
  BOOL displayVariations;
  BOOL allowVariationEntry;
  BOOL displayComments;
  int levelType; // BLITZ_LEVEL, FISCHER_LEVEL, OLDFASHIONED_LEVEL, CUSTOM_LEVEL
  int levelTime;
  int levelIncrement;
  BOOL playerNamesWereEdited;
  BOOL tournamentMode;
  BOOL beep;
}

-(id)init;
-(void)raiseBoardWindow;
-(int)pieceAtSquare:(int)squareIndex;
-(void)destinationSquaresFrom:(int)sqIndex storeIn:(int *)sqArray;
-(void)animateMove:(ChessMove *)move;
-(void)finishMakeMove:(ChessMove *)move;
-(void)madeMoveFrom:(int)fromSq to:(int)toSq;
-(void)displayPlayerNames;
-(void)setCurrentPositionFromFEN:(NSString *)fen;
-(void)setGame:(Game *)newGame;
-(void)newGameWithPGNString:(NSString *)string;
-(IBAction)newGame:(id)sender;
-(void)newGameWithFRCId:(int)FRDId;
-(IBAction)newFRCGame:(id)sender;
-(IBAction)frcSheetOKPressed:(id)sender;
-(IBAction)frcSheetCancelPressed:(id)sender;
-(IBAction)frcSheetRandomPressed:(id)sender;
-(void)frcSheetDidEnd:(NSWindow *)sheet
           returnCode:(int)returnCode
          contextInfo:(void *)contextInfo;
-(IBAction)saveGame:(id)sender;
-(IBAction)addGameToFile:(id)sender;
-(IBAction)castleKingside:(id)sender;
-(IBAction)castleQueenside:(id)sender;
-(IBAction)editPGNTags:(id)sender;
-(IBAction)pgnTagsOKPressed:(id)sender;
-(IBAction)pgnTagsCancelPressed:(id)sender;
-(void)pgnTagsSheetDidEnd:(NSWindow *)sheet
           returnCode:(int)returnCode
          contextInfo:(void *)contextInfo;
-(IBAction)strengthSheetOKPressed:(id)sender;
-(void)strengthSheetDidEnd:(NSWindow *)sheet
		returnCode:(int)returnCode
	       contextInfo:(void *)contextInfo;
-(IBAction)configureEngine:(id)sender;
-(IBAction)flipBoard:(id)sender;
-(IBAction)takeBack:(id)sender;
-(IBAction)stepForward:(id)sender;
-(IBAction)beginningOfGame:(id)sender;
-(IBAction)endOfGame:(id)sender;
-(IBAction)displayVariations:(id)sender;
-(IBAction)displayComments:(id)sender;
-(IBAction)allowVariationEntry:(id)sender;
-(IBAction)nextVariation:(id)sender;
-(IBAction)previousVariation:(id)sender;
-(IBAction)moveVariationUp:(id)sender;
-(IBAction)moveVariationDown:(id)sender;
-(IBAction)beginningOfVariation:(id)sender;
-(IBAction)endOfVariation:(id)sender;
-(IBAction)backToBranchPoint:(id)sender;
-(IBAction)forwardToBranchPoint:(id)sender;
-(IBAction)deleteVariation:(id)sender;
-(IBAction)addComment:(id)sender;
-(IBAction)deleteComment:(id)sender;
-(void)setUpPositionWithFEN:(NSString *)fen;
-(IBAction)setUpPosition:(id)sender;
-(void)setLevelType:(int)newLevelType;
-(void)setTimeControlWithWhiteTime:(int)wtime
			 blackTime:(int)btime
		    whiteIncrement:(int)winc
		    blackIncrement:(int)binc;
-(IBAction)gameInX:(id)sender;
-(IBAction)gameInXPlusY:(id)sender;
-(IBAction)fourtyMovesInXMinutes:(id)sender;
-(IBAction)customLevel:(id)sender;
-(IBAction)limitStrength:(id)sender;
-(Game *)game;
-(void)engineMadeMove:(ChessMove *)move comment:(NSString *)comment;
-(void)engineResigns;
-(IBAction)analysisMode:(id)sender;
-(IBAction)computerPlaysBlack:(id)sender;
-(IBAction)computerPlaysWhite:(id)sender;
-(IBAction)humanPlaysBoth:(id)sender;
-(IBAction)engineMatch:(id)sender;
-(int)gameMode;
-(BOOL)isAtBeginningOfGame;
-(BOOL)isAtEndOfGame;
-(void)displayMoveList;
-(void)switchMainEngineTo:(NSString *)newMainEngine;
-(void)continueAutoplayWithEngine1White:(BOOL)engine1White
		    enginesShouldPonder:(BOOL)shouldPonder;
-(void)autoplayWithWhiteEngine:(NSString *)whiteEngine
		   blackEngine:(NSString *)blackEngine
	   enginesShouldPonder:(BOOL)shouldPonder;
-(void)startMatchWithEngine1:(NSString *)engine1
		     engine2:(NSString *)engine2
	  engine1InitialTime:(int)engine1Time
	  engine2InitialTime:(int)engine2Time
	    engine1Increment:(int)engine1Increment
	    engine2Increment:(int)engine2Increment
	       numberOfGames:(int)numOfGames
		    saveFile:(NSString *)saveFile
		positionFile:(NSString *)positionFile
			 FRC:(BOOL)FRC
		      ponder:(BOOL)ponder;
-(void)stopEngine2;
-(IBAction)promotionChoice:(id)sender;

-(void)boardColorsChanged:(NSNotification *)aNotification;
-(void)toggleBeep;
-(void)toggleTournamentMode;
-(void)increaseWhiteTime;
-(void)decreaseWhiteTime;
-(void)increaseBlackTime;
-(void)decreaseBlackTime;
-(IBAction)saveBoardAsPNG:(id)sender;

@end
