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
@class Game;
@class PGN;

@interface MatchController : NSWindowController {
  IBOutlet id engine1StatsTextField;
  IBOutlet id engine2StatsTextField;
  IBOutlet id gameCountTextField;
  IBOutlet id okButton;

  BoardController *boardController;
  NSString *engine1, *engine2;
  int engine1Time, engine2Time, engine1Increment, engine2Increment;
  int numberOfGames, gamesFinished;
  int engine1Wins, engine1Draws, engine1Losses;
  NSString *saveGameFile, *positionFile;
  PGN *positionPGNFile;
  BOOL FRC;
  BOOL enginesShouldPonder;
  int frcId;

  NSTimer *timer;
}

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
		      ponder:(BOOL)ponder;
-(void)startMatch;
-(void)startNextMatchGame:(NSTimer *)aTimer;
-(void)displayMatchState;
-(void)gameFinished:(Game *)game;
-(IBAction)abortButtonPressed:(id)sender;
-(IBAction)adjudicateButtonPressed:(id)sender;
-(IBAction)okButtonPressed:(id)sender;

@end
