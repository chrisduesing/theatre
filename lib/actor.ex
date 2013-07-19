defmodule Actor do

  defmacro __using__(_opts) do
    quote do

      # Module Public API
      #####################
      
      # overridable, must call start
      def new, do: start(HashDict.new)

      # look up data by id
      def find(id) do
        pid = Data.Store.lookup(__MODULE__, id)
        if :erlang.is_process_alive(pid) do
          pid
        else
          data = Data.Store.retrieve(__MODULE__, id)
          cond do
            data == nil ->
              {:error, :not_found}
            true ->
              state = HashDict.new(data)
              start(state)
          end
        end
      end
      
      
      # Instance Public API
      #####################

      def id(pid), do: sync_call(pid, :id)
      def save(pid), do: sync_call(pid, :save)
      def stop(pid), do: :erlang.exit(pid, :kill) 

      # ask to be notified of certain events
      def subscribe(pid, event_type, subscriber), do: sync_call(pid, :add_subscriber, {event_type, subscriber})
      def unsubscribe(pid, event_type, subscriber), do: sync_call(pid, :remove_subscriber, {event_type, subscriber})

      # sending events to just one subscriber
      def notify(pid, event_type, message), do: pid <- {:event, event_type, message, self()}

      # Create Process
      #####################

      defp start(state) do
        state = actor_init(state)
        pid = spawn_link(__MODULE__, :loop, [state])
        id = Dict.get(state, :id)
        Data.Store.register(__MODULE__, id, pid, state)
        pid
      end

      # called by start, can't make private or spawn won't work
      def loop(state) do
        receive do
          {source, message_type, message, sender} when is_pid(sender) ->
            state = handle(source, message_type, message, state, sender)
          error ->
            handle(:unknown, :error, error, state, nil)
        end
        loop(state)
      end

      # Instance Private
      #####################

      defp actor_init(state) do
        if Dict.get(state, :created_at) == nil do
          state = Dict.put(state, :created_at, :erlang.now())
        end
        if Dict.get(state, :id) == nil do
          state = Dict.put(state, :id, Util.Id.hash(state))
        end
        if Dict.get(state, :subscribers) == nil do
          state = Dict.put(state, :subscribers, HashDict.new)
        end
        init(state)
      end

      # overridable, must return state
      defp init(state), do: state

      # Handlers
      ###################

      # save
      defp handle(:api, :save, nil, state, sender) do
        case Data.Store.persist(__MODULE__, Dict.get(state, :id), HashDict.to_list(state)) do
          :ok ->
            sender <- {:save, true}
          _ ->
            sender <- {:save, false}
        end
        state
      end

      # id
      defp handle(:api, :id, nil, state, sender) do
        sender <- {:id, Dict.get(state, :id)}
        state
      end

      defp handle(:api, :add_subscriber, {event_type, subscriber}, state, sender) do
        subscribers = Dict.get(state, :subscribers)
        event_subscribers = Dict.get(subscribers, event_type, [])
        event_subscribers = [subscriber | event_subscribers]
        subscribers = Dict.put(subscribers, event_type, event_subscribers)
        state = Dict.put(state, :subscribers, subscribers)
        sender <- {:add_subscriber, :ok}
        state
      end

      defp handle(:api, :remove_subscriber, {event_type, subscriber}, state, sender) do
        subscribers = Dict.get(state, :subscribers)
        event_subscribers = Dict.get(subscribers, event_type, [])
        event_subscribers = List.delete(event_subscribers, subscriber)
        subscribers = Dict.put(subscribers, event_type, event_subscribers)
        state = Dict.put(state, :subscribers, subscribers)
        sender <- {:remove_subscriber, :ok}
        state
      end

      # Private Utilities
      #########################

      # brodcast to my listeners
      defp broadcast(event_type, message, state) do
        subscribers = Dict.get(state, :subscribers)
        event_subscribers = Dict.get(subscribers, event_type, [])
        Enum.each(event_subscribers, fn(subscriber) -> subscriber <- {:event, event_type, message, self()} end)
      end
      
      # am I alive?
      def ensure(pid) when is_pid(pid) do
        cond do
          :erlang.is_process_alive(pid) ->
            pid
          true ->
            id = Data.Store.lookup(__MODULE__, pid)
            pid = Data.Store.lookup(__MODULE__, id)
            if :erlang.is_process_alive(pid) do
              pid
            else
              find(id)
            end
        end
      end

      # helper for api functions
      # makes synchronous call to appropriate handler
      def sync_call(pid, message_type) do
        sync_call(pid, message_type, nil) 
      end

      def sync_call(pid, message_type, message) do
        async_call(pid, message_type, message)
        sync_return(message_type)
      end

      # makes asynchronous call to appropriate handler
      def async_call(pid, message_type) do
        async_call(pid, message_type, nil) 
      end

      def async_call(pid, message_type, message) do
        pid = ensure(pid)
        pid <- {:api, message_type, message, self()}
      end

      # waits for response from handler and returns it to caller
      defp sync_return(msg_type) do 
        receive do
          {^msg_type, message} ->
            message
        after 1000 ->
                :error
        end
      end

      # implementing class can override these
      defoverridable [new: 0, init: 1]

      # import and include dependancies
      require Actor.Attribute
      import Actor.Attribute

      require Actor.ErrorHandler
      import Actor.ErrorHandler

    end
  end
end

