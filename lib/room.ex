defmodule Room do
	use Actor

	# API 
	######################	

	def new(coords, description) when is_tuple(coords) do
		state = HashDict.new([coords: coords, rand: :random.uniform(), description: description, avatar_ids: []])
		start(state)
	end

	def init(state) do
		:random.seed(:erlang.now())
		state
	end

	attribute :coords, :tuple
	attribute :height, :number
	attribute :description, :string
	attribute :rand, :number
	attribute :avatars, :list

	def exit(room_pid, avatar_pid, to_coords), do: sync_call(room_pid, {:exit, avatar_pid, to_coords})
	def enter(room_pid, avatar_pid, from_coords), do: sync_call(room_pid, {:enter, avatar_pid, from_coords})


	# Private
	###############

	defp handle({:exit, avatar, _to_coords}, state, sender) do
		avatars = Dict.get(state, :avatars)
		avatars = List.delete(avatars, avatar) 
		sender <- {:exit, true}
		Dict.put(state, :avatars, avatars)
	end

	defp handle({:enter, avatar, from_coords}, state, sender) do
		avatars = Dict.get(state, :avatars)
		avatars = [avatar | avatars]
		sender <- {:enter, true}
		Dict.put(state, :avatars, avatars)
	end


	# error
	defp handle(_, state, sender) do
		sender <- { :error, :unknown_command }
		state
	end

end