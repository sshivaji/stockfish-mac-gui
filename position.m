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


#include "position.h"

const int Directions[16][16] = {
  {0},
  {15, 17, 0},  // WP
  {33, 31, 18, 14, -14, -18, -31, -33, 0},  // WN 
  {17, 15, -15, -17, 0},  // WB 
  {16, 1, -1, -16, 0},  // WR 
  {17, 16, 15, 1, -1, -15, -16, -17, 0},  // WQ 
  {17, 16, 15, 1, -1, -15, -16, -17, 0},  // WK 
  {0},
  {0},
  {-15, -17, 0},  // BP 
  {-33, -31, -18, -14, 14, 18, 31, 33, 0},  // BN 
  {-17, -15, 15, 17, 0},  // BB 
  {-16, -1, 1, 16, 0},  // BR 
  {-17, -16, -15, -1, 1, 15, 16, 17, 0},  // BQ 
  {-17, -16, -15, -1, 1, 15, 16, 17, 0},  // BK
  {0}
};

const uint32_t FileMask[8] = {1, 2, 4, 8, 16, 32, 64, 128};
const int SlidingArray[16] = {0,0,0,1,2,3,0,0,0,0,0,1,2,3,0};
const int PawnPush[2] = {16, -16};

const int PieceMask[OUTSIDE+1] = {
  0,WP_MASK,N_MASK,B_MASK,R_MASK,Q_MASK,K_MASK,0,
  0,BP_MASK,N_MASK,B_MASK,R_MASK,Q_MASK,K_MASK,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

uint8_t PawnRank[2][128];
attack_data_t AttackData_[256];
attack_data_t *AttackData = AttackData_ + 128;
hashkey_t Zobrist[BK][64], ZobColour, ZobEP[64], ZobCastle[16];

extern uint32_t genrand_int32(void);
extern uint64_t genrand_int64(void);
extern void init_mersenne(void);

void init_zobrist(void) {
  int i, j;

  for(i=0; i<BK; i++)
    for(j=0; j<64; j++)
      Zobrist[i][j] = genrand_int64();
  ZobEP[0] = 0;
  for(i=1; i<64; i++) ZobEP[i] = genrand_int64();
  for(i=0; i<16; i++) ZobCastle[i] = genrand_int64();
  ZobColour = genrand_int64();
}

hashkey_t compute_hash_key(const position_t *pos) {
  hashkey_t result = 0ULL;
  int side, sq;
  for(side = WHITE; side <= BLACK; side++) 
    for(sq=KingSquare(pos, side); sq!=PieceListEnd; sq=NextPiece(pos, sq)) 
      if(sq <= H8) result ^= ZOBRIST(pos->board[sq], sq);
  result ^= ZOB_EP(pos->ep_square);
  result ^= ZOB_CASTLE(pos->castle_flags);
  if(pos->side == BLACK) result ^= ZobColour;
  return result;
}

static void init_tables(void) {
  int i;
  for(i = 0; i < 128; i++) 
    PawnRank[WHITE][i] = PawnRank[BLACK][i^0x70] = SquareRank(i);
}

static void init_attack_data(void) {
  int sq, piece, tosq;
  const int *ptr;

  for(sq = 0; sq < 256; sq++) 
    AttackData_[sq].may_attack = AttackData_[sq].step = 0;
  for(sq = A1; sq <= H8; sq++) 
    for(piece = WP; piece <= BK; piece++) 
      for(ptr = Directions[piece]; *ptr; ptr++) 
        for(tosq = sq+(*ptr); !(tosq & 0x88); tosq += (*ptr)) {
          AttackData[sq-tosq].step = *ptr;
          AttackData[sq-tosq].may_attack |= PieceMask[piece];
          if(!PieceIsSlider(piece)) break;
        }
}

void init(void) {
  init_tables();
  init_mersenne();
  init_zobrist();
  init_attack_data();
}

void init_position(position_t *pos) {
  int i;
  for(i=0; i<256; i++) pos->board_[i] = ((i-64)&0x88)? OUTSIDE : EMPTY;
  pos->board = pos->board_ + 64;
}

void init_piece_lists(position_t *pos) {
  int sq, piece;

  for(piece = KING; piece >= KNIGHT; piece--) {
    PieceListStart(pos, piece) = piece-1+128;
    PieceListStart(pos, piece+8) = piece+7+128;
    PrevPiece(pos, piece-1+128) = piece+128; 
    PrevPiece(pos, piece+7+128) = piece+8+128;
  }
  PieceListStart(pos, WP) = PieceListStart(pos, BP) = PieceListEnd;

  for(sq = A1; sq <= H8; sq++) 
    if(pos->board[sq] != OUTSIDE && pos->board[sq] != EMPTY) 
      InsertPiece(pos, pos->board[sq], sq);
}

void copy_position(position_t *dst, const position_t *src) {
  memcpy(dst, src, sizeof(position_t));
  dst->board = dst->board_ + 64;
}

bool is_attacked(const position_t *pos, int square, int side) {
  int sq, tosq, piece, step;
  attack_data_t *a = AttackData-square;

  for(sq = KingSquare(pos, side); sq != PieceListEnd; 
      sq = NextPiece(pos, sq)) {
    if(sq <= H8) {
      piece = pos->board[sq];
      if(PieceMask[piece] & a[sq].may_attack) {
	if(!PieceIsSlider(piece)) return true;
	step = a[sq].step;
	for(tosq=sq+step; pos->board[tosq]==EMPTY&&tosq!=square; tosq+=step);
	if(tosq == square) return true;
      }
    }
  }
  return false;
}

bool position_is_check(const position_t *pos) {
  int us, them;
  move_t move;

  us = pos->side; them = us^1;
  move = pos->last_move;

  if(move == NullMove) return false;
  else if(move == NoMove || MvCastle(move) || MvEP(move))
    return is_attacked(pos, KingSquare(pos, us), them);
  else {
    int ksq = KingSquare(pos, us);
    int from = MvFrom(move), to = MvPiece(move);
    int piece = pos->board[to];
    attack_data_t *a = AttackData - ksq;
    if(a[to].may_attack & PieceMask[piece]) {
      if(!PieceIsSlider(piece)) return true;
      int step = a[to].step, sq;
      for(sq = to + step; pos->board[sq] == EMPTY; sq += step);
      if(sq == ksq) return true;
    }
    if(a[from].may_attack & Q_MASK) {
      int step = a[from].step, sq;
      for(sq = from + step; pos->board[sq] == EMPTY; sq += step);
      if(sq == ksq) {
	for(sq = from - step; pos->board[sq] == EMPTY; sq -= step);
	if(ColourOfPiece(pos->board[sq]) == them &&
	   (a[sq].may_attack & PieceMask[pos->board[sq]]))
	  return true;
      }
    }
  }
  return false;
}

int find_checkers(const position_t *pos, int chsqs[]) {
  int us = pos->side, them = us^1;
  int ksq = KingSquare(pos, us), from, to, step, piece, result = 0;
  move_t move = pos->last_move;
  attack_data_t *a = AttackData - ksq;

  if(move == NullMove) return 0;
  chsqs[0] = chsqs[1] = 0;
  if(move == NoMove || MvCastle(move) || MvEP(move) || MvPromotion(move)) {
    for(from = KingSquare(pos, pos->side^1); from != PieceListEnd && result<2; 
	from = NextPiece(pos, from)) {
      if(from > H8) continue;
      piece = pos->board[from];
      if(PieceMask[piece] & a[from].may_attack) {
	if(PieceIsSlider(piece)) {
	  step = a[from].step;
	  for(to = from + step; pos->board[to] == EMPTY; to += step);
	  if(to == ksq) chsqs[result++] = from;
	}
	else chsqs[result++] = from;
      }
    }
  }
  else {
    from = MvFrom(move); to = MvTo(move);
    piece = pos->board[to];
    if(PieceMask[piece] & a[to].may_attack) {
      if(PieceIsSlider(piece)) {
	int sq;
	step = a[to].step;
	for(sq = to + step; pos->board[sq]==EMPTY; sq += step);
	if(sq == ksq) chsqs[result++] = to;
      }
      else chsqs[result++] = to;
    }
    if(a[from].may_attack & Q_MASK) { // Discovered check possible.
      int sq;
      step = a[from].step;
      for(sq = from + step; pos->board[sq] == EMPTY; sq += step);
      if(sq == ksq) {
	for(sq = from - step; pos->board[sq] == EMPTY; sq -= step);
	if(ColourOfPiece(pos->board[sq]) == them && 
	   (a[sq].may_attack & PieceMask[pos->board[sq]]))
	  chsqs[result++] = sq;
      }
    }
  }
  return result;
}

int is_pinned(const position_t *pos, int square) {
  int side, ksq, p1, p2, step, sq;
  attack_data_t *a;

  side = ColourOfPiece(pos->board[square]);
  ksq = KingSquare(pos, side);

  a = AttackData - ksq + square;
  if(!(a->may_attack & Q_MASK)) return 0;

  if(a->may_attack & R_MASK) p1 = RookOfColour(side^1);
  else p1 = BishopOfColour(side^1);
  p2 = QueenOfColour(side^1);

  step = a->step;
  for(sq = square + step; pos->board[sq] == EMPTY; sq += step);
  if(sq == ksq) {
    for(sq = square - step; pos->board[sq] == EMPTY; sq -= step);
    if(pos->board[sq] == p1 || pos->board[sq] == p2) return step;
  }
  return 0;
}

int count_pieces(const position_t *pos, int colour, int type) {
  int piece, square, count = 0;
  piece = PieceOfColourAndType(colour, type);
  for(square = PieceListStart(pos, piece); square <= H8; 
      square = NextPiece(pos, square))
    count++;
  return count;
}

void init_piece_counts(position_t *pos) {
  int colour, type;
  for(colour = WHITE; colour <= BLACK; colour++)
    for(type = PAWN; type <= QUEEN; type++)
      pos->piece_count[colour][type] = count_pieces(pos, colour, type);
}

char *square2str(int sq, char *str) {
  sprintf(str, "%c%d", (char)SquareFile(sq)+'a', SquareRank(sq) + 1);
  return str;
}

void print_square(int sq) {
  printf("%c%d", (char)SquareFile(sq)+'a', SquareRank(sq) + 1);
}

char *move2str(move_t move, char *str) {
  char letters[BK+2] = " pnbrqk  pnbrqk";
  if(move == NullMove) sprintf(str, "0000");
  else if(move == NoMove) sprintf(str, "(none)");
  else if(MvPromotion(move)) 
    sprintf(str, "%c%d%c%d%c", 
	    (char)SquareFile(MvFrom(move))+'a', SquareRank(MvFrom(move)) + 1,
	    (char)SquareFile(MvTo(move))+'a', SquareRank(MvTo(move)) + 1,
	    letters[MvPromotion(move)]);
  else 
    sprintf(str, "%c%d%c%d", 
	    (char)SquareFile(MvFrom(move))+'a', SquareRank(MvFrom(move)) + 1,
	    (char)SquareFile(MvTo(move))+'a', SquareRank(MvTo(move)) + 1);

  return str;
}

void print_move(move_t move) {
  char str[8];
  move2str(move, str);
  printf("%s ", str);
}

char *time_string(int msecs, char *str) {
  int hours, minutes, seconds, milliseconds, centiseconds;

  hours = msecs / (1000 * 60 * 60);
  minutes = (msecs - hours * 1000 * 60 * 60) / (60 * 1000);
  seconds = (msecs - hours * 1000 * 60 * 60 - minutes * 60 * 1000) / 1000;
  milliseconds = (msecs - hours*1000*60*60 - minutes*1000*60 - seconds*1000);
  centiseconds = milliseconds / 10;
  if(hours) {
    if(minutes >= 10) {
      if(seconds >= 10) 
	sprintf(str, "%d:%d:%d", hours, minutes, seconds); 
      else
	sprintf(str, "%d:%d:0%d", hours, minutes, seconds); 
    }
    else {
      if(seconds >= 10) 
	sprintf(str, "%d:0%d:%d", hours, minutes, seconds); 
      else
	sprintf(str, "%d:0%d:0%d", hours, minutes, seconds); 
    }
  }
  else if(minutes || true) {
    if(seconds >= 10) 
      sprintf(str, "%d:%d", minutes, seconds);
    else
      sprintf(str, "%d:0%d", minutes, seconds); 
  }
  else {
    if(centiseconds >= 10)
      sprintf(str, "%d.%d", seconds, centiseconds);
    else
      sprintf(str, "%d.0%d", seconds, centiseconds); 
  }
  return str; 
}

int parse_square(const char str[]) {
  if(str[0] >= 'a' && str[0] <= 'h' && str[1] >= '1' && str[1] <= '8')
    return str[0]-'a'+(str[1]-'1')*16;
  else return -1;
}

void position_from_fen(position_t *pos, const char *fen) {
  int sq;
  init_position(pos);
  for(sq = A8; sq >= A1; fen++) {
    if(*fen == '\0') {printf("Error!\n"); return; }
    if(isdigit(*fen)) {sq += (*fen) - '1' + 1; continue;}
    switch(*fen) {
    case 'K': pos->board[sq] = WK; break;
    case 'k': pos->board[sq] = BK; break;
    case 'Q': pos->board[sq] = WQ; break;
    case 'q': pos->board[sq] = BQ; break;
    case 'R': pos->board[sq] = WR; break;
    case 'r': pos->board[sq] = BR; break;
    case 'B': pos->board[sq] = WB; break;
    case 'b': pos->board[sq] = BB; break;
    case 'N': pos->board[sq] = WN; break;
    case 'n': pos->board[sq] = BN; break;
    case 'P': pos->board[sq] = WP; break;
    case 'p': pos->board[sq] = BP; break;
    case '/': sq -= SquareFile(sq) + 16; break;
    case ' ': sq = A1 - 1; break;
    default: printf("Error!\n"); return; 
    }
    if(strchr(" /", *fen) == NULL) sq++;
  }
  switch(tolower(*fen)) {
  case 'w': pos->side = WHITE; pos->xside = BLACK; break;
  case 'b': pos->side = BLACK; pos->xside = WHITE; break;
  default: printf("Error!\n"); return; 
  }
  do {fen++;} while(isspace(*fen));

  init_piece_lists(pos);

  pos->castle_flags = WhiteOOMask | WhiteOOOMask | BlackOOMask | BlackOOOMask;
  while(*fen != '\0' && !isspace(*fen)) {
    if(*fen == 'K') {
      pos->castle_flags ^= WhiteOOMask; 
      pos->initial_ksq = E1; pos->initial_krsq = H1;
    }
    else if(*fen == 'Q') {
      pos->castle_flags ^= WhiteOOOMask; 
      pos->initial_ksq = E1; pos->initial_qrsq = A1;
    }
    else if(*fen == 'k') {
      pos->castle_flags ^= BlackOOMask; 
      pos->initial_ksq = E1; pos->initial_krsq = H1;
    }
    else if(*fen == 'q') {
      pos->castle_flags ^= BlackOOOMask;
      pos->initial_ksq = E1; pos->initial_qrsq = A1;
    }
    else if(*fen >= 'A' && *fen <= 'H') {
      pos->initial_ksq = KingSquare(pos, WHITE);
      sq = (int) (*fen) - (int) 'A';
      if(sq > KingSquare(pos, WHITE)) {
        pos->castle_flags ^= WhiteOOMask; pos->initial_krsq = sq;
      }
      else {
        pos->castle_flags ^= WhiteOOOMask; pos->initial_qrsq = sq;
      }
    }
    else if(*fen >= 'a' && *fen <= 'h') {
      pos->initial_ksq = KingSquare(pos, WHITE);
      sq = (int) (*fen) - (int) 'a';
      if(sq > SquareFile(KingSquare(pos, BLACK))) {
        pos->castle_flags ^= BlackOOMask; pos->initial_krsq = sq;
      }
      else {
        pos->castle_flags ^= BlackOOOMask; pos->initial_qrsq = sq;
      }
    }
    fen++;
  }
  while(isspace(*fen)) fen++;
  
  if(*fen=='\0') {
    pos->rule50 = 0; pos->ep_square = 0;
  }
  else {
    if(*fen=='-') pos->ep_square = 0;
    else {
      pos->ep_square = parse_square(fen);
      if(pos->ep_square < 0) pos->ep_square = 0;
      do{fen++;} while(!isspace(*fen));
    }
    do{fen++;} while(isspace(*fen));
    if(isdigit(*fen)) sscanf(fen, "%d", &pos->rule50);
    else pos->rule50 = 0;
  }

  pos->last_move = NoMove;
  pos->check = find_checkers(pos, pos->check_sqs);
  init_piece_counts(pos);
  pos->key = compute_hash_key(pos);
  pos->gply = 0;
}

char *position_to_fen(const position_t *pos, char *fen) {
  int rank, file, square, skip, index = 0;
  char piece_letters[BK+2] = " PNBRQK  pnbrqk";
  char str[256];

  for(rank = RANK_8; rank >= RANK_1; rank--) {
    skip = 0;
    for(file = FILE_A; file <= FILE_H; file++) {
      square = file + rank*16;
      if(pos->board[square] != EMPTY) {
	if(skip > 0) str[index++] = (char)skip + '0';
	str[index++] = piece_letters[pos->board[square]];
	skip = 0;
      }
      else skip++;
    }
    if(skip > 0) str[index++] = (char)skip + '0';
    str[index++] = (rank > RANK_1)? '/' : ' ';
  }
  str[index++] = (pos->side == WHITE)? 'w' : 'b';
  str[index++] = ' ';
  if(!CanCastleQueenside(pos, WHITE) && !CanCastleKingside(pos, WHITE) &&
     !CanCastleQueenside(pos, BLACK) && !CanCastleKingside(pos, BLACK))
    str[index++] = '-';
  else {
    if(CanCastleKingside(pos, WHITE)) 
      str[index++] = 'K';
    if(CanCastleQueenside(pos, WHITE)) 
      str[index++] = 'Q';
    if(CanCastleQueenside(pos, BLACK)) 
      str[index++] = 'k';
    if(CanCastleQueenside(pos, BLACK)) 
      str[index++] = 'q';
  }
  str[index++] = ' ';
  if(pos->ep_square) {
    str[index++] = (char)(SquareFile(pos->ep_square)) + 'a';
    str[index++] = (char)(SquareRank(pos->ep_square)) + '1';
  }
  else str[index++] = '-';
  str[index++] = 0;

  sprintf(fen, "%s %d %d", str, pos->rule50, (pos->gply / 2 + 1));
  return fen;
}

int get_time(void) {
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec*1000 + t.tv_usec/1000; 
}

void fprint_position(FILE *f, const position_t *pos) {
  int file, rank, square, piece;
  char piece_strings[BK+1][8] = 
    {"|   ", "| P ", "| N ", "| B ", "| R ", "| Q ", "| K ", "| ? ", 
     "| ? ", "|=P=", "|=N=", "|=B=", "|=R=", "|=Q=", "|=K="
    };
  char fen[256];

  for(rank = RANK_8; rank >= RANK_1; rank--) {
    fprintf(f, "+---+---+---+---+---+---+---+---+\n");
    for(file = FILE_A; file <= FILE_H; file++) {
      square = file + rank*16;
      piece = pos->board[square];
      if(piece == EMPTY) fprintf(f, (rank + file) % 2? "|   " : "| . ");
      else fprintf(f, piece_strings[piece]); 
    }
    fprintf(f, "|\n"); 
  }
  fprintf(f, "+---+---+---+---+---+---+---+---+\n"); 

  fprintf(f, "%s\n", position_to_fen(pos, fen));
  fprintf(f, "0x%llxULL\n", pos->key);
}

void print_position(const position_t *pos) {
  fprint_position(stdout, pos);
}

bool irreversible(move_t m) {
  return MvCapture(m) || MvPiece(m)==PAWN;
}

void make_move(position_t *pos, move_t m, undo_info_t *u) {
  int from, to, piece, capture, promotion, prom_or_piece, ep;
  int side = pos->side, xside = side^1;

  u->ep_square = pos->ep_square;
  u->castle_flags = pos->castle_flags;
  u->rule50 = pos->rule50;
  u->key = pos->previous_keys[pos->gply] = pos->key;
  u->last_move = pos->last_move;
  u->check = pos->check;
  u->check_sqs[0] = pos->check_sqs[0];
  u->check_sqs[1] = pos->check_sqs[1];

  if(irreversible(m)) pos->rule50 = 0; else pos->rule50++;

  from=MvFrom(m); to=MvTo(m); capture=MvCapture(m); promotion=MvPromotion(m);
  ep = (m & EPFlag);
  piece = pos->board[from];

  if(capture) capture |= (xside<<3); 
  if(promotion) promotion |= (side<<3);
  prom_or_piece = promotion? promotion : piece;

  pos->key ^= ZOBRIST(piece, from); 
  pos->key ^= ZOBRIST(prom_or_piece, to);
  pos->key ^= ZobColour; pos->key ^= ZOB_EP(pos->ep_square);

  if(capture) {
    int capsq = ep? to-PawnPush[side] : to;
    RemovePiece(pos, capsq);
    pos->board[capsq] = EMPTY;
    pos->key ^= ZOBRIST(capture, capsq);
    pos->piece_count[xside][TypeOfPiece(capture)]--;
  }
  if(promotion) {
    RemovePiece(pos, from); InsertPiece(pos, promotion, to);
    pos->piece_count[side][PAWN]--;
    pos->piece_count[side][TypeOfPiece(promotion)]++;
  }
  else MovePiece(pos, from, to);

  pos->board[to] = prom_or_piece; pos->board[from] = EMPTY;

  if(PieceIsPawn(piece) && to-from == 2*PawnPush[side] &&
     (pos->board[to+1] == PawnOfColour(xside) || 
      pos->board[to-1] == PawnOfColour(xside))) {
    pos->ep_square = (to+from)/2;
    pos->key ^= ZOB_EP(pos->ep_square);
  }
  else pos->ep_square = 0;

  if(MvShortCastle(m)) {
    int initialKRSQ = pos->initial_krsq+side*A8;
    int rook = RookOfColour(side);
    int g1 = G1 + side*A8, f1 = F1 + side*A8;

    pos->board[initialKRSQ] = EMPTY; pos->board[f1] = rook;
    pos->board[g1] = KingOfColour(side);
    pos->key ^= ZOBRIST(rook, initialKRSQ); pos->key ^= ZOBRIST(rook, f1);
    init_piece_lists(pos); 
  }
  else if(MvLongCastle(m)) {
    int initialQRSQ = pos->initial_qrsq+side*A8;
    int rook = RookOfColour(side);
    int c1 = C1 + side*A8, d1 = D1 + side*A8;

    pos->board[initialQRSQ] = EMPTY; pos->board[d1] = rook; 
    pos->board[c1] = KingOfColour(side);
    pos->key ^= ZOBRIST(rook, initialQRSQ); pos->key ^= ZOBRIST(rook, d1);
    init_piece_lists(pos); 
  }
  pos->key^=ZOB_CASTLE(pos->castle_flags);
  if(from==pos->initial_ksq || from==pos->initial_krsq || to==pos->initial_krsq)
    ProhibitOO(pos, WHITE);
  if(from==pos->initial_ksq || from==pos->initial_qrsq || to==pos->initial_qrsq)
    ProhibitOOO(pos, WHITE);
  if(from==pos->initial_ksq+A8 || from==pos->initial_krsq+A8 || 
     to==pos->initial_krsq+A8)
    ProhibitOO(pos, BLACK);
  if(from==pos->initial_ksq+A8 || from==pos->initial_qrsq+A8 || 
     to==pos->initial_qrsq+A8)
    ProhibitOOO(pos, BLACK);
  pos->key^=ZOB_CASTLE(pos->castle_flags);

  pos->last_move = m;
  pos->gply++; pos->side ^= 1; pos->xside ^= 1;
  pos->check = find_checkers(pos, pos->check_sqs);
}

void unmake_move(position_t *pos, move_t m, undo_info_t *u) {
  int from, to, piece, capture, promotion, prom_or_piece, ep;
  int side, xside;

  pos->gply--; pos->xside ^= 1; pos->side ^= 1;
  side = pos->side; xside = side^1;
  pos->ep_square = u->ep_square;
  pos->castle_flags = u->castle_flags;
  pos->rule50 = u->rule50;
  pos->key = u->key;
  pos->last_move = u->last_move;
  pos->check = u->check;
  pos->check_sqs[0] = u->check_sqs[0];
  pos->check_sqs[1] = u->check_sqs[1];

  from = MvFrom(m); to = MvTo(m); 
  capture = MvCapture(m); promotion = MvPromotion(m);
  piece = MvPiece(m); ep = (m&EPFlag);

  piece |= (side<<3);
  if(capture) capture |= (xside<<3); 
  if(promotion) promotion |= (side<<3);
  prom_or_piece = promotion? promotion : piece;

  if(promotion) {
    RemovePiece(pos, to); InsertPiece(pos, piece, from);
    pos->piece_count[side][PAWN]++;
    pos->piece_count[side][TypeOfPiece(promotion)]--;
  }
  else MovePiece(pos, to, from);
  pos->board[from] = piece; pos->board[to] = EMPTY;

  if(capture) {
    int capsq = ep? to-PawnPush[side] : to;
    pos->board[capsq] = capture;
    InsertPiece(pos, capture, capsq);
    pos->piece_count[xside][TypeOfPiece(capture)]++;
  }

  if(MvShortCastle(m)) {
    int initialKRSQ = pos->initial_krsq+side*A8;
    int initialKSQ = pos->initial_ksq+side*A8;
    int rook = RookOfColour(side), king = KingOfColour(side);
    int g1 = G1 + side*A8, f1 = F1 + side*A8;

    pos->board[f1] = pos->board[g1] = EMPTY;
    pos->board[initialKRSQ] = rook; pos->board[initialKSQ] = king;
    init_piece_lists(pos);
  }
  if(MvLongCastle(m)) {
    int initialQRSQ = pos->initial_qrsq+side*A8;
    int initialKSQ = pos->initial_ksq+side*A8;
    int rook = RookOfColour(side), king = KingOfColour(side);
    int c1 = C1 + side*A8, d1 = D1 + side*A8;

    pos->board[d1] = pos->board[c1] = EMPTY;
    pos->board[initialQRSQ] = rook; pos->board[initialKSQ] = king;
    init_piece_lists(pos);
  }
}

void make_nullmove(position_t *pos, undo_info_t *u) {
  u->ep_square = pos->ep_square;
  u->castle_flags = pos->castle_flags;
  u->rule50 = pos->rule50;
  u->key = pos->previous_keys[pos->gply] = pos->key;
  u->last_move = pos->last_move;
  pos->key ^= ZobColour; pos->key ^= ZOB_EP(pos->ep_square);
  pos->rule50++; 
  pos->ep_square = 0;
  pos->last_move = NullMove;
  pos->gply++; pos->side ^= 1; pos->xside ^= 1;
}

void unmake_nullmove(position_t *pos, undo_info_t *u) {
  pos->gply--; pos->xside ^= 1; pos->side ^= 1;
  pos->ep_square = u->ep_square;
  pos->castle_flags = u->castle_flags;
  pos->rule50 = u->rule50;
  pos->key = u->key;
  pos->last_move = u->last_move;
}

bool ep_is_legal(position_t *pos, move_t m) {
  bool legal;
  undo_info_t u[1];
  make_move(pos, m, u);
  legal = !is_attacked(pos, KingSquare(pos, (pos->side)^1), pos->side);
  unmake_move(pos, m, u);
  return legal;
}

bool move_is_legal(position_t *pos, move_t m) {
  int side = pos->side, xside = side^1;
  int ksq = KingSquare(pos, side);
  int from = MvFrom(m);
  attack_data_t *a = AttackData-ksq;

  if(pos->check) return true;
  if(MvPiece(m) == KING) return !is_attacked(pos, MvTo(m), xside);
    
  if(a[from].may_attack & Q_MASK) {
    int step = a[from].step, sq;
    if(step == a[MvTo(m)].step) return true;
    if(MvEP(m)) return ep_is_legal(pos, m);
    for(sq = from + step; pos->board[sq] == EMPTY; sq += step);
    if(sq == ksq) {
      for(sq = from-step; pos->board[sq]==EMPTY; sq -= step);
      if(ColourOfPiece(pos->board[sq]) == xside && 
         PieceIsSlider(pos->board[sq]) &&
         (a[sq].may_attack & PieceMask[pos->board[sq]]))
        return false;
    }
  }
  return true;
}

move_stack_t *generate_check_evasions(position_t *pos, move_stack_t *ms) {
  int ksq, from, to, piece, type, tmp, step, rank, prom, pin, checks;
  int side = pos->side, xside = side^1;
  const int *ptr;

  checks = pos->check;
  ksq = KingSquare(pos, side);
  
  // King moves:
  tmp = (ksq<<7)|(KING<<17);
  pos->board[ksq] = EMPTY;
  for(ptr = Directions[KING]; *ptr; ptr++) {
    to = ksq + (*ptr);
    if((pos->board[to]==EMPTY || ColourOfPiece(pos->board[to]) == xside) && 
       (!is_attacked(pos, to, xside)))
      (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
  }
  pos->board[ksq] = KingOfColour(side);

  // Moves by other pieces are only possible if it is not a double check:
  if(checks == 1) {
    attack_data_t *a = AttackData-ksq;
    int chsq = pos->check_sqs[0];
    
    if(PieceIsSlider(pos->board[chsq])) {
      int blockstep = a[chsq].step;
      for(from = NextPiece(pos, ksq); from != PieceListEnd; 
	  from = NextPiece(pos, from)) {
        if(from > H8) continue;
        pin = is_pinned(pos, from);
        piece = pos->board[from]; type = TypeOfPiece(piece);
        tmp = (from<<7)|(type<<17);
        if(type == PAWN) {
          step = PawnPush[side];
          rank = PawnRank[side][from];
          if(rank < RANK_7) {
            if(!pin || abs(pin)==abs(step)) {
              to = from+step;
              if(pos->board[to]==EMPTY) {
                if(a[to].step==blockstep && (to-ksq)*(to-chsq) < 0)
                  (ms++)->move = tmp|to;
                to += step;
                if(rank==RANK_2 && pos->board[to]==EMPTY && 
		   a[to].step==blockstep
                   && (to-ksq)*(to-chsq) < 0)
                  (ms++)->move = tmp|to;
              }
            }
            for(ptr = Directions[piece]; *ptr; ptr++) {
              if(!pin || abs(pin)==abs(*ptr)) {
                to = from + (*ptr);
                if(ColourOfPiece(pos->board[to]) == xside 
                   && (to==chsq || (a[to].step==blockstep && 
                                    (to-ksq)*(to-chsq) < 0)))
                  (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
              }
            }
          }
          else {
            to = from+step;
            if(!pin || abs(pin)==abs(step)) 
              if(pos->board[to]==EMPTY) 
                if(a[to].step==blockstep && (to-ksq)*(to-chsq) < 0)
                  for(prom = QUEEN; prom >= KNIGHT; prom--) 
                    (ms++)->move=tmp|to|(prom<<14);
            for(ptr = Directions[piece]; *ptr; ptr++) {
              if(!pin || abs(pin)==abs(*ptr)) {
                to = from + (*ptr);
                if(ColourOfPiece(pos->board[to]) == xside 
                   && (to==chsq || (a[to].step==blockstep && 
                                    (to-ksq)*(to-chsq) < 0))) {
                  if(PawnRank[side][to]==RANK_8) {
                    for(prom = QUEEN; prom >= KNIGHT; prom--) 
                      (ms++)->move=tmp|to|(TypeOfPiece(pos->board[to])<<20)|(prom<<14);
                  }
                  else
                    (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
                }
              }
            }
          }
        } 
        else { // Not a pawn
          for(ptr = Directions[piece]; *ptr; ptr++) {
            if(pin && abs(pin) != abs(*ptr)) continue;
            if(PieceIsSlider(piece)) {
              to = from;
              do {
                to += (*ptr);
                if((pos->board[to]==EMPTY || 
		    ColourOfPiece(pos->board[to]) == xside)
                   && (to==chsq ||
                       (a[to].step==blockstep && (to-ksq)*(to-chsq) < 0)))
                  (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
              } while(pos->board[to] == EMPTY);
            }
            else {
              to = from + (*ptr);
              if((pos->board[to]==EMPTY||ColourOfPiece(pos->board[to])==xside)
                 && (to==chsq ||
                     (a[to].step==blockstep && (to-ksq)*(to-chsq) < 0)))
                (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
            }
          }
        }
      }
    }
    else { // Checking piece is not a slider.  Blocking moves impossible.
      for(from = NextPiece(pos, ksq); from != PieceListEnd; 
	  from = NextPiece(pos, from)) {
        if(from > H8) continue;
        pin = is_pinned(pos, from);
        piece = pos->board[from]; type = TypeOfPiece(piece);
        tmp = (from<<7)|(type<<17);
        if(type == PAWN) {
          for(ptr = Directions[piece]; *ptr; ptr++) {
            if(!pin || abs(pin)==abs(*ptr)) {
              to = from + (*ptr);
              if(to==chsq) {
                if(PawnRank[side][to]==RANK_8) {
                  for(prom = QUEEN; prom >= KNIGHT; prom--) 
                    (ms++)->move=tmp|to|(TypeOfPiece(pos->board[to])<<20)|(prom<<14);
                }
                else (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
              }
            }
          }
        }
        else {
          for(ptr = Directions[piece]; *ptr; ptr++) {
            if(pin && abs(pin) != abs(*ptr)) continue;
            if(PieceIsSlider(piece)) {
              to = from;
              do {
                to += (*ptr);
                if(to==chsq)
                  (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
              } while(pos->board[to]==EMPTY);
            }
            else {
              to = from + (*ptr);
              if(to==chsq)
                (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
            }
          }
        }
      }
    }

    // Finally, we have the ugly special case of en passant captures:
    if(pos->ep_square) 
      for(ptr = Directions[PawnOfColour(xside)]; *ptr; ptr++) {
        from = pos->ep_square + (*ptr);
        if(pos->board[from] == PawnOfColour(side)) {
          int legal;
	  undo_info_t u[1];
          ms->move = (pos->ep_square)|(from<<7)|(PAWN<<17)|(PAWN<<20)|EPFlag;
          make_move(pos, ms->move, u);
	  legal = !is_attacked(pos, KingSquare(pos, (pos->side)^1), pos->side);
          unmake_move(pos, ms->move, u);
          if(legal) ms++;
        }
      }
  }

  return ms;
}

move_stack_t *generate_moves(position_t *pos, move_stack_t *ms) {
  int from, to, piece, type, tmp, step, rank, prom;
  int side = pos->side, xside = side^1;
  const int *ptr;

  if(pos->check) {
    ms = generate_check_evasions(pos, ms);
    return ms;
  }

  for(from = KingSquare(pos, side); from != PieceListEnd; 
      from = NextPiece(pos, from)) {
    if(from > H8) continue;
    piece = pos->board[from]; type = TypeOfPiece(piece);
    tmp = (from<<7)|(type<<17);
    if(type == PAWN) {
      step = PawnPush[side];
      rank = PawnRank[side][from];
      if(rank < RANK_7) {
        if(pos->board[from+step] == EMPTY) {
          (ms++)->move = tmp|(from+step);
          if(rank == RANK_2 && pos->board[from+2*step] == EMPTY) 
            (ms++)->move = tmp|(from+2*step);
        }
        for(ptr = Directions[piece]; *ptr; ptr++) {
          to = from + (*ptr);
          if(ColourOfPiece(pos->board[to]) == xside)
            (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
        }
      } 
      else {
        if(pos->board[from+step] == EMPTY) 
          for(prom = QUEEN; prom >= KNIGHT; prom--)
            (ms++)->move = tmp|(from+step)|(prom<<14);
        for(ptr = Directions[piece]; *ptr; ptr++) {
          to = from + (*ptr);
          if(ColourOfPiece(pos->board[to]) == xside) {
            if(PawnRank[side][to] == RANK_8) {
              for(prom = QUEEN; prom >= KNIGHT; prom--)
                (ms++)->move = 
		  tmp|to|(TypeOfPiece(pos->board[to])<<20)|(prom<<14);
            }
            else (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
          }
        }
      }
    }
    else {
      for(ptr = Directions[piece]; *ptr; ptr++) {
        if(PieceIsSlider(piece)) {
          to = from;
          do {
            to += (*ptr);
            if(pos->board[to]==EMPTY || ColourOfPiece(pos->board[to])==xside)
              (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
          } while(pos->board[to]==EMPTY);
        }
        else {
          to = from + (*ptr);
          if(pos->board[to]==EMPTY || ColourOfPiece(pos->board[to])==xside) 
            (ms++)->move = tmp|to|(TypeOfPiece(pos->board[to])<<20);
        }
      }
    }
  }

  // Finally, we have the ugly special cases of en passant captures and
  // castling moves:
  if(pos->ep_square) 
    for(ptr = Directions[PawnOfColour(xside)]; *ptr; ptr++) {
      from = pos->ep_square + (*ptr);
      if(pos->board[from] == PawnOfColour(side))
        (ms++)->move = 
	  (pos->ep_square)|(from<<7)|(PAWN<<17)|(PAWN<<20)|EPFlag;
    }

  if(!pos->check) {
    if(CanCastleKingside(pos, side)) {
      int initialKSQ = pos->initial_ksq+side*A8;
      int initialKRSQ = pos->initial_krsq+side*A8;
      int g1 = G1 + side*A8, f1 = F1 + side*A8;
      int illegal = 0, sq;
      for(sq = Min(initialKSQ, g1); sq <= Max(initialKSQ, g1); sq++) 
        if((sq != initialKSQ && sq != initialKRSQ && pos->board[sq] != EMPTY)
	   || is_attacked(pos, sq, xside)) 
          illegal = 1; 
      for(sq = Min(initialKRSQ, f1); sq <= Max(initialKRSQ, f1); sq++)
        if(sq != initialKSQ && sq != initialKRSQ && pos->board[sq] != EMPTY)
          illegal = 1;
      if(!illegal) (ms++)-> move = (KING<<17)|(initialKSQ<<7)|g1|CastleFlag;
    }
    if(CanCastleQueenside(pos, side)) {
      int initialKSQ = pos->initial_ksq+side*A8;
      int initialQRSQ = pos->initial_qrsq+side*A8;
      int c1 = C1 + side*A8, d1 = D1 + side*A8;
      int illegal = 0, sq;
      for(sq = Min(initialKSQ, c1); sq <= Max(initialKSQ, c1); sq++) 
        if((sq != initialKSQ && sq != initialQRSQ && pos->board[sq] != EMPTY) 
	   || is_attacked(pos, sq, xside)) 
          illegal = 1; 
      for(sq = Min(initialQRSQ, d1); sq <= Max(initialQRSQ, d1); sq++)
        if(sq != initialKSQ && sq != initialQRSQ && pos->board[sq] != EMPTY)
          illegal = 1;
      if(pos->initial_qrsq == B1 && 
	 (pos->board[A1+side*A8] == RookOfColour(xside) ||
	  pos->board[A1+side*A8] == QueenOfColour(xside)))
        illegal = 1;
      if(!illegal) (ms++)-> move = (KING<<17)|(initialKSQ<<7)|c1|CastleFlag;
    }
  }

  return ms;
}

move_t generate_move(const position_t *pos, move_t incomplete_move) {
  position_t p[1];
  move_stack_t start[256], *end, *ms;
  copy_position(p, pos);
  end = generate_moves(p, start);
  for(ms = start; ms < end; ms++)
    if((ms->move & 0xFFFF) == (incomplete_move & 0xFFFF))
      return ms->move;
  return 0;
}

bool position_is_mate(position_t *pos) {
  move_stack_t mstck[256], *m;
  if(!pos->check) return false;
  m = generate_check_evasions(pos, mstck);
  if(m == mstck) return true;
  else return false;
}

bool position_is_rule50_draw(const position_t *pos) {
  if(pos->rule50 > 100) return true;
  if(pos->rule50 == 100 && !pos->check) return true;
  return false;
}

bool position_is_material_draw(const position_t *pos) {
  if(PawnCount(pos, WHITE) == 0 && PawnCount(pos, BLACK) == 0 &&
     RookCount(pos, WHITE) == 0 && RookCount(pos, BLACK) == 0 &&
     QueenCount(pos, WHITE) == 0 && QueenCount(pos, BLACK) == 0 &&
     BishopCount(pos, WHITE) + KnightCount(pos, WHITE) <= 1 &&
     BishopCount(pos, BLACK) + KnightCount(pos, BLACK) <= 1)
    return true;
  return false;
}

bool position_is_repetition_draw(const position_t *pos) {
  int i, count = 1;
  for(i = 2; i <= Min(pos->gply, pos->rule50) && count < 3; i += 2)
    if(pos->previous_keys[pos->gply - i] == pos->key) count++;
  if(count >= 3) return true;
  else return false;
}

bool position_is_stalemate(position_t *pos) {
  move_stack_t start[256], *end, *ms;
  if(pos->check) return false;
  end = generate_moves(pos, start);
  for(ms = start; ms < end; ms++)
    if(move_is_legal(pos, ms->move))
      return false;
  return true;
}
  
bool position_is_draw(position_t *pos) {
  return 
    position_is_rule50_draw(pos) ||
    position_is_material_draw(pos) ||
    position_is_repetition_draw(pos) ||
    position_is_stalemate(pos);
}

static int ambiguity(position_t *pos, move_t move) {
  int from, to, piece, n;
  move_stack_t moves[256], *m, *end;

  from = MvFrom(move); to = MvTo(move); piece = pos->board[from];
  if(TypeOfPiece(piece) == KING) return 0;
  if(pos->piece_count[pos->side][TypeOfPiece(piece)] == 1) return 0;

  if(pos->check) end = generate_check_evasions(pos, moves);
  else end = generate_moves(pos, moves);

  n = 0;
  for(m = moves; m < end; m++) 
    if(MvPiece(m->move) == TypeOfPiece(piece) && MvTo(m->move) == to &&
       move_is_legal(pos, m->move)) 
      n++; 
  if(n == 1) return 0;

  n = 0;
  for(m = moves; m < end; m++) 
    if(MvPiece(m->move) == TypeOfPiece(piece) && MvTo(m->move) == to &&
       SquareFile(MvFrom(m->move)) == SquareFile(from) && 
       move_is_legal(pos, m->move)) 
      n++; 
  if(n == 1) return 1;

  n = 0;
  for(m = moves; m < end; m++) 
    if(MvPiece(m->move) == TypeOfPiece(piece) && MvTo(m->move) == to &&
       SquareRank(MvFrom(m->move)) == SquareRank(from) && 
       move_is_legal(pos, m->move)) 
      n++; 
  if(n == 1) return 2;

  return 3;
}

char *san_string(position_t *pos, move_t move, char *str) {
  int piece, from, to;
  char s[10];
  position_t p[1];
  undo_info_t u[1];
  char piece_strings[BK+1][2] = {
    "", "P", "N", "B", "R", "Q", "K", "", "", "P", "N", "B", "R", "Q", "K"
  };

  copy_position(p, pos);
  if(move == NullMove) {
    sprintf(str, "(null)"); return str;
  }
  else if(move == NoMove) {
    sprintf(str, "(none)"); return str;
  }
  else if(MvLongCastle(move)) {
    sprintf(str, "O-O-O"); 
  }
  else if(MvShortCastle(move)) {
    sprintf(str, "O-O"); 
  }
  else {
    piece = MvPiece(move); from = MvFrom(move); to = MvTo(move);
    str[0] = '\0';
    if(piece == PAWN) {
      if(MvCapture(move)) {
	sprintf(s, "%c", (char)SquareFile(from) + 'a');
	strcat(str, s);
      }
    }
    else {
      int amb;
      strcat(str, piece_strings[piece]);
      amb = ambiguity(p, move);
      switch(amb) {
      case 1: 
	sprintf(s, "%c", 'a' + (char)SquareFile(from));
	strcat(str, s);
	break;
      case 2: 
	sprintf(s, "%c", '1' + (char)SquareRank(from));
	strcat(str, s);
	break;
      case 3: 
	sprintf(s, "%c%c", 
		'a' + (char)SquareFile(from), '1' + (char)SquareRank(from));
	strcat(str, s);
	break;
      }
    }
    if(MvCapture(move)) strcat(str, "x");
    sprintf(s, "%c%c", 'a' + (char)SquareFile(to), '1' + (char)SquareRank(to));
    strcat(str, s);
    if(MvPromotion(move)) {
      strcat(str, "="); strcat(str, piece_strings[MvPromotion(move)]);
    }
  }
  make_move(p, move, u);
  if(p->check) {
    move_stack_t mstck[256], *m;
    m = generate_check_evasions(p, mstck);
    if(m - mstck == 0) strcat(str, "#");
    else strcat(str, "+");
  }
  return str;
} 

char *san_line(const position_t *pos, const move_t moves[], int start_column,
	       bool break_lines, bool move_numbers, char *str) {
  position_t p[1];
  undo_info_t u[1];
  int i, j, length, max_length;
  char movestr[10], numstr[10];

  copy_position(p, pos);
  str[0] = '\0';
  length = 0; max_length = 80 - start_column;
  if(move_numbers && p->side == BLACK) {
    sprintf(numstr, "%d... ", p->gply / 2 + 1);
    strcat(str, numstr);
  }
  for(i = 0; moves[i] != NoMove; i++) {
    if(move_numbers && p->side == WHITE) {
      sprintf(numstr, "%d. ", p->gply / 2 + 1);
      length += strlen(numstr) + 1;
      if(break_lines && length > max_length) {
        strcat(str, "\n");
        for(j = 0; j < start_column; j++) strcat(str, " ");
        length = strlen(movestr) + 1;
      }
      strcat(str, numstr);
    }
    san_string(p, moves[i], movestr);
    length += strlen(movestr) + 1;
    if(break_lines && length > max_length) {
      strcat(str, "\n");
      for(j = 0; j < start_column; j++) strcat(str, " ");
      length = strlen(movestr) + 1;
    }
    strcat(str, movestr); strcat(str, " ");
    if(moves[i] == NullMove) make_nullmove(p, u);
    else make_move(p, moves[i], u);
  }
  return str;
}

move_t parse_move(position_t *pos, const char movestr[]) {
  int from, to, prom;
  move_stack_t moves[256], *end, *ms;

  // "0000" is a null move:
  if(strcmp(movestr, "0000") == 0) return NullMove;

  if(strlen(movestr) < 4) return 0;
  from = parse_square(movestr);
  to = parse_square(movestr+2);
  if(from == -1 || to == -1) return 0;
  if(movestr[4] == 'q' || movestr[4] == 'Q') prom = QUEEN;
  else if(movestr[4] == 'r' || movestr[4] == 'R') prom = ROOK;
  else if(movestr[4] == 'b' || movestr[4] == 'B') prom = BISHOP;
  else if(movestr[4] == 'n' || movestr[4] == 'N') prom = KNIGHT;
  else prom = 0;
  end = generate_moves(pos, moves);
  for(ms = moves; ms < end; ms++) {
    if(MvFrom(ms->move) == from && MvTo(ms->move) == to && 
       MvPromotion(ms->move) == prom && move_is_legal(pos, ms->move))
      return ms->move;
    else if(MvShortCastle(ms->move) && MvFrom(ms->move) == from &&
            to == pos->initial_krsq + pos->side * A8 &&
	    move_is_legal(pos, ms->move))
      return ms->move;
    else if(MvLongCastle(ms->move) && MvFrom(ms->move) == from &&
            to == pos->initial_qrsq + pos->side * A8 &&
	    move_is_legal(pos, ms->move))
      return ms->move;
  }
  return NoMove;
}

char *san_move_from_string(const position_t *pos, const char *istr, 
                           char *ostr) {
  position_t p[1];
  copy_position(p, pos);
  san_string(p, parse_move(p, istr), ostr);
  return ostr;
}
  
char *san_line_from_string(const position_t *pos, int start_column, 
                           bool break_lines, bool move_numbers, 
                           const char *istr, char *ostr) {
  position_t p[1];
  undo_info_t u[1];
  const char *c = istr;
  char movestr[10], *m;
  int i = 0;
  move_t move, moves[128];

  copy_position(p, pos);
  while(isspace(*c)) c++;
  while(*c != '\0' && i < 128) {
    m = movestr;
    while(*c != '\0' && !isspace(*c)) *m++ = *c++;
    *m = '\0';
    move = parse_move(p, movestr);
    moves[i++] = move;
    if(move == NoMove) break;
    else if(move == NullMove) {
      make_nullmove(p, u);
      //      move = NoMove;
      //      break;
    }
    else make_move(p, move, u);
    while(isspace(*c)) c++;
  }
  moves[i] = NoMove;
  return san_line(pos, moves, start_column, break_lines, move_numbers, ostr);
}

void find_destination_squares_from(const position_t *pos, int from, 
                                   int squares[]) {
  position_t p[1];
  move_stack_t moves[256], *m, *end;
  int n = 0;

  copy_position(p, pos);
  end = generate_moves(p, moves);
  for(m = moves; m < end; m++) 
    if(MvFrom(m->move) == from && move_is_legal(p, m->move) &&
       (MvPromotion(m->move) == 0 || MvPromotion(m->move) == QUEEN))
      squares[n++] = COMPRESS(MvTo(m->move));
  squares[n] = -1;
}

move_t find_move_matching(const position_t *pos,
                          int from, int to, int promotion) {
  position_t p[1];
  move_stack_t moves[256], *m, *end;
  
  copy_position(p, pos);
  end = generate_moves(p, moves);
  for(m = moves; m < end; m++)
    if(MvFrom(m->move) == from && MvTo(m->move) == to && 
       MvPromotion(m->move) == promotion)
      return m->move;
  return 0;
}
  
move_t parse_san_move(const position_t *pos, const char *movestr) {
  char str[10], *cc;
  const char *c;
  int i, left, right;
  int piece = -1, from_file = -1, from_rank = -1, to, promotion = 0;
  position_t p[1];
  move_stack_t moves[256], *m, *end;
  move_t move = 0;

  if(strncmp(movestr, "O-O-O", 5) == 0) {
    copy_position(p, pos);
    end = generate_moves(p, moves);
    for(m = moves; m < end; m++)
      if(MvLongCastle(m->move)) return m->move;
    return 0;
  }

  if(strncmp(movestr, "O-O", 3) == 0) {
    copy_position(p, pos);
    end = generate_moves(p, moves);
    for(m = moves; m < end; m++)
      if(MvShortCastle(m->move)) return m->move;
    return 0;
  }

  cc = str;
  for(i=0, c=movestr; i<10 && *c!='\0' && *c!='\n' && *c!= ' '; i++, c++) 
    if(!strchr("x=+#", *c)) {
      if(strchr("nrq", *c)) *cc = toupper(*c); else *cc = *c;
      cc++;
    }
  *cc = '\0';

  cc--;
  if(strchr("BNRQ", *cc)) {
    switch(*cc) {
    case 'B': promotion = BISHOP; break;
    case 'N': promotion = KNIGHT; break;
    case 'R': promotion = ROOK; break;
    case 'Q': promotion = QUEEN; break;
    }
    *cc = '\0'; 
  }
  left = 0; right = strlen(str) - 1;
  // Moving piece:
  if(left < right) {
    if(strchr("BNRQK", str[left])) {
      switch(str[left]) {
      case 'B': piece = BISHOP; break;
      case 'N': piece = KNIGHT; break;
      case 'R': piece = ROOK; break;
      case 'Q': piece = QUEEN; break;
      case 'K': piece = KING; break;
      }
      left++;
    }
    else piece = PAWN;
  }

  // To square:
  if(left < right) {
    if(str[right] < '1' || str[right] > '8') return 0;
    for(i = right; str[i] >= '1' && str[i] <= '8'; i-- && i >= left);
    if(!strchr("abcdefgh", str[i])) return 0;
    to = parse_square(str+i);
    right = i;
  }
  else return 0;

  // From square file:
  if(left < right) {
    if(strchr("abcdefgh", str[left])) {
      from_file = (int)str[left] - (int)'a';
      left++;
    }
    if(strchr("12345678", str[left])) 
      from_rank = atoi(str+left) - 1;
  }

  // Generate moves:
  copy_position(p, pos);
  end = generate_moves(p, moves);
  i = 0;
  for(m = moves; m < end; m++)
    if(move_is_legal(p, m->move) && !MvCastle(m->move)) {
      bool match = true;
      if(MvPiece(m->move) != piece) match = false;
      else if(MvTo(m->move) != to) match = false;
      else if(MvPromotion(m->move) != promotion) match = false;
      else if(from_file != -1 && from_file != SquareFile(MvFrom(m->move)))
	match = false;
      else if(from_rank != -1 && from_rank != SquareRank(MvFrom(m->move)))
	match = false;
      if(match) {
	move = m->move;
	i++;
      }
    }
  if(i == 1) return move;
  return 0;
}

int count_legal_moves(const position_t *pos) {
  position_t p[1];
  move_stack_t moves[256], *m, *end;
  int result = 0;

  copy_position(p, pos);
  end = generate_moves(p, moves);
  for(m = moves; m < end; m++)
    if(move_is_legal(p, m->move)) result++;

  return result;
}

move_t can_castle_kingside(position_t *pos) {
  if(CanCastleKingside(pos, pos->side)) {
    move_stack_t start[256], *end, *ms;
    end = generate_moves(pos, start);
    for(ms = start; ms < end; ms++)
      if(MvShortCastle(ms->move) && move_is_legal(pos, ms->move))
	return ms->move;
  }
  return false;
}

move_t can_castle_queenside(position_t *pos) {
  if(CanCastleQueenside(pos, pos->side)) {
    move_stack_t start[256], *end, *ms;
    end = generate_moves(pos, start);
    for(ms = start; ms < end; ms++) 
      if(MvLongCastle(ms->move) && move_is_legal(pos, ms->move))
	return ms->move;
  }
  return false;
}

