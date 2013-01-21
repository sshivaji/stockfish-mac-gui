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
#import "Engine.h"
#import "EngineController.h"
#import "Game.h"
#import "GameNode.h"
#import "position.h"

@implementation EngineController

-(id)initWithBoardController:(BoardController *)bc path:(NSString *)path {
  self = [super initWithWindowNibName: @"EngineWindow"];
  boardController = bc;
  currentPosition = [[ChessPosition alloc] initWithFEN: @"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"];
  pendingSearches = 0;
  engineRole = PLAYING_BLACK;
  shouldPonder = YES;
  pondering = NO;
  thinking = NO;
  engineIsReady = NO;
  subjectiveCPScore = 0;
  whiteScore = [[NSUserDefaults standardUserDefaults]
		 boolForKey: @"Display all Scores from White's Point of View"];
  commentMoves = [[NSUserDefaults standardUserDefaults]
		   boolForKey: @"Include Engine Analysis in Move List"];
  resignCounter = 0;
  shouldResignInHopelessPositions = 
    [[NSUserDefaults standardUserDefaults]
      boolForKey: @"Resign in Hopeless Positions"];
  engine = [[Engine alloc] initWithController: self path: path];
  [engine start];
  return self;
}

-(id)initWithBoardController:(BoardController *)bc name:(NSString *)name {
  return [self initWithBoardController: bc
	       path: [Engine pathOfEngineWithName: name]];
}

-(id)initWithBoardController:(BoardController *)bc {
  return [self initWithBoardController: bc
	       path: [Engine mainEnginePath]];
}

-(id)engine {
  return engine;
}

-(NSString *)engineName {
  return engineName;
}
-(void)setEngineName:(NSString *)newEngineName {
  [newEngineName retain];
  [engineName release];
  engineName = newEngineName;
  [[self window] setTitle: 
		   [NSString stringWithFormat: @"Analysis (%@)", engineName]];
}

-(void)setRole:(int)newRole {
  if(newRole == engineRole) return;
  [self abortThinking];
  engineRole = newRole;
  if(NO && engineRole != IDLE) {
    [self moveWasMade];  // HACK
  }
}

-(int)role {
  return engineRole;
}

-(void)setShouldPonder:(BOOL)newState {
  shouldPonder = newState;
}

-(NSString *)setposString {
  GameNode *node = [game currentNode];
  NSMutableArray *pathToRoot = [[NSMutableArray alloc] init];
  NSMutableString *result;
  int i;

  // Traverse the path from the current node up to the root, and store the
  // moves in an array:
  while([node parent]) {
    [pathToRoot addObject: [node move]];
    node = [node parent];
  }

  // Build the string:
  result = [NSMutableString stringWithFormat: @"position fen %@ ", 
                            [game rootFEN]];
  // if([node move]) [result appendFormat: @"moves "];
  if([pathToRoot count] > 0) [result appendFormat: @"moves "];
  for(i = [pathToRoot count] - 1; i >= 0; i--) {
    ChessMove *move = [pathToRoot objectAtIndex: i];
    if([game isFRCGame] && [move isKingsideCastle])
      [result appendFormat: @"%@ ",
	      [[game currentPosition] UCIStringFromOOMove: move]];
    else if([game isFRCGame] && [move isQueensideCastle])
      [result appendFormat: @"%@ ",
	      [[game currentPosition] UCIStringFromOOOMove: move]];
    else 
      [result appendFormat: @"%@ ", [[pathToRoot objectAtIndex: i] UCIString]];
  }
  
  [pathToRoot release];

  return result;
}

-(void)setCurrentPosition:(ChessPosition *)newPosition {
  copy_position([currentPosition pos], [newPosition pos]);
  legalMovesCount = [currentPosition countLegalMoves];
}

-(void)setPositionFromGame:(Game *)aGame {
  [game release];
  game = [aGame retain];
  [ponderMove release];
  [self setCurrentPosition: [game currentPosition]];
}

-(void)setPositionFromGame:(Game *)aGame withPonderMove:(ChessMove *)pmove {
}

-(void)stopThinking {
  if(thinking) [engine stop];
}

-(void)abortThinking {
  if(engineRole != ANALYSING) engineRole = IDLE;
  [self stopThinking];
}

-(void)moveWasMade {
  ChessPosition *p = [[boardController game] currentPosition];
  //  NSLog(@"in moveWasMade, engineRole is %d\n", engineRole);
  if(engineRole == IDLE) return;
  else if(pondering && [p isEqualToPosition: currentPosition]) { // Ponderhit
    pondering = NO;
    [engine ponderhit];
  }
  else {
    if(pondering) ponderedWrongMove = YES;
    if(pondering || engineRole == ANALYSING) 
      [self stopThinking];
    [self setPositionFromGame: [boardController game]];
    if(engineRole == ANALYSING)
      [self searchInfinite];
    else if(([game whiteToMove] && engineRole == PLAYING_WHITE) ||
	    ([game blackToMove] && engineRole == PLAYING_BLACK))
      [self searchWithWtime: [game whiteRemainingTime]
	    btime: [game blackRemainingTime]
	    winc: [game whiteIncrement]
	    binc: [game blackIncrement]];
  }
}

-(void)windowDidLoad {
  [[self window] setTitle: @"Analysis"];
  [[self window] setFloatingPanel: NO];
}

-(void)clearWindow {
  [self setDepth: @""];
  [self setMove: @"" number: @""];
  [self setTime: @""];
  [self setCPScore: @"" scoreType: 0];
  [self setMateScore: @"" scoreType: 0];
  [self setNodes: @""];
  [self setNPS: @""];
  [self setPV: @""];
}

-(void)setDepth:(NSString *)depth {
  if(pendingSearches != 1) return;
  currentDepth = [depth intValue];
  [depthTextField setStringValue: 
                    [NSString stringWithFormat: @"Depth: %@", depth]];
}

-(void)setMove:(NSString *)move number:(NSString *)num {
  if(pendingSearches != 1) return;
  if(!engineIsReady) return;
  [moveTextField setStringValue: 
                   [NSString stringWithFormat: @"Move: %@ (%@/%d)", 
                             [currentPosition moveToSAN: move], 
                             num, legalMovesCount]];
}

-(void)setTime:(NSString *)time {
  currentTime = [time intValue];
}

-(void)setCPScore:(NSString *)score scoreType:(int)scoreType {
  int value = [score intValue];
  static char scoreTypeChar[3][2] = { ">", "", "<" };

  if(pendingSearches != 1) return;
  if(!engineIsReady) return;

  subjectiveCPScore = value;

  if(whiteScore && ![currentPosition whiteToMove]) {
    value = -value;
    scoreType = -scoreType;
  }

  currentMateScore = 0;
  currentCPScore = value;
  if(value >= 0) 
    [scoreTextField setStringValue:
		      [NSString stringWithFormat: @"Score: %s+%.2f",
                                scoreTypeChar[scoreType + 1],
				(float)value / 100.0]];
  else
    [scoreTextField setStringValue: 
		      [NSString stringWithFormat: @"Score: %s%.2f",
                                scoreTypeChar[scoreType + 1],
				(float)value / 100.0]];
}

-(void)setMateScore:(NSString *)score scoreType:(int)scoreType {
  int value = [score intValue];
  static char scoreTypeChar[3][2] = { ">", "", "<" };
  
  if(pendingSearches != 1) return;
  if(!engineIsReady) return;

  if(whiteScore && ![currentPosition whiteToMove]) {
    value = -value;
    scoreType = -scoreType;
  }

  currentMateScore = value;
  if(value >= 0)
    [scoreTextField setStringValue:
                      [NSString stringWithFormat: @"Score: %s+#%d",
                                scoreTypeChar[scoreType + 1],
                                value]];
  else
    [scoreTextField setStringValue:
                      [NSString stringWithFormat: @"Score: %s-#%d",
                                scoreTypeChar[scoreType + 1],
                                -value]];
}

-(void)setNodes:(NSString *)nodes {
  if(pendingSearches != 1) return;
  if(!engineIsReady) return;
  currentNodeCount = [nodes intValue];
  [nodesTextField setStringValue: 
                    [NSString stringWithFormat: @"Nodes: %@", nodes]];
}

-(void)setNPS:(NSString *)nps {
  if(pendingSearches != 1) return;
  if(!engineIsReady) return;
  [npsTextField setStringValue: 
                    [NSString stringWithFormat: @"Nodes/second: %@", nps]];
}

-(void)setPV:(NSString *)pv {
  if(pendingSearches != 1) return;
  if(!engineIsReady) return;
  if(pondering)
    [pvTextField setStringValue: 
		   [NSString stringWithFormat: @"Main Line: (%@) %@", 
			     ponderMoveString,
			     [currentPosition lineToSAN: pv]]];
  else
    [pvTextField setStringValue: 
		   [NSString stringWithFormat: @"Main Line: %@", 
			     [currentPosition lineToSAN: pv]]];
}

-(NSString *)moveComment {
  if(!commentMoves) return nil;
  if(currentMateScore == 0 && currentCPScore >= 0)
    return [NSString stringWithFormat: @"+%.2f/%d",
		     (float)currentCPScore / 100.0, currentDepth];
  else if(currentMateScore == 0 && currentCPScore < 0)
    return [NSString stringWithFormat: @"%.2f/%d",
		     (float)currentCPScore / 100.0, currentDepth];
  else if(currentMateScore > 0)
    return [NSString stringWithFormat: @"+#%d/%d",
		     currentMateScore, currentDepth];
  else
    return [NSString stringWithFormat: @"-#%d/%d",
		     -currentMateScore, currentDepth];
}

-(void)bestmove:(NSString *)bestmove ponder:(NSString *)ponder {
  ChessMove *move, *pmove;
  //  NSLog(@"in bestmove:ponder:, bestmove is %@, ponder is %@, ponderedWrongMove = %d, pondering is %d, engineRole = %d", 
  //	bestmove, ponder, ponderedWrongMove, pondering, engineRole);
  pendingSearches--;
  if(pendingSearches == 0) thinking = NO;
  if(engineRole == IDLE) return;
  if(!engineIsReady) return;
  if([bestmove isEqualToString: @"0000"]) return;

  if(pendingSearches == 0 && engineRole != ANALYSING &&
     !(pondering && ponderedWrongMove)) {

    if(subjectiveCPScore <= -600 && currentMateScore == 0 && currentDepth >= 6) {
      resignCounter++;
    }

    pondering = NO;
    move = [[currentPosition parseCoordinateMove: bestmove] retain];
    if(shouldPonder && ponder) {
      [currentPosition makeMove: move];
      pmove = [[currentPosition parseCoordinateMove: ponder] retain];
      [ponderMoveString release];
      ponderMoveString = [[currentPosition moveToSAN: ponder] retain];
      [currentPosition makeMove: pmove];
      legalMovesCount = [currentPosition countLegalMoves];
      [self ponderWithWtime: [game whiteRemainingTime]
	    btime: [game blackRemainingTime]
	    winc: [game whiteIncrement]
	    binc: [game blackIncrement]
	    move: bestmove
	    pmove: ponder];
      [pmove release];
    }
    if(shouldResignInHopelessPositions && resignCounter >= 3)
      [boardController engineResigns];
    else 
      [boardController engineMadeMove: move 
		       comment: (currentDepth > 0)? [self moveComment] : nil];
    [move release];
  }
}

-(void)searchInfinite {
  if([[game currentPosition] isTerminal]) return;
  //  NSLog(@"Starting infinite search\n");
  pendingSearches++;
  thinking = YES;
  if(analysisOutput) {
    [previousAnalysisOutput release];
    previousAnalysisOutput = [[NSString stringWithString: analysisOutput]
			       retain];
  }
  [engine setOptionName: @"OwnBook" value: @"false"];
  [engine setOptionName: @"UCI_AnalyseMode" value: @"true"];
  if([game isFRCGame])
    [engine setOptionName: @"UCI_Chess960" value: @"true"];
  else
    [engine setOptionName: @"UCI_Chess960" value: @"false"];
  [engine setPosition: [self setposString]];
  [engine searchInfinite];
}

-(void)searchWithWtime:(int)wtime
                 btime:(int)btime
                  winc:(int)winc
                  binc:(int)binc {
  if([[game currentPosition] isTerminal]) return;
  pendingSearches++;
  pondering = NO;
  thinking = YES;
  if(analysisOutput) {
    [previousAnalysisOutput release];
    previousAnalysisOutput = [[NSString stringWithString: analysisOutput]
			       retain];
  }

  if(shouldPonder) 
    [engine setOptionName: @"Ponder" value: @"true"];
  else
    [engine setOptionName: @"Ponder" value: @"false"];
  if([engine shouldUseOwnBook])
    [engine setOptionName: @"OwnBook" value: @"true"];
  else
    [engine setOptionName: @"OwnBook" value: @"false"];

  [engine setOptionName: @"UCI_AnalyseMode" value: @"false"];
  if([game isFRCGame])
    [engine setOptionName: @"UCI_Chess960" value: @"true"];
  else
    [engine setOptionName: @"UCI_Chess960" value: @"false"];
  [engine setPosition: [self setposString]];
  [engine searchWithWtime: wtime
	  btime: btime
	  winc: winc
	  binc: binc];
}

-(void)ponderWithWtime:(int)wtime
                 btime:(int)btime
                  winc:(int)winc
                  binc:(int)binc 
		  move:(NSString *)move
		 pmove:(NSString *)pmove {
  pendingSearches++;
  thinking = YES;
  if(analysisOutput) {
    [previousAnalysisOutput release];
    previousAnalysisOutput = [[NSString stringWithString: analysisOutput]
			       retain];
  }
  pondering = YES;
  ponderedWrongMove = NO;
  [engine setOptionName: @"UCI_AnalyseMode" value: @"false"];
  if([game isFRCGame])
    [engine setOptionName: @"UCI_Chess960" value: @"true"];
  else
    [engine setOptionName: @"UCI_Chess960" value: @"false"];
  if([[game currentNode] parent])
    [engine setPosition:
	      [NSString stringWithFormat: 
			  @"%@%@ %@", [self setposString], move, pmove]];
  else
    [engine setPosition:
	      [NSString stringWithFormat:
			  @"%@ moves %@ %@", [self setposString], move, pmove]];
  [engine ponderWithWtime: wtime
	  btime: btime
	  winc: winc
	  binc: binc];
}

-(void)startAnalyseMode {
  [self stopThinking];
  pondering = NO;
  engineRole = ANALYSING;
  [self searchInfinite];
}

-(void)startNewGame {
  whiteScore = [[NSUserDefaults standardUserDefaults]
		 boolForKey: @"Display all Scores from White's Point of View"];
  commentMoves = [[NSUserDefaults standardUserDefaults]
		   boolForKey: @"Include Engine Analysis in Move List"];
  resignCounter = 0;
  shouldResignInHopelessPositions = 
    [[NSUserDefaults standardUserDefaults]
      boolForKey: @"Resign in Hopeless Positions"];
  currentDepth = 0;
  subjectiveCPScore = 0;
  engineRole = IDLE;
  [self stopThinking];
  [engine startNewGame];
  engineIsReady = NO;
  [engine askIfReady];
  [self clearWindow];
}

-(void)setEngineIsReady:(BOOL)state {
  engineIsReady = state;
}

-(void)dealloc {
  [currentPosition release];
  [engine quit];
  [engine release];
  [ponderMoveString release];
  [super dealloc];
}

@end
