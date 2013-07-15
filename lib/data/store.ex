defmodule Data.Store do

	#defrecordp :state, [avatars: nil, rooms: nil, worlds: nil]

	# API functions
	######################

	def start do
		state = HashDict.new(data: HashDict.new, pids: HashDict.new)
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
		data_store = :erlang.whereis(:data_store)
		if data_store == :undefined do
			Util.Log.debug("Data Store is Undefined!")
			false
		else
			data_store <- {self(), {:persist, type, id, data}}
			sync_return(:persist)
		end
	end

	def register(type, id, pid) do
		data_store = :erlang.whereis(:data_store)
		if data_store == :undefined do
			Util.Log.debug("Data Store is Undefined!")
			false
		else
			caller = self()
			Util.Log.debug("Data Store register(~p, ~p, ~p) called by ~p~n", [type, id, pid, caller])
			data_store <- {caller, {:register, type, id, pid}}
			sync_return(:register)
		end
	end

	def lookup(type, pid) do
		data_store = :erlang.whereis(:data_store)
		if data_store == :undefined do
			Util.Log.debug("Data Store is Undefined!")
			false
		else
			data_store <- {self(), {:lookup, type, pid}}
			sync_return(:lookup)
		end
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
		Util.Log.debug("Data Store is retrieving #{id}")
		data_dict = Dict.get(state, :data)
		type_dict = Dict.get(data_dict, type)
		instance_data = Dict.get(type_dict, id)
		sender <- {:retrieve, instance_data}
		state
	end

	defp handle({:persist, type, id, data}, state, sender) do
		Util.Log.debug("Data Store is persisting #{id}")
		data_dict = Dict.get(state, :data)
		type_dict = Dict.get(data_dict, type)
		if type_dict == nil do
			data_dict = Dict.put(data_dict, type, HashDict.new)
			type_dict = Dict.get(data_dict, type)
		end
		type_dict = Dict.put(type_dict, id, data)
		data_dict = Dict.put(data_dict, type, type_dict)
		sender <- {:persist, :ok}
		Dict.put(state, :data, data_dict)
	end

	defp handle({:register, type, id, pid}, state, sender) do
		Util.Log.debug("Data Store is registering #{id}")
		pid_dict = Dict.get(state, :pids)
		type_dict = Dict.get(pid_dict, type)
		if type_dict == nil do
			pid_dict = Dict.put(pid_dict, type, HashDict.new)
			type_dict = Dict.get(pid_dict, type)
		end
		type_dict = Dict.put(type_dict, :erlang.pid_to_list(pid), id)
		pid_dict = Dict.put(pid_dict, type, type_dict)
		sender <- {:register, :ok}
		Dict.put(state, :pids, pid_dict)
	end

	defp handle({:lookup, type, pid}, state, sender) do
		Util.Log.debug("Data Store is looking up ~p~n", [:erlang.pid_to_list(pid)])
		pid_dict = Dict.get(state, :pids)
		type_dict = Dict.get(pid_dict, type)
		id = Dict.get(type_dict, :erlang.pid_to_list(pid))
		Util.Log.debug("Data Store found ~p~n", [id])
		sender <- {:lookup, id}
		state
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