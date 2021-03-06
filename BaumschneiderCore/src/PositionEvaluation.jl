module PositionEvaluation


using ..MoveRepresentation
using ..BoardRepresentation
using ..MoveRepresentationUtils


const piece_vals = Dict(
    'P' => 100.0,
    'N' => 280.0,
    'B' => 320.0,
    'R' => 479.0,
    'Q' => 929.0,
    'K' => 60000.0
)


function build_piece_squares_tables()::Dict{Char, Vector{Int}}

    piece_squares_tables = Dict(
    'P'=> [  0,   0,   0,   0,   0,   0,   0,   0,
            78,  83,  86,  73, 102,  82,  85,  90,
             7,  29,  21,  44,  40,  31,  44,   7,
           -17,  16,  -2,  15,  14,   0,  15, -13,
           -26,   3,  10,   9,   6,   1,   0, -23,
           -22,   9,   5, -11, -10,  -2,   3, -19,
           -31,   8,  -7, -37, -36, -14,   3, -31,
             0,   0,   0,   0,   0,   0,   0,   0],

    'N'=> [-66, -53, -75, -75, -10, -55, -58, -70,
            -3,  -6, 100, -36,   4,  62,  -4, -14,
            10,  67,   1,  74,  73,  27,  62,  -2,
            24,  24,  45,  37,  33,  41,  25,  17,
            -1,   5,  31,  21,  22,  35,   2,   0,
           -18,  10,  13,  22,  18,  15,  11, -14,
           -23, -15,   2,   0,   2,   0, -23, -20,
           -74, -23, -26, -24, -19, -35, -22, -69],

    'B'=> [-59, -78, -82, -76, -23,-107, -37, -50,
           -11,  20,  35, -42, -39,  31,   2, -22,
            -9,  39, -32,  41,  52, -10,  28, -14,
            25,  17,  20,  34,  26,  25,  15,  10,
            13,  10,  17,  23,  17,  16,   0,   7,
            14,  25,  24,  15,   8,  25,  20,  15,
            19,  20,  11,   6,   7,   6,  20,  16,
            -7,   2, -15, -12, -14, -15, -10, -10],

    'R'=> [ 35,  29,  33,   4,  37,  33,  56,  50,
            55,  29,  56,  67,  55,  62,  34,  60,
            19,  35,  28,  33,  45,  27,  25,  15,
             0,   5,  16,  13,  18,  -4,  -9,  -6,
           -28, -35, -16, -21, -13, -29, -46, -30,
           -42, -28, -42, -25, -25, -35, -26, -46,
           -53, -38, -31, -26, -29, -43, -44, -53,
           -30, -24, -18,   5,  -2, -18, -31, -32],

    'Q'=> [  6,   1,  -8,-104,  69,  24,  88,  26,
            14,  32,  60, -10,  20,  76,  57,  24,
            -2,  43,  32,  60,  72,  63,  43,   2,
             1, -16,  22,  17,  25,  20, -13,  -6,
           -14, -15,  -2,  -5,  -1, -10, -20, -22,
           -30,  -6, -13, -11, -16, -11, -16, -27,
           -36, -18,   0, -19, -15, -15, -21, -38,
           -39, -30, -31, -13, -31, -36, -34, -42],

    'K'=> [  4,  54,  47, -99, -99,  60,  83, -62,
           -32,  10,  55,  56,  56,  55,  10,   3,
           -62,  12, -57,  44, -67,  28,  37, -31,
           -55,  50,  11,  -4, -19,  13,   0, -49,
           -55, -43, -52, -28, -51, -47,  -8, -50,
           -47, -42, -43, -79, -64, -32, -29, -32,
            -4,   3, -14, -50, -57, -18,  13,   4,
            17,  30,  -3, -14,   6,  -1,  40,  18],
    )

    for (key, table) in piece_squares_tables
        piece_squares_tables[lowercase(key)] = -1 * reverse(table)
    end

    return piece_squares_tables
end


const piece_squares_tables = build_piece_squares_tables()


function eval_piece_squares(move::Move)::Int
    val = 0
    val -= piece_squares_tables[move.piece][move.from_square + 1]
    val += piece_squares_tables[move.piece][move.to_square + 1]

    if move.is_right_castle
        val += (2*move.player_white - 1)*14
    elseif move.is_left_castle
        val += (2*move.player_white - 1)*35
    elseif move.captured_piece !== nothing
        val -= piece_squares_tables[move.captured_piece][move.to_square + 1]
    end

    if move.promotion_piece !== nothing
        val -= piece_squares_tables[move.piece][move.to_square + 1]
        val += piece_squares_tables[move.promotion_piece][move.to_square + 1]
    end

    return val
end
export eval_piece_squares


function count_material_diff(gs::GameState)::Float32
    n_white_pawns = pop_count(gs.white_pawns)
    n_black_pawns = pop_count(gs.black_pawns)
    n_white_rooks = pop_count(gs.white_rooks)
    n_black_rooks = pop_count(gs.black_rooks)
    n_white_knights = pop_count(gs.white_knights)
    n_black_knights = pop_count(gs.black_knights)
    n_white_bishops = pop_count(gs.white_bishops)
    n_black_bishops = pop_count(gs.black_bishops)
    n_white_queens = pop_count(gs.white_queens)
    n_black_queens = pop_count(gs.black_queens)
    n_white_kings = pop_count(gs.white_king)
    n_black_kings = pop_count(gs.black_king)

    return (
        piece_vals['P'] * n_white_pawns +
        -piece_vals['P'] * n_black_pawns +
        piece_vals['R'] * n_white_rooks +
        -piece_vals['R'] * n_black_rooks +
        piece_vals['N'] * n_white_knights +
        -piece_vals['N'] * n_black_knights +
        piece_vals['B'] * n_white_bishops +
        -piece_vals['B'] * n_black_bishops +
        piece_vals['Q'] * n_white_queens +
        -piece_vals['Q'] * n_black_queens +
        piece_vals['K'] * n_white_kings +
        -piece_vals['K'] * n_black_kings
    )
end
export count_material_diff


end

