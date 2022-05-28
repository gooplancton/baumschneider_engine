module MoveRepresentation


struct Move
    piece::Char
    player_white::Bool
    from_square::Int
    to_square::Int
    is_right_castle::Bool
    is_left_castle::Bool
    is_enpassant::Bool
    captured_piece::Union{Char, Nothing}
    promotion_piece::Union{Char, Nothing}
end
export Move


parse_simple_move(
    piece::Char,
    player_white::Bool,
    from_square::Int,
    to_square::Int,
    captured_piece::Union{Char, Nothing}
)::Move = Move(
    piece,
    player_white,
    from_square,
    to_square,
    false,
    false,
    false,
    captured_piece,
    nothing
)
export parse_simple_move


end
