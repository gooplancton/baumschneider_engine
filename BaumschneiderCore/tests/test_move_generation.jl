import BaumschneiderCore.MoveGeneration.generate_legal_moves
import BaumschneiderCore.ChessConstants.initial_fen
import BaumschneiderCore.BoardRepresentationUtils.fen_to_gamestate
import BaumschneiderCore.BoardRepresentationUtils.apply_move!
import BaumschneiderCore.BoardRepresentationUtils.undo_move!
import BaumschneiderCore.BoardRepresentation.GameState


moves_for_ply = Dict()
gs = fen_to_gamestate(initial_fen)

function count_moves(gs::GameState, moves_for_ply::Dict, ply::Int, max_ply::Int)
    if ply > max_ply
        return
    end

    moves = collect(generate_legal_moves(gs))

    for move in moves
        moves_for_ply[ply] += 1
        apply_move!(gs, move)
        count_moves(gs, moves_for_ply, ply+1, max_ply)
        undo_move!(gs, move)
    end
end

count_moves(gs, moves_for_ply, 1, 8)
print(moves_for_ply)

