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
#import "EngineController.h"
#import "UCIOption.h"


@implementation Engine

+(NSString *)mainEnginePath {
  return [[NSBundle mainBundle] pathForResource: @"sf" ofType: nil];
}

+(int)defaultHashSize {
  return [[NSUserDefaults standardUserDefaults]
	   integerForKey: @"Default Hash Table Size"];
}

+(id)installedEngines {
  return 
    [[NSUserDefaults standardUserDefaults] objectForKey: @"InstalledEngines"];
}

+(id)installedEngineOptions {
  return 
    [[NSUserDefaults standardUserDefaults] 
      objectForKey: @"InstalledEngineOptions"];
}

+(id)installedEngineBookOptions {
  return
    [[NSUserDefaults standardUserDefaults]
      objectForKey: @"InstalledEngineBookOptions"];
}

+(NSString *)pathOfEngineWithName:(NSString *)name {
  return [[Engine installedEngines] objectForKey: name];
}

+(NSDictionary *)optionsOfEngineWithName:(NSString *)name {
  return [[Engine installedEngineOptions] objectForKey: name];
}

+(BOOL)useOwnBookForEngineWithName:(NSString *)name {
  if([[[[[NSUserDefaults standardUserDefaults]
	  objectForKey: @"InstalledEngineBookOptions"]
	 objectForKey: name]
	objectForKey: @"BookType"]
       isEqualToString: @"OwnBook"])
    return YES;
  else
    return NO;
}

+(BOOL)useGUIBookForEngineWithName:(NSString *)name {
  if([[[[[NSUserDefaults standardUserDefaults]
	  objectForKey: @"InstalledEngineBookOptions"]
	 objectForKey: name]
	objectForKey: @"BookType"]
       isEqualToString: @"GUIBook"])
    return YES;
  else
    return NO;
}

+(void)uninstallEngineWithName:(NSString *)name {
  NSMutableDictionary *installedEngines =
    [NSMutableDictionary dictionaryWithDictionary:
			   [Engine installedEngines]];
  NSMutableDictionary *installedEngineOptions =
    [NSMutableDictionary dictionaryWithDictionary:
			   [Engine installedEngineOptions]];
  NSMutableDictionary *installedEngineBookOptions =
    [NSMutableDictionary dictionaryWithDictionary:
			   [Engine installedEngineBookOptions]];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if([installedEngines objectForKey: name] != nil) {
    [installedEngines removeObjectForKey: name];
    [defaults setObject: installedEngines forKey: @"InstalledEngines"];
  }
  if([installedEngineOptions objectForKey: name] != nil) {
    [installedEngineOptions removeObjectForKey: name];
    [defaults setObject: installedEngineOptions 
                 forKey: @"InstalledEngineOptions"];
  }
  if([installedEngineBookOptions objectForKey: name] != nil) {
    [installedEngineBookOptions removeObjectForKey: name];
    [defaults setObject: installedEngineBookOptions 
                 forKey: @"InstalledEngineBookOptions"];
  }
}

-(id)initWithController:(EngineController *)ec path:(NSString *)p
	    installOnly:(BOOL)instOnly {
  [super init];
  controller = [ec retain];  // Should I really retain this?
  path = [p retain];
  commandQueue = [[NSMutableArray alloc] init];
  thinking = NO;
  sprintf(inputBuffer, "");
  sprintf(errorBuffer, "");
  isReady = NO;
  installOnly = instOnly;
  return self;
}
  
-(id)initWithController:(EngineController *)ec path:(NSString *)p {
  return [self initWithController: ec path: p installOnly: NO];
}

-(id)initWithController:(EngineController *)ec {
  return [self initWithController: ec path: [Engine mainEnginePath]];
}

-(NSString *)name {
  return name;
}

-(NSString *)author {
  return author;
}

-(NSTask *)task {
  return task;
}

-(NSMutableArray *)options {
  return options;
}

-(NSMutableArray *)visibleOptions {
  NSEnumerator *enumerator = [options objectEnumerator];
  NSMutableArray *array = [[NSMutableArray alloc] init];
  UCIOption *option;
  while((option = [enumerator nextObject]))
    if(![option isHidden])
      [array addObject: option];
  return [array autorelease];
}

-(void)start {
  NSPipe *outputPipe, *inputPipe, *errorPipe;
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
  NSMutableDictionary *environment = 
    [[NSMutableDictionary alloc] initWithDictionary: defaultEnvironment];

  // Set up the task
  task = [[NSTask alloc] init];
  [task setLaunchPath: path];
  [task setCurrentDirectoryPath: [path stringByDeletingLastPathComponent]];

  // Set up the environment
  [environment setObject: @"YES" forKey: @"NSUnBufferedIO"];
  [task setEnvironment: environment];

  // Set up pipe for stdout
  outputPipe = [NSPipe pipe];
  taskOutput = [outputPipe fileHandleForReading];
  [defaultCenter addObserver: self 
                    selector: @selector(taskDataAvailable:)
                        name: NSFileHandleReadCompletionNotification
                      object: taskOutput];
  [task setStandardOutput: outputPipe];

  // Set up pipe for stderr
  errorPipe = [NSPipe pipe];
  taskError = [errorPipe fileHandleForReading];
  [defaultCenter addObserver: self
                    selector: @selector(taskErrorDataAvailable:)
                        name: NSFileHandleReadCompletionNotification
                      object: taskError];
  [task setStandardError: errorPipe];

  // Set up pipe for stdin
  inputPipe = [NSPipe pipe];
  taskInput = [inputPipe fileHandleForWriting];
  [task setStandardInput: inputPipe];

  // Start the task and start looking for data:
  [task launch];
  [taskOutput readInBackgroundAndNotify];

  [self sendCommand: @"uci\n"];

  // Clean-up
  [environment release];
}

-(void)sendCommand:(NSString *)command {
  //  NSLog(@"%@ < %@", name, command);
  [taskInput writeData: [command dataUsingEncoding: 
				   [NSString defaultCStringEncoding]]];
}

-(void)queueCommand:(NSString *)command {
  if(thinking || !isReady) {
    //    NSLog(@"%@ q < %@", name, command);
    [commandQueue addObject: command];
  }
  else [self sendCommand: command];
}

-(void)processQueue {
  NSString *command;
  //  NSLog(@"commandQueue for %@ is: %@", name, commandQueue);
  while([commandQueue count] > 0) {
    command = [[commandQueue objectAtIndex: 0] retain];
    [commandQueue removeObjectAtIndex: 0];
    if([command length] >= 3 && 
       [[command substringToIndex: 2] isEqualToString: @"go"]) {
      thinking = YES;
      [self sendCommand: command];
      [command release];
      break;
    }
    [self sendCommand: command];
    [command release];
  }
}

-(void)searchWithWtime:(int)wtime 
                 btime:(int)btime 
                  winc:(int)winc
                  binc:(int)binc {
  if(thinking || !isReady) 
    [self queueCommand:
	    [NSString stringWithFormat: 
			@"go wtime %d btime %d winc %d binc %d\n",
		      wtime, btime, winc, binc]];
  else {
    thinking = YES;
    [self sendCommand:
	    [NSString stringWithFormat:
			@"go wtime %d btime %d winc %d binc %d\n",
		      wtime, btime, winc, binc]];
  }
}

-(void)ponderWithWtime:(int)wtime 
                 btime:(int)btime 
                  winc:(int)winc
                  binc:(int)binc {
  if(thinking) 
    [self queueCommand:
	    [NSString stringWithFormat: 
			@"go ponder wtime %d btime %d winc %d binc %d\n",
		      wtime, btime, winc, binc]];
  else {
    thinking = YES;
    [self sendCommand:
	    [NSString stringWithFormat: 
			@"go ponder wtime %d btime %d winc %d binc %d\n",
		      wtime, btime, winc, binc]];
  }
}


-(void)searchInfinite {
  if(thinking) [self queueCommand: [NSString stringWithString:
					       @"go infinite\n"]];
  else {
    thinking = YES;
    [self sendCommand: @"go infinite\n"];
  }
}

-(BOOL)hasOptionWithName:(NSString *)optionName {
  NSEnumerator *enumerator = [options objectEnumerator];
  UCIOption *option;
  while((option = [enumerator nextObject]))
    if([[option name] isEqualToString: optionName]) return YES;
  return NO;
}

-(BOOL)supportsLimitStrength {
  return [self hasOptionWithName: @"UCI_LimitStrength"];
}

-(BOOL)supportsOwnBook {
  return [self hasOptionWithName: @"OwnBook"];
}

-(UCIOption *)optionWithName:(NSString *)optionName {
  NSEnumerator *enumerator = [options objectEnumerator];
  UCIOption *option;
  while((option = [enumerator nextObject]))
    if([[option name] isEqualToString: optionName]) return option;
  return nil;
}

-(void)pushButtonNamed:(NSString *)buttonName {
  int i;
  UCIOption *theOption;
  for(i = 0; i < [options count]; i++) {
    theOption = [options objectAtIndex: i];
    if([[theOption name] isEqualToString: buttonName]) {
      [self queueCommand: [NSString stringWithFormat: 
				      @"setoption name %@", buttonName]];
      return;
    }
  }
  //  NSLog(@"UCI engine %@ has no option named %@!", name, buttonName);
}

-(void)setOptionName:(NSString *)optionName value:(NSString *)value {
  int i;
  UCIOption *theOption;
  for(i = 0; i < [options count]; i++) {
    theOption = [options objectAtIndex: i];
    if([[theOption name] isEqualToString: optionName])  {
      if(![[theOption value] isEqualToString: value]) {
	[theOption setValue: value];
	[self queueCommand: [NSString stringWithFormat: 
					@"setoption name %@ value %@\n",
				      optionName, value]];
      }
      return;
    }
  }
  //  NSLog(@"UCI engine %@ has no option named %@!", name, optionName);
}

-(void)immediateSetOptionName:(NSString *)optionName value:(NSString *)value {
  int i;
  UCIOption *theOption;
  for(i = 0; i < [options count]; i++) {
    theOption = [options objectAtIndex: i];
    if([[theOption name] isEqualToString: optionName])  {
      if(![[theOption value] isEqualToString: value]) {
	[theOption setValue: value];
	[self sendCommand: [NSString stringWithFormat: 
				       @"setoption name %@ value %@\n",
				     optionName, value]];
      }
      return;
    }
  }
  //  NSLog(@"UCI engine %@ has no option named %@!", name, optionName);
}

-(void)ponderhit {
  [self sendCommand: @"ponderhit\n"];
}

-(void)stop {
  [self sendCommand: @"stop\n"];
}

-(void)startNewGame {
  [self queueCommand: [NSString stringWithString: @"ucinewgame\n"]];
}

-(void)setPosition:(NSString *)setposString {
  [self queueCommand: setposString];
  [self queueCommand: [NSString stringWithString: @"\n"]];
}

-(void)parseInfo:(NSString *)infoString {
  NSScanner *scanner = [[NSScanner alloc] initWithString: infoString];
  NSCharacterSet *charSet = 
    [[NSCharacterSet whitespaceCharacterSet] invertedSet];
  NSString *str;
  NSMutableString *mstr;
  NSMutableArray *array = [[NSMutableArray alloc] init];
  int i, j;

  // Split infoString into white-space separated tokens, and store them into 
  // 'array':
  while(![scanner isAtEnd]) {
    [scanner scanCharactersFromSet: charSet intoString: &str];
    [array addObject: str];
    // ? [str release]; ?
  }
  [scanner release];

  // Scan for depth:
  for(i = 0; i < [array count]; i++) 
    if([[array objectAtIndex: i] isEqualToString: @"depth"] &&
       i + 1 < [array count]) 
      [controller setDepth: [array objectAtIndex: i + 1]];

  // Scan for node count:
  for(i = 0; i < [array count]; i++) 
    if([[array objectAtIndex: i] isEqualToString: @"nodes"] &&
       i + 1 < [array count]) 
      [controller setNodes: [array objectAtIndex: i + 1]];

  // Scan for nps:
  for(i = 0; i < [array count]; i++) 
    if([[array objectAtIndex: i] isEqualToString: @"nps"] &&
       i + 1 < [array count]) 
      [controller setNPS: [array objectAtIndex: i + 1]];

  // Scan for move:
  for(i = 0; i < [array count]; i++) 
    if([[array objectAtIndex: i] isEqualToString: @"currmove"] &&
       i + 1 < [array count]) {
      // Scan for move number:
      for(j = 0; j < [array count]; j++) 
        if([[array objectAtIndex: j] isEqualToString: @"currmovenumber"] &&
           j + 1 < [array count])
          [controller setMove: [array objectAtIndex: i + 1]
                       number: [array objectAtIndex: j + 1]];
    }

  // scan for time:
  for(i = 0; i < [array count]; i++)
    if([[array objectAtIndex: i] isEqualToString: @"time"] &&
       i + 1 < [array count]) 
      [controller setTime: [array objectAtIndex: i+1]];

  // Scan for score:
  for(i = 0; i < [array count]; i++) 
    if([[array objectAtIndex: i] isEqualToString: @"score"] &&
       i + 2 < [array count]) {
      ScoreType s;
      if (i + 3 < [array count] &&
          [[array objectAtIndex: i + 3] isEqualToString: @"lowerbound"])
        s = SCORE_LOWER_BOUND;
      else if (i + 3 < [array count] &&
               [[array objectAtIndex: i + 3] isEqualToString: @"upperbound"])
        s = SCORE_UPPER_BOUND;
      else
        s = SCORE_EXACT;
      if([[array objectAtIndex: i + 1] isEqualToString: @"cp"])
        [controller setCPScore: [array objectAtIndex: i + 2]
                     scoreType: s];
      else if([[array objectAtIndex: i + 1] isEqualToString: @"mate"])
        [controller setMateScore: [array objectAtIndex: i + 2]
                       scoreType: s];
    }

  // Scan for PV:
  for(i = 0; i < [array count]; i++) 
    if([[array objectAtIndex: i] isEqualToString: @"pv"] &&
       i + 1 < [array count]) {
      mstr = [NSMutableString stringWithString: @""];
      for(j = i + 1; j < [array count]; j++)
        [mstr appendFormat: @"%@ ", [array objectAtIndex: j]];
      [controller setPV: mstr];
    }

  [array release];
}

-(void)parseBestmove:(NSString *)bestmoveString {
  NSScanner *scanner = [[NSScanner alloc] initWithString: bestmoveString];
  NSCharacterSet *charSet = 
    [[NSCharacterSet whitespaceCharacterSet] invertedSet];
  NSMutableArray *array = [[NSMutableArray alloc] init];
  NSString *str;
  NSString *bestmove, *pondermove;

  //  NSLog(@"bestmoveString: %@", bestmoveString);
  // Split bestmoveString into white-space separated tokens, and store them
  // into 'array':
  while(![scanner isAtEnd]) {
    [scanner scanCharactersFromSet: charSet intoString: &str];
    [array addObject: str];
  }
  [scanner release];

  if([array count] >= 2) {
    bestmove = [array objectAtIndex: 1];
    if([array count] >= 4)
      pondermove = [array objectAtIndex: 3];
    else pondermove = nil;
    [controller bestmove: bestmove ponder: pondermove];
  }
  [array release];
}

-(void)saveOptions {
  NSMutableDictionary *installedEngineOptions =
    [NSMutableDictionary dictionaryWithDictionary:
			   [Engine installedEngineOptions]];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *array = [[NSMutableArray alloc] init];
  NSEnumerator *enumerator = [options objectEnumerator];
  UCIOption *option;

  while((option = [enumerator nextObject]))
    [array addObject: [option dictionary]];

  [installedEngineOptions setObject: array forKey: name];
  [defaults setObject: installedEngineOptions 
               forKey: @"InstalledEngineOptions"];
  [array release];
}

-(void)loadOptions {
  NSArray *optionsArray = [[Engine installedEngineOptions] objectForKey: name];
  NSEnumerator *enumerator = [optionsArray objectEnumerator];
  NSDictionary *dict;

  while((dict = [enumerator nextObject])) 
    if([dict objectForKey: @"value"])
      [self immediateSetOptionName: [dict objectForKey: @"name"]
                             value: [dict objectForKey: @"value"]];
}

-(BOOL)shouldUseGUIBook {
  return [Engine useGUIBookForEngineWithName: name];
}

-(BOOL)shouldUseOwnBook {
  return [Engine useOwnBookForEngineWithName: name];
}

-(void)setShouldUseGUIBook {
  NSMutableDictionary *installedEngineBookOptions = 
    [NSMutableDictionary dictionaryWithDictionary: 
			   [Engine installedEngineBookOptions]];
  NSMutableDictionary *bookOptions = [[NSMutableDictionary alloc] init];

  [self setOptionName: @"OwnBook" value: @"false"];
  [bookOptions setObject: @"GUIBook" forKey: @"BookType"];
  [installedEngineBookOptions setObject: bookOptions forKey: name];
  [[NSUserDefaults standardUserDefaults] 
    setObject: installedEngineBookOptions
       forKey: @"InstalledEngineBookOptions"];
  [bookOptions release];
}

-(void)setShouldUseOwnBook {
  NSMutableDictionary *installedEngineBookOptions = 
    [NSMutableDictionary dictionaryWithDictionary: 
			   [Engine installedEngineBookOptions]];
  NSMutableDictionary *bookOptions = [[NSMutableDictionary alloc] init];

  [self setOptionName: @"OwnBook" value: @"true"];
  [bookOptions setObject: @"OwnBook" forKey: @"BookType"];
  [installedEngineBookOptions setObject: bookOptions forKey: name];
  [[NSUserDefaults standardUserDefaults] 
    setObject: installedEngineBookOptions
       forKey: @"InstalledEngineBookOptions"];
  [bookOptions release];
}

-(void)setShouldUseNoBook {
  NSMutableDictionary *installedEngineBookOptions = 
    [NSMutableDictionary dictionaryWithDictionary: 
			   [Engine installedEngineBookOptions]];
  NSMutableDictionary *bookOptions = [[NSMutableDictionary alloc] init];

  [self setOptionName: @"OwnBook" value: @"false"];
  [bookOptions setObject: @"NoBook" forKey: @"BookType"];
  [installedEngineBookOptions setObject: bookOptions forKey: name];
  [[NSUserDefaults standardUserDefaults] 
    setObject: installedEngineBookOptions
       forKey: @"InstalledEngineBookOptions"];
  [bookOptions release];
}
  
-(void)handleCommand:(char *)command {
  // NSLog(@"%@ > %@", name, [NSString stringWithUTF8String: command]);
  if(strncmp(command, "option", 6) == 0) {
    UCIOption *newOption = 
      [[UCIOption alloc]
        initWithString: [NSString stringWithUTF8String:command]];
    if(options == NULL) 
      options = [[NSMutableArray alloc] init];
    [options addObject: newOption];
    // NSLog(@"new UCI option: %@", newOption);
    [newOption release];
  }
  if(strncmp(command, "uciok", 5) == 0) {
    NSMutableDictionary *installedEngines = 
      [NSMutableDictionary dictionaryWithDictionary:
			     [Engine installedEngines]];
    NSMutableDictionary *installedEngineOptions =
      [NSMutableDictionary dictionaryWithDictionary:
			     [Engine installedEngineOptions]];
    NSMutableDictionary *installedEngineBookOptions =
      [NSMutableDictionary dictionaryWithDictionary:
			     [Engine installedEngineBookOptions]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if([installedEngines objectForKey: name] == nil) {
      [installedEngines setObject: path forKey: name];
      [defaults setObject: installedEngines forKey: @"InstalledEngines"];
    }

    if(installOnly)
      [self quit];
    else {
      if([installedEngineOptions objectForKey: name] == nil) {
	[self setOptionName: @"Hash" 
                      value: [NSString stringWithFormat: @"%d", [Engine defaultHashSize]]];
	[self saveOptions];
      }
      else
	[self loadOptions];
      
      if([installedEngineBookOptions objectForKey: name] == nil) {
	if([self supportsOwnBook] &&
	   [[[self optionWithName: @"OwnBook"] defaultValue] 
	     isEqualToString: @"true"]) 
	  [self setShouldUseOwnBook];
	else
	  [self setShouldUseGUIBook];
      }
      
      [self askIfReady];
    }
  }
  if(strncmp(command, "readyok", 7) == 0) {
    isReady = YES;
    [controller setEngineIsReady: YES];
    [self processQueue];
  }
  if(strncmp(command, "id name", 7) == 0) {
    name = [[NSString stringWithUTF8String: command + 8] retain];
    [controller setEngineName: name];
    // NSLog(@"Engine name: %@", name);
  }
  if(strncmp(command, "id author", 9) == 0) {
    author = [[NSString stringWithUTF8String: command + 10] retain];
    // NSLog(@"Engine author: %@", author);
  }
  if(strncmp(command, "info", 4) == 0) {
    [self parseInfo: [NSString stringWithUTF8String: command + 5]];
  }
  if(strncmp(command, "bestmove", 8) == 0) {
    thinking = NO;
    [self parseBestmove: [NSString stringWithUTF8String: command]];
    [self processQueue];
  }
}

-(void)taskDataAvailable:(NSNotification *)aNotification {
  const char *bytes;
  NSData *incomingData;

  // NSLog(@"task data for %@", name);
  incomingData =
    [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem];
  if(incomingData && [incomingData length]) {
    NSString *incomingText = 
      [[NSString alloc] initWithData: incomingData
                            encoding: NSASCIIStringEncoding];
    //    bytes = [incomingData bytes];
    bytes = [incomingText UTF8String];
    if(bytes != NULL) {
      strcat(inputBuffer, bytes);
      if(inputBuffer[strlen(inputBuffer) - 1] == '\n') {
	char *running, *command;
	running = inputBuffer;
	for(command = strsep(&running, "\n"); command != NULL; 
	    command = strsep(&running, "\n")) 
	  [self handleCommand: command];
	sprintf(inputBuffer, "");
      }
    }
    [incomingText release];
    [taskOutput readInBackgroundAndNotify];
  }
}

-(void)handleError:(char *)error {
  NSLog(@"%@ > ERROR: %@", name, [NSString stringWithUTF8String: error]);
}

-(void)taskErrorDataAvailable:(NSNotification *)aNotification {
  const char *bytes;
  NSData *incomingData;

  incomingData =
    [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem];
  if(incomingData && [incomingData length]) {
    NSString *incomingText = 
      [[NSString alloc] initWithData: incomingData
                            encoding: NSASCIIStringEncoding];
    bytes = [incomingText UTF8String];
    if(bytes != NULL) {
      strcat(errorBuffer, bytes);
      if(errorBuffer[strlen(inputBuffer) - 1] == '\n') {
	char *running, *command;
	running = errorBuffer;
	for(command = strsep(&running, "\n"); command != NULL; 
	    command = strsep(&running, "\n")) 
	  [self handleError: command];
	sprintf(errorBuffer, "");
      }
    }
    [incomingText release];
    [taskError readInBackgroundAndNotify];
  }
}

-(void)askIfReady {
  isReady = NO;
  [self sendCommand: @"isready\n"];
}

-(void)quit {
  [self sendCommand: @"quit\n"];
}
  
-(void)dealloc {
  //  [self quit];
  [path release];
  [name release];
  [author release];
  [options release];
  [task release];
  /*
    [taskInput release];
    [taskOutput release];
    [taskError release];
  */
  [controller release];
  [commandQueue release];
  [super dealloc];
}

@end
