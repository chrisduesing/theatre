defmodule Data.Store do

	#defrecordp :state, [avatars: nil, rooms: nil, worlds: nil]

	# API functions
	######################

	def start do
		#state = state(avatars: HashDict.new, rooms: HashDict.new, worlds: HashDict.new)
		state = HashDict.new(avatar: HashDict.new, room: HashDict.new, world: HashDict.new)
		pid = spawn(Data.Store, :loop, [state])
		:erlang.register(:data_store, pid)
	end

	def shutdown do
		pid = :erlang.whereis(:data_store)
		:erlang.exit(pid, :shutdown)
	end

	def retrieve(type, id) do
		:erlang.whereis(:data_store) <- {self(), {:retrieve, type, id}}
		sync_return(:retrieve)
	end

	def persist(type, id, data) do
		:erlang.whereis(:data_store) <- {self(), {:persist, type, id, data}}
		sync_return(:persist)
	end


	# Private functions
	######################

	def loop(state) do
		receive do
			{sender, message} ->
				state = handle(message, state, sender)
		end
		loop(state)
	end


	# handlers
	defp handle({:retrieve, type, id}, state, sender) do
		type_dict = Dict.get(state, type)
		instance_data = Dict.get(type_dict, id)
		sender <- {:retrieve, instance_data}
		state
	end

	defp handle({:persist, type, id, data}, state, sender) do
		type_dict = Dict.get(state, type)
		type_dict = Dict.put(type_dict, id, data)
		sender <- {:persist, :ok}
		Dict.put(state, type, type_dict)
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