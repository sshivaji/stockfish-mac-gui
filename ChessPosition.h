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
#import "position.h"

@class ChessMove;

@interface ChessPosition : NSObject {
  position_t pos[1];
}

+(BOOL)looksLikeAFENString:(NSString *)string;

+(id)initialPosition;
+(id)positionAfterMakingMove:(ChessMove *)move 
		fromPosition:(ChessPosition *)position;
+(NSString *)fenFromFRCid:(int)FRCid;
+(id)positionWithFRCid:(int)FRCid;

-(id)initWithFEN:(NSString *)fen;
-(id)init;

-(NSString *)FENString;
-(NSString *)description;
-(void)display;
-(NSString *)moveToSAN:(NSString *)moveString;
-(NSString *)lineToSAN:(NSString *)lineString moveNumbers:(BOOL)moveNums;
-(NSString *)lineToSAN:(NSString *)lineString;
-(ChessMove *)parseSANMove:(NSString *)str;
-(ChessMove *)parseCoordinateMove:(NSString *)str;
-(position_t *)pos;
-(uint64_t)hashkey;
-(int)pieceAtSquare:(int)squareIndex;
-(BOOL)whiteToMove;
-(int)moveNumber;
-(ChessMove *)generateMoveFrom:(int)from to:(int)to 
			 promotion:(int)promotion;
-(ChessMove *)generateMoveFrom:(int)from to:(int)to;
-(int)countLegalMoves;
-(BOOL)moveFrom:(int)from to:(int)to promotion:(int)promotion;
-(BOOL)moveFrom:(int)from to:(int)to;
-(void)makeMove:(ChessMove *)move;
-(void)destinationSquaresFrom:(int)sqIndex storeIn:(int *)sqArray;
-(BOOL)isEqualToPosition:(ChessPosition *)aPosition;
-(BOOL)isMate;
-(BOOL)isRule50Draw;
-(BOOL)isRepetitionDraw;
-(BOOL)isMaterialDraw;
-(BOOL)isStalemate;
-(BOOL)isDraw;
-(BOOL)isTerminal;
-(BOOL)whiteCanCastleKingside;
-(BOOL)whiteCanCastleQueenside;
-(BOOL)blackCanCastleKingside;
-(BOOL)blackCanCastleQueenside;
-(BOOL)sideToMoveCanCastleKingsideImmediately;
-(BOOL)sideToMoveCanCastleQueensideImmediately;
-(ChessMove *)generateOO;
-(ChessMove *)generateOOO;
-(NSString *)UCIStringFromOOMove:(ChessMove *)move;
-(NSString *)UCIStringFromOOOMove:(ChessMove *)move;


// USE THE FOLLOWING FUNCTIONS ONLY IF YOU REALLY KNOW WHAT YOU'RE DOING!
// They will usually leave the position object in an inconsistent state.
-(void)putPiece:(int)piece atSquare:(int)squareIndex;
-(void)removePieceAtSquare:(int)squareIndex;

@end
