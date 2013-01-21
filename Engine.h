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

typedef enum {
  SCORE_LOWER_BOUND = -1,
  SCORE_EXACT = 0,
  SCORE_UPPER_BOUND = 1
} ScoreType;

@class EngineController;
@class UCIOption;

@interface Engine : NSObject {
  NSString *path;
  NSString *name;
  NSString *author;
  BOOL isRunning;
  NSMutableArray *options;
  NSTask *task;
  NSFileHandle *taskInput, *taskOutput, *taskError;
  EngineController *controller;
  char inputBuffer[16384];
  char errorBuffer[1024];
  NSMutableArray *commandQueue;
  BOOL thinking;
  BOOL isReady;
  BOOL installOnly;
}

+(NSString *)mainEnginePath;
+(int)defaultHashSize;
+(id)installedEngines;
+(id)installedEngineOptions;
+(id)installedEngineBookOptions;
+(NSString *)pathOfEngineWithName:(NSString *)name;
+(NSDictionary *)optionsOfEngineWithName:(NSString *)name;
+(BOOL)useOwnBookForEngineWithName:(NSString *)name;
+(BOOL)useGUIBookForEngineWithName:(NSString *)name;
+(void)uninstallEngineWithName:(NSString *)name;
-(id)initWithController:(EngineController *)ec path:(NSString *)p
	    installOnly:(BOOL)instOnly;
-(id)initWithController:(EngineController *)ec path:(NSString *)p;
-(id)initWithController:(EngineController *)ec;
-(NSString *)name;
-(NSString *)author;
-(NSTask *)task;
-(void)saveOptions;
-(void)loadOptions;
-(NSMutableArray *)options;
-(NSMutableArray *)visibleOptions;
-(BOOL)hasOptionWithName:(NSString *)optionName;
-(BOOL)supportsLimitStrength;
-(BOOL)supportsOwnBook;
-(BOOL)shouldUseOwnBook;
-(BOOL)shouldUseGUIBook;
-(void)setShouldUseOwnBook;
-(void)setShouldUseGUIBook;
-(void)setShouldUseNoBook;
-(UCIOption *)optionWithName:(NSString *)optionName;
-(void)start;
-(void)sendCommand:(NSString *)command;
-(void)searchWithWtime:(int)wtime 
                 btime:(int)btime 
                  winc:(int)winc
                  binc:(int)binc;
-(void)ponderWithWtime:(int)wtime 
                 btime:(int)btime 
                  winc:(int)winc
                  binc:(int)binc;
-(void)searchInfinite;
-(void)pushButtonNamed:(NSString *)buttonName;
-(void)setOptionName:(NSString *)optionName value:(NSString *)value;
-(void)immediateSetOptionName:(NSString *)optionName value:(NSString *)value;
-(void)ponderhit;
-(void)stop;
-(void)setPosition:(NSString *)setposString;
-(void)startNewGame;
-(void)askIfReady;
-(void)taskDataAvailable:(NSNotification *)aNotification;
-(void)quit;


@end
