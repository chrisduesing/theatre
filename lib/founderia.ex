defmodule Founderia do

	defrecordp :state, [worlds: nil]

	# API
	###############
	def start do
		state = init()
		spawn_link(Founderia, :loop, [state])
	end

	def home_world do
		:erlang.whereis(:home_world)
	end

	# Private
	################
	defp init do
		home_world = World.Builder.build_world
		:erlang.register(:home_world, home_world)
		state(worlds: [home_world])
	end
	

	def loop(state) do
		start_time = :erlang.now()
		receive do
			message -> 
				IO.puts inspect(message)
				loop(state)
		after 1000 ->
						state = update_npcs(state)
						loop(state)
		end
	end

	defp update_npcs(state) do
		# Avatar.Npcs.wander()
		state
	end

end
