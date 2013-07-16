# Founderia

a game

*** TODO: consistency!

Right now there are no ids, but I am passing rooms by location and everything else by pid

Proposed Solution:

All functions take pids, but references between objects store ids (room.avatars == list of avatar_ids)

Each type has a .find(id) method, in order to re-constitute relationships to real objects

Some kind of persistence, though it would be nice to just use ets or something for now, it can go away at restart

World can serve as the lookup point for live processes, translate things like coords to rooms

# An example

	def test do
		# get the world, area and a room
		world = Founderia.main_world
		area = World.main_area(world)
		room = Area.room(area, {0,0})
		
		# create a couple NPCs
		avatar1 = Avatar.new("Avatar 1")
		avatar2 = Avatar.new("Avatar 2")

		# add them to the world
		Avatar.enter_world(avatar1, world, area, room)
		Avatar.enter_world(avatar2, world, area, room)

		# create a player's avatar
		firedrake = Avatar.new("Firedrake")
		player = Player.new

		# assign the avatar to the player
		# and enter the world
		Player.play(player, firedrake, world, area, room)

		# make a npc walk around
		Avatar.move(avatar2, :south)
		Avatar.move(avatar2, :north)
	end

iex(1)> Founderia.test  
Room at 0, 0  
The room has the following occupants:  
Avatar 2  
Avatar 1  

Avatar 2 just left the room.  
Avatar 2 just entered the room.  
