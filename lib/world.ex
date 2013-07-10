defmodule World do
	
	defrecordp :state, [rooms: HashDict.new]

	# api 
	############

	def start do
		state = state()
		spawn_link(World, :loop, [state])
	end

	def room(world_pid, coords) do
		world_pid <- {self, {:room, coords}}
		sync_return(:room)
	end

	def add_room(world_pid, coords, room_pid) do
		world_pid <- {self, {:add_room, coords, room_pid}}
	end

	# private
	###############

	def loop(state) do
		receive do
			{sender, message} ->
				state = handle(message, state, sender)
		end
		loop(state)
	end

	# handlers
	defp handle({:room, {x, y}}, state, sender) do
		sender <- {:room, Dict.get(state(state, :rooms), {x, y})}
		state
	end

	defp handle({:add_room, {x, y}, room}, state, _sender) do
		rooms = Dict.put(state(state, :rooms), {x, y}, room)
		state(state, rooms: rooms)
	end

	# error
	defp handle(_, state, sender) do
		sender <- { :error, :unknown_command }
		state
	end

	# util
	defp sync_return(msg_type) do 
		receive do
			{^msg_type, message} ->
				message
		after 1000 ->
						:error
		end
	end

end


