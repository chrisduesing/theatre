defmodule Util.Log do

	def debug(x) do 
    :io_lib.format("~p", [x])
    |> :lists.flatten
    |> :erlang.list_to_binary
		|> IO.puts
	end

end