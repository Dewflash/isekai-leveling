class_name ProdewtyResourcePickup
extends Node3D

## A field drop is a real expedition state, not a presentation-only reward.
## GameSession owns the amount and persistence; this node only exposes the
## nearby interaction and updates its readable world label.

var world: Node
var pickup_id := ""
var node_id := ""
var resource_id := "wood"
var resource_label := "Wood"
var discovery_id := ""
var amount := 1

func interact(_actor: Node) -> void:
	if world != null and world.has_method("collect_expedition_pickup"):
		world.collect_expedition_pickup(self)

func set_amount(value: int) -> void:
	amount = maxi(0, value)
	_refresh_label()

func _ready() -> void:
	_refresh_label()

func _refresh_label() -> void:
	var label := get_node_or_null("PickupLabel") as Label3D
	if label != null:
		label.text = "%s  x%d" % [resource_label.to_upper(), amount]
