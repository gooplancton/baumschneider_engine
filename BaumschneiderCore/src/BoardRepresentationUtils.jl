module BoardRepresentationUtils

using ..MoveRepresentation
using ..MoveRepresentationUtils
using ..BoardRepresentation
using ..ChessConstants
using ResumableFunctions


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


function pprint_board(gs::GameState)::Array{Char}
    squares = []
    for idx in 0:63
        piece = piece_at_square(gs, idx)
        piece = piece !== nothing ? piece : ' '
        push!(squares, piece)
    end
    
    return permutedims(reshape(squares, (8, 8)))
end
export pprint_board



function get_piece_bb(gs::GameState, piece::Char)::UInt64
    if piece == 'p'
        return gs.black_pawns
    elseif piece == 'P'
        return gs.white_pawns
    elseif piece == 'r'
        return gs.black_rooks
    elseif piece == 'R'
        return gs.white_rooks
    elseif piece == 'n'
        return gs.black_knights
    elseif piece == 'N'
        return gs.white_knights
    elseif piece == 'b'
        return gs.black_bishops
    elseif piece == 'B'
        return gs.white_bishops
    elseif piece == 'q'
        return gs.black_queens
    elseif piece == 'Q'
        return gs.white_queens
    elseif piece == 'k'
        return gs.black_king
    elseif piece == 'K'
        return gs.white_king
    end
end
export get_piece_bb


function set_piece_bb!(gs::GameState, piece::Char, bb::UInt64)
    if piece == 'p'
        gs.black_pawns = bb
    elseif piece == 'P'
        gs.white_pawns = bb
    elseif piece == 'r'
        gs.black_rooks = bb
    elseif piece == 'R'
        gs.white_rooks = bb
    elseif piece == 'n'
        gs.black_knights = bb
    elseif piece == 'N'
        gs.white_knights = bb
    elseif piece == 'b'
        gs.black_bishops = bb
    elseif piece == 'B'
        gs.white_bishops = bb
    elseif piece == 'q'
        gs.black_queens = bb
    elseif piece == 'Q'
        gs.white_queens = bb
    elseif piece == 'k'
        gs.black_king = bb
    elseif piece == 'K'
        gs.white_king = bb
    end
end
export set_piece_bb



"""
Converts the provided FEN string into the engine's internal game state representation

Args:
    fen: the FEN string
"""
function fen_to_gamestate(fen::String)::GameState
    idx = 0

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
        if char in piece_symbols
            pieces_bbs[char] = set_bit(pieces_bbs[char], idx)
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
        nothing
    )
end
export fen_to_gamestate


function set_bit_on_piece_bb!(gs::GameState, piece::Char, idx::Int)
    bb = get_piece_bb(gs, piece)
    bb = set_bit(bb, idx)
    set_piece_bb!(gs, piece, bb)
end


function clear_bit_on_piece_bb!(gs::GameState, piece::Char, idx::Int)
    bb = get_piece_bb(gs, piece)
    bb = clear_bit(bb, idx)
    set_piece_bb!(gs, piece, bb)
end


function switch_bit_on_piece_bb!(gs::GameState, piece::Char, idx_set::Int, idx_unset::Int)
    bb = get_piece_bb(gs, piece)
    bb = set_bit(clear_bit(bb, idx_unset), idx_set)
    set_piece_bb!(gs, piece, bb)
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

    if move.captured_piece !== nothing && !move.is_enpassant
        clear_bit_on_piece_bb!(gs, move.captured_piece, move.to_square)
    end

    gs.prev_enpassant = gs.enpassant
    gs.enpassant = nothing
    if (move.piece == 'P') | (move.piece == 'p')


        # ENPASSANT
        if move.is_enpassant
            capture_sq = move.player_white ? gs.prev_enpassant + 8 : gs.prev_enpassant - 8
            clear_bit_on_piece_bb!(gs, move.captured_piece, capture_sq)
        end

        # DOUBLE PUSH
        if abs(move.to_square - move.from_square) == 16
            gs.enpassant = (move.to_square + move.from_square) >> 1
        end


        # PROMOTION
        if move.promotion_piece !== nothing
            clear_bit_on_piece_bb!(gs, move.piece, move.to_square)
            set_bit_on_piece_bb!(gs, move.promotion_piece, move.to_square)
        end
    end

    update_castling_rights!(gs, move)

    if move.is_right_castle && move.player_white
        gs.white_rooks = clear_bit(gs.white_rooks, 63)
        gs.white_rooks = set_bit(gs.white_rooks, 61)
    elseif move.is_left_castle && move.player_white
        gs.white_rooks = clear_bit(gs.white_rooks, 56)
        gs.white_rooks = set_bit(gs.white_rooks, 59)
    elseif move.is_right_castle && !move.player_white
        gs.black_rooks = clear_bit(gs.black_rooks, 7)
        gs.black_rooks = set_bit(gs.black_rooks, 5)
    elseif move.is_left_castle && !move.player_white
        gs.black_rooks = clear_bit(gs.black_rooks, 0)
        gs.black_rooks = set_bit(gs.black_rooks, 3)
    end

    gs.white_to_move = !gs.white_to_move

    return nothing
end
export apply_move!


function undo_move!(gs::GameState, move::Move)
    
    switch_bit_on_piece_bb!(gs, move.piece, move.from_square, move.to_square)


    if move.captured_piece !== nothing && !move.is_enpassant
        set_bit_on_piece_bb!(gs, move.captured_piece, move.to_square)
    end

    gs.enpassant = gs.prev_enpassant
    gs.prev_enpassant = nothing
    if (move.piece == 'P') | (move.piece == 'p')

        # ENPASSANT
        if move.is_enpassant
            capture_sq = move.player_white ? gs.prev_enpassant + 8 : gs.prev_enpassant - 8
            set_bit_on_piece_bb!(gs, move.captured_piece, capture_sq)
        end

        # PROMOTION
        if move.promotion_piece !== nothing
            set_bit_on_piece_bb!(gs, move.piece, move.to_square)
            clear_bit_on_piece_bb!(gs, move.promotion_piece, move.to_square)

            captured_piece = move.captured_piece !== nothing ? move.captured_piece : ' '
        end
    end

    revert_castling_rights!(gs)

    if move.is_right_castle && move.player_white
        gs.white_rooks = clear_bit(gs.white_rooks, 63)
        gs.white_rooks = set_bit(gs.white_rooks, 61)
    elseif move.is_left_castle && move.player_white
        gs.white_rooks = clear_bit(gs.white_rooks, 56)
        gs.white_rooks = set_bit(gs.white_rooks, 59)
    elseif move.is_right_castle && !move.player_white
        gs.black_rooks = clear_bit(gs.black_rooks, 7)
        gs.black_rooks = set_bit(gs.black_rooks, 5)
    elseif move.is_left_castle && !move.player_white
        gs.black_rooks = clear_bit(gs.black_rooks, 0)
        gs.black_rooks = set_bit(gs.black_rooks, 3)
    end

    gs.white_to_move = !gs.white_to_move

    return nothing
end
export undo_move!


function piece_at_square(gs::GameState, idx::Int)::Union{Nothing, Char}
    for piece in piece_symbols
        bb = get_piece_bb(gs, piece)
        if (bb >> idx) % 2 == 1
            return piece
        end
    end

    return nothing
end
export piece_at_square


function pieces_on_squares(gs::GameState)::Vector{Tuple{Int, Char}}
    squares = []
    for piece_idx in 0:63
        piece = piece_at_square(gs, piece_idx)
        if piece !== nothing
            push!(squares, (piece_idx, piece))
        end
    end

    @inbounds return squares
end
export pieces_on_squares


function uci_to_move(gs::GameState, uci::AbstractString)::Move

    from_sq_letter = uci[1]
    from_sq_num = uci[2]
    from_square_idx = alg_to_idx(from_sq_letter, from_sq_num)

    to_sq_letter = uci[3]
    to_sq_num = uci[4]
    to_square_idx = alg_to_idx(to_sq_letter, to_sq_num)

    if uci == "e1g1"
        return Move(
            'K',
            true,
            from_square_idx,
            to_square_idx,
            true,
            false,
            false,
            nothing,
            nothing
        )
    elseif uci == "e1c1"
        return Move(
            'K',
            true,
            from_square_idx,
            to_square_idx,
            false,
            true,
            false,
            nothing,
            nothing
        )
    elseif uci == "e8g8"
        return Move(
            'k',
            true,
            from_square_idx,
            to_square_idx,
            true,
            false,
            false,
            nothing,
            nothing
        )
    elseif uci == "e8c8"
        return Move(
            'k',
            true,
            from_square_idx,
            to_square_idx,
            false,
            true,
            false,
            nothing,
            nothing
        )
    else
        moving_piece = piece_at_square(gs, from_square_idx)
        captured_piece = piece_at_square(gs, to_square_idx)
        if lowercase(moving_piece) == 'p' && to_square_idx == gs.enpassant
            captured_piece = gs.white_to_move ? 'p' : 'P'
        end

        if length(uci) == 5
            promotion_piece_lc = uci[5]
            promotion_piece = gs.white_to_move ? uppercase(promotion_piece) : promotion_piece_lc

            return Move(
                moving_piece,
                gs.white_to_move,
                from_square_idx,
                to_square_idx,
                false,
                false,
                false,
                false,
                promotion_piece
            )
        else
            return parse_simple_move(
                moving_piece,
                gs.white_to_move,
                from_square_idx,
                to_square_idx,
                captured_piece
            )
        end
    end

end
export uci_to_move


end
