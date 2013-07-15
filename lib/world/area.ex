defmodule World.Area do
	use Actor

	# API methods
	######################

	def new(name) do
		state = HashDict.new([name: name, rooms: HashDict.new])
		start(state)
	end

	attribute :name, :string

	def room(area_pid, coords), do: sync_call(area_pid, {:room, coords})
	def room(area_pid, coords, room_pid), do: sync_call(area_pid, {:room, coords, room_pid})


	# Private
	###############

	defp handle({:room, {x, y}}, state, sender) do
		rooms = Dict.get(state, :rooms)
		room = Dict.get(rooms, {x, y})
		sender <- {:room, room}
		state
	end

	defp handle({:room, {x, y}, room}, state, _sender) do
		rooms = Dict.get(state, :rooms)
		rooms = Dict.put(rooms, {x, y}, room)
		Dict.put(state, :rooms, rooms)
	end

	# error
	defp handle(_, state, sender) do
		sender <- { :error, :unknown_command }
		state
	end

end