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
#import "BoardView.h"
#import "Book.h"
#import "CommentWindowController.h"
#import "CustomLevelController.h"
#import "Game.h"
#import "position.h"
#import "ChessClock.h"
#import "Engine.h"
#import "EngineConfigController.h"
#import "EngineController.h"
#import "MatchController.h"
#import "NewEngineMatchController.h"
#import "SearchLogController.h"
#import "SetupR64WindowController.h"
#import "UCIOption.h"


@implementation BoardController

-(id)init {
  [super init];
  guiBook = [[Book alloc] initWithFilename: [[NSBundle mainBundle]
					      pathForResource: @"guibook.bin"
					      ofType: nil]];
  game = [[Game alloc] init];
  [game setWhitePlayer: NSFullUserName()];
  timer = [[NSTimer scheduledTimerWithTimeInterval: 1.0
		    target: self
		    selector: @selector(timerWasFired:)
		    userInfo: nil
		    repeats: YES]
	    retain];
  gameMode = COMPUTER_BLACK;
  displayVariations = YES;
  allowVariationEntry = YES;
  displayComments = YES;
  boardIsFlipped = NO;
  levelType = FISCHER_LEVEL;
  levelTime = 5;
  levelIncrement = 1;
  playerNamesWereEdited = NO;
  tournamentMode = NO;
  beep = [[NSUserDefaults standardUserDefaults]
	   boolForKey: @"Beep when Making Moves"];

  [[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(boardColorsChanged:)
					name: @"BoardColorsChanged"
					object: nil];
  [[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(toggleBeep:)
					name: @"BeepWhenMakingMovesChanged"
					object: nil];

  ec1 = [[EngineController alloc] initWithBoardController: self];
  [ec1 showWindow: self];

  /*
  searchLogController = [[SearchLogController alloc] init];
  [searchLogController showWindow: self];
  [searchLogController setFont];
  */

  // Remember position and size of board window.  This doesn't work, so
  // it's commented out.
  /*
  [[boardWindow windowController] setShouldCascadeWindows: NO];
  [boardWindow setFrameUsingName: [boardWindow representedFilename]];
  [boardWindow setAutosaveName: [boardWindow representedFilename]];
  */
  
  return self;
}

-(void)raiseBoardWindow {
  [boardWindow makeKeyAndOrderFront: nil];
}

-(int)pieceAtSquare:(int)squareIndex {
  [moveListWindow setFloatingPanel: NO]; // UGLY HACK!  MOVE ME LATER!!
  if(boardIsFlipped)
    return [game pieceAtSquare: 63-squareIndex];
  else
    return [game pieceAtSquare: squareIndex];
}

-(void)destinationSquaresFrom:(int)sqIndex storeIn:(int *)sqArray {
  if(boardIsFlipped) {
    int *sq;
    [[game currentPosition] destinationSquaresFrom: 63-sqIndex 
                            storeIn: sqArray];
    for(sq = sqArray; *sq != -1; sq++) *sq = 63 - *sq;
  }    
  else
    [[game currentPosition] destinationSquaresFrom: sqIndex storeIn: sqArray];
}

-(void)gameOver {
  if(gameMode == ENGINE_MATCH) {
    [ec1 stopThinking];
    [ec2 stopThinking];
    if([[game currentPosition] isMate]) {
      if([game whiteToMove]) [game setResult: BLACK_WINS];
      else [game setResult: WHITE_WINS];
    }
    else [game setResult: DRAW];
    [engineMatchController gameFinished: game];
  }
  else {
    [ec1 stopThinking];
    if([[game currentPosition] isMate]) {
      if([game whiteToMove]) {
	[game setResult: BLACK_WINS];
	NSRunAlertPanel(@"Checkmate", @"Black wins", @"OK", nil, nil);
      }
      else {
	[game setResult: WHITE_WINS];
	NSRunAlertPanel(@"Checkmate", @"White wins", @"OK", nil, nil);
      }
    }
    else { // Draw
      [game setResult: DRAW];
      if([[game currentPosition] isMaterialDraw]) 
	NSRunAlertPanel(@"Draw", @"Insufficient material", @"OK", nil, nil);
      else if([[game currentPosition] isRule50Draw]) 
	NSRunAlertPanel(@"Draw", @"50 Moves", @"OK", nil, nil);
      else if([[game currentPosition] isRepetitionDraw]) 
	NSRunAlertPanel(@"Draw", @"Third Repetition", @"OK", nil, nil);
      else if([[game currentPosition] isStalemate])
	NSRunAlertPanel(@"Draw", @"Stalemate", @"OK", nil, nil);
    }
    [ec1 setRole: IDLE];
    gameMode = BOTH;
  }
}

-(NSString *)moveListString {
  return [game moveListStringWithComments: displayComments
	       variations: displayVariations];
}

-(NSAttributedString *)moveListAttributedString {
  return [game moveListAttributedStringWithComments: displayComments
	       variations: displayVariations];
}

-(void)displayMoveList {
  [[moveListView textStorage] setAttributedString: 
				[self moveListAttributedString]];
}

-(void)animateMove:(ChessMove *)move {
  int from = COMPRESS(MvFrom([move move])), to = COMPRESS(MvTo([move move]));
  int remainingTime;
  NSTimeInterval duration;
  if(boardIsFlipped) {
    from = 63 - from;
    to = 63 - to;
  }
  remainingTime = [game whiteToMove]?
    [game whiteRemainingTime] : [game blackRemainingTime];
  if(remainingTime <= 15000)
    // Less than 15 seconds left, skip animation
    return;
  else if(remainingTime > 300000)
    // More than five minutes left, use slow animation
    duration = 0.25;
  else
    // Between 15 seconds and 5 minutes left.  Let the speed of animation
    // depend linearly on the remaining time.
    duration = 0.05 + 0.2 * (remainingTime - 15000.0) / 285000.0;

  [boardView animateMoveFrom: from to: to time: duration];
}

-(void)finishMakeMove:(ChessMove *)move {
  [self animateMove: move];
  if(allowVariationEntry)
    [game insertMove: move];
  else
    [game makeMove: move];
  // [moveListView setString: [self moveListString]];
  //  [moveListView setAttributedString: [self moveListAttributedString]];
  // [[moveListView textStorage] setAttributedString: 
  //				[self moveListAttributedString]];
  [self displayMoveList];
  [boardView setNeedsDisplay: YES];

  // Game Over?
  if([[game currentPosition] isTerminal]) {
    [self gameOver];
    [self displayMoveList];
  }
  else { // Game not over!
    // Should we use the GUI opening book?
    if(gameMode != BOTH && gameMode != ANALYSIS &&
       [[ec1 engine] shouldUseGUIBook]) {
      ChessMove *bookMove = 
	[guiBook pickMoveForPosition: [game currentPosition]
		 withVariety: 0];
      if(bookMove != nil) 
	[self engineMadeMove: bookMove comment: nil];
      else [ec1 moveWasMade];
    }
    else [ec1 moveWasMade];
  }
}

-(void)madeMoveFrom:(int)fromSq to:(int)toSq {
  int fsq = boardIsFlipped? 63-fromSq : fromSq;
  int tsq = boardIsFlipped? 63-toSq : toSq;
  ChessMove *move = [[game generateMoveFrom: fsq to: tsq] retain];
  if([move isNullMove]) { // Must be a promotion
    int promotion;
    [move release];
    promotion = QUEEN - [NSApp runModalForWindow: promotionWindow];
    [promotionWindow close];
    move = [[game generateMoveFrom: fsq to: tsq promotion: promotion] retain];
  }
  [self finishMakeMove: move];
  [move release];
}

-(BOOL)isAtBeginningOfGame {
  return [game isAtBeginningOfGame];
}

-(BOOL)isAtEndOfGame {
  return [game isAtEndOfGame];
}

-(void)engineMadeMove:(ChessMove *)move comment:(NSString *)comment {
  //  NSLog(@"inEngineMadeMove:, move is %@", move);
  [self animateMove: move];
  [game makeMove: move];
  if(comment)
    [game addComment: comment];
  [self displayMoveList];
  [boardView setNeedsDisplay: YES];

  if(tournamentMode)
    [game saveToFile: @"/Users/tord/CurrentGame.pgn"];

  // Game Over?
  if([[game currentPosition] isTerminal]) {
    [self gameOver];
    [self displayMoveList];
  }
  else { // Game not over!
    if(tournamentMode) {
      [[NSSound soundNamed: @"Glass"] play];
      [boardView highlightBoard];
    }
    else if(beep)
      [[NSSound soundNamed: @"Pop"] play];
    // NSBeep();
    if(gameMode == ENGINE_MATCH) {
      if(([game whiteToMove] && [ec1 role] == PLAYING_WHITE) ||
	 ([game blackToMove] && [ec1 role] == PLAYING_BLACK)) {
	// Should we use the GUI opening book?
	if([[ec1 engine] shouldUseGUIBook]) {
	  ChessMove *bookMove = 
	    [guiBook pickMoveForPosition: [game currentPosition]
		     withVariety: 0];
	  if(bookMove != nil) 
	    [self engineMadeMove: bookMove comment: nil];
	  else [ec1 moveWasMade];
	}
	else [ec1 moveWasMade];
      }
      else if(([game whiteToMove] && [ec2 role] == PLAYING_WHITE) ||
	      ([game blackToMove] && [ec2 role] == PLAYING_BLACK)) {
	if([[ec2 engine] shouldUseGUIBook]) {
	  ChessMove *bookMove = 
	    [guiBook pickMoveForPosition: [game currentPosition]
		     withVariety: 0];
	  if(bookMove != nil) 
	    [self engineMadeMove: bookMove comment: nil];
	  else [ec2 moveWasMade];
	}
	else [ec2 moveWasMade];
      }
    }
  }
}

-(void)engineResigns {
  if([game whiteToMove]) [game setResult: BLACK_WINS];
  else [game setResult: WHITE_WINS];
  [self displayMoveList];
  if(gameMode == ENGINE_MATCH) {
    [ec1 stopThinking];
    [ec2 stopThinking];
    [engineMatchController gameFinished: game];
  }
  else {
    NSString *s = [NSString stringWithFormat: @"%@ resigns", [ec1 engineName]];
    [ec1 stopThinking];
    NSRunAlertPanel(s, @"Well done!", @"OK", nil, nil);
    [ec1 setRole: IDLE];
    gameMode = BOTH;
  }
}

-(void)displayPlayerNames {
  [playersTextField setStringValue: [NSString stringWithFormat: @"%@ - %@",
					      [game whitePlayer],
					      [game blackPlayer]]];
}

-(void)timerWasFired:(NSTimer *)timer {
  [clockTextField setStringValue: [game clockString]];
  if(gameMode == COMPUTER_WHITE) {
    if([[game whitePlayer] isEqualToString: @"?"]) {
      [game setWhitePlayer: [ec1 engineName]];
      [self displayPlayerNames];
    }
  }
  else if(gameMode == COMPUTER_BLACK) {
    if([[game blackPlayer] isEqualToString: @"?"] ||
       [game blackPlayer] == nil) {
      [game setBlackPlayer: [ec1 engineName]];
      [self displayPlayerNames];
    }
  }
}

-(void)setCurrentPositionFromFEN:(NSString *)fen {
  [ec1 startNewGame];
  [game release];
  game = [[Game alloc] initWithFEN: fen];
  if([game whiteToMove]) {
    [game setWhitePlayer: NSFullUserName()];
    [game setBlackPlayer: [ec1 engineName]];
    gameMode = COMPUTER_BLACK;
    [ec1 setRole: PLAYING_BLACK];
  } else {
    [game setBlackPlayer: NSFullUserName()];
    [game setWhitePlayer: [ec1 engineName]];
    gameMode = COMPUTER_WHITE;
    [ec1 setRole: PLAYING_WHITE];
  }
  boardIsFlipped = NO;
  playerNamesWereEdited = NO;
  [boardView setNeedsDisplay: YES];
  [moveListView setString: @""];
}

-(void)setGame:(Game *)newGame {
  [newGame retain];
  [ec1 startNewGame];
  [game release];
  game = newGame;
  if([game whiteToMove]) {
    [game setWhitePlayer: NSFullUserName()];
    [game setBlackPlayer: [ec1 engineName]];
    gameMode = COMPUTER_BLACK;
    [ec1 setRole: PLAYING_BLACK];
  } else {
    [game setBlackPlayer: NSFullUserName()];
    [game setWhitePlayer: [ec1 engineName]];
    gameMode = COMPUTER_WHITE;
    [ec1 setRole: PLAYING_WHITE];
  }
  boardIsFlipped = NO;
  playerNamesWereEdited = NO;
  [boardView setNeedsDisplay: YES];
  [self displayPlayerNames];
  [self displayMoveList];
  //  [moveListView setString: [self moveListString]];
}

-(void)newGameWithPGNString:(NSString *)string {
  Game *newGame;

  @try {
    newGame = [[Game alloc] initWithPGNString: string];
    [newGame goToBeginningOfGame];
  }
  @catch (NSException *e) {
    NSRunAlertPanel(@"Error while parsing game",
		    [e reason], nil, nil, nil, nil);
    return;
  }
  @finally {
  }
  
  [ec1 startNewGame];
  if(ec2) [ec2 startNewGame];
  [game release];
  game = newGame;
  gameMode = BOTH;
  [ec1 setRole: IDLE];
  boardIsFlipped = NO;
  playerNamesWereEdited = NO;
  [boardView setNeedsDisplay: YES];
  [self displayPlayerNames];
  [self displayMoveList];
  //  [moveListView setString: [self moveListString]];
  // [[game currentPosition] display];
}

-(IBAction)newGame:(id)sender {
  [ec1 startNewGame];
  if(ec2) [ec2 startNewGame];
  [game release];
  game = [[Game alloc] init];
  [game setWhitePlayer: NSFullUserName()];
  gameMode = COMPUTER_BLACK;
  [ec1 setRole: PLAYING_BLACK];
  boardIsFlipped = NO;
  playerNamesWereEdited = NO;
  [boardView setNeedsDisplay: YES];
  [moveListView setString: @""];
}

-(void)newGameWithFRCId:(int)FRCId {
  [ec1 startNewGame];
  if(ec2) [ec2 startNewGame];
  [game release];
  game = [[Game alloc] initWithFRCid: FRCId];
  [game setWhitePlayer: NSFullUserName()];
  gameMode = COMPUTER_BLACK;
  [ec1 setRole: PLAYING_BLACK];
  boardIsFlipped = NO;
  playerNamesWereEdited = NO;
  [boardView setNeedsDisplay: YES];
  [moveListView setString: @""];
}

-(IBAction)newFRCGame:(id)sender {
  [NSApp beginSheet: frcSheet
         modalForWindow: boardWindow
         modalDelegate: self
         didEndSelector: @selector(frcSheetDidEnd:returnCode:contextInfo:)
         contextInfo: nil];
}

-(IBAction)frcSheetOKPressed:(id)sender {
  [frcSheet orderOut: sender];
  [NSApp endSheet: frcSheet returnCode: 1];
}

-(IBAction)frcSheetCancelPressed:(id)sender {
  [frcSheet orderOut: sender];
  [NSApp endSheet: frcSheet returnCode: 0];
}

-(IBAction)frcSheetRandomPressed:(id)sender {
  [frcIdTextField setIntValue: abs([ChessClock currentSystemTime]) % 960];
}

-(void)frcSheetDidEnd:(NSWindow *)sheet
           returnCode:(int)returnCode
          contextInfo:(void *)contextInfo {
  if(returnCode == 1)
    [self newGameWithFRCId: [frcIdTextField intValue]];
}

-(IBAction)saveGame:(id)sender {
  NSSavePanel *panel = [NSSavePanel savePanel];

  [panel setRequiredFileType: @"pgn"];
  if([panel runModal] == NSOKButton) 
    [game saveToFile: [panel filename]];
}

-(IBAction)addGameToFile:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  NSArray *fileTypes = [NSArray arrayWithObjects: @"pgn", nil];

  if([panel runModalForTypes: fileTypes] == NSOKButton) 
    [game saveToFile: [panel filename]];
} 

-(IBAction)castleKingside:(id)sender {
  [self finishMakeMove: [[game currentPosition] generateOO]];
}

-(IBAction)castleQueenside:(id)sender {
  [self finishMakeMove: [[game currentPosition] generateOOO]];
}

-(IBAction)editPGNTags:(id)sender {
  [whiteTextField setStringValue: [game whitePlayer]];
  [blackTextField setStringValue: [game blackPlayer]];
  [eventTextField setStringValue: [game event]];
  [siteTextField setStringValue: [game site]];
  [dateTextField setStringValue: [game date]];
  [roundTextField setStringValue: [game round]];
  [resultPopup removeAllItems];
  [resultPopup addItemWithTitle: @"Unknown"];
  [resultPopup addItemWithTitle: @"1-0"];
  [resultPopup addItemWithTitle: @"0-1"];
  [resultPopup addItemWithTitle: @"1/2-1/2"];
  switch([game result]) {
  case UNKNOWN: [resultPopup selectItemAtIndex: 0]; break;
  case WHITE_WINS: [resultPopup selectItemAtIndex: 1]; break;
  case BLACK_WINS: [resultPopup selectItemAtIndex: 2]; break;
  case DRAW: [resultPopup selectItemAtIndex: 3]; break;
  }
		 
  [NSApp beginSheet: pgnTagsSheet
         modalForWindow: boardWindow
         modalDelegate: self
         didEndSelector: @selector(pgnTagsSheetDidEnd:returnCode:contextInfo:)
         contextInfo:nil];
}

-(IBAction)pgnTagsOKPressed:(id)sender {
  [pgnTagsSheet orderOut: sender];
  if(![[game whitePlayer] isEqualToString: [whiteTextField stringValue]]) {
    playerNamesWereEdited = YES;
    [game setWhitePlayer: [whiteTextField stringValue]];
  }
  if(![[game blackPlayer] isEqualToString: [blackTextField stringValue]]) {
    playerNamesWereEdited = YES;
    [game setBlackPlayer: [blackTextField stringValue]];
  }
  [game setEvent: [eventTextField stringValue]];
  [game setSite: [siteTextField stringValue]];
  [game setRound: [roundTextField stringValue]];
  switch([resultPopup indexOfSelectedItem]) {
  case 1: [game setResult: WHITE_WINS]; break;
  case 2: [game setResult: BLACK_WINS]; break;
  case 3: [game setResult: DRAW]; break;
  default: [game setResult: UNKNOWN];
  }
  [self displayPlayerNames];
  [NSApp endSheet: pgnTagsSheet returnCode: 1];
}

-(IBAction)pgnTagsCancelPressed:(id)sender {
  [pgnTagsSheet orderOut: sender];
  [NSApp endSheet: pgnTagsSheet returnCode: 0];
}

-(void)pgnTagsSheetDidEnd:(NSWindow *)sheet
               returnCode:(int)returnCode
              contextInfo:(void *)contextInfo {
}

-(IBAction)flipBoard:(id)sender {
  boardIsFlipped = !boardIsFlipped;
  [boardView setNeedsDisplay: YES];
}

-(IBAction)takeBack:(id)sender {
  [game unmakeMove];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)stepForward:(id)sender {
  [game stepForward];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)beginningOfGame:(id)sender {
  [game goToBeginningOfGame];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)endOfGame:(id)sender {
  [game goToEndOfGame];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)displayVariations:(id)sender {
  displayVariations = !displayVariations;
  if(!displayVariations)
    allowVariationEntry = NO;
  [self displayMoveList];
  //  [moveListView setString: [self moveListString]];
}

-(IBAction)displayComments:(id)sender {
  displayComments = !displayComments;
  [self displayMoveList];
  //  [moveListView setString: [self moveListString]];
}

-(IBAction)allowVariationEntry:(id)sender {
  allowVariationEntry = !allowVariationEntry;
  if(allowVariationEntry) 
    displayVariations = YES;
  [self displayMoveList];
  //  [moveListView setString: [self moveListString]];
}

-(IBAction)nextVariation:(id)sender {
  [game goToNextVariation];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)previousVariation:(id)sender {
  [game goToPreviousVariation];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)moveVariationUp:(id)sender {
  [game moveVariationUp];
  // [moveListView setString: [self moveListString]];
  [self displayMoveList];
}

-(IBAction)moveVariationDown:(id)sender {
  [game moveVariationDown];
  //  [moveListView setString: [self moveListString]];
  [self displayMoveList];
}

-(IBAction)beginningOfVariation:(id)sender {
  [game goToBeginningOfVariation];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)endOfVariation:(id)sender {
  [game goToEndOfVariation];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)backToBranchPoint:(id)sender {
  [game goBackToBranchPoint];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)forwardToBranchPoint:(id)sender {
  [game goForwardToBranchPoint];
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [boardView setNeedsDisplay: YES];
  [self displayMoveList];
  if(gameMode == ANALYSIS) [ec1 startAnalyseMode];
}

-(IBAction)deleteVariation:(id)sender {
  if(NSRunAlertPanel(@"Delete variation?",
		     @"You cannot undo this action.",
		     @"OK", @"Cancel", nil, nil)
     == NSAlertDefaultReturn) {
    [game deleteVariation];
    [boardView setNeedsDisplay: YES];
    //    [moveListView setString: [self moveListString]];
    [self displayMoveList];
  }
}

-(IBAction)addComment:(id)sender {
  if(commentWindowController)
    [commentWindowController release];
  commentWindowController = 
    [[CommentWindowController alloc] 
      initWithMove: [[game currentNode] move]
      boardController: self];
  [commentWindowController showWindow: self];
}

-(IBAction)deleteComment:(id)sender {
  if(NSRunAlertPanel(@"Delete comment?",
		     @"You cannot undo this action.",
		     @"OK", @"Cancel", nil, nil)
     == NSAlertDefaultReturn) {
    [game deleteComment];
    //    [moveListView setString: [self moveListString]];
    [self displayMoveList];
  }
}

-(void)setUpPositionWithFEN:(NSString *)fen {
  if(setupController) [setupController release];
  setupController = [[SetupR64WindowController alloc] 
		      initWithBoardController: self
		      FEN: fen];
  [setupController showWindow: self];
}  

-(IBAction)setUpPosition:(id)sender {
  [self setUpPositionWithFEN: [[game currentPosition] FENString]];
  /*
  if(setupController) [setupController release];
  setupController = [[SetupR64WindowController alloc] 
		      initWithBoardController: self
		      FEN: [[game currentPosition] FENString]];
  [setupController showWindow: self];
  */
}

-(IBAction)configureEngine:(id)sender {
  if(engineConfigController) 
    [engineConfigController release];
  engineConfigController = 
    [[EngineConfigController alloc] initWithEngine: [ec1 engine]];
  [engineConfigController showWindow: self];
}

-(void)setLevelType:(int)newLevelType {
  levelType = newLevelType;
}

-(void)setTimeControlWithWhiteTime:(int)wtime
			 blackTime:(int)btime
		    whiteIncrement:(int)winc
		    blackIncrement:(int)binc {
  [game setTimeControlWithWhiteTime: wtime
	blackTime: btime
	whiteIncrement: winc
	blackIncrement: binc];
}

-(void)setTimeControlWithWhiteTime:(int)wtime
			  forMoves:(int)wmoves
			 blackTime:(int)btime
			  forMoves:(int)bmoves {
  [game setTimeControlWithWhiteTime: wtime
	forMoves: wmoves
	blackTime: btime
	forMoves: bmoves];
}

-(IBAction)gameInX:(id)sender {
  levelType = BLITZ_LEVEL;
  levelTime = [sender tag];
  levelIncrement = 0;
  [self setTimeControlWithWhiteTime: levelTime * 60000
        blackTime: levelTime * 60000
        whiteIncrement: 0
        blackIncrement: 0];
}

-(IBAction)gameInXPlusY:(id)sender {
  levelType = FISCHER_LEVEL;
  levelTime = [sender tag];
  switch(levelTime) {
  case 1: case 2: case 5: levelIncrement = 1; break;
  case 10: levelIncrement = 2; break;
  default: levelIncrement = 5; break;
  }
  [self setTimeControlWithWhiteTime: levelTime * 60000
        blackTime: levelTime * 60000
        whiteIncrement: levelIncrement * 1000
        blackIncrement: levelIncrement * 1000];
}

-(IBAction)fourtyMovesInXMinutes:(id)sender {
  levelType = OLDFASHIONED_LEVEL;
  levelTime = [sender tag];
  levelIncrement = 0;
  [self setTimeControlWithWhiteTime: levelTime * 60000
	forMoves: 40
	blackTime: levelTime * 60000
	forMoves: 40];
}

-(IBAction)customLevel:(id)sender {
  if(customLevelController) 
    [customLevelController release];
  customLevelController = 
    [[CustomLevelController alloc] initWithBoardController: self];
  [customLevelController showWindow: self];
}

-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
  SEL action = [menuItem action];
  if(NO) {
  }
  else if(action == @selector(castleKingside:)) {
    if([[game currentPosition] sideToMoveCanCastleKingsideImmediately])
      return YES;
    else
      return NO;
  }
  else if(action == @selector(castleQueenside:)) {
    if([[game currentPosition] sideToMoveCanCastleQueensideImmediately])
      return YES;
    else
      return NO;
  }
  else if(action == @selector(takeBack:) || 
	  action == @selector(beginningOfGame:))
    return ![self isAtBeginningOfGame];
  else if(action == @selector(stepForward:) || action == @selector(endOfGame:))
    return ![self isAtEndOfGame];
  else if(action == @selector(allowVariationEntry:)) {
    if(allowVariationEntry)
      [menuItem setTitle: @"Disable Variation Entry"];
    else
      [menuItem setTitle: @"Enable Variation Entry"];
    return YES;
  }
  else if(action == @selector(displayVariations:)) {
    if(displayVariations)
      [menuItem setTitle: @"Hide Variations"];
    else
      [menuItem setTitle: @"Show Variations"];
    return ![game isInAVariation];
  }
  else if(action == @selector(displayComments:)) {
    if(displayComments)
      [menuItem setTitle: @"Hide Comments"];
    else
      [menuItem setTitle: @"Show Comments"];
    return YES;
  }
  else if(action == @selector(nextVariation:)) {
    if(!displayVariations) return NO;
    if(![game nextVariationExists]) return NO;
    return YES;
  }
  else if(action == @selector(previousVariation:)) {
    if(!displayVariations) return NO;
    if(![game previousVariationExists]) return NO;
    return YES;
  }
  else if(action == @selector(backToBranchPoint:)) {
    //    if(!displayVariations) return NO;
    if(![game branchPointExistsUp]) return NO;
    return YES;
  }
  else if(action == @selector(forwardToBranchPoint:)) {
    //    if(!displayVariations) return NO;
    if(![game branchPointExistsDown]) return NO;
    return YES;
  }
  else if(action == @selector(beginningOfVariation:)) {
    if([game isAtBeginningOfVariation]) return NO;
    return YES;
  }
  else if(action == @selector(endOfVariation:)) {
    if([game isAtEndOfVariation]) return NO;
    return YES;
  }
  else if(action == @selector(moveVariationUp:)) {
    if(!displayVariations) return NO;
    if(!allowVariationEntry) return NO;
    if(![game previousVariationExists]) return NO;
    return YES;
  }
  else if(action == @selector(moveVariationDown:)) {
    if(!displayVariations) return NO;
    if(!allowVariationEntry) return NO;
    if(![game nextVariationExists]) return NO;
    return YES;
  }
  else if(action == @selector(deleteComment:)) {
    if([game commentExistsForCurrentMove]) return YES;
    return NO;
  }
  else if(action == @selector(configureEngine:)) {
    [menuItem setTitle: [NSString stringWithFormat: @"Configure %@...",
				  [ec1 engineName]]];
    return YES;
  }
  else if(action == @selector(gameInX:)) {
    if(levelType == BLITZ_LEVEL) {
      int tag = [menuItem tag];
      if(tag == levelTime) [menuItem setState: NSOnState];
      else [menuItem setState: NSOffState];
    }
    else [menuItem setState: NSOffState];
  }
  else if(action == @selector(gameInXPlusY:)) {
    if(levelType == FISCHER_LEVEL) {
      int tag = [menuItem tag];
      if(tag == levelTime) [menuItem setState: NSOnState];
      else [menuItem setState: NSOffState];
    }
    else [menuItem setState: NSOffState];
  }
  else if(action == @selector(fourtyMovesInXMinutes:)) {
    if(levelType == OLDFASHIONED_LEVEL) {
      int tag = [menuItem tag];
      if(tag == levelTime) [menuItem setState: NSOnState];
      else [menuItem setState: NSOffState];
    }
    else [menuItem setState: NSOffState];
    return YES;
  }
  else if(action == @selector(customLevel:)) {
    if(levelType == CUSTOM_LEVEL) [menuItem setState: NSOnState];
    else [menuItem setState: NSOffState];
  }
  else if(action == @selector(limitStrength:)) {
    if([[ec1 engine] supportsLimitStrength])
      return YES;
    else
      return NO;
  }
  return YES;
}

-(Game *)game {
  return game;
}

-(IBAction)analysisMode:(id)sender {
  gameMode = ANALYSIS;
  [ec1 abortThinking];
  [ec1 setPositionFromGame: game];
  [ec1 startAnalyseMode];
}

-(IBAction)computerPlaysBlack:(id)sender {
  gameMode = COMPUTER_BLACK;
  if(!playerNamesWereEdited) {
    [game setBlackPlayer: [ec1 engineName]];
    [game setWhitePlayer: NSFullUserName()];
    [self displayPlayerNames];
  }
  [ec1 setRole: PLAYING_BLACK];
  if([game blackToMove]) {
    [game pushClock];
    if([[ec1 engine] shouldUseGUIBook]) {
      ChessMove *bookMove = [guiBook pickMoveForPosition: [game currentPosition]
				     withVariety: 0];
      if(bookMove != nil) {
	[self animateMove: bookMove];
	[game makeMove: bookMove];
	[self displayMoveList];
	[boardView setNeedsDisplay: YES];
      }
      else [ec1 moveWasMade];
    }
    else [ec1 moveWasMade];
  }
}

-(IBAction)computerPlaysWhite:(id)sender {
  gameMode = COMPUTER_WHITE;
  if(!playerNamesWereEdited) {
    [game setWhitePlayer: [ec1 engineName]];
    [game setBlackPlayer: NSFullUserName()];
    [self displayPlayerNames];
  }
  [ec1 setRole: PLAYING_WHITE];
  if([game whiteToMove]) {
    [game pushClock];
    if([[ec1 engine] shouldUseGUIBook]) {
      ChessMove *bookMove = [guiBook pickMoveForPosition: [game currentPosition]
				     withVariety: 0];
      if(bookMove != nil) {
	[self animateMove: bookMove];
	[game makeMove: bookMove];
	[self displayMoveList];
	[boardView setNeedsDisplay: YES];
      }
      else [ec1 moveWasMade];
    }
    else [ec1 moveWasMade];
  }
}

-(IBAction)humanPlaysBoth:(id)sender {
  gameMode = BOTH;
  [ec1 setRole: IDLE];
  [ec1 stopThinking];
}

-(IBAction)engineMatch:(id)sender {
  //  gameMode = ENGINE_MATCH;
  if(newEngineMatchController)
    [newEngineMatchController release];
  newEngineMatchController = 
    [[NewEngineMatchController alloc] initWithBoardController: self];
  [newEngineMatchController showWindow: self];
}

-(IBAction)limitStrength:(id)sender {
  UCIOption *option = [[ec1 engine] optionWithName: @"UCI_Elo"];
  [strengthSlider setMaxValue: [option max]];
  [strengthSlider setMinValue: [option min]];
  [strengthSlider setIntValue: [[option value] intValue]];
  [strengthEloTextField setIntValue: [[option value] intValue]];

  [NSApp beginSheet: strengthSheet
	 modalForWindow: boardWindow
	 modalDelegate: self
	 didEndSelector: @selector(strengthSheetDidEnd:returnCode:contextInfo:)
	 contextInfo: nil];
}

-(IBAction)strengthSheetOKPressed:(id)sender {
  UCIOption *option = [[ec1 engine] optionWithName: @"UCI_Elo"];
  
  if([strengthSlider intValue] == [option max]) {
    [[ec1 engine] setOptionName: @"UCI_LimitStrength" value: @"false"];
    [[ec1 engine] setOptionName: @"UCI_Elo" value: [option defaultValue]];
  }
  else {
    [[ec1 engine] setOptionName: @"UCI_LimitStrength" value: @"true"];
    [[ec1 engine] setOptionName: @"UCI_Elo"
		  value: [NSString stringWithFormat: @"%d",
				   [strengthSlider intValue]]];
  }
    
  [strengthSheet orderOut: sender];
  [NSApp endSheet: strengthSheet returnCode: 1];
}

-(void)strengthSheetDidEnd:(NSWindow *)sheet
		returnCode:(int)returnCode
	       contextInfo:(void *)contextInfo {
}


-(int)gameMode {
  return gameMode;
}

-(void)switchMainEngineTo:(NSString *)newMainEngine {
  [[ec1 engine] quit];
  [ec1 close];
  [ec1 release];
  ec1 = [[EngineController alloc] 
	  initWithBoardController: self name: newMainEngine];
  // If we are at the beginning of the game, update the player names at the
  // top of the move list window:
  if([game isAtBeginningOfGame] && [game isAtEndOfGame] &&
     !playerNamesWereEdited) {
    [game setBlackPlayer: [ec1 engineName]];
    // [self displayPlayerNames];
  }

  [ec1 showWindow: self];
}

-(void)continueAutoplayWithEngine1White:(BOOL)engine1White 
		    enginesShouldPonder:(BOOL)shouldPonder {
  gameMode = BOTH;
  [ec1 setRole: IDLE];
  [ec2 setRole: IDLE];
  if(engine1White) {
    [game setWhitePlayer: [ec1 engineName]];
    [game setBlackPlayer: [ec2 engineName]];
  }
  else {
    [game setWhitePlayer: [ec2 engineName]];
    [game setBlackPlayer: [ec1 engineName]];
  }  
  [self displayPlayerNames];

  gameMode = ENGINE_MATCH;
  [ec1 setShouldPonder: shouldPonder];
  [ec2 setShouldPonder: shouldPonder];

  if(engine1White) {
    [ec1 setRole: PLAYING_WHITE];
    [ec2 setRole: PLAYING_BLACK];
  }
  else {
    [ec1 setRole: PLAYING_BLACK];
    [ec2 setRole: PLAYING_WHITE];
  }

  //  [game pushClock];

  if((engine1White && [game whiteToMove]) || 
     (!engine1White && [game blackToMove])) { 
    if([[ec1 engine] shouldUseGUIBook]) {
      ChessMove *bookMove = [guiBook pickMoveForPosition: [game currentPosition]
				     withVariety: 0];
      if(bookMove != nil)
	[self engineMadeMove: bookMove comment: nil];
      else [ec1 moveWasMade];
    }
    else [ec1 moveWasMade];
  }
  else { // engine 2 to move:
    if([[ec2 engine] shouldUseGUIBook]) {
      ChessMove *bookMove = [guiBook pickMoveForPosition: [game currentPosition]
				     withVariety: 0];
      if(bookMove != nil)
	[self engineMadeMove: bookMove comment: nil];
      else [ec2 moveWasMade];
    }
    else [ec2 moveWasMade];
  }
}

-(void)autoplayWithWhiteEngine:(NSString *)whiteEngine
		   blackEngine:(NSString *)blackEngine 
	   enginesShouldPonder:(BOOL)shouldPonder {
  NSString *engine;
  EngineController *ec;

  gameMode = BOTH;
  
  [[ec1 engine] quit];
  [ec1 close];
  [ec1 release];
  ec1 = [[EngineController alloc] 
	  initWithBoardController: self name: whiteEngine];
  [ec1 setRole: IDLE];
  [ec1 showWindow: self];
  if(ec2) {
    [[ec2 engine] quit];
    [ec2 close];
    [ec2 release];
  }
  ec2 = [[EngineController alloc] 
	  initWithBoardController: self name: blackEngine];
  [ec2 setRole: IDLE];
  [ec2 showWindow: self];

  [game setWhitePlayer: whiteEngine];
  [game setBlackPlayer: blackEngine];
  [self displayPlayerNames];

  gameMode = ENGINE_MATCH;

  [ec1 setShouldPonder: shouldPonder];
  [ec2 setShouldPonder: shouldPonder];
  [ec1 setRole: PLAYING_WHITE];
  [ec2 setRole: PLAYING_BLACK];

  if([game whiteToMove]) {
    engine = whiteEngine;
    ec = ec1;
  }
  else {
    engine = blackEngine;
    ec = ec2;
  }

  //  [game pushClock];

  // It would have seemed more natural to use [[ec1 engine] shouldUseGUIBook]
  // in the "if" statement below, but this will not always work, because it
  // could happen that the engine has not finished initializing.  In this
  // case, the engine's "name" slot will still be empty, and
  // [[ec1 engine] shouldUseGUIBook will always return NO.
  if([Engine useGUIBookForEngineWithName: engine]) {
    ChessMove *bookMove = [guiBook pickMoveForPosition: [game currentPosition]
				   withVariety: 0];
    if(bookMove != nil) 
      [self engineMadeMove: bookMove comment: nil];
    else [ec moveWasMade];
  }
  else [ec moveWasMade];
}

-(void)startMatchWithEngine1:(NSString *)engine1
		     engine2:(NSString *)engine2
	  engine1InitialTime:(int)engine1Time
	  engine2InitialTime:(int)engine2Time
	    engine1Increment:(int)engine1Increment
	    engine2Increment:(int)engine2Increment
	       numberOfGames:(int)numOfGames
		    saveFile:(NSString *)saveFile
		positionFile:(NSString *)positionFile
			 FRC:(BOOL)frc 
		      ponder:(BOOL)ponder {
  if(engineMatchController)
    [engineMatchController release];
  engineMatchController = 
    [[MatchController alloc] initWithBoardController: self
			     engine1: engine1
			     engine2: engine2
			     engine1Time: engine1Time
			     engine2Time: engine2Time
			     engine1Increment: engine1Increment
			     engine2Increment: engine2Increment
			     numberOfGames: numOfGames
			     saveFile: saveFile
			     positionFile: positionFile
			     FRC: frc
			     ponder: ponder];
  [engineMatchController showWindow: self];
  [engineMatchController startMatch];
}

-(void)stopEngine2 {
  if(ec2) {
    [[ec2 engine] quit];
    [ec2 close];
    [ec2 release];
    ec2 = nil;
  }
}

-(IBAction)promotionChoice:(id)sender {
  [NSApp stopModalWithCode: [sender tag]];
}

-(void)boardColorsChanged:(NSNotification *)aNotification {
  [boardView setNeedsDisplay: YES];
}

-(void)toggleTournamentMode {
  tournamentMode = !tournamentMode;
}

-(void)toggleBeep:(NSNotification *)aNotification {
  beep = !beep;
}

-(void)increaseWhiteTime {
  if(tournamentMode) {
    [[game clock] addTimeForWhite: 5000];
    [clockTextField setStringValue: [game clockString]];
  }
}

-(void)decreaseWhiteTime {
  if(tournamentMode) {
    [[game clock] addTimeForWhite: -5000];
    [clockTextField setStringValue: [game clockString]];
  }
}

-(void)increaseBlackTime {
  if(tournamentMode) {
    [[game clock] addTimeForBlack: 5000];
    [clockTextField setStringValue: [game clockString]];
  }
}

-(void)decreaseBlackTime {
  if(tournamentMode) {
    [[game clock] addTimeForBlack: -5000];
    [clockTextField setStringValue: [game clockString]];
  }
}


-(IBAction)saveBoardAsPNG:(id)sender {
  NSSavePanel *panel = [NSSavePanel savePanel];

  [panel setRequiredFileType: @"png"];
  if([panel runModal] == NSOKButton)
    [boardView saveBoardAsPNG: [panel filename]];
}


-(void)dealloc {
  NSLog(@"Destroying %@", self);
  [ec1 release];
  [timer invalidate];
  [timer release];
  [game release];
  [ec1 release];
  if(ec2) [ec2 release];
  [engineConfigController release];
  [guiBook release];
  [super dealloc];
}


@end
