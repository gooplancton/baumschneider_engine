module PositionEvaluation


using ..BoardRepresentation
using ..MoveRepresentationUtils


function evaluate_position(gs::GameState)::Float32
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

    return (
        1.0 * n_white_pawns + 
        -1.0 * n_black_pawns +
        5.0 * n_white_rooks +
        -5.0 * n_black_rooks +
        3.0 * (n_white_knights + n_white_bishops) +
        -3.0 * (n_black_knights + n_black_bishops) +
        9.0 * n_white_queens + 
        -9.0 * n_black_queens
    )
end
export evaluate_position


end

