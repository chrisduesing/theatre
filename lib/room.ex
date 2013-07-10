defmodule Room do

	@on_load :seed_random

	defrecordp :state, [id: nil, x: 0, y: 0, height: 0.0, rand: 0.0, description: "", avatar_ids: nil]

	# "Class" API methods
	######################

	def find(id) do
		data = Data.Store.retrieve(:room, id)
		cond do
			data == nil ->
				{:error, :not_found}
			true ->
				#Util.Log.debug(data)
				state = list_to_tuple([Room | Enum.map(data, fn({key, value}) -> value end)])
				start(state)
		end
	end

	def new(x, y, description) do
		state = state(x: x, y: y, rand: :random.uniform(), description: description, avatar_ids: [])
		state = state(state, id: Util.Id.hash(state))
		start(state)
	end

	def start(state) do
		spawn_link(Room, :loop, [state])
	end


	# "Instance" API methods 
	######################

	def save(room_pid) do
		room_pid <- {self(), :save}
		sync_return(:save)
	end

	def id(room_pid) do
		room_pid <- {self(), :id}
		sync_return(:id)
	end

	def coords(room_pid) do
		room_pid <- {self(), :coords}
		sync_return(:coords)
	end

	def height(room_pid) do
		room_pid <- {self(), :height}
		sync_return(:height)
	end

	def update_height(room_pid, height) do
		room_pid <- {self(), {:update_height, height}}
	end

	def description(room_pid) do
		room_pid <- {self(), :description}
		sync_return(:description)
	end

	def rand(room_pid) do
		room_pid <- {self(), :rand}
		sync_return(:rand)
	end

	# exited = Room.exit(old_room, state(state, :id), coords)
	def exit(room_pid, avatar_pid, to_coords) do
		room_pid <- { self(), {:exit, avatar_pid, to_coords} }
		sync_return(:exit)
	end

	# entered = Room.enter(room, state(state, :id), old_coords)
	def enter(room_pid, avatar_pid, from_coords) do
		room_pid <- { self(), {:enter, avatar_pid, from_coords} }
		sync_return(:enter)
	end

	def avatars(room_pid) do
		room_pid <- { self(), :avatars }
		sync_return(:avatars)
	end

	# Private
	###############

	def loop(state) do
		receive do
			{sender, message} ->
				state = handle(message, state, sender)
		end
		loop(state)
	end

	# handlers

	defp handle(:save, state, sender) do
		case Data.Store.persist(:room, state(state, :id), state(state)) do
			:ok ->
				sender <- {:save, true}
			_ ->
				sender <- {:save, false}
		end
		state
	end

	defp handle(:id, state, sender) do
		sender <- {:id, state(state, :id)}
		state
	end

	defp handle(:coords, state, sender) do
		sender <- {:coords, {state(state, :x), state(state, :y)}}
		state
	end

	defp handle(:height, state, sender) do
		sender <- {:height, state(state, :height)}
		state
	end

	defp handle({:update_height, height}, state, _sender) do
		state(state, height: height)
	end

	defp handle(:description, state, sender) do 
		sender <- {:description, state(state, :description)}
		state
	end

	defp handle(:rand, state, sender) do
		sender <- {:rand, state(state, :rand)}
		state
	end

	defp handle({:exit, avatar, _to_coords}, state, sender) do
		avatar_ids = state(state, :avatar_ids)
		avatar_ids = List.delete(avatar_ids, Avatar.id(avatar)) 
		sender <- {:exit, true}
		state(state, avatar_ids: avatar_ids)
	end

	defp handle({:enter, avatar, from_coords}, state, sender) do
		Util.Log.debug("#{inspect avatar} is entering #{inspect self()} from #{inspect from_coords}")
		avatar_ids = state(state, :avatar_ids)
		avatars = [Avitar.id(avatar) | avatar_ids]
		sender <- {:enter, true}
		state(state, avatar_ids: avatar_ids)
	end

	defp handle(:avatars, state, sender) do
		sender <- {:avatars, state(state, :avatar_ids)}
		state
	end

	# error
	defp handle(_, state, sender) do
		sender <- { :error, :unknown_command }
		state
	end
	
	# util
	def seed_random do
		:random.seed(:erlang.now())
		:ok
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