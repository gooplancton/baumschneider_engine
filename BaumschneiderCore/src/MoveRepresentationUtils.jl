module MoveRepresentationUtils


using ResumableFunctions
using ..MoveRepresentation
using ..BoardRepresentation
using ..ChessConstants


"""
Converts the provided bitboard index in the chessboard's algebraic notation

Args:
    idx: the bitboard index, which goes from 1 to 64.
"""
function idx_to_alg(idx::Int)::String
    letter_idx = (idx % 8) + 1
    number = 8 - (idx ÷ 8)
    letter = "abcdefgh"[letter_idx]

    return letter * string(number)
end


"""
Converts the provided algebraic notation position to bitboard index

Args:
    letter: the column in algebraic notation (e.g. "e")
    number: the row in algebraic notation (e.g. 1)
"""
function alg_to_idx(letter::Char, number::Int)::Int
    row = (9 - number) - 1
    col = findfirst(letter, "abcdefgh") - 1

    return row * 8 + col
end


alg_to_idx(letter::Char, number::Char)::Int = alg_to_idx(letter, parse(Int, number))


function move_to_alg(move::Move)::String
    if move.is_left_castle
        return "0-0-0"
    elseif move.is_right_castle
        return "0-0"
    end

    moving_piece = uppercase(move.piece)
    from_square = idx_to_alg(move.from_square)
    to_square = idx_to_alg(move.to_square)
    if moving_piece == 'P' && move.captured_piece === nothing
        moving_piece = ' '
    elseif moving_piece == 'P' && move.captured_piece !== nothing
        moving_piece = from_square[1]
    end

    if move.captured_piece !== nothing
        to_square = 'x'*to_square
    end

    promotion = ' '
    if move.promotion_piece !== nothing
        promotion = '='*uppercase(move.promotion_piece)
    end

    return moving_piece*to_square*promotion
end
export move_to_alg


function move_to_uci(move::Move)::String
    promotion_piece = move.promotion_piece !== nothing ? move.promotion_piece : ""
    return idx_to_alg(move.from_square)*idx_to_alg(move.to_square)*promotion_piece
end
export move_to_uci


function set_bit(bitboard::UInt64, idx::Int)::UInt64
    return bitboard | (1 << idx)
end
export set_bit


function clear_bit(bitboard::UInt64, idx::Int)::UInt64
    return bitboard & ~(1 << idx)
end
export clear_bit

"""
Converts the provided algebraic notation position to bitboard index

Args:
    alg: the algebraic notation position (e.g. "e4")
"""
function alg_to_idx(alg::String)::Int
    letter, number = alg[0], parse(UInt64, alg[1])

    return alg_to_idx(letter, number)
end
export alg_to_idx


function idx_to_bb(idx::Int)::UInt64
    return set_bit(UInt64(0), idx)
end
export idx_to_bb


function rank_to_bb(rank::Int)::UInt64
    return reduce(
        |,
        [idx_to_bb(idx) for idx in range((8 - rank) * 8, length=8)],
        init=UInt64(0)
    )
end
export rank_to_bb


function file_to_bb(file::Int)::UInt64
    return reduce(
        |,
        [idx_to_bb(idx) for idx in range(file - 1, step=8, length=8)],
        init=UInt64(0)
    )
end
export file_to_bb


function bitscan_forward(bb::UInt64)::Int
    
    if bb == 0
        return -1
    end

    @inbounds return debruijn_seq_fw[(((bb & -bb) * debruijn64) >> 58) + 1]
end
export bitscan_forward


function bitscan_backward(bb::UInt64)::Int

    if bb == 0
        return -1
    end

    bb |= bb >> 1
    bb |= bb >> 2
    bb |= bb >> 4
    bb |= bb >> 8
    bb |= bb >> 16
    bb |= bb >> 32

    @inbounds return debruijn_seq_bw[((bb * debruijn64) >> 58) + 1]
end
export bitscan_backward


@resumable function bb_set_bits_idxs(bb::UInt64)::Int
    for i in 0:63
        if (bb << -i) % 2 != 0
            @yield i
        end
    end
end
export bb_set_bits_idxs


function pop_count(bb::UInt64)::Int
    count = 0
    while bb != 0
        count += 1
        bb &= bb - 1
    end
    return count
end
export pop_count


end
