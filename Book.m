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


#import "Book.h"
#import "ChessMove.h"
#import "ChessPosition.h"


// constants
#define BOOK_KEY_MASK 0xFFFFFFFFFFFF0000ULL
#define BOOK_MOVE_MASK 0xFFFFULL

// types
typedef struct {
  move_t move;
  unsigned score, factor;
} BookEntry;

// prototypes
static uint64_t read_uint64(FILE *f);
static int compare(const void *a, const void *b);
static void sort_book_moves(BookEntry *moves, int n);

// private methods:
@interface Book (PrivateAPI)
-(int)searchForKey:(uint64_t)key;
-(int)findBookMovesForKey:(uint64_t)key storeInArray:(BookEntry *)moves;
@end


@implementation Book

-(id)initWithFilename:(NSString *)filename {
  struct stat fs;
  unsigned i, j;

  self = [super init];
  file = fopen([filename UTF8String], "rb");
  if(file == NULL) 
    [[NSException exceptionWithName: @"BookNotFound"
		  reason: [NSString stringWithFormat:
				      @"Book file %@ not found", filename]
		  userInfo: nil]
      raise];

  stat([filename UTF8String], &fs);
  size = fs.st_size;

  firstKey = read_uint64(file) & BOOK_KEY_MASK;
  fseek(file, size - 16, SEEK_SET);
  lastKey = read_uint64(file) & BOOK_KEY_MASK;

  // Seed random move generator for book moves:
  i = abs(get_time()) % 10000;
  for(j = 0; j < i; j++) genrand_int32();

  return self;
}

-(void)close {
  if(file != NULL) fclose(file);
}

-(int)searchForKey:(uint64_t)key {
  int start, middle, end;
  uint64_t k;

  start = 0;
  end = size/16 - 1;

  while(start < end) {
    middle = (start + end) / 2;
    fseek(file, 16 * middle, SEEK_SET);
    k = read_uint64(file) & BOOK_KEY_MASK;
    if(key <= k) end = middle; else start = middle + 1;
  }

  fseek(file, 16 * start, SEEK_SET);
  k = read_uint64(file) & BOOK_KEY_MASK;

  return (k == key)? start : -1;
}

-(int)findBookMovesForKey:(uint64_t)key storeInArray:(BookEntry *)moves {
  int i, n = 0;
  uint64_t bookData, bookKey;

  key &= BOOK_KEY_MASK;
  i = [self searchForKey: key];
  if(i == -1) return 0;
  fseek(file, i * 16, SEEK_SET);

  do {
    bookData = read_uint64(file);
    bookKey = bookData & BOOK_KEY_MASK;

    if(bookKey == key) {
      moves[n].move = bookData & BOOK_MOVE_MASK;
      bookData = read_uint64(file);
      moves[n].score = (unsigned)(bookData & 0xFFFFFFFF);
      moves[n].factor = (unsigned)(bookData >> 32);
      //      print_move(moves[n].move);
      //      printf("score = %d, factor = %d\n", moves[n].score, moves[n].factor);
      n++; i++;
    }
  } while(bookKey == key && i < size);
  
  return n;
}

-(ChessMove *)pickMoveForPosition:(ChessPosition *)position
		      withVariety:(int)variety {
  BookEntry moves[64];
  unsigned n, i, r, s, sum;
  move_t move;

  n = [self findBookMovesForKey: [position hashkey] storeInArray: moves];
  if(n == 0) return nil;
  sort_book_moves(moves, n);

  sum = 0;
  for(i = 0; i < n; i++) sum += moves[i].factor * moves[i].score;
  r = genrand_int32() % sum;
  s = 0;
  for(i = 0; i < n; i++) {
    s += moves[i].factor * moves[i].score;
    if(s > r) break;
  }

  // Ugly hack to handle promotions correctly:
  if(MvPromotion(moves[i].move) == PAWN) moves[i].move |= (QUEEN << 14);

  move = generate_move([position pos], moves[i].move);
  if(move)
    return [[[ChessMove alloc] initWithPosition: position move: move]
	     autorelease];
  else
    return nil;
}

-(void)dealloc {
  if(file != NULL) fclose(file);
  [super dealloc];
}

static uint64_t read_uint64(FILE *f) {
  int i;
  unsigned char c;
  uint64_t result = 0;

  for(i = 7; i >= 0; i--) {
    c = fgetc(f);
    result += (uint64_t)(((uint64_t)c) << ((uint64_t)i*8ULL));
  }
  return result;
}

static int compare(const void *a, const void *b) {
  BookEntry *b1, *b2;
  b1 = (BookEntry *)a; b2 = (BookEntry *)b;
  if(b1->factor * b1->score < b2->factor * b2->score) return 1;
  else return -1;
}
  
static void sort_book_moves(BookEntry moves[], int n) {
  qsort(moves, n, sizeof(BookEntry), compare);
}


@end
