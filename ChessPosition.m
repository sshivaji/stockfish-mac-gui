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
#import "ChessMove.h"
#import "frc-fens.h"

@implementation ChessPosition

// The following method should be improved!
+(BOOL)looksLikeAFENString:(NSString *)string {
  NSCharacterSet *allowedFirstCharacters =
    [NSCharacterSet characterSetWithCharactersInString: 
		      @"pnbrqkPNBRQK12345678"];
  const char *cstring;
  int numOfSlashes, i;
  NSRange range;

  // Does the string start with a valid character?
  range = [string rangeOfCharacterFromSet: allowedFirstCharacters];
  if(range.location != 0) return NO;

  // Count the number of slashes:
  numOfSlashes = 0;
  cstring = [string UTF8String];
  for(i = 0; i < [string length]; i++)
    if(cstring[i] == '/') numOfSlashes++;
  if(numOfSlashes != 7) return NO;

  return YES;
}
  
+(void)initialize {
  init();
  [super initialize];
}

+(id)initialPosition {
  ChessPosition *p =
    [[ChessPosition alloc] 
      initWithFEN: [NSString stringWithUTF8String: STARTPOS]];
  [p autorelease];
  return p;
}

+(id)positionAfterMakingMove: (ChessMove *)move 
		fromPosition:(ChessPosition *)position {
  ChessPosition *newPosition = [[ChessPosition alloc] init];
  undo_info_t u[1];
  copy_position([newPosition pos], [position pos]);
  make_move([newPosition pos], [move move], u);
  [newPosition autorelease];
  return newPosition;
}

+(NSString *)fenFromFRCid:(int)FRCid {
  return [NSString stringWithUTF8String: FRCFens[FRCid]];
}

+(id)positionWithFRCid:(int)FRCid {
  ChessPosition *p = 
    [[ChessPosition alloc] initWithFEN: [ChessPosition fenFromFRCid: FRCid]];
  [p autorelease];
  return p;
}

-(id)initWithFEN:(NSString *)fen {
  [super init];
  position_from_fen(pos, [fen UTF8String]);
  return self;
}

-(id)init {
  [super init];
  return self;
}

-(NSString *)FENString {
  char str[256];
  return [NSString stringWithUTF8String: position_to_fen(pos, str)];
}

-(NSString *)description {
  return [NSString stringWithFormat: @"<ChessPosition: %@ (0x%llxULL)>", 
		   [self FENString], pos->key];
}

-(NSString *)moveToSAN:(NSString *)moveString {
  char str[16];
  return [NSString stringWithUTF8String:
                     san_move_from_string(pos, [moveString UTF8String], str)];
}

static char Str[2048];
-(NSString *)lineToSAN:(NSString *)lineString moveNumbers:(BOOL)moveNums {
  //  char str[2048];
  return [NSString stringWithUTF8String: 
                     san_line_from_string(pos, 0, NO, moveNums, 
                                          [lineString UTF8String], Str)];
}

-(NSString *)lineToSAN:(NSString *)lineString {
  return [self lineToSAN: lineString moveNumbers: YES];
}

-(position_t *)pos {
  return pos;
}

-(uint64_t)hashkey {
  return pos->key;
}

-(int)pieceAtSquare:(int)squareIndex {
  return pos->board[EXPAND(squareIndex)];
}

-(BOOL)whiteToMove {
  return (pos->side == WHITE)? YES : NO;
}

-(int)moveNumber {
  if((pos->side == WHITE && pos->gply % 2 == 0) ||
     (pos->side == BLACK && pos->gply % 2 == 1))
    return pos->gply / 2 + 1;
  else
    return pos->gply / 2 + 2;
}

-(ChessMove *)generateMoveFrom:(int)from to:(int)to 
		     promotion:(int)promotion {
  ChessMove *move;
  move = [[ChessMove alloc] 
	   initWithPosition: self 
	   move: find_move_matching(pos, EXPAND(from), EXPAND(to), promotion)];
  [move autorelease];
  return move;
}

-(ChessMove *)generateMoveFrom:(int)from to:(int)to {
  return [self generateMoveFrom: from to: to promotion: 0];
}

-(int)countLegalMoves {
  return count_legal_moves(pos);
}
  
-(BOOL)moveFrom:(int)from to:(int)to promotion:(int)promotion {
  move_t m = find_move_matching(pos, EXPAND(from), EXPAND(to), promotion);
  undo_info_t u[1];
  if(m == 0) return NO;
  make_move(pos, m, u);
  return YES;
}

-(BOOL)moveFrom:(int)from to:(int)to {
  return [self moveFrom:from to:to promotion:0];
}

-(void)makeMove:(ChessMove *)move {
  // Should check for legality!
  undo_info_t u[1];
  make_move(pos, [move move], u);
}

-(void)destinationSquaresFrom:(int)sqIndex storeIn:(int *)sqArray {
  find_destination_squares_from(pos, EXPAND(sqIndex), sqArray);
}

-(ChessMove *)parseSANMove:(NSString *)str {
  move_t m = parse_san_move(pos, [str UTF8String]);
  ChessMove *move;
  if(m == 0) return nil;
  move = [[ChessMove alloc] initWithPosition: self move: m];
  [move autorelease];
  return move;
}

// Parse move in g1f3 notation.  We should check for legality ...
-(ChessMove *)parseCoordinateMove:(NSString *)str {
  move_t m = parse_move(pos, [str UTF8String]);
  ChessMove *move = [[ChessMove alloc] initWithPosition: self move:m];
  [move autorelease];
  return move;
}

-(void)display {
  print_position(pos);
}

-(BOOL)isEqualToPosition:(ChessPosition *)aPosition {
  if([aPosition pos]->key == [self pos]->key)
    return YES;
  else
    return NO;
}

-(BOOL)isMate {
  return position_is_mate(pos);
}

-(BOOL)isRule50Draw {
  return position_is_rule50_draw(pos);
}

-(BOOL)isRepetitionDraw {
  return position_is_repetition_draw(pos);
}

-(BOOL)isMaterialDraw {
  return position_is_material_draw(pos);
}

-(BOOL)isStalemate {
  return position_is_stalemate(pos);
}

-(BOOL)isDraw {
  return position_is_draw(pos);
}

-(BOOL)isTerminal {
  return (position_is_mate(pos) || position_is_draw(pos));
}

-(BOOL)whiteCanCastleKingside {
  if(CanCastleKingside(pos, WHITE)) return YES;
  else return NO;
}

-(BOOL)whiteCanCastleQueenside {
  if(CanCastleQueenside(pos, WHITE)) return YES;
  else return NO;
}

-(BOOL)blackCanCastleKingside {
  if(CanCastleKingside(pos, BLACK)) return YES;
  else return NO;
}

-(BOOL)blackCanCastleQueenside {
  if(CanCastleQueenside(pos, BLACK)) return YES;
  else return NO;
}

-(BOOL)sideToMoveCanCastleKingsideImmediately {
  if(can_castle_kingside(pos)) return YES;
  else return NO;
}

-(BOOL)sideToMoveCanCastleQueensideImmediately {
  if(can_castle_queenside(pos)) return YES;
  else return NO;
}

-(ChessMove *)generateOO {
  ChessMove *move;
  move = [[ChessMove alloc]
	   initWithPosition: self
	   move: can_castle_kingside(pos)];
  [move autorelease];
  return move;
}

-(ChessMove *)generateOOO {
  ChessMove *move;
  move = [[ChessMove alloc]
	   initWithPosition: self
	   move: can_castle_queenside(pos)];
  [move autorelease];
  return move;
}

-(NSString *)UCIStringFromOOMove:(ChessMove *)move {
  int rank = SquareRank(MvFrom([move move]));
  return [NSString stringWithFormat: @"%c%d%c%d",
		   pos->initial_ksq + 'a', rank + 1,
		   pos->initial_krsq + 'a', rank + 1];
}

-(NSString *)UCIStringFromOOOMove:(ChessMove *)move {
  int rank = SquareRank(MvFrom([move move]));
  return [NSString stringWithFormat: @"%c%d%c%d",
		   pos->initial_ksq + 'a', rank + 1,
		   pos->initial_qrsq + 'a', rank + 1];
}

-(void)putPiece:(int)piece atSquare:(int)squareIndex {
  pos->board[EXPAND(squareIndex)] = piece;
}


// USE THE FOLLOWING FUNCTIONS ONLY IF YOU REALLY KNOW WHAT YOU'RE DOING!
// They will usually leave the position object in an inconsistent state.
-(void)removePieceAtSquare:(int)squareIndex {
  pos->board[EXPAND(squareIndex)] = EMPTY;
}

-(void)dealloc {
  //  NSLog(@"Destroying %@", self);
  [super dealloc];
}

@end
