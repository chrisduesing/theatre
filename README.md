# Founderia  
A MUD engine, written in Elixir

## Actors
Each actor is a running process, backed by a module that implements Actor. Every interaction between actors works based on pids, rather than an identifier.

### Creation and retrieval
Each model has a .new and .find(id) method, in order to re-constitute relationships to real objects.

### Process death
Due to the reliance on PIDs, if a process dies your handle to an actor is worthless. Actors address this by registering themselves with the storage system when they are created, and each of their api methods calls ensure(pid) to make sure it is alive. If it is not, it does a database lookup and creates a new pid with the same data. This is completely transparent process to the caller. 

One caveat is that the actor holding the reference to the dead pid will keep using it, causing the overhead of a lookup/new process for every call. To address this we need to:  
1) Resolve find to an already living pid, if there is one, rather than creating a new one.  
2) Use the notification system to swap out held reference pids in state behind the scenes.

### Persistence 
Currently Data.Store just keeps everything in a hash. Needs to add at least dets tables to persist across restarts.

ToDo:  
1) Investigate need for data conversion to and from storage, current model data is a nested hashdict.  
2) Consider document store like Riak, ORM mapping sounds horrible.

### A web of living objects
Due to the nature of having live objects that exist with no relationship to queries or requests, there needs to be a good way to find entry points to the objects you want to interact with.

Founderia holds a reference to the main world, which it builds at startup.

World holds a reference to its main area (presumably the outdoors).

Area holds a hashmap reference to its rooms and provides facilities for lookup via coordinates. Origin is always {0, 0}, so that is a safe place to start.

## An example

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

## Developed with no client.
The goal is to have a websocket connection to a Ember based browser client. Because engine is client agnostic, could potentially do traditional telnet as well, or of course native iOS, Android etc.

