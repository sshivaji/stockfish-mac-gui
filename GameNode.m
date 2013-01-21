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


#import "GameNode.h"
#import "ChessMove.h"
#import "ChessPosition.h"

#import "MyNSAttributedStringAdditions.h"
#import "MyNSMutableAttributedStringAdditions.h"

@implementation GameNode

-(id)initWithPosition:(ChessPosition *)pos move:(ChessMove *)mv
	       parent:(GameNode *)pnode {
  [super init];
  //  NSLog(@"Creating new node with pos = %@, move = %@, parent = %@",
  //	pos, move, parent);
  position = [pos retain];
  move = [mv retain];
  parent = pnode; // [pnode retain];
  children = [[NSMutableArray alloc] init];

  return self;
}

-(id)initWithPosition:(ChessPosition *)pos {
  return [self initWithPosition: pos move: nil parent: nil];
}

-(id)init {
  return [self initWithPosition: [ChessPosition initialPosition]];
}

-(id)position {
  return position;
}

-(id)move {
  return move;
}

-(GameNode *)parent {
  return parent;
}

-(NSMutableArray *)children {
  return children;
}

-(id)childNodeAtIndex:(int)index {
  return [children objectAtIndex: index];
}

-(id)firstChildNode {
  return [self childNodeAtIndex: 0];
}

-(NSArray *)remainingChildNodes {
  NSRange range;
  int numOfChildren = [children count];
  if(numOfChildren <= 1) return nil;
  range.location = 1;
  range.length = [children count] - 1;
  return [children subarrayWithRange: range];
}

-(NSArray *)siblings {
  if(parent == nil) return nil;
  return [parent children];
}

-(BOOL)isFirstChild {
  if(parent == nil) return YES;
  if(self == [parent firstChildNode]) return YES;
  return NO;
}

-(void)addChildNode:(ChessMove *)mv {
  GameNode *newNode;
  //  [mv retain];
  newNode = [[GameNode alloc] initWithPosition: [ChessPosition
                                                  positionAfterMakingMove: mv
                                                  fromPosition: position]
                              move: mv
                              parent: self];
  [children addObject: newNode];
  [newNode release];
  //  [mv release];
}

-(void)removeChildNodeAtIndex:(int)index {
  [children removeObjectAtIndex: index];
}

-(void)removeAllChildNodes {
  [children removeAllObjects];
}

-(NSString *)moveListStringWithoutSiblings {
  if(move == nil) // root node, should never happen.
    return [[self childNodeAtIndex: 0] moveListString];
  else {
    NSMutableString *str;
    if(![position whiteToMove])
      str = [[NSMutableString stringWithFormat: @"%d. ",
			      [[parent position] moveNumber]] retain];
    else
      str = [[NSMutableString stringWithFormat: @"%d... ",
			      [[parent position] moveNumber]] retain];
    [str appendString: [move SANString]];
    if([move comment]) 
      [str appendString: [NSString stringWithFormat:@" {%@} ", [move comment]]];
    if([children count] > 0) {
      [str appendString: @" "];
      [str appendString: [[self firstChildNode] moveListString]];
    }
    [str autorelease];
    return str;
  }
}

-(void)moveListStringWithParensAppendedToString: (NSMutableString *)str {
  if(move == nil) // root node, should never happen
    return;
  else {
    [str appendString: @"("];
    [str appendString: [self moveListStringWithoutSiblings]];
    [str appendString: @") "];
  }
}
    
-(NSString *)moveListString {
  if(move == nil) // root node
    return [[self childNodeAtIndex: 0] moveListString];
  else {
    NSMutableString *str;
    if(![position whiteToMove])
      str = [[NSMutableString stringWithFormat: @"%d. ",
			      [[parent position] moveNumber]] retain];
    else
      str = [[NSMutableString stringWithString: @""] retain];
    [str appendString: [move SANString]];
    if([move comment]) 
      [str appendString: [NSString stringWithFormat:@" {%@} ", [move comment]]];
    if([children count] > 0 || [[parent remainingChildNodes] count] > 0)
      [str appendString: @" "];
    [[parent remainingChildNodes] 
      makeObjectsPerformSelector: 
	@selector(moveListStringWithParensAppendedToString:)
      withObject: str];
    if([children count] > 0) {
      [str appendString: [[self firstChildNode] moveListString]];
    }
    [str autorelease];
    return str;
  }
}

-(NSString *)moveListStringWithComments:(BOOL)includeComments
			     variations:(BOOL)includeVariations {
  if(move == nil) // root node
    return [[self childNodeAtIndex: 0] 
	     moveListStringWithComments: includeComments
	     variations: includeVariations];
  else {
    NSMutableString *str;
    if(![position whiteToMove])
      str = [[NSMutableString stringWithFormat: @"%d. ",
			      [[parent position] moveNumber]] retain];
    else if([[self parent] move] == nil)
      // Parent node was root move, and black moved first:  Add move number
      str = [[NSMutableString stringWithString: @"1... "] retain];
    else
      str = [[NSMutableString stringWithString: @""] retain];
    [str appendString: [move SANString]];

    if(includeComments && [move comment]) 
      [str appendString: [NSString stringWithFormat:@" {%@} ", [move comment]]];

    if([children count] > 0 || 
       ([[parent remainingChildNodes] count] > 0 && includeVariations))
      [str appendString: @" "];

    if(includeVariations) 
      [[parent remainingChildNodes] 
	makeObjectsPerformSelector: 
	  @selector(moveListStringWithParensAppendedToString:)
	withObject: str];

    if([children count] > 0)
      [str appendString: 
	     [[self firstChildNode] moveListStringWithComments: includeComments
				    variations: includeVariations]];
    [str autorelease];
    return str;
  }
}

-(NSAttributedString *)moveListAttributedStringWithoutSiblingsIncludeComments:(BOOL)includeComments
								  currentNode:(GameNode *)currentNode {
  if(move == nil) // root node, should never happen.
    return nil;
  else {
    NSMutableAttributedString *str, *movestr;
    if(![position whiteToMove])
      str = [[NSMutableAttributedString 
	       attributedStringWithFormat: @"%d. ",
	       [[parent position] moveNumber]] retain];
    else
      str = [[NSMutableAttributedString 
	       attributedStringWithFormat: @"%d... ",
	       [[parent position] moveNumber]] retain];

    movestr = [NSMutableAttributedString attributedStringWithString:
					   [move SANString]];
    if(self == currentNode) {
      [movestr addAttribute: NSBackgroundColorAttributeName
	       value: [NSColor lightGrayColor]
	       range: NSMakeRange(0, [movestr length])];
    }
    [str appendAttributedString: movestr];

    if([move comment]) {
      NSMutableAttributedString *commentString =
	[NSMutableAttributedString attributedStringWithFormat: @" {%@} ",
				   [move comment]];
      [commentString addAttribute: NSForegroundColorAttributeName
		     value: [NSColor blueColor]
		     range: NSMakeRange(0, [commentString length])];
      [str appendAttributedString: commentString];
    }
    if([children count] > 0) {
      [str appendString: @" "];
      [str appendAttributedString:
	     [[self firstChildNode]
	       moveListAttributedStringWithComments: includeComments
	       variations: YES
	       currentNode: currentNode]];
    }
    [str autorelease];
    return str;
  }
}

-(NSAttributedString *)moveListAttributedStringWithComments:(BOOL)includeComments
						 variations:(BOOL)includeVariations
						currentNode:(GameNode *)currentNode {
  if(move == nil) // root node
    return [[self childNodeAtIndex: 0]
	     moveListAttributedStringWithComments: includeComments
	     variations: includeVariations
	     currentNode: currentNode];
  else {
    NSMutableAttributedString *str, *movestr;
    
    if(![position whiteToMove])
      str = [[NSMutableAttributedString attributedStringWithFormat: @"%d. ",
					[[parent position] moveNumber]] retain];
    else if([[self parent] move] == nil)
      // Parent node was root move, and black moved first:  Add move number
      str = [[NSMutableAttributedString attributedStringWithString: @"1... "]
	      retain];
    else
      str = [[NSMutableAttributedString attributedStringWithString: @""] retain];
    movestr = [NSMutableAttributedString attributedStringWithString:
					   [move SANString]];
    if(self == currentNode) {
      [movestr addAttribute: NSBackgroundColorAttributeName
	       value: [NSColor lightGrayColor]
	       range: NSMakeRange(0, [movestr length])];
    }
    [str appendAttributedString: movestr];

    if(includeComments && [move comment]) {
      NSMutableAttributedString *commentString =
	[NSMutableAttributedString attributedStringWithFormat: @" {%@} ",
				   [move comment]];
      [commentString addAttribute: NSForegroundColorAttributeName
		     value: [NSColor blueColor]
		     range: NSMakeRange(0, [commentString length])];
      [str appendAttributedString: commentString];
    }

    if([children count] > 0 ||
       ([[parent remainingChildNodes] count] > 0 && includeVariations))
      [str appendString: @" "];

    if(includeVariations) {
      NSEnumerator *e = [[parent remainingChildNodes] objectEnumerator];
      GameNode *node;
      while((node = [e nextObject])) {
	[str appendString: @"("];
	[str appendAttributedString: 
	       [node moveListAttributedStringWithoutSiblingsIncludeComments:
		       includeComments
		     currentNode: currentNode]];
	[str appendString: @") "];
      }
    }
    if([children count] > 0)
      [str appendAttributedString:
	     [[self firstChildNode]
	       moveListAttributedStringWithComments: includeComments
	       variations: includeVariations
	       currentNode: currentNode]];

    [str autorelease];
    return str;
  }
}
    
-(void)dealloc {
  //  NSLog(@"Destroying <GameNode: %@>", self);
  // [children removeAllObjects];
  // NSLog(@"Releasing children: %@", children);
  [children release];
  if(move != nil) [move release];
  [position release];
  // [parent release];
  [super dealloc];
}

-(NSString *)description {
  return [NSString stringWithFormat: @"pos=%@, move=%@, %d children",
		   position, [move SANString], [children count]];
}

@end
