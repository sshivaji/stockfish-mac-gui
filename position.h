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


#if !defined(POSITION_H_INCLUDED)
#define POSITION_H_INCLUDED

////
//// Includes
////

#include <unistd.h>
#include <sys/time.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <assert.h>
#include <ctype.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdbool.h>


////
//// Constants and macros
////

#define STARTPOS "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

#define MAX_GAME_LENGTH 1024

enum {WHITE, BLACK};

enum {PAWN=1, KNIGHT=2, BISHOP=3, ROOK=4, QUEEN=5, KING=6};
enum {WP=1, WN=2, WB=3, WR=4, WQ=5, WK=6, 
      BP=9, BN=10, BB=11, BR=12, BQ=13, BK=14,
      EMPTY=16, OUTSIDE=32};

enum {RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8};
enum {FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H};

typedef enum result_t {
  WHITE_WINS, BLACK_WINS, WHITE_STALEMATES, BLACK_STALEMATES, DRAW, UNKNOWN
} result_t;

#define ColourOfPiece(piece) ((piece) >> 3)
#define PieceHasColour(piece, colour) (((piece) & 24) == ((colour) << 3))
#define PieceIsWhite(piece) (PieceHasColour(piece, WHITE))
#define PieceIsBlack(piece) (PieceHasColour(piece, BLACK))

#define TypeOfPiece(piece) ((piece) & 7)
#define PieceHasType(piece, type) (TypeOfPiece(piece) == type)
#define PieceIsPawn(piece) (PieceHasType(piece, PAWN))
#define PieceIsKnight(piece) (PieceHasType(piece, KNIGHT))
#define PieceIsBishop(piece) (PieceHasType(piece, BISHOP))
#define PieceIsRook(piece) (PieceHasType(piece, ROOK))
#define PieceIsQueen(piece) (PieceHasType(piece, QUEEN))
#define PieceIsKing(piece) (PieceHasType(piece, KING))

#define PieceOfColourAndType(colour, type) (((colour) << 3) | (type))
#define PieceHasColourAndType(piece, colour, type) \
  ((piece) == PieceOfColourAndType(colour, type))

#define PawnOfColour(colour) (PieceOfColourAndType(colour, PAWN))
#define KnightOfColour(colour) (PieceOfColourAndType(colour, KNIGHT))
#define BishopOfColour(colour) (PieceOfColourAndType(colour, BISHOP))
#define RookOfColour(colour) (PieceOfColourAndType(colour, ROOK))
#define QueenOfColour(colour) (PieceOfColourAndType(colour, QUEEN))
#define KingOfColour(colour) (PieceOfColourAndType(colour, KING))

#define PiecesHaveSameColour(piece1, piece2) (((piece1)&24) == ((piece2)&24))
#define PiecesHaveOppositeColour(piece1, piece2) \
  (((piece1)&24) == ((piece2)&16))

#define PieceIsSlider(piece) (SlidingArray[piece])

#define PawnCount(pos, side) ((pos)->piece_count[side][PAWN])
#define KnightCount(pos, side) ((pos)->piece_count[side][KNIGHT])
#define BishopCount(pos, side) ((pos)->piece_count[side][BISHOP])
#define RookCount(pos, side) ((pos)->piece_count[side][ROOK])
#define QueenCount(pos, side) ((pos)->piece_count[side][QUEEN])

#define HasPieceOfType(pos, side, type) ((pos)->piece_count[side][type] > 0)
#define HasPawns(pos, side) HasPieceOfType(pos, side, PAWN)
#define HasKnights(pos, side) HasPieceOfType(pos, side, KNIGHT)
#define HasBishops(pos, side) HasPieceOfType(pos, side, BISHOP)
#define HasRooks(pos, side) HasPieceOfType(pos, side, ROOK)
#define HasQueens(pos, side) HasPieceOfType(pos, side, QUEEN)
#define HasSliders(pos, side) \
  (HasBishops(pos,side)||HasRooks(pos,side)||HasQueens(pos,side))
#define HasHorizontalSliders(pos,side) \
  (HasRooks(pos,side)||HasQueens(pos,side))
#define HasDiagonalSliders(pos,side) \
  (HasBishops(pos,side)||HasQueens(pos,side))

#define KingSquare(pos,side) ((pos)->piece_list[KingOfColour(side)+128].n)
#define PieceList(pos,sq) ((pos)->piece_list[sq])
#define PieceListStart(pos,piece) ((pos)->piece_list[(piece)+128].n)
#define NextPiece(pos,square) ((pos)->piece_list[square].n)
#define PrevPiece(pos,square) ((pos)->piece_list[square].p)

#define RemovePiece(pos,square) do {                                \
    NextPiece(pos,PrevPiece(pos,square)) = NextPiece(pos,square); \
    PrevPiece(pos,NextPiece(pos,square)) = PrevPiece(pos,square); \
  } while(0)

#define InsertPiece(pos,piece,square) do {             \
    NextPiece(pos,square) = PieceListStart(pos,piece); \
    PrevPiece(pos,NextPiece(pos,square)) = square; \
    PrevPiece(pos,square) = piece+128;                 \
    PieceListStart(pos,piece) = square;                    \
  } while(0)

#define MovePiece(pos,from,to) do {                 \
    PieceList(pos,to) = PieceList(pos,from);            \
    PrevPiece(pos,NextPiece(pos,to)) = to;      \
    NextPiece(pos,PrevPiece(pos,to)) = to;      \
  } while(0)

#define PieceListEnd (BK + 128 + 1)

#define PawnListStart(pos,side) PieceListStart(pos,PawnOfColour(side))
#define KnightListStart(pos,side) PieceListStart(pos,KnightOfColour(side))
#define BishopListStart(pos,side) PieceListStart(pos,BishopOfColour(side))
#define RookListStart(pos,side) PieceListStart(pos,RookOfColour(side))
#define QueenListStart(pos,side) PieceListStart(pos,QueenOfColour(side))

#define Queenside 0
#define Kingside 1
#define WhiteOOMask 1
#define WhiteOOOMask 2
#define BlackOOMask 4
#define BlackOOOMask 8
/*
const int Queenside = 0, Kingside = 1;
const int WhiteOOMask = 1, WhiteOOOMask = 2, BlackOOMask = 4, BlackOOOMask = 8;
*/

#define CanCastleQueenside(pos,side) (((pos)->castle_flags&(1<<(1+((side)*2))))==0)
#define CanCastleKingside(pos,side) (((pos)->castle_flags&(1<<((side)*2)))==0)
#define CanCastle(pos, side) \
  (CanCastleQueenside(pos,side)||CanCastleKingside(pos, side))

#define ProhibitOO(pos, side) ((pos)->castle_flags |= (1 << ((side)*2)))
#define ProhibitOOO(pos, side) ((pos)->castle_flags |= (1 << ((side)*2 + 1)))

#define NullMove 0
#define NoMove 1

#define MvFrom(x) (((x)>>7)&127)
#define MvTo(x) ((x)&127)
#define MvPromotion(x) (((x)>>14)&7)
#define MvPiece(x) (((x)>>17)&7)
#define MvCapture(x) (((x)>>20)&7)
#define EPFlag (1<<23)
#define MvEP(x) ((x)&EPFlag)
#define CastleFlag (1<<24)
#define MvCastle(x) ((x)&CastleFlag)
#define MvShortCastle(m) (MvCastle(m) && SquareFile(MvTo(m))==FILE_G)
#define MvLongCastle(m) (MvCastle(m) && SquareFile(MvTo(m))==FILE_C)

#define WP_MASK 1
#define BP_MASK 2
#define N_MASK 4
#define K_MASK 8
#define B_MASK 16
#define R_MASK 32
#define Q_MASK 64

#define EXPAND(x) ((x)+((x)&~7))
#define COMPRESS(x) (((x)+((x)&7))>>1)

#define ZOBRIST(x,y) Zobrist[(x)-1][COMPRESS(y)]
#define ZOB_EP(y) ZobEP[COMPRESS(y)]
#define ZOB_CASTLE(y) ZobCastle[y]

#define Max(x,y) (((x)>(y))?(x):(y))
#define Min(x,y) (((x)<(y))?(x):(y))

#define SquareFile(x) ((x)&15)
#define SquareRank(x) ((x)>>4)

enum {
  A1=0x00, B1=0x01, C1=0x02, D1=0x03, E1=0x04, F1=0x05, G1=0x06, H1=0x07,
  A2=0x10, B2=0x11, C2=0x12, D2=0x13, E2=0x14, F2=0x15, G2=0x16, H2=0x17,
  A3=0x20, B3=0x21, C3=0x22, D3=0x23, E3=0x24, F3=0x25, G3=0x26, H3=0x27,
  A4=0x30, B4=0x31, C4=0x32, D4=0x33, E4=0x34, F4=0x35, G4=0x36, H4=0x37,
  A5=0x40, B5=0x41, C5=0x42, D5=0x43, E5=0x44, F5=0x45, G5=0x46, H5=0x47,
  A6=0x50, B6=0x51, C6=0x52, D6=0x53, E6=0x54, F6=0x55, G6=0x56, H6=0x57,
  A7=0x60, B7=0x61, C7=0x62, D7=0x63, E7=0x64, F7=0x65, G7=0x66, H7=0x67,
  A8=0x70, B8=0x71, C8=0x72, D8=0x73, E8=0x74, F8=0x75, G8=0x76, H8=0x77
};


////
//// Types
////

#include <stdint.h>

typedef int move_t;

typedef uint64_t hashkey_t;

typedef struct list_t {
  uint8_t p, n;
} list_t;

typedef struct position_t {
  uint8_t board_[256];
  uint8_t *board;
  list_t piece_list[256];
  move_t last_move;
  int ep_square;
  int castle_flags;
  int rule50;
  int gply;
  int side, xside;
  int piece_count[2][8];
  int material[2];
  int psq[2];
  int check, check_sqs[2];
  int initial_ksq, initial_krsq, initial_qrsq;
  hashkey_t key, previous_keys[MAX_GAME_LENGTH];
} position_t;

typedef struct move_stack_t {
  move_t move;
} move_stack_t;

typedef struct undo_info_t {
  hashkey_t key;
  int ep_square, rule50, castle_flags, check, check_sqs[2];
  move_t last_move;
} undo_info_t;

typedef struct attack_data_t {
  uint8_t may_attack;
  int8_t step;
} attack_data_t;

////
//// Global variables
////


extern hashkey_t Zobrist[BK][64], ZobColour, ZobEP[64], ZobCastle[16];


////
//// Functions
////

extern void init(void);
extern char *time_string(int msecs, char *str);
extern void position_from_fen(position_t *pos, const char *fen);
extern char *position_to_fen(const position_t *pos, char *fen);
extern move_t generate_move(const position_t *pos, move_t incomplete_move);
extern bool position_is_mate(position_t *pos);
extern bool position_is_rule50_draw(const position_t *pos);
extern bool position_is_material_draw(const position_t *pos);
extern bool position_is_repetition_draw(const position_t *pos);
extern bool position_is_stalemate(position_t *pos);
extern bool position_is_draw(position_t *pos);
extern char *move2str(move_t move, char *str);
extern char *san_string(position_t *pos, move_t move, char *str);
extern char *san_move_from_string(const position_t *pos, const char *istr, 
                                  char *ostr);
extern char *san_line_from_string(const position_t *pos, int start_column, 
                                  bool break_lines, bool move_numbers, 
                                  const char *istr, char *ostr);
extern void find_destination_squares_from(const position_t *pos, int from, 
                                          int squares[]);
extern move_t find_move_matching(const position_t *pos,
                                 int from, int to, int promotion);
extern move_t parse_move(position_t *pos, const char *movestr);
extern void make_move(position_t *pos, move_t m, undo_info_t *u);
extern void unmake_move(position_t *pos, move_t m, undo_info_t *u);
extern void print_position(const position_t *pos);
extern void fprint_position(FILE *f, const position_t *pos);
extern void copy_position(position_t *dst, const position_t *src);
extern move_t parse_san_move(const position_t *pos, const char *movestr);
extern int count_legal_moves(const position_t *pos);
extern move_t can_castle_kingside(position_t *pos);
extern move_t can_castle_queenside(position_t *pos);


#endif // !defined(POSITION_H_INCLUDED)
