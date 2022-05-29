module ChessConstants


const initial_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
export initial_fen


const knight_directions = [6, 15, 17, 10, -6, -15, -17, -10]
export knight_directions


const symbols_to_bitboards = Dict(
    'R' => :white_rooks,
    'N' => :white_knights,
    'B' => :white_bishops,
    'K' => :white_king,
    'Q' => :white_queens,
    'P' => :white_pawns,
    'r' => :black_rooks,
    'n' => :black_knights,
    'b' => :black_bishops,
    'k' => :black_king,
    'q' => :black_queens,
    'p' => :black_pawns,
)
export symbols_to_bitboards


const possible_promotion_pieces = ['q', 'n', 'r', 'b']
export possible_promotion_pieces


const debruijn64 = UInt64(0x03f79d71b4cb0a89)
export debruijn64


const debruijn_seq_fw = [
    0,  1, 48,  2, 57, 49, 28,  3,
   61, 58, 50, 42, 38, 29, 17,  4,
   62, 55, 59, 36, 53, 51, 43, 22,
   45, 39, 33, 30, 24, 18, 12,  5,
   63, 47, 56, 27, 60, 41, 37, 16,
   54, 35, 52, 21, 44, 32, 23, 11,
   46, 26, 40, 15, 34, 20, 31, 10,
   25, 14, 19,  9, 13,  8,  7,  6
]
export debruijn_seq_fw


const debruijn_seq_bw = [
    0, 47,  1, 56, 48, 27,  2, 60,
    57, 49, 41, 37, 28, 16,  3, 61,
    54, 58, 35, 52, 50, 42, 21, 44,
    38, 32, 29, 23, 17, 11,  4, 62,
    46, 55, 26, 59, 40, 36, 15, 53,
    34, 51, 20, 43, 31, 22, 10, 45,
    25, 39, 14, 33, 19, 30,  9, 24,
    13, 18,  8, 12,  7,  6,  5, 63
]
export debruijn_seq_bw


end
