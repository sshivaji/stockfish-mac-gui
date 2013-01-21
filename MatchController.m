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
#import "Game.h"
#import "MatchController.h"
#import "PGN.h"

@implementation MatchController

-(id)initWithBoardController:(BoardController *)bc
		     engine1:(NSString *)e1
		     engine2:(NSString *)e2
		 engine1Time:(int)e1time
		 engine2Time:(int)e2time
	    engine1Increment:(int)e1inc
	    engine2Increment:(int)e2inc
	       numberOfGames:(int)numOfGames
		    saveFile:(NSString *)sFile
		positionFile:(NSString *)pFile
			 FRC:(BOOL)frc 
		      ponder:(BOOL)ponder {
  self = [super initWithWindowNibName: @"MatchStats"];

  boardController = bc;
  engine1 = [e1 retain]; engine2 = [e2 retain];
  engine1Time = e1time; engine2Time = e2time; 
  engine1Increment = e1inc; engine2Increment = e2inc;
  numberOfGames = numOfGames;
  saveGameFile = [sFile retain];

  positionFile = [pFile retain];
  if(positionFile) {
    positionPGNFile = [[PGN alloc] initWithFilename: positionFile];
    [positionPGNFile initializeGameIndices];
  }

  FRC = frc;
  enginesShouldPonder = ponder;
  gamesFinished = engine1Wins = engine1Draws = engine1Losses = 0;

  return self;
}

-(void)windowDidLoad {
  [[self window] setTitle: @"Engine Match"];
  [self displayMatchState];
}

-(void)startMatch {
  [self startNextMatchGame: nil];
}

-(void)startNextMatchGame:(NSTimer *)aTimer {
  //  NSLog(@"in -[MatchController startNextMatchGame:]");
  if(aTimer) {
    [aTimer invalidate];
    [aTimer release];
  }
  if(positionFile) {
    [boardController newGameWithPGNString:
		       [positionPGNFile pgnStringForGameNumber:
					  gamesFinished / 2]];
  }
  else if(FRC) {
    if(gamesFinished % 2 == 0) // Pick new random position:
      frcId = abs([ChessClock currentSystemTime]) % 960;
    [boardController newGameWithFRCId: frcId];
  }
  else
    [boardController newGame: nil];
  if(gamesFinished % 2 == 0) { // Engine 1 is white:
    [boardController 
      setTimeControlWithWhiteTime: engine1Time
      blackTime: engine2Time
      whiteIncrement: engine1Increment
      blackIncrement: engine2Increment];
    if(gamesFinished == 0) 
      [boardController autoplayWithWhiteEngine: engine1
		       blackEngine: engine2
		       enginesShouldPonder: enginesShouldPonder];
    else
      [boardController continueAutoplayWithEngine1White: YES
		       enginesShouldPonder: enginesShouldPonder];
  }
  else { // Engine 2 is white: 
    [boardController 
      setTimeControlWithWhiteTime: engine2Time
      blackTime: engine1Time
      whiteIncrement: engine2Increment
      blackIncrement: engine1Increment];
    [boardController continueAutoplayWithEngine1White: NO
		     enginesShouldPonder: enginesShouldPonder];
  }
}
    

-(void)displayMatchState {
  [engine1StatsTextField 
    setStringValue: [NSString stringWithFormat:
				@"%@: %.1f (+%d, =%d, -%d)",
			      engine1,
			      engine1Wins + engine1Draws * 0.5,
			      engine1Wins, engine1Draws, engine1Losses]];
  [engine2StatsTextField 
    setStringValue: [NSString stringWithFormat:
				@"%@: %.1f (+%d, =%d, -%d)",
			      engine2,
			      engine1Losses + engine1Draws * 0.5,
			      engine1Losses, engine1Draws, engine1Wins]];
  [gameCountTextField 
    setStringValue: [NSString stringWithFormat: @"%d/%d games played",
			      gamesFinished, numberOfGames]];
  if(gamesFinished == numberOfGames) {
    [boardController stopEngine2];
    [okButton setEnabled: YES];
  }
  else
    [okButton setEnabled: NO];
}

-(void)gameFinished:(Game *)game {
  if(saveGameFile) {
    [game setEvent: @"Computer chess game"];
    [game setSite: [[NSHost currentHost] name]];
    [game setRound: [NSString stringWithFormat: @"%d", gamesFinished+1]];
    [game saveToFile: saveGameFile];
  }
  if(gamesFinished % 2 == 0) { // Engine 1 was white
    if([game result] == WHITE_WINS) engine1Wins++;
    else if([game result] == BLACK_WINS) engine1Losses++;
    else engine1Draws++;
  }
  else { // Engine 1 was black
    if([game result] == WHITE_WINS) engine1Losses++;
    else if([game result] == BLACK_WINS) engine1Wins++;
    else engine1Draws++;
  }
  gamesFinished++;
  [self displayMatchState];
  if(gamesFinished < numberOfGames)
    timer = [[NSTimer scheduledTimerWithTimeInterval: 1.0
		      target: self
		      selector: @selector(startNextMatchGame:)
		      userInfo: nil
		      repeats: NO] retain];
}

-(IBAction)abortButtonPressed:(id)sender {
  NSRunAlertPanel(@"Not implemented yet!", @"", @"OK", nil, nil);
}

-(IBAction)adjudicateButtonPressed:(id)sender {
  NSRunAlertPanel(@"Not implemented yet!", @"", @"OK", nil, nil);
}

-(IBAction)okButtonPressed:(id)sender {
  [[self window] close];
}

-(void)dealloc {
  [engine1 release];
  [engine2 release];
  [saveGameFile release];
  [positionFile release];
  [positionPGNFile release];
  [super dealloc];
}


@end
