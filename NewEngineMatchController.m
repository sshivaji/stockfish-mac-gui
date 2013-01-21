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
#import "Engine.h"
#import "NewEngineMatchController.h"

@implementation NewEngineMatchController

-(id)initWithBoardController:(BoardController *)bc {
  self = [super initWithWindowNibName: @"NewMatch"];
  boardController = bc;
  return self;
}

-(void)windowDidLoad {
  NSArray *array;
  NSEnumerator *e;
  NSString *s;

  [whiteEnginePopup removeAllItems];
  [blackEnginePopup removeAllItems];

  array = [[Engine installedEngines] allKeys];
  e = [[array sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
	objectEnumerator];
  while((s = [e nextObject])) {
    [whiteEnginePopup addItemWithTitle: s];
    [blackEnginePopup addItemWithTitle: s];
  }
}
  
-(IBAction)cancelButtonPressed:(id)sender {
  [[self window] close];
}

-(IBAction)configureEngine1Pressed:(id)sender {
}

-(IBAction)configureEngine2Pressed:(id)sender {
}

-(IBAction)okButtonPressed:(id)sender {
  if(saveFile != nil ||
     NSRunAlertPanel(@"No save game file chosen!", 
		     @"The games will not be saved. Continue?",
		     @"OK", @"Cancel", nil) == NSAlertDefaultReturn) {
    [[self window] close];
    [boardController 
      startMatchWithEngine1: [whiteEnginePopup titleOfSelectedItem]
      engine2: [blackEnginePopup titleOfSelectedItem]
      engine1InitialTime: [whiteInitialTimeTextField intValue] * 60000
      engine2InitialTime: [blackInitialTimeTextField intValue] * 60000
      engine1Increment: [whiteMoveBonusTextField intValue] * 1000
      engine2Increment: [blackMoveBonusTextField intValue] * 1000
      numberOfGames: [numOfGamesTextField intValue]
      saveFile: saveFile
      positionFile: positionFile
      FRC: [FRCSwitch state]
      ponder: [ponderSwitch state]];
  }
}

-(IBAction)pickPositionPressed:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  NSArray *fileTypes = [NSArray arrayWithObjects: @"pgn", nil];

  [panel beginSheetForDirectory: nil
	 file: nil
	 types: fileTypes
	 modalForWindow: [self window]
	 modalDelegate: self
	 didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
	 contextInfo: nil];
}

-(void)openPanelDidEnd:(id)sheet
	    returnCode:(int)returnCode
	   contextInfo:(void *)contextInfo {
  if(returnCode == NSOKButton) {
    positionFile = [[sheet filename] retain];
    //    NSLog(@"Using position file %@", positionFile);
  }
}

-(IBAction)pickSavePressed:(id)sender {
  NSSavePanel *panel = [NSSavePanel savePanel];
  [panel setRequiredFileType: @"pgn"];
  [panel beginSheetForDirectory: nil
	 file: nil
	 modalForWindow: [self window]
	 modalDelegate: self
	 didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:)
	 contextInfo: nil];
}

-(void)savePanelDidEnd:(id)sheet
	    returnCode:(int)returnCode
	   contextInfo:(void *)contextInfo {
  if(returnCode == NSOKButton) {
    saveFile = [[sheet filename] retain];
    //    NSLog(@"Saving to %@", [sheet filename]);
  }
}

-(void)dealloc {
  [saveFile release];
  [positionFile release];
  [super dealloc];
}

@end
