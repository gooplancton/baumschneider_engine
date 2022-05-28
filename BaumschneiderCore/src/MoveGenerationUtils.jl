using ..BoardRepresentation
using ..MoveRepresentation
using ResumableFunctions


function knight_attacks_empty_bb(from_square::Int)::UInt64
    from_square_bb = idx_to_bb(from_square)
    attack_bb = UInt64(0)

    for i in knight_directions
        attack_bb |= set_bit(attack_bb, from_square + i)
    end

    apply_gh_mask = (from_square_bb & (file_bbs['A'] | file_bbs['B'])) != 0
    apply_ab_mask = (from_square_bb & (file_bbs['G'] | file_bbs['H'])) != 0
    gh_mask = (file_bbs['G'] | file_bbs['H']) * apply_gh_mask
    ab_mask = (file_bbs['A'] | file_bbs['B']) * apply_ab_mask

    attack_bb &= ~(gh_mask)
    attack_bb &= ~(ab_mask)

    return attack_bb
end


function king_attacks_empty_bb(from_square::Int)::UInt64
    from_square_bb = idx_to_bb(from_square)
    attack_bb = UInt64(0)

    # SOUTH AND NORTH (NO NEED TO MASK)
    attack_bb |= from_square_bb << 8
    attack_bb |= from_square_bb << -8
    # for i in [8, -8]
    #     attack_bb |= from_square_bb << i
    # end

    # EAST, SOUTHEAST AND NORTHEAST (MASK THE A FILE)
    attack_bb |= from_square_bb << 1 & ~file_bbs['A']
    attack_bb |= from_square_bb << 9 & ~file_bbs['A']
    attack_bb |= from_square_bb << -7 & ~file_bbs['A']

    # for i in [1, 9, -7]
    #     attack_bb |= from_square_bb << i & ~file_bbs['A']
    # end

    # WEST, SOUTHWEST AND NORTHWEST (MASK THE H FILE)
    attack_bb |= from_square_bb << -1 & ~file_bbs['H']
    attack_bb |= from_square_bb << 7 & ~file_bbs['H']
    attack_bb |= from_square_bb << -9 & ~file_bbs['H']
    # for i in [-1, 7, -9]
    #     attack_bb |= from_square_bb << i & ~file_bbs['H']
    # end

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


function north_ray_bb(from_square::Int)::UInt64
    ray_bb = UInt64(0x0101010101010101) # A file
    file_idx = from_square % 8
    reverse_rank_idx = from_square ÷ 8

    return ray_bb << (file_idx - 8 * (8 - reverse_rank_idx))
end


function south_ray_bb(from_square::Int)::UInt64
    ray_bb = UInt64(0x0101010101010101) # A file
    file_idx = from_square % 8
    reverse_rank_idx = from_square ÷ 8

    return ray_bb << (file_idx + 8 * (reverse_rank_idx + 1))
end


function east_ray_bb(from_square::Int)::UInt64
    file_idx = from_square % 8
    reverse_rank_idx = from_square ÷ 8
    ray_bb = UInt64(2^(7 - file_idx) - 1)
    
    return ray_bb << (file_idx + 1 + 8 * reverse_rank_idx)
end


function west_ray_bb(from_square::Int)::UInt64
    file_idx = from_square % 8
    reverse_rank_idx = from_square ÷ 8
    ray_bb = UInt64(2^file_idx - 1)
    
    return ray_bb << (8 * reverse_rank_idx)
end


function northwest_ray_bb(from_square::Int)::UInt64
    file_idx = from_square % 8
    reverse_rank_idx = from_square ÷ 8
    idx = from_square
    ray_bb = UInt64(0)

    for _ in range(1, min(file_idx, reverse_rank_idx))
        idx -= 9
        ray_bb = set_bit(ray_bb, idx)
    end

    return ray_bb
end


function northeast_ray_bb(from_square::Int)::UInt64
    file_idx = from_square % 8
    reverse_rank_idx = from_square ÷ 8
    idx = from_square
    ray_bb = UInt64(0)

    for _ in range(1, min(7-file_idx, reverse_rank_idx))
        idx -= 7
        ray_bb = set_bit(ray_bb, idx)
    end

    return ray_bb
end


function southwest_ray_bb(from_square::Int)::UInt64
    file_idx = from_square % 8
    reverse_rank_idx = from_square ÷ 8
    idx = from_square
    ray_bb = UInt64(0)

    for _ in range(1, min(file_idx, 7-reverse_rank_idx))
        idx += 7
        ray_bb = set_bit(ray_bb, idx)
    end

    return ray_bb
end


function southeast_ray_bb(from_square::Int)::UInt64
    file_idx = from_square % 8
    reverse_rank_idx = from_square ÷ 8
    idx = from_square
    ray_bb = UInt64(0)

    for _ in range(1, min(7-file_idx, 7-reverse_rank_idx))
        idx += 9
        ray_bb = set_bit(ray_bb, idx)
    end

    return ray_bb
end


function rook_attacks_empty_bb(from_square::Int)::UInt64
    return (
        south_ray_bb(from_square)
        | east_ray_bb(from_square)
        | west_ray_bb(from_square)
        | north_ray_bb(from_square)
    )
end


function bishop_attacks_empty_bb(from_square::Int)::UInt64
    return (
        southeast_ray_bb(from_square)
        | southwest_ray_bb(from_square)
        | northeast_ray_bb(from_square)
        | northwest_ray_bb(from_square)
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

    empty_board_moves = knight_attacks_empty_bb(from_square)
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
    ray_bb_fun::Function,
    self_occupancy::UInt64,
    adv_occupancy::UInt64,
    ray_before_piece::Bool
)::UInt64

    piece_ray = ray_bb_fun(from_square)
    masked_blockers = (adv_occupancy | self_occupancy) & piece_ray
    blocker_idx = (
        ray_before_piece
        ? bitscan_backward(masked_blockers)
        : bitscan_forward(masked_blockers)
    )

    blocker_ray = blocker_idx >= 0 ? ray_bb_fun(blocker_idx) : UInt64(0)
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
        northwest_ray_bb,
        self_occupancy,
        adv_occupancy,
        true
    )
    moves_ne = sliding_piece_pseudolegal_moves_bb(
        from_square,
        northeast_ray_bb,
        self_occupancy,
        adv_occupancy,
        true
    )
    moves_se = sliding_piece_pseudolegal_moves_bb(
        from_square,
        southeast_ray_bb,
        self_occupancy,
        adv_occupancy,
        false
    )
    moves_sw = sliding_piece_pseudolegal_moves_bb(
        from_square,
        southwest_ray_bb,
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
        north_ray_bb,
        self_occupancy,
        adv_occupancy,
        true
    )
    moves_e = sliding_piece_pseudolegal_moves_bb(
        from_square,
        east_ray_bb,
        self_occupancy,
        adv_occupancy,
        false
    )
    moves_s = sliding_piece_pseudolegal_moves_bb(
        from_square,
        south_ray_bb,
        self_occupancy,
        adv_occupancy,
        false
    )
    moves_w = sliding_piece_pseudolegal_moves_bb(
        from_square,
        west_ray_bb,
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


function is_black_king_in_check(gs::GameState)::Bool
    attacked_bb = side_attacked_bb(gs, true)
    king_bb = gs.black_king

    return (attacked_bb & king_bb) != 0
end


function moving_side_can_capture_king(gs::GameState)::Bool
    attacked_bb = side_attacked_bb(gs, gs.white_to_move)
    enemy_king_bb = gs.white_to_move ? gs.black_king : gs.white_king

    return (attacked_bb & enemy_king_bb) != 0
end
