defmodule Actor do

  defmacro __using__(_opts) do
    quote do

			def new do
				start(HashDict.new)
			end

			def start(state) do
				state = actor_init(state)
				pid = spawn_link(__MODULE__, :loop, [state])
				Data.Store.register(__MODULE__, Dict.get(state, :id), pid)
				pid
			end

			defp actor_init(state) do
				if Dict.get(state, :created_at) == nil do
					state = Dict.put(state, :created_at, :erlang.now())
				end
				if Dict.get(state, :id) == nil do
					state = Dict.put(state, :id, Util.Id.hash(state))
				end
				init(state)
			end

			defp init(state) do
				state
			end

      def loop(state) do
				receive do
					{sender, message} ->
						state = handle(message, state, sender)
				end
				loop(state)
			end

			def save(pid) do
				pid <- {self(), :save}
				sync_return(:save)
			end

			def stop(pid) do
				:erlang.exit(pid, :kill) 
			end

			defp handle(:save, state, sender) do
				case Data.Store.persist(__MODULE__, Dict.get(state, :id), HashDict.to_list(state)) do
					:ok ->
						sender <- {:save, true}
					_ ->
						sender <- {:save, false}
				end
				state
			end

			def id(pid) do
				sync_call(pid, :id)
			end

			defp handle(:id, state, sender) do
				sender <- {:id, Dict.get(state, :id)}
				state
			end

			def find(id) do
				data = Data.Store.retrieve(__MODULE__, id)
				cond do
					data == nil ->
						{:error, :not_found}
					true ->
						state = HashDict.new(data)
						start(state)
				end
			end

			def ensure(pid) do
				if :erlang.is_process_alive(pid) do
					pid
				else
					id = Data.Store.lookup(__MODULE__, pid)
					find(id)
				end
			end

			def sync_call(pid, data) do
				msg_type = data
				if :erlang.is_tuple(msg_type) do
					[msg_type | rest] = :erlang.tuple_to_list(data)
				end
				async_call(pid, data)
				sync_return(msg_type)
			end

			def async_call(pid, data) do
				pid = ensure(pid)
				pid <- {self(), data}
			end

			defp sync_return(msg_type) do 
				receive do
					{^msg_type, message} ->
						message
				after 1000 ->
								:error
				end
			end

      defoverridable [new: 0, init: 1]

			require Actor.Attribute
			import Actor.Attribute

    end
  end
end

