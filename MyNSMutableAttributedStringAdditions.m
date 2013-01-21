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


#import "MyNSAttributedStringAdditions.h"
#import "MyNSMutableAttributedStringAdditions.h"

@implementation NSMutableAttributedString (MyNSMutableAttributedStringAdditions)

+(NSMutableAttributedString *)attributedStringWithString:(NSString *)string {
  NSMutableAttributedString *result = 
    [[NSMutableAttributedString alloc] initWithString: string];
  return [result autorelease];
}

+(NSMutableAttributedString *)attributedStringWithAttributedString:(NSAttributedString *)string {
  NSMutableAttributedString *result = 
    [[NSMutableAttributedString alloc] initWithAttributedString: string];
  return [result autorelease];
}

+(NSMutableAttributedString *)attributedStringWithFormat:(NSString *)format, ... {
  va_list args;
  NSString *string;
  NSMutableAttributedString *astring;

  va_start(args, format);
  string = [[NSString alloc] initWithFormat: format arguments: args];
  va_end(args);
  astring = [[NSMutableAttributedString alloc] initWithString: string];
  [string release];

  return [astring autorelease];
}

-(void)appendString:(NSString *)string {
  [self appendAttributedString:
	  [NSAttributedString attributedStringWithString: string]];
}

-(void)appendFormat:(NSString *)format, ... {
  va_list args;
  NSString *string;
  va_start(args, format);
  string = [[NSString alloc] initWithFormat: format arguments: args];
  va_end(args);
  [self appendString: string];
  [string release];
  va_end(args);
}


@end
