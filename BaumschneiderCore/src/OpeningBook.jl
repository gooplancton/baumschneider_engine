module OpeningBook


using ..BoardRepresentation
using ..MoveRepresentation
using ..MoveRepresentationUtils
using Random


function opening_uci_to_move(gs::GameState, uci::String)::Move

    from_sq_letter = uci[1]
    from_sq_num = uci[2]
    from_square_idx = alg_to_idx(from_sq_letter, from_sq_num)

    to_sq_letter = uci[3]
    to_sq_num = uci[4]
    to_square_idx = alg_to_idx(to_sq_letter, to_sq_num)

    if uci == "e1g1"
        return Move(
            "K",
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
            "K",
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
            "k",
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
            "k",
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
        moving_piece = gs.squares[from_square_idx]
        captured_piece = gs.squares[to_square_idx]
        captured_piece = captured_piece == ' ' ? nothing : captured_piece

        return parse_simple_move(
            moving_piece,
            gs.white_to_move,
            from_square_idx,
            to_square_idx,
            captured_piece
        )
    end

end


function generate_opening_book_from_file(fname::String, min_moves::Int = 4)::Vector{Vector{String}}
    file = open(fname)
    openings = []

    while !eof(file)
        opening_str = readine(file)
        opening_vec = split(opening_str, " ")
        if length(opening_vec) >= min_moves
            push!(openings, opening_vec)
        end
    end

    close(file)
    return openings
end


function sample_opening_book(openings::Vector{Vector{String}}, current::Vector{String})::Union{String, Nothing}
    matching_openings = filter(
        op->all(op[i] == cur_mov for (i, cur_mov) in enumerate(current)),
        openings
    )

    if length(matching_openings) == 0
        return nothing
    end

    opening = shuffle(matching_openings)[1]
    next_move = opening[length(current) + 1]

    if next_move == "*"
        return nothing
    else
        return next_move
    end

end


end
