class_name ProdewtyCraftingStation
extends Node3D

var world: Node
var station_id := "workshop"
var station_label := "Workshop"

func interact(_actor: Node) -> void:
	if world != null and world.has_method("station_interact"):
		world.station_interact(self)
