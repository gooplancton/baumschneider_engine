using ..BoardRepresentation
using ..MoveRepresentation
using ..ChessConstants
using ResumableFunctions


function king_attacks_empty_bb(from_square::Int)::UInt64
    from_square_bb = idx_to_bb(from_square)
    attack_bb = UInt64(0)

    # SOUTH AND NORTH (NO NEED TO MASK)
    attack_bb |= from_square_bb << 8
    attack_bb |= from_square_bb << -8

    # EAST, SOUTHEAST AND NORTHEAST (MASK THE A FILE)
    attack_bb |= from_square_bb << 1 & ~file_bbs['A']
    attack_bb |= from_square_bb << 9 & ~file_bbs['A']
    attack_bb |= from_square_bb << -7 & ~file_bbs['A']

    # WEST, SOUTHWEST AND NORTHWEST (MASK THE H FILE)
    attack_bb |= from_square_bb << -1 & ~file_bbs['H']
    attack_bb |= from_square_bb << 7 & ~file_bbs['H']
    attack_bb |= from_square_bb << -9 & ~file_bbs['H']

    return attack_bb
end


function white_pawn_attacks_empty_bb(from_square::Int)::UInt64
    from_square_bb = idx_to_bb(from_square)
    attack_bb = UInt64(0)

    attack_bb |= from_square_bb << -7 & ~file_bbs['A']
    attack_bb |= from_square_bb << -9 & ~file_bbs['H']

    return attack_bb
end


function black_pawn_attacks_empty_bb(from_square::Int)::UInt64
    from_square_bb = idx_to_bb(from_square)
    attack_bb = UInt64(0)

    attack_bb |= from_square_bb << 7 & ~file_bbs['H']
    attack_bb |= from_square_bb << 9 & ~file_bbs['A']

    return attack_bb
end


function white_pawn_moves_empty_bb(from_square::Int)::UInt64
    from_square_bb = idx_to_bb(from_square)
    moves_bb = from_square_bb << -8

    pawn_can_double_push = (from_square_bb & rank_bbs[2]) != 0
    moves_bb |= (from_square_bb*pawn_can_double_push) << -16

    return moves_bb
end


function black_pawn_moves_empty_bb(from_square::Int)::UInt64
    from_square_bb = idx_to_bb(from_square)
    moves_bb = from_square_bb << 8

    pawn_can_double_push = (from_square_bb & rank_bbs[7]) != 0
    moves_bb |= (from_square_bb*pawn_can_double_push) << 16

    return moves_bb
end


function rook_attacks_empty_bb(from_square::Int)::UInt64
    return (
        south_rays_bb[from_square]
        | east_rays_bb[from_square]
        | west_rays_bb[from_square]
        | north_rays_bb[from_square]
    )
end


function bishop_attacks_empty_bb(from_square::Int)::UInt64
    return (
        southeast_rays_bb[from_square]
        | southwest_rays_bb[from_square]
        | northeast_rays_bb[from_square]
        | northwest_rays_bb[from_square]
    )
end


function queen_attacks_empty_bb(from_square::Int)::UInt64
    return bishop_attacks_empty_bb(from_square) | rook_attacks_empty_bb(from_square)
end


function knight_pseudolegal_moves_bb(
    from_square::Int,
    self_occupancy::UInt64,
    adv_occupancy::UInt64
)::UInt64

    empty_board_moves = knight_attacks_bb[from_square]
    return empty_board_moves & ~self_occupancy
end


function king_pseudolegal_moves_bb(
    from_square::Int,
    self_occupancy::UInt64,
    adv_occupancy::UInt64
)::UInt64

    empty_board_moves = king_attacks_empty_bb(from_square)
    return empty_board_moves & ~(self_occupancy | adv_occupancy)
end


function white_pawn_pseudolegal_moves_bb(
    from_square::Int,
    self_occupancy::UInt64,
    adv_occupancy::UInt64
)::UInt64

    empty_board_moves = white_pawn_moves_empty_bb(from_square)
    pushes = empty_board_moves & ~(self_occupancy | adv_occupancy)
    captures = white_pawn_attacks_empty_bb(from_square) & adv_occupancy

    return pushes | captures
end


function black_pawn_pseudolegal_moves_bb(
    from_square::Int,
    self_occupancy::UInt64,
    adv_occupancy::UInt64
)::UInt64

    empty_board_moves = black_pawn_moves_empty_bb(from_square)
    pushes = empty_board_moves & ~self_occupancy
    captures = black_pawn_attacks_empty_bb(from_square) & adv_occupancy

    return pushes | captures
end


function sliding_piece_pseudolegal_moves_bb(
    from_square::Int,
    ray_bb_dict::Dict{Int, UInt64},
    self_occupancy::UInt64,
    adv_occupancy::UInt64,
    ray_before_piece::Bool
)::UInt64

    piece_ray = ray_bb_dict[from_square]
    masked_blockers = (adv_occupancy | self_occupancy) & piece_ray
    blocker_idx = (
        ray_before_piece
        ? bitscan_backward(masked_blockers)
        : bitscan_forward(masked_blockers)
    )

    blocker_ray = blocker_idx >= 0 ? ray_bb_dict[blocker_idx] : UInt64(0)
    attacks = piece_ray & ~blocker_ray
    
    return attacks & ~self_occupancy
end


function bishop_pseudolegal_moves_bb(
    from_square::Int,
    self_occupancy::UInt64,
    adv_occupancy::UInt64
)::UInt64

    moves_nw = sliding_piece_pseudolegal_moves_bb(
        from_square,
        northwest_rays_bb,
        self_occupancy,
        adv_occupancy,
        true
    )
    moves_ne = sliding_piece_pseudolegal_moves_bb(
        from_square,
        northeast_rays_bb,
        self_occupancy,
        adv_occupancy,
        true
    )
    moves_se = sliding_piece_pseudolegal_moves_bb(
        from_square,
        southeast_rays_bb,
        self_occupancy,
        adv_occupancy,
        false
    )
    moves_sw = sliding_piece_pseudolegal_moves_bb(
        from_square,
        southwest_rays_bb,
        self_occupancy,
        adv_occupancy,
        false
    )

    return  moves_ne | moves_nw | moves_se | moves_sw
end


function rook_pseudolegal_moves_bb(
    from_square::Int,
    self_occupancy::UInt64,
    adv_occupancy::UInt64
)::UInt64

    moves_n = sliding_piece_pseudolegal_moves_bb(
        from_square,
        north_rays_bb,
        self_occupancy,
        adv_occupancy,
        true
    )
    moves_e = sliding_piece_pseudolegal_moves_bb(
        from_square,
        east_rays_bb,
        self_occupancy,
        adv_occupancy,
        false
    )
    moves_s = sliding_piece_pseudolegal_moves_bb(
        from_square,
        south_rays_bb,
        self_occupancy,
        adv_occupancy,
        false
    )
    moves_w = sliding_piece_pseudolegal_moves_bb(
        from_square,
        west_rays_bb,
        self_occupancy,
        adv_occupancy,
        true
    )

    return moves_n | moves_w | moves_s | moves_e
end


function queen_pseudolegal_moves_bb(
    from_square::Int,
    self_occupancy::UInt64,
    adv_occupancy::UInt64
)::UInt64

    return (
        bishop_pseudolegal_moves_bb(from_square, self_occupancy, adv_occupancy)
        | rook_pseudolegal_moves_bb(from_square, self_occupancy, adv_occupancy)
    )
end


function is_white_king_in_check(gs::GameState)::Bool
    attacked_bb = side_attacked_bb(gs, true)
    king_bb = gs.white_king

    return (attacked_bb & king_bb) != 0
end
export is_white_king_in_check


function is_black_king_in_check(gs::GameState)::Bool
    attacked_bb = side_attacked_bb(gs, true)
    king_bb = gs.black_king

    return (attacked_bb & king_bb) != 0
end
export is_black_king_in_check


function moving_side_can_capture_king(gs::GameState)::Bool
    attacked_bb = side_attacked_bb(gs, gs.white_to_move)
    enemy_king_bb = gs.white_to_move ? gs.black_king : gs.white_king

    return (attacked_bb & enemy_king_bb) != 0
end
export moving_side_can_capture_king
