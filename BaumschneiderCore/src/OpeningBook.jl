module OpeningBook


using ..BoardRepresentation
using ..MoveRepresentation
using ..MoveRepresentationUtils
using Random


function generate_opening_book_from_file(fname::String, min_moves::Int = 4)::Vector{Vector{String}}
    file = open(fname)
    openings = []

    while !eof(file)
        opening_str = readline(file)
        opening_vec = split(opening_str, " ")
        if length(opening_vec) >= min_moves
            push!(openings, opening_vec)
        end
    end

    close(file)
    return openings
end
export generate_opening_book_from_file


function sample_opening_book(openings::Vector{Vector{String}}, current::Vector{String})::Union{String, Nothing}
    filter!(
        op->length(op) > length(current),
        openings
    )

    filter!(
        op->all(op[i] == cur_mov for (i, cur_mov) in enumerate(current)),
        openings
    )

    if length(openings) == 0
        return nothing
    end

    opening = shuffle(openings)[1]
    next_move = opening[length(current) + 1]

    if next_move == "*"
        return nothing
    else
        return next_move
    end

end
export sample_opening_book


end
