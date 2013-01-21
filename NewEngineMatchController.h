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

@interface NewEngineMatchController : NSWindowController {
  IBOutlet id alternateColorsSwitch;
  IBOutlet id FRCSwitch;
  IBOutlet id ponderSwitch;
  IBOutlet id blackEnginePopup;
  IBOutlet id blackInitialTimeTextField;
  IBOutlet id blackMoveBonusTextField;
  IBOutlet id numOfGamesTextField;
  IBOutlet id whiteEnginePopup;
  IBOutlet id whiteInitialTimeTextField;
  IBOutlet id whiteMoveBonusTextField;

  NSString *saveFile;
  NSString *positionFile;
  BoardController *boardController;
}

-(id)initWithBoardController:(BoardController *)bc;
-(IBAction)cancelButtonPressed:(id)sender;
-(IBAction)configureEngine1Pressed:(id)sender;
-(IBAction)configureEngine2Pressed:(id)sender;
-(IBAction)okButtonPressed:(id)sender;
-(IBAction)pickPositionPressed:(id)sender;
-(IBAction)pickSavePressed:(id)sender;
-(void)savePanelDidEnd:(id)sheet
	    returnCode:(int)returnCode
	   contextInfo:(void *)contextInfo;
-(void)openPanelDidEnd:(id)sheet
	    returnCode:(int)returnCode
	   contextInfo:(void *)contextInfo;

@end
