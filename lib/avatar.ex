defmodule Avatar do
	use Actor

	# API
	######################

	def new(name) do
		equipment = HashDict.new([head: nil, torso: nil, arms: nil, legs: nil, feet: nil, held: nil]) #items
		inventory = HashDict.new([back: nil, belt: nil, carried: nil]) # containers
		state = HashDict.new([name: name, world: nil, area: nil, room: nil, equipment: equipment, inventory: inventory, wounds: []])
		start(state)
	end

	attribute :name, :string
	attribute :world, :pid
	attribute :area, :pid
	attribute :room, :pid
	attribute :wounds, :list
	attribute :inventory, :tuple
	attribute :equipment, :tuple
	
	def enter_world(avatar, world, area, room), do: sync_call(avatar, :enter_world, {world, area, room})
	def move(avatar, direction), do: sync_call(avatar, :move, {direction, 1})
	def wear(avatar, location, item), do: sync_call(avatar, :wear, {location, item})


	# Private
	###############

	defp handle(:api, :enter_world, {world, area, room}, state, sender) do
		entered = Room.enter(room, self(), nil)
		if entered do
			state = Dict.put(state, :world, world)
			state = Dict.put(state, :area, area)
			state = Dict.put(state, :room, room)
			sender <- {:enter_world, self()}
			state
		else
			sender <- {:enter_world, {:error, :could_not_enter_room}}
			state
		end
	end

	defp handle(:api, :move, {direction, distance}, state, sender) do
		area = Dict.get(state, :area)
		room = Dict.get(state, :room)
		coords = Room.coords(room)
		new_coords = new_coords(direction, distance, coords)
		new_room = Area.room(area, new_coords)
		if new_room do
			Room.unsubscribe(room, :room_events, self())
			exited = Room.exit(room, self(), new_coords)
			entered = Room.enter(new_room, self(), coords)
			Room.subscribe(new_room, :room_events, self())
			if exited && entered do
				state = Dict.put(state, :room, new_room)
				sender <- {:move, self()}
				state
			else
				sender <- {:move, {:error, :could_not_go_there}}
				state
			end
		else
			sender <- {:error, :no_such_room}
			state
		end
	end


	defp handle(:api, :wear, {location, item}, state, _sender) do
		equipment = Dict.get(state, :equipment)
		_old_item = Dict.get(equipment, location)
		equipment = Dict.put(equipment, location, item)
		state = Dict.put(state, :equipment, equipment)
		# if old_equipment drop
		state
	end

	defp handle(:event, :room_events, message, state, _sender) do
		IO.puts "The room I am in just told me #{ inspect message}"
		state
	end

	# error
	handle_unknown

	# Helpers
	def new_coords(:north, distance, {x, y}), do: {x + distance, y}
	def new_coords(:east,  distance, {x, y}), do: {x, y + distance}
	def new_coords(:south, distance, {x, y}), do: {x - distance, y}
	def new_coords(:west,  distance, {x, y}), do: {x, y - distance}

end