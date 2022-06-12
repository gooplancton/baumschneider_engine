module MoveGeneration


include("MoveGenerationUtils.jl")
using ..MoveRepresentationUtils
using ..BoardRepresentationUtils
using ..PrecomputedBitboards
using ..OpeningBook


function piece_moves_bb(piece::Char, from_square::Int, white_occupancy::UInt64, black_occupancy::UInt64)::UInt64
    if piece == 'p'
        return black_pawn_pseudolegal_moves_bb(from_square, black_occupancy, white_occupancy)
    elseif piece == 'P'
        return white_pawn_pseudolegal_moves_bb(from_square, white_occupancy, black_occupancy)
    elseif piece == 'r'
        return rook_pseudolegal_moves_bb(from_square, black_occupancy, white_occupancy)
    elseif piece == 'R'
        return rook_pseudolegal_moves_bb(from_square, white_occupancy, black_occupancy)
    elseif piece == 'n'
        return knight_pseudolegal_moves_bb(from_square, black_occupancy, white_occupancy)
    elseif piece == 'N'
        return knight_pseudolegal_moves_bb(from_square, white_occupancy, black_occupancy)
    elseif piece == 'b'
        return bishop_pseudolegal_moves_bb(from_square, black_occupancy, white_occupancy)
    elseif piece == 'B'
        return bishop_pseudolegal_moves_bb(from_square, white_occupancy, black_occupancy)
    elseif piece == 'q'
        return queen_pseudolegal_moves_bb(from_square, black_occupancy, white_occupancy)
    elseif piece == 'Q'
        return queen_pseudolegal_moves_bb(from_square, white_occupancy, black_occupancy)
    elseif piece == 'k'
        return king_pseudolegal_moves_bb(from_square, black_occupancy, white_occupancy)
    elseif piece == 'K'
        return king_pseudolegal_moves_bb(from_square, white_occupancy, black_occupancy)
    end
end


function generate_enpassant_move(gs::GameState, offset::Int, pawns_bb::UInt64)::Union{Move, Nothing}
    enpassant_square = gs.enpassant_history[gs.num_moves]
    if enpassant_square === nothing
        return nothing
    end

    pawn_should_be_idx = enpassant_square + offset
    pawn_should_be_bb = idx_to_bb(pawn_should_be_idx)
    piece = gs.white_to_move ? 'P' : 'p'
    captured_piece = gs.white_to_move ? 'p' : 'P'

    if (pawn_should_be_bb & pawns_bb) != 0
        return Move(
            piece,
            gs.white_to_move,
            pawn_should_be_idx,
            gs.enpassant,
            false,
            false,
            true,
            captured_piece,
            nothing
        )
    else
        return nothing
    end
end


function generate_promotion_moves(gs::GameState, promovable_pawns_bb::UInt64)::Vector{Move}
    moves = []
    for from_square in bb_set_bits_idxs(promovable_pawns_bb)
        promotion_row = gs.white_to_move ? rank_bbs[8] : rank_bbs[1]
        promovable_pawn_moves_bb = (
            gs.white_to_move 
            ? white_pawn_pseudolegal_moves_bb(from_square, white_occupancy_bb(gs), black_occupancy_bb(gs))
            : black_pawn_pseudolegal_moves_bb(from_square, black_occupancy_bb(gs), white_occupancy_bb(gs))
        )

        to_squares_bb = promovable_pawn_moves_bb & promotion_row
        if to_squares_bb == 0
            continue
        else
            for to_square in bb_set_bits_idxs(to_squares_bb)
                for prom_piece in possible_promotion_pieces
                    prom_piece = gs.white_to_move ? uppercase(prom_piece) : prom_piece
                    captured_piece = piece_at_square(gs, to_square)

                    move = Move(
                        gs.white_to_move ? 'P' : 'p',
                        gs.white_to_move,
                        from_square,
                        to_square,
                        false,
                        false,
                        false,
                        captured_piece,
                        prom_piece
                    )

                    push!(moves, move)
                end
            end
        end
    end

    return moves
end


function side_attacked_bb(gs::GameState, side_white::Bool)::UInt64
    attacks_bb = UInt64(0)
    white_occupancy = white_occupancy_bb(gs)
    black_occupancy = black_occupancy_bb(gs)
    for (from_square, piece) in pieces_on_squares(gs)
        if piece === nothing || (isuppercase(piece) != side_white)
            continue
        end

        moves_bb = piece_moves_bb(piece, from_square, white_occupancy, black_occupancy)
        attacks_bb |= moves_bb
    end

    return attacks_bb
end


function generate_left_castle_move(gs::GameState)::Union{Move, Nothing}
    castling_right = (
        gs.white_to_move 
        ? gs.castling_rights.white_can_castle_left
        : gs.castling_rights.black_can_castle_left
    )

    if !castling_right
        return nothing
    end

    total_occupancy_bb = black_occupancy_bb(gs) | white_occupancy_bb(gs)
    king_square_idx = gs.white_to_move ? 60 : 4
    rook_square_bb = gs.white_to_move ? idx_to_bb(56) : idx_to_bb(0)
    castling_line = west_rays_bb[king_square_idx] & ~rook_square_bb
    other_pieces_in_line_bb = total_occupancy_bb & castling_line

    if other_pieces_in_line_bb != 0
        return nothing
    end

    enemy_attacks_bb = side_attacked_bb(gs, !gs.white_to_move)
    king_travel_path = gs.white_to_move ? gs.white_king : gs.black_king
    king_travel_path = set_bit(king_travel_path, king_square_idx - 1)
    king_travel_path = set_bit(king_travel_path, king_square_idx - 2)
    
    king_passes_through_enemy_attack = (king_travel_path & enemy_attacks_bb) != 0
    if king_passes_through_enemy_attack
        return nothing
    else
        return Move(
            gs.white_to_move ? 'K' : 'k',
            gs.white_to_move,
            king_square_idx,
            king_square_idx - 2,
            false,
            true,
            false,
            nothing,
            nothing
        )
    end

end


function generate_right_castle_move(gs::GameState)::Union{Move, Nothing}
    castling_right = (
        gs.white_to_move
        ? gs.castling_rights.white_can_castle_right 
        : gs.castling_rights.black_can_castle_right
    )

    if !castling_right
        return nothing
    end

    total_occupancy_bb = black_occupancy_bb(gs) | white_occupancy_bb(gs)
    king_square_idx = gs.white_to_move ? 60 : 4
    rook_square_bb = gs.white_to_move ? idx_to_bb(63) : idx_to_bb(7)
    castling_line = east_rays_bb[king_square_idx] & ~rook_square_bb
    other_pieces_in_line_bb = total_occupancy_bb & castling_line

    if other_pieces_in_line_bb != 0
        return nothing
    end

    enemy_attacks_bb = side_attacked_bb(gs, !gs.white_to_move)
    king_travel_path = gs.white_to_move ? gs.white_king : gs.black_king
    king_travel_path = set_bit(king_travel_path, king_square_idx + 1)
    king_travel_path = set_bit(king_travel_path, king_square_idx + 2)
    
    king_passes_through_enemy_attack = (king_travel_path & enemy_attacks_bb) != 0
    if king_passes_through_enemy_attack
        return nothing
    else
        return Move(
            gs.white_to_move ? 'K' : 'k',
            gs.white_to_move,
            king_square_idx,
            king_square_idx + 2,
            true,
            false,
            false,
            nothing,
            nothing
        )
    end

end


function generate_pseudolegal_moves(gs::GameState, white_occupancy::UInt64, black_occupancy::UInt64)::Vector{Move}

    moves = []
    for (from_square, piece) in pieces_on_squares(gs)

        if piece === nothing
            continue
        end

        is_white_piece = !islowercase(piece)
        if is_white_piece != gs.white_to_move
            continue
        end

        moves_bb = piece_moves_bb(piece, from_square, white_occupancy, black_occupancy)
        to_squares = bb_set_bits_idxs(moves_bb)
        for to_square in to_squares
            captured_piece = piece_at_square(gs, to_square)
            push!(moves, parse_simple_move(
                piece,
                is_white_piece,
                from_square,
                to_square,
                captured_piece,
            ))
        end
    end

    return moves
end
export generate_pseudolegal_moves # REMOVE LATER


const rays_bbs = Dict(
    (false, 8) => north_rays_bb,
    (true, 8) => south_rays_bb,
    (false, 7) => northeast_rays_bb,
    (true, 7) => southwest_rays_bb,
    (false, 9) => northwest_rays_bb,
    (true, 9) => southeast_rays_bb,
    (false, 1) => west_rays_bb,
    (true, 1) => east_rays_bb
)



function check_ray_bb(from_square::Int, king_square::Int)::UInt64
    diff = from_square - king_square
    piece_before_king = diff < 0
    for offset in 7:9
        if diff % offset == 0
            return (
                rays_bbs[(piece_before_king, offset)][from_square]
                & rays_bbs[(!piece_before_king, offset)][king_square]
            )
        end
    end

    distance_to_edge = piece_before_king ? king_square % 8 : 8 - king_square % 8
    if abs(diff) < distance_to_edge
        return (
            rays_bbs[(piece_before_king, 1)][from_square]
            & rays_bbs[(!piece_before_king, 1)][king_square]
        )
    end

    return UInt64(0)
end


function is_legal_move(
    gs::GameState,
    move::Move,
    self_occupancy_bb::UInt64,
    adv_attacked_noking_bb::UInt64,
    pieces_attacking_king_bb::UInt64,
    pieces_pinning_bb::UInt64
)::Bool
    # https://peterellisjones.com/posts/generating-legal-chess-moves-efficiently/
    # PART 1: KING MOVES
    if lowercase(move.piece) == 'k'
        return (adv_attacked_noking_bb & idx_to_bb(move.to_square)) == 0
    end
    # PART 2: CHECK EVASIONS
    n_pieces_attacking_king = pop_count(pieces_attacking_king_bb)
    king_square = gs.white_to_move ? bitscan_forward(gs.white_king) : bitscan_forward(gs.black_king)
    if n_pieces_attacking_king > 1
        return false
    elseif n_pieces_attacking_king == 1
        checking_piece_idx = bitscan_forward(pieces_attacking_king_bb)
        attacking_ray_bb = check_ray_bb(checking_piece_idx, king_square)
        attacking_ray_bb |= pieces_attacking_king_bb

        return (attacking_ray_bb & idx_to_bb(move.to_square)) != 0
    end
    # PART 3: PINNED pieces
    for pinning_piece_idx in bb_set_bits_idxs(pieces_pinning_bb)
        pin_ray = check_ray_bb(pinning_piece_idx, king_square) | idx_to_bb(pinning_piece_idx)
        pinned_piece_idx = bitscan_forward(pin_ray & self_occupancy_bb)
        
        if move.from_square == pinned_piece_idx
            return (pin_ray & idx_to_bb(move.to_square)) != 0
        end
    end
    # PART 4: ENPASSANT
    ##### apply/undo the move
    if move.is_enpassant
        apply_move!(gs, move)
        legal = !moving_side_can_capture_king(gs)
        undo_move!(gs, move)
        
        return legal
    end

    return true
end
export is_legal_move


function is_move_absolute_pin(move::Move, king_square::Int, self_occupancy_bb::UInt64)::Bool
    pin_ray = check_ray_bb(move.from_square, king_square)
    return (
        (idx_to_bb(move.to_square) & pin_ray) != 0
        && pop_count(pin_ray & self_occupancy_bb) == 1
    )
end


@resumable function generate_legal_moves(gs::GameState, only_captures::Bool = false)::Move

    ## GENERATE MOVES FOR OPPOSING PLAYER (ATTACKED SQUARES)
    white_occupancy = white_occupancy_bb(gs)
    black_occupancy = black_occupancy_bb(gs)

    if gs.white_to_move
        king_bb = gs.white_king
        self_occupancy_bb = white_occupancy
    else
        king_bb = gs.black_king
        self_occupancy_bb = black_occupancy
    end

    king_square = bitscan_forward(king_bb)
    gs.white_to_move = !gs.white_to_move
    adv_attacked_squares_bb = UInt64(0)
    pieces_attacking_king_bb = UInt64(0)
    pieces_pinning_bb = UInt64(0)

    for adv_move in generate_pseudolegal_moves(gs, white_occupancy & ~king_bb, black_occupancy & ~king_bb)
        adv_attacked_squares_bb |= idx_to_bb(adv_move.to_square)
        if (adv_move.to_square == king_square)
            pieces_attacking_king_bb |= idx_to_bb(adv_move.from_square)
        elseif is_move_absolute_pin(adv_move, king_square, self_occupancy_bb)
            pieces_pinning_bb |= idx_to_bb(adv_move.from_square)
        end
    end
    gs.white_to_move = !gs.white_to_move
    adv_attacked_noking_bb = adv_attacked_squares_bb & ~king_bb
    pawns_bb = gs.white_to_move ? gs.white_pawns : gs.black_pawns
    
    left_castle_move = generate_left_castle_move(gs)
    if left_castle_move !== nothing && !only_captures
        @yield left_castle_move
    end

    right_castle_move = generate_right_castle_move(gs)
    if right_castle_move !== nothing && !only_captures
        @yield right_castle_move
    end

    right_enp_offset = gs.white_to_move ? -7 : 9
    right_enpassant_move = generate_enpassant_move(gs, right_enp_offset, pawns_bb)
    if right_enpassant_move !== nothing
        @yield right_enpassant_move
    end

    left_enp_offset = gs.white_to_move ? -9 : 7
    left_enpassant_move = generate_enpassant_move(gs, left_enp_offset, pawns_bb)
    if left_enpassant_move !== nothing
        @yield left_enpassant_move
    end

    promovable_row_bb = gs.white_to_move ? rank_bbs[7] : rank_bbs[2]
    promovable_pawns_bb = pawns_bb & promovable_row_bb
    if promovable_pawns_bb != 0
        promotion_moves = generate_promotion_moves(gs, promovable_pawns_bb)
        for move in promotion_moves
            if move.captured_piece !== nothing || !only_captures
                @yield move
            end
        end
    end

    for move in generate_pseudolegal_moves(gs, white_occupancy, black_occupancy)
        if is_legal_move(gs, move, self_occupancy_bb, adv_attacked_noking_bb, pieces_attacking_king_bb, pieces_pinning_bb)
            if move.captured_piece == nothing && only_captures
                continue
            end

            @yield move
        end
    end
end
export generate_legal_moves


function is_legal_usermove(gs::GameState, move::Move)::Bool
    usermove_uci = move_to_uci(move)
    for legal_move in generate_legal_moves(gs)
        legal_move_uci = move_to_uci(legal_move)
        if legal_move_uci == usermove_uci
            return true
        end
    end

    return false
end
export is_legal_usermove


end
