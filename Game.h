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
#import "GameNode.h"
#import "ChessPosition.h"
#import "ChessMove.h"
#import "ChessClock.h"

@interface Game : NSObject {
  NSString *whitePlayer;
  NSString *blackPlayer;
  NSString *event;
  NSString *site;
  NSString *round;
  NSString *date;
  result_t result;
  NSString *rootFEN;
  GameNode *root;
  GameNode *currentNode;
  ChessClock *clock;
  BOOL FRC;
}

-(id)initWithFEN:(NSString *)fen;
-(id)initWithFRCid:(int)FRCid;
-(id)initWithPGNString:(NSString *)string;
-(id)init;
-(ChessClock *)clock;
-(NSString *)rootFEN;
-(NSString *)whitePlayer;
-(void)setWhitePlayer:(NSString *)str;
-(NSString *)blackPlayer;
-(void)setBlackPlayer:(NSString *)str;
-(NSString *)event;
-(void)setEvent:(NSString *)str;
-(NSString *)site;
-(void)setSite:(NSString *)str;
-(NSString *)date;
-(void)setDate:(NSString *)str;
-(NSString *)round;
-(void)setRound:(NSString *)str;
-(result_t)result;
-(void)setResult:(result_t)r;
-(id)root;
-(id)currentNode;
-(id)currentPosition;
-(int)pieceAtSquare:(int)squareIndex;
-(void)insertMove:(ChessMove *)move;
-(void)makeMove:(ChessMove *)move;
-(void)unmakeMove;
-(void)stepForward;
-(void)goToBeginningOfGame;
-(void)goToEndOfGame;
-(BOOL)isAtBeginningOfGame;
-(BOOL)isAtEndOfGame;
-(BOOL)previousVariationExists;
-(BOOL)nextVariationExists;
-(void)goToPreviousVariation;
-(void)goToNextVariation;
-(void)moveVariationUp;
-(void)moveVariationDown;
-(BOOL)branchPointExistsUp;
-(BOOL)branchPointExistsDown;
-(void)goBackToBranchPoint;
-(void)goForwardToBranchPoint;
-(BOOL)isAtBeginningOfVariation;
-(BOOL)isAtEndOfVariation;
-(void)goToBeginningOfVariation;
-(void)goToEndOfVariation;
-(void)deleteVariation;
-(BOOL)isInAVariation;
-(void)addComment:(NSString *)comment;
-(void)deleteComment;
-(BOOL)commentExistsForCurrentMove;
-(void)addNAG:(int)nag;
-(ChessMove *)parseSANMove:(NSString *)str;
-(NSString *)moveListString;
-(NSString *)moveListStringWithComments:(BOOL)includeComments
			     variations:(BOOL)includeVariations;
-(NSAttributedString *)moveListAttributedStringWithComments:(BOOL)includeComments
						 variations:(BOOL)includeVariations;
-(NSString *)PGNString;
-(ChessMove *)generateMoveFrom:(int)from to:(int)to 
		     promotion:(int)promotion;
-(ChessMove *)generateMoveFrom:(int)from to:(int)to;
-(BOOL)whiteToMove;
-(BOOL)blackToMove;
-(void)startClock;
-(void)stopClock;
-(int)whiteRemainingTime;
-(int)blackRemainingTime;
-(int)whiteIncrement;
-(int)blackIncrement;
-(NSString *)clockString;
-(BOOL)isFRCGame;
-(void)setIsFRCGame:(BOOL)isFRCGame;
-(void)setTimeControlWithWhiteTime:(int)whiteTime
                         blackTime:(int)blackTime
                    whiteIncrement:(int)whiteIncrement
                    blackIncrement:(int)blackIncrement;
-(void)setTimeControlWithWhiteTime:(int)whiteTime
			  forMoves:(int)whiteNumOfMoves
			 blackTime:(int)blackTime
			  forMoves:(int)blackNumOfMoves;
-(void)dealloc;
-(void)saveToFile:(NSString *)filename;

@end
