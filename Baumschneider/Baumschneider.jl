import BaumschneiderCore.Engine.start_game
import BaumschneiderCore.Engine.push_move!
import BaumschneiderCore.Engine.play_next_move!
import BaumschneiderCore.MoveRepresentationUtils.uci_to_move
import BaumschneiderCore.MoveRepresentationUtils.move_to_uci


function main()

    engine = nothing

    while !eof(stdin)
        command = split(readline(stdin), " ")
        if command[1] == "xboard"
            println("feature done=0")
            println("feature sigint=0 sigterm=0 usermove=1 reuse=1 setboard=1 ics=1 myname=\"Baumschneider\"")
            println("feature done=1")
        elseif command[1] == "new"
            engine = start_game()
        elseif command[1] == "usermove"
            uci_move = command[2]
            move = uci_to_move(engine.game_state, uci_move)
            push_move!(engine, move)
            play_next_move!(engine)
            cpu_move = move_to_uci(last(engine.moves))
            println("move "*cpu_move)
        elseif command[1] == "quit"
            exit()
        end
    end
end

main()
