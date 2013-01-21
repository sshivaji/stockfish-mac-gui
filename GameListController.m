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
#import "GameListController.h"
#import "GameParser.h"
#import "PGN.h"


// private  methods:

@interface GameListController (PrivateAPI)
-(void)initializeGameIndicesInBackground:(id)ignore;
-(void)finishedReadingIndices:(NSNotification *)note;
@end

@implementation GameListController

-(id)initWithBoardController:(BoardController *)bc
		    filename:(NSString *)aFilename {
  self = [super initWithWindowNibName: @"GameList"];
  pgnFileFinishedLoading = NO;
  boardController = bc;
  filename = [aFilename retain];

  errorWhileReadingFile = NO;

  @try {
    pgnFile = [[PGN alloc] initWithFilename: filename];

    // Read the game indices in a background thread.  We need to be notified
    // when this thread is finished:

    // Doesn't work.  I need to find out how to catch only the 
    // NSThreadWillExitNotification for the thread that was just launched,
    // rather than for any thread.  I can't find out how to do this.  :-(
    // For now, read indices in the foreground instead.

    /*
      [[NSNotificationCenter defaultCenter]
      addObserver: self
      selector: @selector(finishedReadingIndices:)
      name: @"NSThreadWillExitNotification"
      object: nil];

      [NSThread detachNewThreadSelector: 
      @selector(initializeGameIndicesInBackground:)
      toTarget: self
      withObject: nil];
    */

    [pgnFile initializeGameIndices];
  }
  @catch (NSException *e) {
    errorWhileReadingFile = YES;
  }
  @finally {
  }
  
  pgnFileFinishedLoading = YES;

  return self;
}

-(void)initializeGameIndicesInBackground:(id)ignore {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  [pgnFile initializeGameIndices];
  NSLog(@"Exiting thread");
  [NSThread exit];

  [pool release];
}

-(void)finishedReadingIndices:(NSNotification *)note {
  NSLog(@"Finished!");
  [gameList reloadData];
  pgnFileFinishedLoading = YES;
}

-(void)doubleClickInGameList:(id)sender {
  [self loadGame: sender];
}

-(void)windowDidLoad {
  [[self window] setTitle: [filename lastPathComponent]];
  [gameList setDoubleAction: @selector(doubleClickInGameList:)];
}

-(int)numberOfRowsInTableView:(id)aTableView {
  return [pgnFile numberOfGames];
}

-(id)tableView:(id)aTableView objectValueForTableColumn:(id)aTableColumn
	   row:(int)rowIndex {
  if(!pgnFileFinishedLoading) return [NSString stringWithFormat: @""];
  [pgnFile goToGameNumber: rowIndex];
  if([[aTableColumn identifier] isEqualToString: @"GAME"])
    return [NSString stringWithFormat: @"%d", rowIndex + 1];
  else if([[aTableColumn identifier] isEqualToString: @"WHITE"])
    return [pgnFile white];
  else if([[aTableColumn identifier] isEqualToString: @"BLACK"])
    return [pgnFile black];
  else if([[aTableColumn identifier] isEqualToString: @"RESULT"])
    return [pgnFile result];
  else return [NSString stringWithFormat: @""];
}

-(IBAction)closeGameFile:(id)sender {
  [[self window] close];
  [pgnFile release];
}

-(IBAction)loadGame:(id)sender {
  [boardController newGameWithPGNString:
		     [pgnFile pgnStringForGameNumber: [gameList selectedRow]]];
  [boardController raiseBoardWindow];
}

-(void)dealloc {
  [filename release];
  if(pgnFile) [pgnFile release];
  [super dealloc];
}

@end
