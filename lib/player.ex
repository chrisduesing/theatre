defmodule Player do
	use Actor

	# API
	######################

	attribute :avatar, :pid

	def new(avatar) do
		state = HashDict.new([avatar: avatar])
		start(state)
	end

	def play(player_pid), do: sync_call(player_pid, :play)


	# Private
	###############

	defp handle(:api, :play, nil, state, sender) do
		avatar = Dict.get(state, :avatar)
		Avatar.subscribe(avatar, :room_events, self())
		world = Founderia.main_world
		area = World.main_area(world)
		room = Area.room(area, {0,0})
		Avatar.enter_world(avatar, world, area, room)
		sender <- {:play, :ok}
		state
	end

	defp handle(:event, :room_events, {:room, [description: description, avatars: avatars]}, state, _sender) do
		IO.puts description
		IO.puts "The room has the following occupants:"
		Enum.each avatars, fn(avatar) -> 
													 if Avatar.id(avatar) != Avatar.id(Dict.get(state, :avatar)) do
														 IO.puts Avatar.name(avatar) 
													 end
											 end
		IO.puts ""
		state
	end

	defp handle(:event, :room_events, {:enter, avatar}, state, _sender) do
		name = Avatar.name(avatar)
		IO.puts "#{name} just entered the room."
		state
	end

	defp handle(:event, :room_events, {:exit, avatar}, state, _sender) do
		name = Avatar.name(avatar)
		IO.puts "#{name} just left the room."
		state
	end
		
end