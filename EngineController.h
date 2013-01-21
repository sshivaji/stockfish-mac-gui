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
@class ChessMove;
@class ChessPosition;
@class Engine;
@class Game;

enum {PLAYING_WHITE, PLAYING_BLACK, ANALYSING, IDLE};

@interface EngineController : NSWindowController {
  IBOutlet NSTextField *depthTextField;
  IBOutlet NSTextField *moveTextField;
  IBOutlet NSTextField *scoreTextField;
  IBOutlet NSTextField *nodesTextField;
  IBOutlet NSTextField *npsTextField;
  IBOutlet NSTextField *pvTextField;
  BoardController *boardController;
  Game *game;
  ChessMove *ponderMove;
  ChessPosition *currentPosition;  // Not necessarily equal to the current
                                   // position in the game, because we may be
                                   // pondering!
  NSString *engineName;
  int legalMovesCount;
  int pendingSearches;
  int engineRole;  // PLAYING_WHITE, PLAYING_BLACK, ANALYSING or IDLE
  BOOL thinking;
  BOOL shouldPonder;
  BOOL pondering;
  BOOL ponderedWrongMove;
  NSString *ponderMoveString;
  Engine *engine;
  BOOL engineIsReady;

  BOOL whiteScore, commentMoves;

  int currentTime, currentDepth, currentCPScore, currentMateScore;
  int currentNodeCount;

  int subjectiveCPScore;
  int resignCounter;
  BOOL shouldResignInHopelessPositions;

  NSMutableString *analysisOutput;
  NSString *previousAnalysisOutput;
}

-(id)initWithBoardController:(BoardController *)bc path:(NSString *)path;
-(id)initWithBoardController:(BoardController *)bc name:(NSString *)name;
-(id)initWithBoardController:(BoardController *)bc;
-(id)engine;
-(NSString *)engineName;
-(void)setEngineName:(NSString *)newEngineName;
-(void)setCurrentPosition:(ChessPosition *)newPosition;
-(void)setPositionFromGame:(Game *)aGame;
-(void)setPositionFromGame:(Game *)aGame withPonderMove:(ChessMove *)pmove;
-(void)clearWindow;
-(void)setDepth:(NSString *)depth;
-(void)setMove:(NSString *)move number:(NSString *)num;
-(void)setTime:(NSString *)time;
-(void)setCPScore:(NSString *)score scoreType: (int)scoreType;
-(void)setMateScore:(NSString *)score scoreType: (int)scoreType;
-(void)setNodes:(NSString *)nodes;
-(void)setNPS:(NSString *)nps;
-(void)setPV:(NSString *)pv;
-(void)bestmove:(NSString *)bestmove ponder:(NSString *)ponder;
-(void)searchInfinite;
-(void)searchWithWtime:(int)wtime
                 btime:(int)btime
                  winc:(int)winc
                  binc:(int)binc;
-(void)ponderWithWtime:(int)wtime
                 btime:(int)btime
                  winc:(int)winc
                  binc:(int)binc 
		  move:(NSString *)move
		 pmove:(NSString *)move;
-(void)setRole:(int)newRole;
-(int)role;
-(void)setShouldPonder:(BOOL)newState;
-(void)moveWasMade;
-(void)stopThinking;
-(void)abortThinking;
-(void)startAnalyseMode;
-(void)startNewGame;
-(void)setEngineIsReady:(BOOL)state;

@end
