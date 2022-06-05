module MoveSearch


using ..MoveGeneration
using ..BoardRepresentation
using ..BoardRepresentationUtils
using ..PositionEvaluation


function minimax_search_max(gs::GameState, depth::Int, alpha::Float32, beta::Float32)::Float32
    if depth == 0 
        return count_material_diff(gs)
    end

    moves = generate_legal_moves(gs)
    n_moves = 0

    for move in moves
        n_moves += 1
        apply_move!(gs, move)
        material_score = minimax_search_min(gs, depth-1, alpha, beta)
        move_score = eval_piece_squares(move)
        score = material_score + move_score
        undo_move!(gs, move)
        if score >= beta 
            return beta
        end
        
        if score > alpha
            gs.best_move_from_position = move
            alpha = score
        end
    end

    if n_moves == 0
        if is_white_king_in_check(gs)
            return -Inf32  # black wins
        elseif is_black_king_in_check(gs)
            return Inf32  # white wins
        else
            return 0  # stalemate
        end
    end

   return alpha
end

function minimax_search_min(gs::GameState, depth::Int, alpha::Float32, beta::Float32)::Float32
    if depth == 0 
        return count_material_diff(gs)
    end

    moves = generate_legal_moves(gs)
    n_moves = 0

    for move in moves
        n_moves += 1
        apply_move!(gs, move)
        material_score = minimax_search_min(gs, depth-1, alpha, beta)
        move_score = eval_piece_squares(move)
        score = material_score + move_score
        undo_move!(gs, move)
        if score <= alpha
            return alpha
        end
        
        if score < beta
            gs.best_move_from_position = move
            beta = score
        end
    end

    if n_moves == 0
        if is_white_king_in_check(gs)
            return -Inf32  # black wins
        elseif is_black_king_in_check(gs)
            return Inf32  # white wins
        else
            return 0  # stalemate
        end
    end

    return beta
end


minimax_search!(gs::GameState, depth::Int)::Float32 = minimax_search_max(gs, depth, -Inf32, +Inf32)
export minimax_search!


end
