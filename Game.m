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


#import "Game.h"
#import "GameParser.h"
#import "MyNSMutableAttributedStringAdditions.h"

@implementation Game

-(id)initWithFEN:(NSString *)fen {
  ChessPosition *position;

  [super init];
  rootFEN = [fen retain];
  position = [[ChessPosition alloc] initWithFEN: fen];
  root = [[GameNode alloc] initWithPosition: position];
  [position release];
  currentNode = root;
  whitePlayer = [[NSString stringWithString: @"?"] retain];
  blackPlayer = [[NSString stringWithString: @"?"] retain];
  event = [[NSString stringWithString: @"?"] retain];
  site = [[NSString stringWithString: @"?"] retain];
  round = [[NSString stringWithString: @"?"] retain];
  {
    NSCalendarDate *now = [[NSCalendarDate calendarDate] retain];
    date = [[NSString stringWithFormat: @"%4d.%02d.%2d",
		      [now yearOfCommonEra],
		      [now monthOfYear],
		      [now dayOfMonth]]
	     retain];
    [now release];
  }
  result = UNKNOWN;
  clock = [[ChessClock alloc] init];
  FRC = NO;
  //  [self startClock];

  return self;
}

-(id)initWithFRCid:(int)FRCid {
  [self initWithFEN: [ChessPosition fenFromFRCid: FRCid]];
  FRC = YES;
  return self;
}

-(id)initWithPGNString:(NSString *)string {
  GameParser *gp;
  PGNToken token[1];
  char name[PGN_STRING_SIZE], value[PGN_STRING_SIZE];

  [self init];

  gp = [[GameParser alloc] initWithString: string];

  // Scan for PGN headers first:
  while(YES) {
    [gp getNextToken: token];
    if(token->type != '[') break;
    [gp getNextToken: token];

    if(token->type != TOKEN_SYMBOL) 
      [[NSException exceptionWithName: @"PGNHeaderException"
		    reason: @"Invalid PGN header"
		    userInfo: nil]
	raise];
    
    strcpy(name, token->string);
    [gp getNextToken: token];

    if(token->type != TOKEN_STRING) 
      [[NSException exceptionWithName: @"PGNHeaderException"
		    reason: @"Invalid PGN header"
		    userInfo: nil]
	raise];

    strcpy(value, token->string);
    [gp getNextToken: token];
    
    if(token->type != ']')
      [[NSException exceptionWithName: @"PGNHeaderException"
		    reason: @"Invalid PGN header"
		    userInfo: nil]
	raise];

    // OK, now we have a PGN tag consisting of a (name, value) pair.  Is
    // it one of the tags we care about?
    if(NO) {
    } else if(strcmp(name, "White") == 0) {
      [whitePlayer release];
      whitePlayer = [[NSString stringWithUTF8String: value] retain];
    } else if(strcmp(name, "Black") == 0) {
      [blackPlayer release];
      blackPlayer = [[NSString stringWithUTF8String: value] retain];
    } else if(strcmp(name, "Event") == 0) {
      [event release];
      event = [[NSString stringWithUTF8String: value] retain];
    } else if(strcmp(name, "Site") == 0) {
      [site release];
      site = [[NSString stringWithUTF8String: value] retain];
    } else if(strcmp(name, "Round") == 0) {
      [round release];
      round = [[NSString stringWithUTF8String: value] retain];
    } else if(strcmp(name, "Date") == 0) {
      [date release];
      date = [[NSString stringWithUTF8String: value] retain];
    } else if(strcmp(name, "Result") == 0) {
      if(strncmp(value, "1-0", 3) == 0)
	result = WHITE_WINS;
      else if(strncmp(value, "0-1", 3) == 0)
	result = BLACK_WINS;
      else if(strncmp(value, "1/2-1/2", 7) == 0)
	result = DRAW;
      else
	result = UNKNOWN;
    } else if(strncmp(name, "FEN", 3) == 0) {
      [rootFEN release];
      rootFEN = [[NSString stringWithUTF8String: value] retain];
    }
  }

  // We have finished scanning the headers. If a FEN was given, set up the
  // given position. 
  if(rootFEN) {
    ChessPosition *position;
    [root release];
    position = [[ChessPosition alloc] initWithFEN: rootFEN];
    root = [[GameNode alloc] initWithPosition: position];
    [position release];
    currentNode = root;
  }

  do {
    if(NO) {
    } else if(token->type == '{') {
      [self addComment: [gp readComment]];
    } else if(token->type == '(') {
      // Beginning of a Recursive Annotation Variation (RAV). Go up to the
      // parent node and start inserting moves from there:
      if(currentNode == root) 
	[[NSException exceptionWithName: @"PGNException"
		      reason: @"Variation before first move"
		      userInfo: nil] raise];
      else 
	currentNode = [currentNode parent];
    } else if(token->type == ')') {
      // End of a RAV. Go to the start of the variation and down to the first
      // child node:
      [self goToBeginningOfVariation];
      currentNode = [currentNode firstChildNode];
    } else if(token->type == TOKEN_NAG) {
      [self addNAG: atoi(token->string)];
    } else if(token->type == TOKEN_SYMBOL) {
      // This should be a move. Try to parse it:
      ChessMove *move = 
	[self parseSANMove: [NSString stringWithUTF8String: token->string]];
      if(move == nil) { // Failed to parse move
	[[self currentPosition] display];
	NSLog(@"Illegal move: %s", token->string);
	NSLog(@"%@", [self PGNString]);
	[[NSException exceptionWithName: @"PGNException"
		      reason: [NSString stringWithFormat:
					  @"Illegal move: %s",
					token->string]
		      userInfo: nil] raise];
      } else { 
	[self insertMove: move];
      }
    } else if(token->type == TOKEN_RESULT || token->type == TOKEN_EOF) {
      // Finished
      break;
    }
  } while([gp getNextToken: token]);

  [gp release];

  NSAssert(round != nil, @"Round is nil!");

  return self;
}
  
-(id)init {
  return [self initWithFEN: [NSString stringWithUTF8String: STARTPOS]];
}

-(ChessClock *)clock {
  return clock;
}

-(NSString *)rootFEN {
  return rootFEN;
}

-(NSString *)whitePlayer {
  return whitePlayer;
}

-(void)setWhitePlayer:(NSString *)str {
  [str retain];
  [whitePlayer release];
  whitePlayer = str;
}

-(NSString *)blackPlayer {
  return blackPlayer;
}

-(void)setBlackPlayer:(NSString *)str {
  [str retain];
  [blackPlayer release];
  blackPlayer = str;
}

-(NSString *)event {
  return event;
}

-(void)setEvent:(NSString *)str {
  [str retain];
  [event release];
  event = str;
}

-(NSString *)site {
  return site;
}

-(void)setSite:(NSString *)str {
  [str retain];
  [site release];
  site = str;
}

-(NSString *)date {
  return date;
}

-(void)setDate:(NSString *)str {
  [str retain];
  [date release];
  date = str;
}

-(NSString *)round {
  return round;
}

-(void)setRound:(NSString *)str {
  [str retain];
  [round release];
  round = str;
}

-(result_t)result {
  return result;
}

-(void)setResult:(result_t)r {
  result = r;
}

-(id)root {
  return root;
}

-(id)currentNode {
  return currentNode;
}

-(id)currentPosition {
  return [currentNode position];
}

-(int)pieceAtSquare:(int)squareIndex {
  return [[self currentPosition] pieceAtSquare: squareIndex];
}

-(void)pushClock {
  if(![clock isRunning]) {
    //    [[self currentPosition] display];
    if([self whiteToMove])
      [clock startClockForWhite];
    else 
      [clock startClockForBlack];
  }
  else [clock pushClock];
}

-(void)insertMove:(ChessMove *)move {
  [currentNode addChildNode: move];
  currentNode = [[currentNode children] lastObject];
  [self pushClock];
} 

-(void)makeMove:(ChessMove *)move {
  [currentNode removeAllChildNodes];
  [self insertMove: move];
}

-(void)unmakeMove {
  if(currentNode != root)
    currentNode = [currentNode parent];
}

-(void)stepForward {
  if([[currentNode children] count] > 0)
    currentNode = [currentNode firstChildNode];
}

-(void)goToBeginningOfGame {
  while(currentNode != root) currentNode = [currentNode parent];
}

-(void)goToEndOfGame {
  for(currentNode = root; [[currentNode children] count] > 0;
      currentNode = [currentNode firstChildNode]);
}

-(void)deleteVariation {
  if(currentNode != root) {
    GameNode *parent = [currentNode parent];
    [[parent children] removeObjectIdenticalTo: currentNode];
    currentNode = parent;
  }
}

-(BOOL)isAtBeginningOfGame {
  if(currentNode == root) return YES;
  else return NO;
}

-(BOOL)isAtEndOfGame {
  GameNode *node;

  if([[currentNode children] count] > 0) return NO;
  for(node = root; [[node children] count] > 0; node = [node firstChildNode]);
  if(node == currentNode) return YES;
  else return NO;
}

-(BOOL)previousVariationExists {
  if(currentNode == root) return NO;
  if([[[currentNode parent] children] indexOfObject: currentNode] == 0)
    return NO;
  else
    return YES;
}

-(BOOL)nextVariationExists {
  NSMutableArray *siblings;
  if(currentNode == root) return NO;
  siblings = [[currentNode parent] children];
  if([siblings indexOfObject: currentNode] < [siblings count] - 1)
    return YES;
  else 
    return NO;
}

-(void)goToPreviousVariation {
  if([self previousVariationExists]) {
    NSMutableArray *siblings = [[currentNode parent] children];
    currentNode = [siblings objectAtIndex: 
			      [siblings indexOfObject: currentNode] - 1];
  }
}    

-(void)goToNextVariation {
  if([self nextVariationExists]) {
    NSMutableArray *siblings = [[currentNode parent] children];
    currentNode = [siblings objectAtIndex: 
			      [siblings indexOfObject: currentNode] + 1];
  }
}    

-(void)moveVariationUp {
  if([self previousVariationExists]) {
    NSMutableArray *siblings = [[currentNode parent] children];
    int index = [siblings indexOfObject: currentNode];
    id tmp = [siblings objectAtIndex: index - 1];
    [tmp retain];
    [siblings replaceObjectAtIndex: index - 1 withObject: currentNode];
    [siblings replaceObjectAtIndex: index withObject: tmp];
    [tmp release];
  }
}

-(void)moveVariationDown {
  if([self nextVariationExists]) {
    NSMutableArray *siblings = [[currentNode parent] children];
    int index = [siblings indexOfObject: currentNode];
    id tmp = [siblings objectAtIndex: index + 1];
    [tmp retain];
    [siblings replaceObjectAtIndex: index + 1 withObject: currentNode];
    [siblings replaceObjectAtIndex: index withObject: tmp];
    [tmp release];
  }
}

-(BOOL)branchPointExistsUp {
  GameNode *node;
  if(currentNode != root) {
    node = [currentNode parent];
    while(node != root) {
      if([[[node parent] children] count] > 1)
        return YES;
      node = [node parent];
    }
  }
  return NO;
}

-(BOOL)branchPointExistsDown {
  GameNode *node;
  if([[currentNode children] count] > 0) {
    node = [currentNode firstChildNode];
    while([[node children] count] > 0) {
      if([[node children] count] > 1) return YES;
      node = [node firstChildNode];
    }
  }
  return NO;
}

-(void)goBackToBranchPoint {
  if([self branchPointExistsUp]) {
    GameNode *node = [currentNode parent];
    while(node != root) {
      if([[[node parent] children] count] > 1) {
	currentNode = node;
	return;
      }
      node = [node parent];
    }
  }
}

-(void)goForwardToBranchPoint {
  if([self branchPointExistsDown]) {
    GameNode *node = [currentNode firstChildNode];
    while([[node children] count] > 0) {
      if([[node children] count] > 1) {
	currentNode = [node firstChildNode];
	return;
      }
      node = [node firstChildNode];
    }
  }
}

-(BOOL)isAtBeginningOfVariation {
  return [self isAtBeginningOfGame];
}

-(void)goToBeginningOfVariation {
  GameNode *node;

  if(currentNode == root) return;
  for(node = currentNode/*[currentNode parent]*/;
      node != root && [node isFirstChild];
      node = [node parent])
    NSLog(@"node = %@", node);
  //  NSLog(@"node = %@, root = %@", node, root);
  if(node != root) currentNode = [node parent];
  else currentNode = node;
}

-(BOOL)isAtEndOfVariation {
  if([[currentNode children] count] == 0) return YES;
  else return NO;
}

-(void)goToEndOfVariation {
  while([[currentNode children] count] > 0)
    currentNode = [currentNode firstChildNode];
}

-(BOOL)isInAVariation {
  GameNode *node;

  for(node = currentNode; node != root; node = [node parent])
    if(node != [[node parent] firstChildNode]) return YES;
  return NO;
}

-(void)addComment:(NSString *)comment {
  if(currentNode != root)
    [[currentNode move] setComment: comment];
}

-(void)deleteComment {
  if(currentNode != root)
    [[currentNode move] deleteComment];
}

-(BOOL)commentExistsForCurrentMove {
  if(currentNode == root) return NO;
  else return [[currentNode move] hasComment];
}

-(void)addNAG:(int)nag {
  if(currentNode != root)
    [[currentNode move] setNAG: nag];
}

-(ChessMove *)parseSANMove:(NSString *)str {
  return [[self currentPosition] parseSANMove: str];
}

static NSString* breakLinesInString(NSString *string) {
  NSScanner *scanner = [[NSScanner alloc] initWithString: string];
  NSCharacterSet *charSet = 
    [[NSCharacterSet whitespaceCharacterSet] invertedSet];
  NSString *str;
  NSMutableString *mstr;
  NSMutableArray *array = [[NSMutableArray alloc] init];
  int i, j;

  // Split 'string' into white-space separated tokens, and store them into
  // 'array':
  while(![scanner isAtEnd]) {
    [scanner scanCharactersFromSet: charSet intoString: &str];
    [array addObject: str];
  }
  [scanner release];
  
  // Build new string:
  mstr = [NSMutableString stringWithString: @""];
  j = 0;
  for(i = 0; i < [array count]; i++) {
    int length = [[array objectAtIndex: i] length];
    if(j + length + 1 < 80) {
      if(i > 0) { // HACK
	[mstr appendString: @" "];
	j += length + 1;
      }
      else j += length;
    }
    else {
      [mstr appendString: @"\n"];
      j = length;
    }
    [mstr appendString: [array objectAtIndex: i]];
  }
  return [NSString stringWithString: mstr];
}

static char ResultString[6][10] = 
  {"1-0", "0-1", "3/4-1/4", "1/4-3/4", "1/2-1/2", "*"};
  
-(NSString *)PGNString {
  NSMutableString *str;
  str = [[NSMutableString stringWithFormat: @"[Event \"%@\"]\n", event] retain];
  [str appendFormat: @"[Site \"%@\"]\n", site];
  [str appendFormat: @"[Date \"%@\"]\n", date];
  [str appendFormat: @"[Round \"%@\"]\n", round];
  [str appendFormat: @"[White \"%@\"]\n", whitePlayer];
  [str appendFormat: @"[Black \"%@\"]\n", blackPlayer];
  [str appendFormat: @"[Result \"%s\"]\n", ResultString[result]];
  if(FRC) [str appendFormat: @"[Variant \"fischerandom\"]\n"];
  if(![rootFEN isEqualToString: [NSString stringWithUTF8String: STARTPOS]])
    [str appendFormat: @"[FEN \"%@\"]\n", rootFEN];
  [str appendFormat: @"\n"];
  [str appendString: breakLinesInString([self moveListString])];
  [str appendString: @"\n\n"];
  [str autorelease];
  return str;
}

-(NSString *)moveListString {
  return [NSString stringWithFormat: @"%@\n%s",
		   [root moveListString], ResultString[result]];
}

-(NSString *)moveListStringWithComments:(BOOL)includeComments
			     variations:(BOOL)includeVariations {
  return [NSString stringWithFormat: @"%@\n%s",
		   [root moveListStringWithComments: includeComments
			 variations: includeVariations],
		   ResultString[result]];
}

-(NSAttributedString *)moveListAttributedStringWithComments:(BOOL)includeComments
						 variations:(BOOL)includeVariations {
  NSMutableAttributedString *string = 
    [root moveListAttributedStringWithComments: includeComments
	  variations: includeVariations
	  currentNode: currentNode];
  [string appendString: [NSString stringWithFormat: @"\n%s",
				  ResultString[result]]];
  return string;
}

-(ChessMove *)generateMoveFrom:(int)from to:(int)to 
		     promotion:(int)promotion {
  return [[self currentPosition] generateMoveFrom: from to: to
				 promotion: promotion];
}

-(ChessMove *)generateMoveFrom:(int)from to:(int)to {
  return [[self currentPosition] generateMoveFrom: from to: to];
}

-(BOOL)whiteToMove {
  return [[self currentPosition] whiteToMove];
}

-(BOOL)blackToMove {
  return ![[self currentPosition] whiteToMove];
}

-(void)startClock {
  if([self whiteToMove])
    [clock startClockForWhite];
  else
    [clock startClockForBlack];
}

-(void)stopClock {
  [clock stopClock];
}

-(int)whiteRemainingTime {
  return [clock whiteRemainingTime];
}

-(int)blackRemainingTime {
  return [clock blackRemainingTime];
}

-(int)whiteIncrement {
  return [clock whiteIncrement];
}

-(int)blackIncrement {
  return [clock blackIncrement];
}

-(NSString *)clockString {
  return [NSString stringWithFormat: @"%@  %@",
		   [clock whiteRemainingTimeString],
		   [clock blackRemainingTimeString]];
}

-(BOOL)isFRCGame {
  return FRC;
}

-(void)setIsFRCGame:(BOOL)isFRCGame {
  FRC = isFRCGame;
}

-(void)setTimeControlWithWhiteTime:(int)whiteTime
                         blackTime:(int)blackTime
                    whiteIncrement:(int)whiteIncrement
                    blackIncrement:(int)blackIncrement {
  [clock resetWithWhiteTime: whiteTime
         blackTime: blackTime
         whiteIncrement: whiteIncrement
         blackIncrement: blackIncrement];
}

-(void)setTimeControlWithWhiteTime:(int)whiteTime
			  forMoves:(int)whiteNumOfMoves
			 blackTime:(int)blackTime
			  forMoves:(int)blackNumOfMoves {
  [clock resetWithWhiteTime: whiteTime
	 forMoves: whiteNumOfMoves
	 blackTime: blackTime
	 forMoves: blackNumOfMoves];
}

-(void)saveToFile:(NSString *)filename {
  FILE *pgnFile;
  pgnFile = fopen([filename UTF8String], "a");
  fputs([[self PGNString] UTF8String], pgnFile);
  fclose(pgnFile);
}

-(void)dealloc {
  NSAssert(round != nil, @"Round is nil!");
  [whitePlayer release];
  [blackPlayer release];
  [event release];
  [site release];
  [round release];
  [date release];
  [root release];
  [clock release];
  [rootFEN release];

  // We don't have to release currentNode, because it is guaranteed to
  // be the root node or one of its descendants.
  
  [super dealloc];
}

@end
