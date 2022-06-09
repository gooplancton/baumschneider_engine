module PrecomputedBitboards

using ..ChessConstants
using ..MoveRepresentationUtils


const rank_bbs = Dict([
    (rank, rank_to_bb(rank))
    for rank in range(1, 8)
])
export rank_bbs


const file_bbs = Dict([
    ("ABCDEFGH"[file], file_to_bb(file))
    for file in range(1, 8)
])
export file_bbs


function knight_attacks_empty_bb(from_square::Int)::UInt64
    from_square_bb = idx_to_bb(from_square)
    attack_bb = UInt64(0)

    for i in (6, 15, 17, 10, -6, -15, -17, -10)
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


const knight_attacks_bb = Dict(
    [(i, knight_attacks_empty_bb(i)) for i in 0:63]
)
export knight_attacks_bb


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


const west_rays_bb = Dict(
    [(i, west_ray_bb(i)) for i in 0:63]
)
export west_rays_bb

const east_rays_bb = Dict(
    [(i, east_ray_bb(i)) for i in 0:63]
)
export east_rays_bb

const north_rays_bb = Dict(
    [(i, north_ray_bb(i)) for i in 0:63]
)
export north_rays_bb

const south_rays_bb = Dict(
    [(i, south_ray_bb(i)) for i in 0:63]
)
export south_rays_bb

const northwest_rays_bb = Dict(
    [(i, northwest_ray_bb(i)) for i in 0:63]
)
export northwest_rays_bb

const southwest_rays_bb = Dict(
    [(i, southwest_ray_bb(i)) for i in 0:63]
)
export southwest_rays_bb

const northeast_rays_bb = Dict(
    [(i, northeast_ray_bb(i)) for i in 0:63]
)
export northeast_rays_bb

const southeast_rays_bb = Dict(
    [(i, southeast_ray_bb(i)) for i in 0:63]
)
export southeast_rays_bb


end
