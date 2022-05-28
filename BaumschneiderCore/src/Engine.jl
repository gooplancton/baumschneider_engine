module Engine


using ..ChessConstants
using ..BoardRepresentation
using ..BoardRepresentationUtils
using ..MoveRepresentation
using ..MoveRepresentationUtils
using ..MoveSearch


mutable struct ChessEngine
    game_state::GameState
    is_white_player::Bool
    moves::Vector{Move}
    opening_book::Vector{Vector{String}}
    is_playing_from_book::Bool
    search_depth::Int
end


start_game(as_white_player::Bool=true)::ChessEngine = ChessEngine(
    fen_to_gamestate(initial_fen),
    !as_white_player,
    [],
    generate_opening_book_from_file("../openings/openings.txt"),
    true,
    5
)


function apply_move!(engine::ChessEngine, move::Move)
    push!(engine.moves, move)
    apply_move!(engine.game_state, move)
end


function play_next_move!(engine::ChessEngine)!
    if engine.is_playing_from_book
        move_uci = sample_opening_book(
            engine.opening_book,
            [move_to_uci(move) for move in engine.moves]
        )

        if move_uci !== nothing
            apply_move!(engine, opening_uci_to_move(move_uci))
            return nothing
        else
            engine.is_playing_from_book = false
        end
    end

    minimax_search!(engine.game_state, engne.search_depth)
    apply_move!(engine, engine.game_state.best_move_from_position)

    return nothing
end


end
