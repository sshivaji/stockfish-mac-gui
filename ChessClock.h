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


@interface ChessClock : NSObject {
  int whiteInitialTime, blackInitialTime;
  int whiteIncrement, blackIncrement;
  int whiteConsumedTime, blackConsumedTime;
  int whiteAccumulatedIncrement, blackAccumulatedIncrement;
  int whiteNumOfMoves, blackNumOfMoves;
  int whiteRemainingMoves, blackRemainingMoves;
  BOOL isRunning, isRunningForWhite, isRunningForBlack;
  int lastStartTime;
}

+(int)currentSystemTime;
+(NSString *)prettyTimeString:(int)msecs;
-(id)initWithWhiteTime:(int)wtime 
	     blackTime:(int)btime
	whiteIncrement:(int)winc
	blackIncrement:(int)binc;
-(id)initWithTime:(int)time increment:(int)inc;
-(id)initWithWhiteTime:(int)wtime forMoves:(int)wNumOfMoves
	     blackTime:(int)btime forMoves:(int)bNumOfMoves;
-(id)initWithTime:(int)time forMoves:(int)numOfMoves;
-(id)init;
-(void)resetWithWhiteTime:(int)wtime
                blackTime:(int)btime
           whiteIncrement:(int)winc
           blackIncrement:(int)binc;
-(void)resetWithWhiteTime:(int)wtime
		 forMoves:(int)wNumOfMoves
		blackTime:(int)btime
		 forMoves:(int)bNumOfMoves;
-(BOOL)isRunning;
-(int)whiteRemainingTime;
-(int)blackRemainingTime;
-(NSString *)whiteRemainingTimeString;
-(NSString *)blackRemainingTimeString;
-(int)whiteInitialTime;
-(void)setWhiteInitialTime:(int)newTime;
-(int)blackInitialTime;
-(void)setBlackInitialTime:(int)newTime;
-(int)whiteIncrement;
-(void)setWhiteIncrement:(int)newIncrement;
-(int)blackIncrement;
-(void)setBlackIncrement:(int)newIncrement;
-(void)startClockForWhite;
-(void)startClockForBlack;
-(void)stopClock;
-(void)pushClock;
-(void)addTimeForWhite:(int)msecs;
-(void)addTimeForBlack:(int)msecs;

@end
