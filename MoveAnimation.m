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


#import "MoveAnimation.h"


@implementation MoveAnimation

-(id)init {
  self = [super initWithDuration: 0.06 animationCurve: NSAnimationEaseIn];
  return self;
}

-(int)from {
  return from;
}

-(int)to {
  return to;
}

-(void)setCurrentProgress:(NSAnimationProgress)progress {
  NSRect r;
  [super setCurrentProgress: progress];
  //[[self delegate] setNeedsDisplay: YES];
  //[[self delegate] drawRect: r];
  [[self delegate] display];
}

-(void)startAnimationFrom:(int)fromSq to:(int)toSq {
  from = fromSq;
  to = toSq;
  [super startAnimation];
}


@end
