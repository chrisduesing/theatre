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
	
	def enter_world(avatar, world, area, room), do: sync_call(avatar, {:enter_world, world, area, room})
	def move(avatar, direction), do: sync_call(avatar, {:move, direction, 1})
	def wear(avatar, location, item), do: sync_call(avatar, {:wear, location, item})


	# Private
	###############

	defp handle({:enter_world, world, area, room}, state, sender) do
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

	defp handle({:move, direction, distance}, state, sender) do
		area = Dict.get(state, :area)
		room = Dict.get(state, :room)
		coords = Room.coords(room)
		new_coords = new_coords(direction, distance, coords)
		new_room = Area.room(area, new_coords)
		if new_room do
			exited = Room.exit(room, self(), new_coords)
			entered = Room.enter(new_room, self(), coords)
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


	defp handle({:wear, location, item}, state, sender) do
		equipment = Dict.get(state, :equipment)
		old_item = Dict.get(equipment, location)
		equipment = Dict.put(equipment, location, item)
		state = Dict.put(state, :equipment, equipment)
		# if old_equipment drop
		state
	end

	# error
	defp handle(_, state, sender) do
		sender <- { :error, :unknown_command }
		state
	end

	# Helpers
	def new_coords(:north, distance, {x, y} = coords), do: {x + distance, y}
	def new_coords(:east,  distance, {x, y} = coords), do: {x, y + distance}
	def new_coords(:south, distance, {x, y} = coords), do: {x - distance, y}
	def new_coords(:west,  distance, {x, y} = coords), do: {x, y - distance}

end