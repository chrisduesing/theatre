defmodule Avatar do

	defrecordp :state, [id: nil, name: nil, wounds: nil, coords: nil, equipment: nil, inventory: nil, created_at: nil]

	# api 
	############

	def start(name) do
		equipment = HashDict.new([head: nil, torso: nil, arms: nil, legs: nil, feet: nil, held: nil]) #items
		inventory = HashDict.new([back: nil, belt: nil, carried: nil]) # containers
		state = state(name: name, coords: nil, equipment: equipment, inventory: inventory, created_at: :erlang.now())
		state = state(state, id: Util.Id.hash(state))
		spawn_link(Avatar, :loop, [state])
	end

	def id(avatar_pid) do
		avatar_pid <- {self(), :id}
		sync_return(:id)
	end

	def name(avatar_pid) do
		avatar_pid <- {self(), :name}
		sync_return(:name)
	end

	def coords(avatar_pid) do
		avatar_pid <- {self(), :coords}
		sync_return(:coords)
	end

	def enter_world(avatar_pid, world_pid, coords) do
		avatar_pid <- {self(), {:enter_world, world_pid, coords}}
		sync_return(:enter_world)
	end

	def move(avatar_pid, world_pid, coords) do
		avatar_pid <- {self(), {:move, world_pid, coords}}
		sync_return(:move)
	end

	def wear(avatar_pid, location, item) do
		avatar_pid <- {self(), {:wear, location, item}}
	end

	def equipment(avatar_pid) do
		avatar_pid <- {self(), :equipment}
		sync_return(:equipment)
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
	defp handle(:id, state, sender) do
		sender <- {:id, state(state, :id)}
		state
	end

	defp handle(:name, state, sender) do
		sender <- {:name, state(state, :name)}
		state
	end

	defp handle(:coords, state, sender) do
		sender <- {:coords, state(state, :coords)}
		state
	end

	defp handle(:equipment, state, sender) do
		sender <- {:equipment, state(state, :equipment)}
		state
	end

	defp handle({:wear, location, item}, state, sender) do
		equipment = state(state, :equipment)
		old_item = Dict.get(equipment, location)
		equipment = Dict.put(equipment, location, item)
		state = state(state, equipment: equipment)
		# if old_equipment drop
		state
	end

	defp handle({:enter_world, world, coords}, state, sender) do
		room = World.room(world, coords)
		if room do
			entered = Room.enter(room, self(), nil)
			if entered do
				state = state(state, coords: coords)
				sender <- {:enter_world, coords}
				state
			else
				sender <- {:enter_world, {:error, :could_not_enter_room}}
				state
			end
		else
			sender <- {:enter_world, {:error, :no_such_room}}
			state
		end
	end

	defp handle({:move, world, coords}, state, sender) do
		old_coords = state(state, :coords)
		old_room = World.room(world, old_coords)
		room = World.room(world, coords)
		Util.Log.debug("#{inspect sender} that #{inspect self()} entered #{inspect room} at #{inspect coords}")
		if is_pid(old_room) && is_pid(room) do
			exited = Room.exit(old_room, self(), coords)
			entered = Room.enter(room, self(), old_coords)
			if exited && entered do
				state = state(state, coords: coords)
				sender <- {:move, state(state, :coords)}
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

	# error
	defp handle(_, state, sender) do
		sender <- { :error, :unknown_command }
		state
	end

	defp sync_return(msg_type) do 
		receive do
			{^msg_type, message} ->
				message
		after 1000 ->
						:error
		end
	end


end