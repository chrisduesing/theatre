defmodule Room do

	@on_load :seed_random

	defrecordp :state, [x: 0, y: 0, height: 0.0, rand: 0.0, description: "", avatars: nil]

	# api 
	############

	def start(x, y, description) do
		state = state(x: x, y: y, rand: :random.uniform(), description: description, avatars: [])
		spawn_link(Room, :loop, [state])
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
		avatars = state(state, :avatars)
		avatars = List.delete(avatars, avatar) 
		sender <- {:exit, true}
		state(state, avatars: avatars)
	end

	defp handle({:enter, avatar, from_coords}, state, sender) do
		Util.Log.debug("#{inspect avatar} is entering #{inspect self()} from #{inspect from_coords}")
		avatars = state(state, :avatars)
		avatars = [avatar | avatars]
		sender <- {:enter, true}
		state(state, avatars: avatars)
	end

	defp handle(:avatars, state, sender) do
		sender <- {:avatars, state(state, :avatars)}
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