defmodule Founderia do

	defrecordp :state, [world: nil]

	# API
	###############
	def start do
		state = init()
		spawn_link(Founderia, :loop, [state])
	end

	# Private
	################
	defp init do
		state(world: World.Builder.build_world)
	end
	

	defp loop(state) do
		start_time = :erlang.now()
		state = update_npcs(state)
		loop(state)
	end

	defp update_npcs(state) do
		# Avatar.Npcs.wander()
		state
	end

end
