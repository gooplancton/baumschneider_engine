module BoardRepresentation

using ..MoveRepresentation


struct CastlingRights
    white_can_castle_left::Bool
    white_can_castle_right::Bool

    black_can_castle_left::Bool
    black_can_castle_right::Bool
end
export CastlingRights


mutable struct GameState
    white_pawns::UInt64
    white_king::UInt64
    white_queens::UInt64
    white_knights::UInt64
    white_bishops::UInt64
    white_rooks::UInt64
    
    black_pawns::UInt64
    black_king::UInt64
    black_queens::UInt64
    black_knights::UInt64
    black_bishops::UInt64
    black_rooks::UInt64

    prev_enpassant::Union{Int, Nothing}
    enpassant::Union{Int, Nothing}

    castling_rights_history::Vector{CastlingRights}
    castling_rights::CastlingRights


    white_to_move::Bool
    num_moves::UInt64

    # redundant mailbox representation for easier iteration
    squares::Vector{Char}

    best_move_from_position::Union{Move, Nothing}
end
export GameState


end
