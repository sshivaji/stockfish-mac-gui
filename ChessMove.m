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


#import "ChessMove.h"


@implementation ChessMove

-(id)initWithPosition:(ChessPosition *)position move:(move_t)m {
  char str[10];
  position_t *pos = [position pos];

  [super init];
  SANString = [[NSString stringWithUTF8String: san_string(pos, m, str)] retain];
  move = m;
  time = 0;
  return self;
}
	
-(void)setTime:(int)t {
  time = t;
}

-(move_t)move {
  return move;
}

-(BOOL)isNullMove {
  if(move == NullMove) return YES;
  else return NO;
}

-(int)time {
  return time;
}

-(NSString *)comment {
  return comment;
}

-(void)setComment:(NSString *)c {
  [c retain];
  [comment release];
  comment = c;
}

-(void)deleteComment {
  if(comment) {
    [comment release];
    comment = nil;
  }
}

-(BOOL)hasComment {
  if(comment) return YES;
  else return NO;
}

-(int)NAG {
  return NAG;
}

-(void)setNAG:(int)newNAG {
  NAG = newNAG;
}

-(BOOL)hasNAG {
  // Correct? Should check in PGN standard whether '$0' is possible!
  if(NAG == 0) return NO; 
  else return YES;
}

-(NSString *)UCIString {
  char str[16];
  move2str(move, str);
  return [NSString stringWithUTF8String: str];
}

-(NSString *)SANString {
  return SANString;
}

-(NSString *)description {
  if(comment)
    return [NSString stringWithFormat: @"<ChessMove: %@ {%@} (%d)>", 
                     SANString, comment, move];
  else
    return [NSString stringWithFormat: @"<ChessMove: %@ (%d)>", 
                     SANString, move];
}

-(BOOL)isCastle {
  if(MvCastle(move)) return YES;
  else return NO;
}
  
-(BOOL)isKingsideCastle {
  if(MvShortCastle(move)) return YES;
  else return NO;
}

-(BOOL)isQueensideCastle {
  if(MvLongCastle(move)) return YES;
  else return NO;
}

-(void)dealloc {
  //  NSLog(@"Destroying %@", self);
  [comment release];
  [SANString release];
  [super dealloc];
}

@end
