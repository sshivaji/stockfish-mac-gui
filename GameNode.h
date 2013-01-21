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

@class ChessPosition;
@class ChessMove;

@interface GameNode : NSObject {
  ChessPosition *position;
  ChessMove *move;
  GameNode *parent;
  NSMutableArray *children;
}

-(id)initWithPosition:(ChessPosition *)pos move:(ChessMove *)mv
	       parent:(GameNode *)pnode;
-(id)initWithPosition:(ChessPosition *)pos;
-(id)init;
-(id)position;
-(id)move;
-(GameNode *)parent;
-(NSMutableArray *)children;
-(void)addChildNode:(ChessMove *)mv;
-(id)childNodeAtIndex:(int)index;
-(id)firstChildNode;
-(NSArray *)remainingChildNodes;
-(NSArray *)siblings;
-(BOOL)isFirstChild;
-(void)removeChildNodeAtIndex:(int)index;
-(void)removeAllChildNodes;
-(void)dealloc;
-(NSString *)description;
-(NSString *)moveListStringWithoutSiblings;
-(void)moveListStringWithParensAppendedToString: (NSMutableString *)str;
-(NSString *)moveListString;
-(NSString *)moveListStringWithComments:(BOOL)includeComments
			     variations:(BOOL)includeVariations;
-(NSAttributedString *)moveListAttributedStringWithComments:(BOOL)includeComments
						 variations:(BOOL)includeVariations
						currentNode:(GameNode *)currentNode;

@end
