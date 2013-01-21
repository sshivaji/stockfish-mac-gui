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


#import "Engine.h"
#import "UninstallWindowController.h"

@implementation UninstallWindowController

-(id)init {
  self = [super initWithWindowNibName: @"UninstallEngine"];
  installedEngines = 
    [[[[Engine installedEngines] allKeys]
       sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
      retain];
  return self;
}

-(int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [installedEngines count];
}

-(id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn*)aTableColumn
           row:(int)rowIndex {
  if(rowIndex < [installedEngines count]) 
    return [installedEngines objectAtIndex: rowIndex];
  return [NSString stringWithString: @""];
}

-(IBAction)cancelButtonPressed:(id)sender {
  [[self window] close];
}

-(IBAction)okButtonPressed:(id)sender {
  NSLog(@"%@", [installedEngines objectAtIndex: [engineTable selectedRow]]);
  [Engine uninstallEngineWithName:
	    [installedEngines objectAtIndex: [engineTable selectedRow]]];
  [[self window] close];
}

-(void)dealloc {
  [engineTable release];
  [super dealloc];
}

@end
