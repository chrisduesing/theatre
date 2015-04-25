defmodule 3d do

  def volume(item) when is_record(item, Item) do
    item.width * item.height * item.depth
  end

end