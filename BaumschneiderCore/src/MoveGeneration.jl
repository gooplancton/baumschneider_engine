module MoveGeneration


include("MoveGenerationUtils.jl")
using ..MoveRepresentationUtils
using ..BoardRepresentationUtils
using ..PrecomputedBitboards


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
    if gs.enpassant === nothing
        return nothing
    end

    pawn_should_be_idx = gs.enpassant + offset
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
                    captured_piece = gs.squares[to_square + 1]
                    captured_piece = (captured_piece == ' ') ? nothing : captured_piece

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
    for (index, piece) in enumerate(gs.squares)
        if piece == ' ' || (islowercase(piece) != side_white)
            continue
        end

        from_square = index - 1
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
            king_square_idx - 2,
            true,
            false,
            false,
            nothing,
            nothing
        )
    end

end


@resumable function generate_pseudolegal_moves(gs::GameState)::Move

    white_occupancy = white_occupancy_bb(gs)
    black_occupancy = black_occupancy_bb(gs)
    pawns_bb = gs.white_to_move ? gs.white_pawns : gs.black_pawns
    
    left_castle_move = generate_left_castle_move(gs)
    if left_castle_move !== nothing
    end

    right_castle_move = generate_right_castle_move(gs)
    if right_castle_move !== nothing
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
            @yield move
        end
    end


    for (index, piece) in enumerate(gs.squares)

        if piece == ' '
            continue
        end

        is_white_piece = !islowercase(piece)
        if is_white_piece != gs.white_to_move
            continue
        end

        from_square = index - 1
        moves_bb = piece_moves_bb(piece, from_square, white_occupancy, black_occupancy)
        to_squares = bb_set_bits_idxs(moves_bb)
        for to_square in to_squares
            captured_piece = gs.squares[to_square + 1]
            captured_piece = (captured_piece == ' ') ? nothing : captured_piece
            @yield parse_simple_move(
                piece,
                is_white_piece,
                from_square,
                to_square,
                captured_piece,
            )
        end
    end
end
export generate_pseudolegal_moves


end
