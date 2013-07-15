defmodule Founderia do
	use Application.Behaviour

	defrecordp :state, [worlds: nil]

	# API
	###############
	def start(_type, _args) do
		state = init()
		pid = spawn_link(Founderia, :loop, [state])
		:erlang.register(:founderia, pid)
		{:ok, pid}
	end

	def founderia do
		:erlang.whereis(:founderia)
	end

	def home_world do
		:erlang.whereis(:home_world)
	end

	# Private
	################
	defp init do
		Data.Store.start
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
