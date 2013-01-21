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


#import "UCIOption.h"


// private methods:
@interface UCIOption (PrivateAPI)
+(BOOL)isKeyword:(NSString *)string;
@end


@implementation UCIOption

+(BOOL)isKeyword:(NSString *)string {
  NSArray *keywords = 
    [NSArray arrayWithObjects: 
               @"name", @"type", @"default", @"max", @"min", @"var", nil];
  int i;
  for(i = 0; i < [keywords count]; i++)
    if([[keywords objectAtIndex: i] isEqualToString: string])
      return YES;
  return NO;
}

-(id)initWithString:(NSString *)string {
  NSScanner *scanner;
  NSCharacterSet *charSet;
  NSString *str;
  NSMutableString *mstr;
  NSMutableArray *array;
  int i, j;

  [super init];
  charSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
  scanner = [[NSScanner alloc] initWithString: string];
  array = [[NSMutableArray alloc] init];

  while(![scanner isAtEnd]) {
    [scanner scanCharactersFromSet: charSet intoString: &str];
    [array addObject: str];
  }

  [scanner release];

  // Scan for name:
  for(i = 0; i < [array count]; i++)
    if([[array objectAtIndex: i] isEqualToString: @"name"]) {
      mstr = [NSMutableString stringWithString: @""];
      for(j = i + 1; 
          j < [array count] && ![UCIOption isKeyword: [array objectAtIndex: j]];
          j++) {
        if(j > i + 1) [mstr appendString: @" "];
        [mstr appendString: [array objectAtIndex: j]];
      }
      name = [[NSString stringWithString: mstr] retain];
    }

  // Scan for type:
  for(i = 0; i < [array count]; i++)
    if([[array objectAtIndex: i] isEqualToString: @"type"]) {
      NSString *s = [array objectAtIndex: i+1];
      if([s isEqualToString: @"spin"]) type = UCI_SPIN;
      else if([s isEqualToString: @"combo"]) type = UCI_COMBO;
      else if([s isEqualToString: @"check"]) type = UCI_CHECK;
      else if([s isEqualToString: @"string"]) type = UCI_STRING;
      else if([s isEqualToString: @"button"]) type = UCI_BUTTON;
      else type = UCI_UNKNOWN;
    }

  // Scan for default value:
  for(i = 0; i < [array count]; i++)
    if([[array objectAtIndex: i] isEqualToString: @"default"]) {
      mstr = [NSMutableString stringWithString: @""];
      for(j = i + 1; 
          j < [array count] && ![UCIOption isKeyword: [array objectAtIndex: j]];
          j++) {
        if(j > i + 1) [mstr appendString: @" "];
        [mstr appendString: [array objectAtIndex: j]];
      }
      defaultValue = [[NSString stringWithString: mstr] retain];
      value = [[NSString stringWithString: mstr] retain];
    }

  if(type == UCI_SPIN) {
    // Scan for min and max values:
    for(i = 0; i < [array count]; i++) {
      if([[array objectAtIndex: i] isEqualToString: @"min"]) 
        min = [[array objectAtIndex: i+1] intValue];
      else if([[array objectAtIndex: i] isEqualToString: @"max"]) 
        max = [[array objectAtIndex: i+1] intValue];
    }
  }
  else if(type == UCI_COMBO) {
    // Scan for allowed values:
    NSMutableArray *a = [[NSMutableArray alloc] init];
    for(i = 0; i < [array count]; i++)
      if([[array objectAtIndex: i] isEqualToString: @"var"]) {
        mstr = [NSMutableString stringWithString: @""];
        for(j = i + 1; 
            j<[array count] && ![UCIOption isKeyword:[array objectAtIndex: j]];
            j++) {
          if(j > i + 1) [mstr appendString: @" "];
          [mstr appendString: [array objectAtIndex: j]];
        }
        [a addObject: mstr];
      }
    comboValues = [[NSArray arrayWithArray: a] retain];
    [a release];
  }
  [array release];

  return self;
}

-(NSString *)description {
  switch(type) {
  case UCI_SPIN:
    return [NSString stringWithFormat: 
                       @"<UCIOption: name %@, type UCI_SPIN, default %@, value %@, min %d, max %d>",
                     name, defaultValue, value, min, max];
  case UCI_COMBO:
    return [NSString stringWithFormat:
                       @"<UCIOption: name %@, type UCI_COMBO, default %@, value %@, possible values %@>",
                     name, defaultValue, value, comboValues];
  case UCI_CHECK:
    return [NSString stringWithFormat:
                       @"<UCIOption: name %@, type UCI_CHECK, default %@, value %@>",
                     name, defaultValue, value];
  case UCI_STRING:
    return [NSString stringWithFormat:
                       @"<UCIOption: name %@, type UCI_STRING, default %@, value %@>",
                     name, defaultValue, value];
  case UCI_BUTTON:
    return [NSString stringWithFormat: 
                       @"<UCIOption: name %@, type UCI_BUTTON>", name];
  default:
    return [NSString stringWithString: @"<UCIOption: unknown type>"];
  }
}

-(NSString *)name {
  return name;
}

-(void)setName:(NSString *)newName {
  [newName retain];
  [name release];
  name = newName;
}

-(int)min {
  return min;
}

-(void)setMin:(int)newMin {
  min = newMin;
}

-(int)max {
  return max;
}

-(void)setMax:(int)newMax {
  max = newMax;
}

-(int)type {
  return type;
}

-(void)setType:(int)newType {
  type = newType;
}

-(NSArray *)comboValues {
  return comboValues;
}

 -(void)setComboValues:(NSArray *)newComboValues {
  [newComboValues retain];
  [comboValues release];
  comboValues = newComboValues;
 }

-(NSString *)defaultValue {
  return defaultValue;
}

 -(void)setDefaultValue:(NSString *)newDefaultValue {
  [newDefaultValue retain];
  [defaultValue release];
  defaultValue = newDefaultValue;
 }

-(NSString *)value {
  return value;
}

-(void)setValue: (NSString *)newValue {
  [newValue retain];
  [value release];
  value = [newValue copy];
  [newValue release];
}

-(NSDictionary *)dictionary {
  NSMutableDictionary *mdict = [[NSMutableDictionary alloc] init];
  NSDictionary *dict;

  //  NSLog(@"in -[UCIOption dictionary] for option %@", self);
  [mdict setObject: [NSString stringWithString: name] forKey: @"name"];
  [mdict setObject: [NSNumber numberWithInt: type] forKey: @"type"];
  [mdict setObject: [NSNumber numberWithInt: min] forKey: @"min"];
  [mdict setObject: [NSNumber numberWithInt: max] forKey: @"max"];
  if(comboValues)
    [mdict setObject: [NSArray arrayWithArray: comboValues] 
	   forKey: @"comboValues"];
  if(defaultValue)
    [mdict setObject: [NSString stringWithString: defaultValue]
	   forKey: @"defaultValue"];
  if(value)
    [mdict setObject: [NSString stringWithString: value] forKey: @"value"];
  dict = [[NSDictionary alloc] initWithDictionary: mdict];
  [mdict release];
  //  NSLog(@"Leaving -[UCIOption dictionary] for option %@", self);
  return [dict autorelease];
}

-(BOOL)isHidden {
  if([name isEqualToString: @"MultiPV"]) return YES;
  if([name isEqualToString: @"Ponder"]) return YES;
  if([name isEqualToString: @"OwnBook"]) return YES;
  if([name hasPrefix: @"UCI_"]) return YES;
  return NO;
}

-(id)copyWithZone:(NSZone *)zone {
  UCIOption *copy = [[[self class] allocWithZone: zone] init];
  [copy setName: name];
  [copy setMin: min];
  [copy setMax: max];
  [copy setType: type];
  [copy setComboValues: comboValues];
  [copy setDefaultValue: defaultValue];
  [copy setValue: value];
  return copy;
 }
 
-(void)dealloc {
  [name release];
  [comboValues release];
  [defaultValue release];
  [value release];
  [super dealloc];
}

@end

