class_name ProdewtyFarmPlot
extends Node3D

var world: Node
var plot_id := "sanctuary_plot_01"
var state := "empty"
var crop := "wheat"
var growth := 0
var watered := false

func interact(_actor: Node) -> void:
	if world != null and world.has_method("farm_plot_interact"):
		world.farm_plot_interact(self)

func sync_from_session(data: Dictionary) -> void:
	state = str(data.get("state", "empty"))
	crop = str(data.get("crop", "wheat"))
	growth = int(data.get("growth", 0))
	watered = bool(data.get("watered", false))

func to_dict() -> Dictionary:
	return {"state": state, "crop": crop, "growth": growth, "watered": watered}
