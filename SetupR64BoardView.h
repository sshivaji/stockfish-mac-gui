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

@class SetupR64WindowController;

@interface SetupR64BoardView : NSView {
  SetupR64WindowController *controller;
  float sideLength;
  int highlightSquares[64];
  int mouseUpSquare;
  int mouseDownSquare;
  NSPoint squareCentres[64];
}

-(void)setController:(SetupR64WindowController *)c;

@end
