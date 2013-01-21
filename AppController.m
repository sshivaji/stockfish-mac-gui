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


#import "AppController.h"
#import "BoardController.h"
#import "Engine.h"
#import "EngineConfigController.h"
#import "Game.h"
#import "GameListController.h"
#import "PreferencesController.h"
#import "UninstallWindowController.h"


static BOOL this_mac_runs_leopard(void) {
  NSString *versionPlistPath = @"/System/Library/CoreServices/SystemVersion.plist";
  NSString *currentSystemVersion = [[[NSDictionary dictionaryWithContentsOfFile:versionPlistPath] objectForKey:@"ProductVersion"] retain];
  const char *str = [currentSystemVersion UTF8String];
  [currentSystemVersion autorelease];
  return strlen(str) >= 3 && str[3] >= '5';
}


@implementation AppController

// static NSMutableDictionary *installedEngines;


+(void)initialize {
  NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
  NSMutableDictionary *defaultInstalledEngines;
  NSMutableDictionary *defaultInstalledEngineOptions;
  NSMutableDictionary *defaultEngineBookOptions;

  defaultInstalledEngines = [[NSMutableDictionary alloc] init];
  [defaultInstalledEngines setObject: [Engine mainEnginePath]
			   forKey: @"Stockfish 2.0.1"];
    
  defaultInstalledEngineOptions = [[NSMutableDictionary alloc] init];
  defaultEngineBookOptions = [[NSMutableDictionary alloc] init];

  [defaultValues setObject: defaultInstalledEngines
		 forKey: @"InstalledEngines"];
  [defaultValues setObject: defaultInstalledEngineOptions
		 forKey: @"InstalledEngineOptions"];
  [defaultValues setObject: defaultEngineBookOptions
		 forKey: @"InstalledEngineBookOptions"];

  [defaultValues setObject: @"Stockfish 2.0.1" forKey: @"Default Engine"];

  [defaultValues setObject: [NSNumber numberWithBool: YES]
		 forKey: @"Include Engine Analysis in Move List"];
  [defaultValues setObject: [NSNumber numberWithBool: YES]
		 forKey: @"Display all Scores from White's Point of View"];
  [defaultValues setObject: [NSNumber numberWithInt: 128]
		 forKey: @"Default Hash Table Size"];
  [defaultValues setObject: [NSNumber numberWithBool: YES]
		 forKey: @"Resign in Hopeless Positions"];

  [defaultValues setObject:
		   [NSArchiver archivedDataWithRootObject:
				 [NSColor colorWithDeviceRed: 0.57
					  green: 0.40
					  blue: 0.35
					  alpha: 1.0]]
		 forKey: @"Dark Square Color"];
  [defaultValues setObject:
		   [NSArchiver archivedDataWithRootObject:
				 [NSColor colorWithDeviceRed: 0.9
					  green: 0.8
					  blue: 0.7 
					  alpha: 1.0]]
		 forKey: @"Light Square Color"];  

  [defaultValues setObject: [NSNumber numberWithBool: NO]
		 forKey: @"Beep when Making Moves"];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
  [defaultInstalledEngines release];
  [defaultInstalledEngineOptions release];
  [defaultEngineBookOptions release];
}

-(id)init {
  self = [super init];
  gameListWindows = [[NSMutableArray alloc] init];
  mainEngineName = [[NSString stringWithString: @"Stockfish 2.0.1"] retain];
  return self;
}

-(void)updateEnginesMenu {
  NSArray *array;
  NSEnumerator *e;
  NSString *s;

  // NSMenu has no removeAllItems method??
  //  [installedEnginesMenu removeAllItems];
  while([installedEnginesMenu numberOfItems] > 0)
    [installedEnginesMenu removeItemAtIndex: 0];

  array = [[Engine installedEngines] allKeys];
  e = [[array sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
	objectEnumerator];
  while((s = [e nextObject])) {
    NSMenuItem *item;
    item = [[NSMenuItem alloc] initWithTitle: s
			       action: @selector(selectEngine:)
			       keyEquivalent: @""];
    [item setTarget: self];
    [installedEnginesMenu addItem: item];
    [item release];
  }
}

-(void)awakeFromNib {
  [self updateEnginesMenu];
  [NSApp setDelegate: self];
}

-(IBAction)openGameFile:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  NSArray *fileTypes = [NSArray arrayWithObjects: @"pgn", nil];
  GameListController *glc;
  
  if([panel runModalForTypes: fileTypes] == NSOKButton) {
    glc = [[GameListController alloc]
	    initWithBoardController: boardController
	    filename: [panel filename]];
    [gameListWindows addObject: glc];
    [glc showWindow: self];
    [glc release];  // Retained in gameListWindows
  }
}

-(IBAction)selectEngine:(id)sender {
  [mainEngineName release];
  mainEngineName = [[NSString stringWithString: [sender title]] retain];
  [boardController switchMainEngineTo: [sender title]];
}

-(id)boardController {
  return boardController;
}

-(IBAction)copyPosition:(id)sender {
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  [pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
      owner: self];
  [pb setString: [[[boardController game] currentPosition] FENString]
      forType: NSStringPboardType];
}

-(IBAction)copyGame:(id)sender {
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  [pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
      owner: self];
  [pb setString: [[boardController game] PGNString]
      forType: NSStringPboardType];
}

-(IBAction)paste:(id)sender {
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  NSString *type = [pb availableTypeFromArray:
			 [NSArray arrayWithObject: NSStringPboardType]];
  NSString *value, *string;;

  if(type) {
    value = [[pb stringForType: NSStringPboardType]
	      stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    string = [NSString stringWithUTF8String: [value UTF8String]];
    if([string hasPrefix: @"["]) { // Could be a game in PGN notation
      Game *game;

      @try {
	game = [[Game alloc] initWithPGNString: string];
      }
      @catch (NSException *e) {
	NSRunAlertPanel(@"Error while parsing game",
			[e reason], nil, nil, nil, nil);
	[game release];
	return;
      }
      @finally {
      }

      if(game) {
	NSAssert([game round] != nil, @"[game round] is nil!");
	[game release];
	if(NSRunAlertPanel(@"Paste game from clipboard?", 
			   @"This will erase the current game. You cannot undo this action.",
			   @"OK", @"Cancel", nil, nil) 
	   == NSAlertDefaultReturn) {
	  [boardController newGameWithPGNString: string];
	  return;
	}
      }
    }
    else if([ChessPosition looksLikeAFENString: string]) {
      [boardController setUpPositionWithFEN: string];
      return;
    }
  }
  NSBeep();
}

-(IBAction)computerPlaysBlack:(id)sender {
  [boardController computerPlaysBlack: sender];
}

-(IBAction)computerPlaysWhite:(id)sender {
  [boardController computerPlaysWhite: sender];
}

-(IBAction)youPlayBoth:(id)sender {
  [boardController humanPlaysBoth: sender];
}

-(IBAction)analysisMode:(id)sender {
  [boardController analysisMode: sender];
}

-(void)waitForEngineExit:(id)engine {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // NSMenuItem *item;
  while([[engine task] isRunning]);
  sleep(2);
  [engine release];
  [self updateEnginesMenu];
  /*
  item = [[NSMenuItem alloc] initWithTitle: [engine name]
			     action: @selector(selectEngine:)
			     keyEquivalent: @""];
  [item setTarget: self];
  [installedEnginesMenu addItem: item];
  [item release];
  */
  [pool release];
}  

-(void)installEngineWithPath:(NSString *)path {
  Engine *engine = [[Engine alloc] initWithController: nil path: path
				   installOnly: true];
  [engine start];
  [NSThread detachNewThreadSelector: @selector(waitForEngineExit:)
	    toTarget: self
	    withObject: engine];
}

-(IBAction)installNewUCIEngine:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  if([panel runModalForTypes: nil] == NSOKButton) 
    [self installEngineWithPath: [panel filename]];
}

-(IBAction)uninstallUCIEngine:(id)sender {
  if(uninstallWindowController)
    [uninstallWindowController release];
  uninstallWindowController = [[UninstallWindowController alloc] init];
  [uninstallWindowController showWindow: self];
}

-(IBAction)preferences:(id)sender {
  if(preferencesController)
    [preferencesController release];
  preferencesController = [[PreferencesController alloc] init];
  [preferencesController showWindow: self];
}

-(BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
  SEL action = [menuItem action];
  if(action == @selector(computerPlaysWhite:)) {
    if([boardController gameMode] == COMPUTER_WHITE)
      [menuItem setState: NSOnState];
    else
      [menuItem setState: NSOffState];
    return YES;
  }
  else if(action == @selector(computerPlaysBlack:)) {
    if([boardController gameMode] == COMPUTER_BLACK)
      [menuItem setState: NSOnState];
    else
      [menuItem setState: NSOffState];
    return YES;
  }
  else if(action == @selector(youPlayBoth:)) {
    if([boardController gameMode] == BOTH)
      [menuItem setState: NSOnState];
    else
      [menuItem setState: NSOffState];
    return YES;
  }
  else if(action == @selector(analysisMode:)) {
    if([boardController gameMode] == ANALYSIS)
      [menuItem setState: NSOnState];
    else
      [menuItem setState: NSOffState];
    return YES;
  }
  else if(action == @selector(selectEngine:)) {
    if([[menuItem title] isEqualToString: mainEngineName])
      [menuItem setState: NSOnState];
    else
      [menuItem setState: NSOffState];
    if([[Engine installedEngines] objectForKey: [menuItem title]] != nil)
      return YES;
    else 
      return NO;
  }
  return YES;
}

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [boardController raiseBoardWindow];
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
}

-(void)dealloc {
  [gameListWindows release];
  [mainEngineName release];
  [super dealloc];
}

@end
