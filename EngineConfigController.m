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


#import "EngineConfigController.h"
#import "Engine.h"
#import "UCIOption.h"

@implementation EngineConfigController

-(id)initWithEngine:(Engine *)anEngine {
  self = [super initWithWindowNibName: @"EngineConfigWindow"];
  engine = anEngine;
  options = [[NSMutableArray alloc] initWithArray: [engine visibleOptions] 
                                    copyItems: YES];
  [optionsTable reloadData];
  return self;
}

-(void)windowDidLoad {
  [[self window] setTitle: [NSString stringWithFormat: @"Configure %@",
                                     [engine name]]];
  [bookChoicePopup removeAllItems];
  [bookChoicePopup addItemWithTitle: @"GUI Book"];
  if([engine supportsOwnBook])
    [bookChoicePopup addItemWithTitle: @"Engine Book"];
  [bookChoicePopup addItemWithTitle: @"No Book"];
  if([engine shouldUseOwnBook])
    [bookChoicePopup selectItemWithTitle: @"Engine Book"];
  else if([engine shouldUseGUIBook])
    [bookChoicePopup selectItemWithTitle: @"GUI Book"];
  else
    [bookChoicePopup selectItemWithTitle: @"No Book"];
    

  [bookVarietyPopup removeAllItems];
  [bookVarietyPopup addItemWithTitle: @"Low"];
  [bookVarietyPopup addItemWithTitle: @"Medium"];
  [bookVarietyPopup addItemWithTitle: @"High"];
  [bookVarietyPopup selectItemWithTitle: @"Medium"];

  [optionsTable reloadData];
  [self tableViewSelectionDidChange:nil];
}

-(int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [options count];
}

-(id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn*)aTableColumn
           row:(int)rowIndex {
  if(rowIndex < [options count]) {
    if([[aTableColumn identifier] isEqualToString: @"Option"])
      return [[options objectAtIndex: rowIndex] name];
    else
      return [[options objectAtIndex: rowIndex] value];
  }
  return [NSString stringWithString: @""];
}

-(void)comboOptionChanged:(id)sender {
  [[options objectAtIndex: [optionsTable selectedRow]]
    setValue: [control titleOfSelectedItem]];
  [optionsTable reloadData];
}

-(void)checkOptionChanged:(id)sender {
  [[options objectAtIndex: [optionsTable selectedRow]]
    setValue: [sender state]? @"true" : @"false"];
  [optionsTable reloadData];
}

-(void)buttonWasPushed:(id)sender {
  [engine pushButtonNamed: 
            [[options objectAtIndex: [optionsTable selectedRow]] name]];
}

-(void)controlTextDidChange:(id)aNotification {
  [[options objectAtIndex: [optionsTable selectedRow]]
    setValue: [control stringValue]];
  [optionsTable reloadData];
}

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  int rowIndex = [optionsTable selectedRow];
  UCIOption *option = [options objectAtIndex: rowIndex];

  // Display option name:
  if([option type] != UCI_CHECK && [option type] != UCI_BUTTON)
    [currentOptionName setStringValue: [NSString stringWithFormat: @"%@:",
                                                 [option name]]];
  else
    [currentOptionName setStringValue: @""];

  // Display option information:
  if([option type] == UCI_SPIN) 
    [currentOptionInfo setStringValue:
                         [NSString stringWithFormat:
                                     @"Between %d and %d, the default is %@",
                                   [option min], [option max], 
                                   [option defaultValue]]];
  else if([option type] == UCI_CHECK)
    [currentOptionInfo setStringValue:
                         [NSString stringWithFormat:
                                     @"The default is %@", 
                                   [option defaultValue]]];
  else if([option type] == UCI_COMBO)
    [currentOptionInfo setStringValue:
                         [NSString stringWithFormat:
                                     @"The default is %@",
                                   [option defaultValue]]];
  else if([option type] == UCI_STRING)
    [currentOptionInfo setStringValue:
                         [NSString stringWithFormat:
                                     @"The default is %@",
                                   [option defaultValue]]];
  else 
    [currentOptionInfo setStringValue: @""];

  // Display an editable text field, a popup menu, or a checkbox, depending
  // on the option type:
  if(control) {
    [control removeFromSuperview];
    [control release];
    control = nil;
  }
  if([option type] == UCI_SPIN || [option type] == UCI_STRING) {
    NSRect r;
    control = [[NSTextField alloc] init];
    [control setStringValue: [option value]];
    [control setDelegate: self];
    [[currentOptionBox contentView] addSubview: control];
    r.origin.x = 295.0; r.origin.y = 32.0;
    r.size.width = 220.0; r.size.height = 20.0;
    [control setFrame: r];
  }
  else if([option type] == UCI_COMBO) {
    NSRect r;
    int i;
    control = [[NSPopUpButton alloc] init];
    for(i = 0; i < [[option comboValues] count]; i++) {
      NSMenuItem *item;
      NSString *title = [[option comboValues] objectAtIndex: i];
      [control addItemWithTitle: title];
      item = [[control menu] itemWithTitle: title];
      [item setTarget: self];
      [item setAction: @selector(comboOptionChanged:)];
    }
    [control selectItemWithTitle: [option value]];
    [[currentOptionBox contentView] addSubview: control];
    r.origin.x = 295.0; r.origin.y = 25.0; 
    r.size.width = 225.0; r.size.height = 30.0;
    [control setFrame: r];
  }
  else if([option type] == UCI_CHECK) {
    NSRect r;
    control = [[NSButton alloc] init];
    [control setButtonType: NSSwitchButton];
    [control setTitle: [option name]];
    [[currentOptionBox contentView] addSubview: control];
    if([[option value] isEqualToString: @"true"])
      [control setState: NSOnState];
    else
      [control setState: NSOffState];
    [control setTarget: self];
    [control setAction: @selector(checkOptionChanged:)];
    r.origin.x = 12.0; r.origin.y = 26.0;
    r.size.width = 215.0; r.size.height = 30.0;
    [control setFrame: r];
  }
  else if([option type] == UCI_BUTTON) {
    NSRect r;
    control = [[NSButton alloc] init];
    [control setButtonType: NSMomentaryPushButton];
    [control setBezelStyle: NSRoundedBezelStyle];
    [control setTitle: [option name]];
    [[currentOptionBox contentView] addSubview: control];
    [control setTarget: self];
    [control setAction: @selector(buttonWasPushed:)];
    r.origin.x = 12.0; r.origin.y = 18.0;
    r.size.width = 215.0; r.size.height = 30.0;
    [control setFrame: r];
  }
}

-(IBAction)okButtonPressed:(id)sender {
  int i;

  // UCI options
  for(i = 0; i < [options count]; i++)
    if(!([[options objectAtIndex: i] type] == UCI_BUTTON) &&
       ![[[options objectAtIndex: i] value]
          isEqualToString: [[[engine options] objectAtIndex: i] value]]) {
      [engine setOptionName: [[options objectAtIndex: i] name]
              value: [[options objectAtIndex: i] value]];
    }
  [engine saveOptions];

  // Book options
  if([[bookChoicePopup titleOfSelectedItem] isEqualToString: @"GUI Book"])
    [engine setShouldUseGUIBook];
  else if([[bookChoicePopup titleOfSelectedItem] 
	    isEqualToString: @"Engine Book"])
    [engine setShouldUseOwnBook];
  else  if([[bookChoicePopup titleOfSelectedItem] isEqualToString: @"No Book"])
    [engine setShouldUseNoBook];
    
  [[self window] close];
}

-(IBAction)cancelButtonPressed:(id)sender {
  [[self window] close];
}

-(IBAction)defaultsButtonPressed:(id)sender {
  int i;
  for(i = 0; i < [options count]; i++) {
    if([[[options objectAtIndex: i] name] isEqualToString: @"Hash"])
      [[options objectAtIndex: i] 
	setValue: [NSString stringWithFormat: @"%d", [Engine defaultHashSize]]];
    else
      [[options objectAtIndex: i] 
	setValue: [[options objectAtIndex: i] defaultValue]];
  }
  [optionsTable reloadData];
}

-(void) dealloc {
  [options release];
  [control release];
  [super dealloc];
}
  
@end
