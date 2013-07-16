defmodule World.Builder do
	import Math.Perlin

	def build_world do
		world = World.new("The World")
		area = Area.new("Outside")
		create_rooms(area)
		World.main_area(world, area)
		world
	end

	defp create_rooms(area) do
		grid_bottom = -4
		grid_top = 4
		coord_list = Enum.to_list(grid_bottom .. grid_top)
		lc x inlist coord_list, y inlist coord_list do
			room = Room.new({x, y}, room_description(x, y))
			Room.height(room, noise_2d(x, y))
			Area.room(area, {x, y}, room)
		end
	end

	defp room_description(x, y) do
		"Room at #{x}, #{y}"
	end

end