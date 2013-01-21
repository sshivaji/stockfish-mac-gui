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


#import "ChessClock.h"
#import "position.h"


@implementation ChessClock

+(int)currentSystemTime {
  return get_time();
}

+(NSString *)prettyTimeString:(int)msecs {
  int seconds = msecs / 1000;
  int minutes = seconds / 60;
  int hours = minutes / 60;
  char str[256], str2[10];

  if(hours) {
    sprintf(str, "%d:", hours);
    if((minutes % 60) < 10) strcat(str, "0");
  }
  else
    sprintf(str, "");
  sprintf(str2, "%d:", minutes % 60);
  if((seconds % 60) < 10) strcat(str2, "0");
  strcat(str, str2);
  sprintf(str2, "%d", seconds % 60);
  strcat(str, str2);
  return [NSString stringWithUTF8String: str];
}

-(id)initWithWhiteTime:(int)wtime 
	     blackTime:(int)btime
	whiteIncrement:(int)winc
	blackIncrement:(int)binc {
  [super init];
  whiteInitialTime = wtime;
  blackInitialTime = btime;
  whiteIncrement = winc;
  blackIncrement = binc;
  whiteConsumedTime = blackConsumedTime = 0;
  whiteAccumulatedIncrement = blackAccumulatedIncrement = 0;
  isRunning = NO;
  lastStartTime = 0;
  whiteNumOfMoves = blackNumOfMoves = 0;
  return self;
}

-(id)initWithTime:(int)time increment:(int)inc {
  return [self initWithWhiteTime: time
	       blackTime: time
	       whiteIncrement: inc
	       blackIncrement: inc];
}

-(id)initWithWhiteTime:(int)wtime forMoves:(int)wNumOfMoves
	     blackTime:(int)btime forMoves:(int)bNumOfMoves {
  [super init];
  whiteInitialTime = wtime;
  blackInitialTime = btime;
  whiteNumOfMoves = whiteRemainingMoves = wNumOfMoves;
  blackNumOfMoves = blackRemainingMoves = bNumOfMoves;
  whiteIncrement = blackIncrement = 0;
  return self;
}

-(id)initWithTime:(int)time forMoves:(int)numOfMoves {
  return [self initWithWhiteTime: time forMoves: numOfMoves
	       blackTime: time forMoves: numOfMoves];
}
  
-(id)init {
  return [self initWithTime: 300000 increment: 1000];
}

-(void)resetWithWhiteTime:(int)wtime
                blackTime:(int)btime
           whiteIncrement:(int)winc
           blackIncrement:(int)binc {
  whiteInitialTime = wtime;
  blackInitialTime = btime;
  whiteIncrement = winc;
  blackIncrement = binc;
  whiteConsumedTime = blackConsumedTime = 0;
  whiteAccumulatedIncrement = blackAccumulatedIncrement = 0;
}

-(void)resetWithWhiteTime:(int)wtime
		 forMoves:(int)wNumOfMoves
		blackTime:(int)btime
		 forMoves:(int)bNumOfMoves {
  whiteInitialTime = wtime;
  blackInitialTime = btime;
  whiteNumOfMoves = whiteRemainingMoves = wNumOfMoves;
  blackNumOfMoves = blackRemainingMoves = bNumOfMoves;
  whiteIncrement = blackIncrement = 0;
}

-(BOOL)isRunning {
  return isRunning;
}

-(int)whiteRemainingTime {
  int result = whiteInitialTime - whiteConsumedTime + whiteAccumulatedIncrement;
  if(isRunningForWhite) 
    result -= [ChessClock currentSystemTime] - lastStartTime;
  if(result < 0) result = 0;
  return result;
}

-(int)blackRemainingTime {
  int result = blackInitialTime - blackConsumedTime + blackAccumulatedIncrement;
  if(isRunningForBlack) 
    result -= [ChessClock currentSystemTime] - lastStartTime;
  if(result < 0) result = 0;
  return result;
}

-(NSString *)whiteRemainingTimeString {
  return [ChessClock prettyTimeString: [self whiteRemainingTime]];
}

-(NSString *)blackRemainingTimeString {
  return [ChessClock prettyTimeString: [self blackRemainingTime]];
}

-(int)whiteInitialTime {
  return whiteInitialTime;
}

-(void)setWhiteInitialTime:(int)newTime {
  whiteInitialTime = newTime;
  whiteAccumulatedIncrement = 0;
}

-(int)blackInitialTime {
  return blackInitialTime;
}

-(void)setBlackInitialTime:(int)newTime {
  blackInitialTime = newTime;
  blackAccumulatedIncrement = 0;
}

-(int)whiteIncrement {
  return whiteIncrement;
}

-(void)setWhiteIncrement:(int)newIncrement {
  whiteIncrement = newIncrement;
}

-(int)blackIncrement {
  return blackIncrement;
}

-(void)setBlackIncrement:(int)newIncrement {
  blackIncrement = newIncrement;
}

-(void)startClockForWhite {
  if(!isRunning) {
    lastStartTime = [ChessClock currentSystemTime];
    isRunning = YES;
    isRunningForWhite = YES;
    isRunningForBlack = NO;
  }
}

-(void)startClockForBlack {
  if(!isRunning) {
    lastStartTime = [ChessClock currentSystemTime];
    isRunning = YES;
    isRunningForWhite = NO;
    isRunningForBlack = YES;
  }
}

-(void)stopClock {
  if(isRunning) {
    [self pushClock];
    isRunning = isRunningForWhite = isRunningForBlack = NO;
  }
}

-(void)pushClock {
  if(isRunning) {
    int currentTime = [ChessClock currentSystemTime];
    int consumedTime = currentTime - lastStartTime;
    if(isRunningForWhite) {
      whiteConsumedTime += consumedTime;
      whiteAccumulatedIncrement += whiteIncrement;
      if(whiteNumOfMoves) {
	whiteRemainingMoves--;
	if(whiteRemainingMoves == 0)
	  whiteAccumulatedIncrement += whiteInitialTime;
      }
      isRunningForWhite = NO;
      isRunningForBlack = YES;
    }
    else {
      blackConsumedTime += consumedTime;
      blackAccumulatedIncrement += blackIncrement;
      if(blackNumOfMoves) {
	blackRemainingMoves--;
	if(blackRemainingMoves == 0)
	  blackAccumulatedIncrement += blackInitialTime;
      }
      isRunningForWhite = YES;
      isRunningForBlack = NO;
    }
    lastStartTime = currentTime;
  }
}

-(void)addTimeForWhite:(int)msecs {
  whiteInitialTime += msecs;
}

-(void)addTimeForBlack:(int)msecs {
  blackInitialTime += msecs;
}

@end
