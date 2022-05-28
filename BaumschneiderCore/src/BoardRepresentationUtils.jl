module BoardRepresentationUtils

using ..MoveRepresentation
using ..BoardRepresentation


function white_occupancy_bb(gs::GameState)::UInt64
    return (
        gs.white_pawns
        | gs.white_rooks
        | gs.white_knights
        | gs.white_bishops
        | gs.white_queens
        | gs.white_king
    )
end
export white_occupancy_bb


function black_occupancy_bb(gs::GameState)::UInt64
    return (
        gs.black_pawns
        | gs.black_rooks
        | gs.black_knights
        | gs.black_bishops
        | gs.black_queens
        | gs.black_king
    )
end
export black_occupancy_bb


function show(gs::GameState)::Array{Char}
    return permutedims(reshape(gs.squares, (8, 8)))
end


"""
Converts the provided FEN string into the engine's internal game state representation

Args:
    fen: the FEN string
"""
function fen_to_gamestate(fen::String)::GameState
    idx = 0

    gs_squares = fill(' ', 64)
    pieces, active, castling, enpassant, _, totmoves = split(fen, " ")
    pieces_bbs = Dict([
        ('R', UInt64(0)),
        ('N', UInt64(0)),
        ('B', UInt64(0)),
        ('K', UInt64(0)),
        ('Q', UInt64(0)),
        ('P', UInt64(0)),
        ('r', UInt64(0)),
        ('n', UInt64(0)),
        ('b', UInt64(0)),
        ('k', UInt64(0)),
        ('q', UInt64(0)),
        ('p', UInt64(0)),
    ])

    ## PIECE LAYOUT
    for char in pieces
        if char in keys(symbols_to_bitboards)
            pieces_bbs[char] = set_bit(pieces_bbs[char], idx)
            gs_squares[idx + 1] = char
            idx += 1
        elseif tryparse(Int, string(char)) !== nothing
            idx += parse(Int, char)
        elseif char != '/'
            throw(error("invalid FEN"))
        end
    end

    # ACTIVE PLAYER
    if active == "w"
        gs_white_to_move = true
    elseif active == "b"
        gs_white_to_move = false
    else
        throw(error("invalid FEN"))
    end

    castling_rights = Dict([
        ('K', false),
        ('Q', false),
        ('k', false),
        ('q', false),
    ])

    # CASTLING RIGHTS
    for key in keys(castling_rights)
        castling_rights[key] = occursin(key, castling)
    end

    gs_enpassant = nothing

    # EN PASSANT
    if length(enpassant) == 2
        letter = enpassant[1]
        number = parse(UInt64, enpassant[2])
        row = (9 - number) - 1
        col = findfirst(letter, "hgfedcba") - 1
        gs_enpassant = row * 8 + col
    end

    # MOVE COUNT
    gs_num_moves = parse(UInt64, totmoves)

    return GameState(
        pieces_bbs['P'],
        pieces_bbs['K'],
        pieces_bbs['Q'],
        pieces_bbs['N'],
        pieces_bbs['B'],
        pieces_bbs['R'],
        pieces_bbs['p'],
        pieces_bbs['k'],
        pieces_bbs['q'],
        pieces_bbs['n'],
        pieces_bbs['b'],
        pieces_bbs['r'],
        nothing,
        gs_enpassant,
        [],
        CastlingRights(
            castling_rights['Q'],
            castling_rights['K'],
            castling_rights['q'],
            castling_rights['k'],
        ),
        gs_white_to_move,
        gs_num_moves,
        gs_squares,
        nothing
    )
end
export fen_to_gamestate


function set_bit_on_piece_bb!(gs::GameState, piece::Char, idx::Int)
    
    if piece == 'p'
        gs.black_pawns = set_bit(gs.black_pawns, idx)
    elseif piece == 'P'
        gs.white_pawns = set_bit(gs.white_pawns, idx)
    elseif piece == 'r'
        gs.black_rooks = set_bit(gs.black_rooks, idx)
    elseif piece == 'R'
        gs.white_rooks = set_bit(gs.white_rooks, idx)
    elseif piece == 'n'
        gs.black_knights = set_bit(gs.black_knights, idx)
    elseif piece == 'N'
        gs.white_knights = set_bit(gs.white_knights, idx)
    elseif piece == 'b'
        gs.black_bishops = set_bit(gs.black_bishops, idx)
    elseif piece == 'B'
        gs.white_bishops = set_bit(gs.white_bishops, idx)
    elseif piece == 'q'
        gs.black_queens = set_bit(gs.black_queens, idx)
    elseif piece == 'Q'
        gs.white_queens = set_bit(gs.white_queens, idx)
    elseif piece == 'k'
        gs.black_king = set_bit(gs.black_king, idx)
    elseif piece == 'K'
        gs.white_king = set_bit(gs.white_king, idx)
    end

end


function clear_bit_on_piece_bb!(gs::GameState, piece::Char, idx::Int)
    
    if piece == 'p'
        gs.black_pawns = clear_bit(gs.black_pawns, idx)
    elseif piece == 'P'
        gs.white_pawns = clear_bit(gs.white_pawns, idx)
    elseif piece == 'r'
        gs.black_rooks = clear_bit(gs.black_rooks, idx)
    elseif piece == 'R'
        gs.white_rooks = clear_bit(gs.white_rooks, idx)
    elseif piece == 'n'
        gs.black_knights = clear_bit(gs.black_knights, idx)
    elseif piece == 'N'
        gs.white_knights = clear_bit(gs.white_knights, idx)
    elseif piece == 'b'
        gs.black_bishops = clear_bit(gs.black_bishops, idx)
    elseif piece == 'B'
        gs.white_bishops = clear_bit(gs.white_bishops, idx)
    elseif piece == 'q'
        gs.black_queens = clear_bit(gs.black_queens, idx)
    elseif piece == 'Q'
        gs.white_queens = clear_bit(gs.white_queens, idx)
    elseif piece == 'k'
        gs.black_king = clear_bit(gs.black_king, idx)
    elseif piece == 'K'
        gs.white_king = clear_bit(gs.white_king, idx)
    end

end


function switch_bit_on_piece_bb!(gs::GameState, piece::Char, idx_set::Int, idx_unset::Int)
    
    if piece == 'p'
        gs.black_pawns = set_bit(clear_bit(gs.black_pawns, idx_unset), idx_set)
    elseif piece == 'P'
        gs.white_pawns = set_bit(clear_bit(gs.white_pawns, idx_unset), idx_set)
    elseif piece == 'r'
        gs.black_rooks = set_bit(clear_bit(gs.black_rooks, idx_unset), idx_set)
    elseif piece == 'R'
        gs.white_rooks = set_bit(clear_bit(gs.white_rooks, idx_unset), idx_set)
    elseif piece == 'n'
        gs.black_knights = set_bit(clear_bit(gs.black_knights, idx_unset), idx_set)
    elseif piece == 'N'
        gs.white_knights = set_bit(clear_bit(gs.white_knights, idx_unset), idx_set)
    elseif piece == 'b'
        gs.black_bishops = set_bit(clear_bit(gs.black_bishops, idx_unset), idx_set)
    elseif piece == 'B'
        gs.white_bishops = set_bit(clear_bit(gs.white_bishops, idx_unset), idx_set)
    elseif piece == 'q'
        gs.black_queens = set_bit(clear_bit(gs.black_queens, idx_unset), idx_set)
    elseif piece == 'Q'
        gs.white_queens = set_bit(clear_bit(gs.white_queens, idx_unset), idx_set)
    elseif piece == 'k'
        gs.black_king = set_bit(clear_bit(gs.black_king, idx_unset), idx_set)
    elseif piece == 'K'
        gs.white_king = set_bit(clear_bit(gs.white_king, idx_unset), idx_set)
    end

end


function u64_to_vec(u::UInt64)::BitVector
    res = BitVector(undef, sizeof(u)*8)
    res.chunks[1] = u % UInt64
    
    return res
end


function pprint_bb(bb::UInt64)
    vec = u64_to_vec(bb)
    permutedims(reshape(vec, (8, 8)))
end


function update_castling_rights!(gs::GameState, move::Move)
    push!(gs.castling_rights_history, gs.castling_rights)
    if move.is_left_castle || move.is_right_castle
        gs.castling_rights = CastlingRights(false, false, false, false)
    elseif move.piece == 'K'
        gs.castling_rights = CastlingRights(
            false,
            false,
            gs.castling_rights.black_can_castle_left,
            gs.castling_rights.black_can_castle_right
        )
    elseif move.piece == 'k'
        new_rights = CastlingRights(
            gs.castling_rights.white_can_castle_left,
            gs.castling_rights.white_can_castle_right,
            false,
            false,
        )
    elseif move.piece == 'R' && move.from_square == 56 # Q
        new_rights = CastlingRights(
            false,
            gs.castling_rights.white_can_castle_right,
            gs.castling_rights.black_can_castle_left,
            gs.castling_rights.black_can_castle_right
        )
    elseif move.piece == 'R' && move.from_square == 63 # K
        new_rights = CastlingRights(
            gs.castling_rights.white_can_castle_left,
            false,
            gs.castling_rights.black_can_castle_left,
            gs.castling_rights.black_can_castle_right
        )
    elseif move.piece == 'r' && move.from_square == 0 # q
        push!(gs.castling_rights_history, gs.castling_rights)
        new_rights = CastlingRights(
            gs.castling_rights.white_can_castle_left,
            gs.castling_rights.white_can_castle_right,
            false,
            gs.castling_rights.black_can_castle_right
        )
    elseif move.piece == 'r' && move.from_square == 7 # k
        push!(gs.castling_rights_history, gs.castling_rights)
        new_rights = CastlingRights(
            gs.castling_rights.white_can_castle_left,
            gs.castling_rights.white_can_castle_right,
            gs.castling_rights.black_can_castle_left,
            false
        )
    end

    return nothing
end


function revert_castling_rights!(gs::GameState)
    gs.castling_rights = pop!(gs.castling_rights_history)
end


function apply_move!(gs::GameState, move::Move)
    
    switch_bit_on_piece_bb!(gs, move.piece, move.to_square, move.from_square)
    gs.squares[move.from_square + 1] = ' '
    gs.squares[move.to_square + 1] = move.piece

    if move.captured_piece !== nothing && !move.is_enpassant
        clear_bit_on_piece_bb!(gs, move.captured_piece, move.to_square)
    end

    gs.prev_enpassant = gs.enpassant
    gs.enpassant = nothing
    if (move.piece == 'P') | (move.piece == 'p')


        # ENPASSANT
        if move.is_enpassant
            capture_sq = move.white_to_move ? gs.prev_enpassant + 8 : gs.prev_enpassant - 8
            clear_bit_on_piece_bb!(gs, move.captured_piece, capture_sq)
            gs.squares[capture_sq + 1] = ' '
        end

        # DOUBLE PUSH
        if abs(move.to_square - move.from_square) == 16
            gs.enpassant = (move.to_square + move.from_square) >> 1
        end


        # PROMOTION
        if move.promotion_piece !== nothing
            clear_bit_on_piece_bb!(gs, move.piece, move.to_square)
            set_bit_on_piece_bb!(gs, move.promotion_piece, move.to_square)

            gs.squares[move.to_square + 1] = move.promotion_piece
        end
    end

    update_castling_rights!(gs, move)

    if move.is_right_castle && move.player_white
        gs.white_rooks = clear_bit(gs.white_rooks, 63)
        gs.white_rooks = set_bit(gs.white_rooks, 61)
        gs.squares[63] = ' '
        gs.squares[61] = 'R'
    elseif move.is_left_castle && move.player_white
        gs.white_rooks = clear_bit(gs.white_rooks, 56)
        gs.white_rooks = set_bit(gs.white_rooks, 59)
        gs.squares[56] = ' '
        gs.squares[59] = 'R'
    elseif move.is_right_castle && !move.player_white
        gs.black_rooks = clear_bit(gs.black_rooks, 7)
        gs.black_rooks = set_bit(gs.black_rooks, 5)
        gs.squares[7] = ' '
        gs.squares[5] = 'r'
    elseif move.is_left_castle && !move.player_white
        gs.black_rooks = clear_bit(gs.black_rooks, 0)
        gs.black_rooks = set_bit(gs.black_rooks, 3)
        gs.squares[0] = ' '
        gs.squares[4] = 'r'
    end

    gs.white_to_move = !gs.white_to_move

    return nothing
end
export apply_move!


function undo_move!(gs::GameState, move::Move)
    
    switch_bit_on_piece_bb!(gs, move.piece, move.from_square, move.to_square)

    gs.squares[move.from_square + 1] = move.piece
    gs.squares[move.to_square + 1] = ' '

    if move.captured_piece !== nothing && !move.is_enpassant
        set_bit_on_piece_bb!(gs, move.captured_piece, move.to_square)
        gs.squares[move.to_square + 1] = move.captured_piece
    end

    gs.enpassant = gs.prev_enpassant
    gs.prev_enpassant = nothing
    if (move.piece == 'P') | (move.piece == 'p')

        # ENPASSANT
        if move.is_enpassant
            capture_sq = move.white_to_move ? gs.prev_enpassant + 8 : gs.prev_enpassant - 8
            set_bit_on_piece_bb!(gs, move.captured_piece, capture_sq)
            gs.squares[move.to_square + 1] = move.captured_piece
        end

        # PROMOTION
        if move.promotion_piece !== nothing
            set_bit_on_piece_bb!(gs, move.piece, move.to_square)
            clear_bit_on_piece_bb!(gs, move.promotion_piece, move.to_square)

            captured_piece = move.captured_piece !== nothing ? move.captured_piece : ' '
            gs.squares[move.to_square + 1] = captured_piece
            gs.squares[move.from_square + 1] = move.piece
        end
    end

    revert_castling_rights!(gs)

    if move.is_right_castle && move.player_white
        gs.white_rooks = clear_bit(gs.white_rooks, 63)
        gs.white_rooks = set_bit(gs.white_rooks, 61)
        gs.squares[61] = ' '
        gs.squares[63] = 'R'
    elseif move.is_left_castle && move.player_white
        gs.white_rooks = clear_bit(gs.white_rooks, 56)
        gs.white_rooks = set_bit(gs.white_rooks, 59)
        gs.squares[59] = ' '
        gs.squares[56] = 'R'
    elseif move.is_right_castle && !move.player_white
        gs.black_rooks = clear_bit(gs.black_rooks, 7)
        gs.black_rooks = set_bit(gs.black_rooks, 5)
        gs.squares[5] = ' '
        gs.squares[7] = 'r'
    elseif move.is_left_castle && !move.player_white
        gs.black_rooks = clear_bit(gs.black_rooks, 0)
        gs.black_rooks = set_bit(gs.black_rooks, 3)
        gs.squares[4] = ' '
        gs.squares[0] = 'r'
    end

    gs.white_to_move = !gs.white_to_move

    return nothing
end
export undo_move!


end

