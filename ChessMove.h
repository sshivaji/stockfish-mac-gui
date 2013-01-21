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
#import "ChessPosition.h"
#import "position.h"

@interface ChessMove : NSObject {
  move_t move;
  NSString *comment;
  NSString *SANString;
  int NAG;
  int time;
}

-(id)initWithPosition:(ChessPosition *)position move:(move_t)m;
-(move_t)move;
-(BOOL)isNullMove;
-(int)time;
-(void)setTime:(int)t;
-(NSString *)comment;
-(void)setComment:(NSString *)c;
-(void)deleteComment;
-(BOOL)hasComment;
-(int)NAG;
-(void)setNAG:(int)newNAG;
-(BOOL)hasNAG;
-(NSString *)UCIString;
-(NSString *)SANString;
-(NSString *)description;
-(BOOL)isCastle;
-(BOOL)isKingsideCastle;
-(BOOL)isQueensideCastle;
-(void)dealloc;

@end
