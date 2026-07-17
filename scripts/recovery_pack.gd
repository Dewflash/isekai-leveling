class_name ProdewtyRecoveryPack
extends Node3D

var world: Node
var loot: Dictionary = {}
var pack_id := ""
var zone_id := ""
var depleted := false

func interact(_actor: Node) -> void:
	if depleted:
		return
	if world != null and world.has_method("recover_loot") and world.recover_loot(pack_id):
		depleted = true
		visible = false
		queue_free()
