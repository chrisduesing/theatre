defmodule Data.Store do

  # API functions
  ######################

  def start do
    state = HashDict.new(data_by_id: HashDict.new, id_by_pid: HashDict.new, pid_by_id: HashDict.new, pid_locks: HashDict.new, lock_subscribers: HashDict.new)
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

  def register(type, id, pid, data) do
    data_store = :erlang.whereis(:data_store)
    if data_store == :undefined do
      Util.Log.debug("Data Store is Undefined!")
      false
    else
      caller = self()
      data_store <- {caller, {:register, type, id, pid, data}}
      sync_return(:register)
    end
  end

  def lookup(type, id_or_pid) do
    data_store = :erlang.whereis(:data_store)
    if data_store == :undefined do
      Util.Log.debug("Data Store is Undefined!")
      false
    else
      data_store <- {self(), {:lookup, type, id_or_pid}}
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


  # Handlers
  ################

  defp handle({:retrieve, type, id}, state, sender) do
    data = get_data(state, type, id)
    sender <- {:retrieve, data}
    state
  end

  defp handle({:persist, type, id, data}, state, sender) do
    state = put_data(state, type, id, data) 
    sender <- {:persist, :ok}
    state
  end

  defp handle({:register, type, id, pid, data}, state, sender) do
    state = put_id(state, type, pid, id) 
    state = put_pid(state, type, id, pid) 
    state = put_data(state, type, id, data) 
    lock_subscribers = get_lock_subscribers(state, id)
    Enum.each lock_subscribers, fn(subscriber) -> subscriber <- {:unlocked, pid} end
    state = reset_lock_subscribers(state, id)
    sender <- {:register, :ok}
    state
  end

  defp handle({:lookup, type, pid}, state, sender) when is_pid(pid) do
    id = get_id(state, type, pid)
    sender <- {:lookup, id}
    state
  end

  defp handle({:lookup, type, id}, state, sender) do
    pid = get_pid(state, type, id)
    if :erlang.is_process_alive(pid) do
      sender <- {:lookup, {:ok, pid}}
    else
      if get_pid_lock(state, id) == nil do
        state = put_pid_lock(state, id, sender)
        sender <- {:lookup, {:error, :locking}}
      else
        state = add_lock_subscriber(state, id, sender)
        sender <- {:lookup, {:wait, :locked}}
      end
    end
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

  # Helpers
  ##############

  defp get_data(state, type, id) do
    data_dict = Dict.get(state, :data_by_id)
    type_dict = Dict.get(data_dict, type, HashDict.new)
    Dict.get(type_dict, id)
  end

  defp put_data(state, type, id, data) do
    data_dict = Dict.get(state, :data_by_id)
    type_dict = Dict.get(data_dict, type, HashDict.new)
    type_dict = Dict.put(type_dict, id, data)
    data_dict = Dict.put(data_dict, type, type_dict)
    Dict.put(state, :data_by_id, data_dict)
  end

  defp get_id(state, type, pid) do
    data_dict = Dict.get(state, :id_by_pid)
    type_dict = Dict.get(data_dict, type, HashDict.new)
    Dict.get(type_dict, :erlang.pid_to_list(pid))
  end

  defp put_id(state, type, pid, id) do
    id_dict = Dict.get(state, :id_by_pid)
    type_dict = Dict.get(id_dict, type, HashDict.new)
    type_dict = Dict.put(type_dict, :erlang.pid_to_list(pid), id)
    id_dict = Dict.put(id_dict, type, type_dict)
    Dict.put(state, :id_by_pid, id_dict)
  end

  defp get_pid(state, type, id) do
    data_dict = Dict.get(state, :pid_by_id)
    type_dict = Dict.get(data_dict, type, HashDict.new)
    pid_list = Dict.get(type_dict, id)
    :erlang.list_to_pid(pid_list)
  end

  defp put_pid(state, type, id, pid) do
    pid_dict = Dict.get(state, :pid_by_id)
    type_dict = Dict.get(pid_dict, type, HashDict.new)
    type_dict = Dict.put(type_dict, id, :erlang.pid_to_list(pid))
    pid_dict = Dict.put(pid_dict, type, type_dict)
    Dict.put(state, :pid_by_id, pid_dict)
  end

  defp get_pid_lock(state, id) do
    pid_lock_dict = Dict.get(state, :pid_locks)
    Dict.get(pid_lock_dict, id)
  end

  defp put_pid_lock(state, id, pid) do
    pid_lock_dict = Dict.get(state, :pid_locks)
    pid_lock_dict = Dict.put(pid_lock_dict, id, :erlang.pid_to_list(pid))
    Dict.put(state, :pid_locks, pid_lock_dict)
  end

  defp get_lock_subscribers(state, id) do
    lock_subscribers_dict = Dict.get(state, :lock_subscribers)
    Dict.get(lock_subscribers_dict, id, [])
  end

  defp add_lock_subscriber(state, id, lock_subscriber) do
    lock_subscribers_dict = Dict.get(state, :lock_subscribers)
    lock_subscribers = Dict.get(lock_subscribers_dict, id, [])
    lock_subscribers = [lock_subscriber | lock_subscribers]
    lock_subscribers_dict = Dict.put(lock_subscribers, id, lock_subscribers)
    Dict.put(state, :lock_subscribers, lock_subscribers_dict)
  end

  defp reset_lock_subscribers(state, id) do
    lock_subscribers_dict = Dict.get(state, :lock_subscribers)
    lock_subscribers_dict = Dict.put(lock_subscribers_dict, id, [])
    Dict.put(state, :lock_subscribers, lock_subscribers_dict)
  end

end