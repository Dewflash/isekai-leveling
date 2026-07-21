extends SceneTree

const SessionScript = preload("res://scripts/game_session.gd")

func _operational_shell(session: Node) -> String:
	var structure_id := "workshop_001"
	session.structures[structure_id] = {"id": structure_id, "kind": "workshop", "cell": [3, 9], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 36.0, "delivered_materials": {"wood": 12, "stone": 8}}
	session.call("_recalculate_structure_effects")
	return structure_id

func _init() -> void:
	var session := SessionScript.new()
	session.save_slot = "qa_workshop_fitout"
	root.add_child(session)
	var structure_id := _operational_shell(session)
	assert(not session.built["workshop"])
	assert(session.start_workshop_job("plank").is_empty())
	assert(not session.can_place_interior_station(structure_id, "workbench", [NAN, -1]))
	assert(not session.can_place_interior_station(structure_id, "workbench", [-2.5, -1]))
	assert(not session.can_place_interior_station(structure_id, "workbench", [-1, 2]))
	assert(not session.can_place_interior_station("forged_parent", "workbench", [-2, -1]))
	var placed := session.place_interior_station(structure_id, "workbench", [-2, -1], 0, [0, 0])
	assert(str(placed.get("state", "")) == "blueprint")
	assert(not session.can_place_interior_station(structure_id, "workbench", [2, -1]))
	assert(not session.can_place_interior_station(structure_id, "anvil", [-2, -1]))
	assert(session.interior_stations[structure_id].size() == 1)
	assert(session.deliver_interior_station_material(structure_id, str(placed["id"]), "fiber", 1).is_empty())
	session.inventory["wood"] = 4
	session.inventory["stone"] = 2
	var partial := session.deliver_interior_station_material(structure_id, str(placed["id"]), "wood", 4)
	assert(str(partial.get("state", "")) == "blueprint")
	assert(int(session.inventory["wood"]) == 0)
	var assembling := session.deliver_interior_station_material(structure_id, str(placed["id"]), "stone", 2)
	assert(str(assembling.get("state", "")) == "building")
	assert(not session.built["workshop"])
	session.advance_day(session.day + 1)
	assert(str(session.interior_stations[structure_id][placed["id"]]["state"]) == "operational")
	assert(session.built["workshop"])
	# A capability is bound to one parent and one exact station identity.
	session.inventory["wood"] = 3
	session.inventory["stone"] = 1
	var job := session.start_workshop_job("plank", str(placed["id"]), structure_id)
	assert(str(job.get("structure_id", "")) == structure_id)
	assert(str(job.get("station_id", "")) == str(placed["id"]))
	session.advance_day(session.day + 1)
	assert(not session.claim_workshop_job().is_empty())
	assert(session.station_job["structure_id"] == "")
	assert(session.save_game())
	var loaded := SessionScript.new()
	loaded.save_slot = "qa_workshop_fitout"
	root.add_child(loaded)
	assert(loaded.load_game())
	assert(loaded.interior_stations[structure_id][placed["id"]]["state"] == "operational")
	# v24 migration installs a deterministic operational Workbench only for a
	# placed operational shell; it does not create invisible capability on a
	# shell that never existed.
	var legacy_payload: Dictionary = loaded.call("_to_dict")
	legacy_payload["save_version"] = 24
	legacy_payload.erase("interior_stations")
	var migrated: Dictionary = loaded.call("_migrate_payload", legacy_payload)
	assert(migrated.has("interior_stations"))
	assert(not migrated["interior_stations"].get(structure_id, {}).is_empty())
	var forged_payload: Dictionary = legacy_payload.duplicate(true)
	forged_payload["save_version"] = 25
	forged_payload["interior_stations"] = {}
	forged_payload["built"]["workshop"] = true
	assert(not bool(loaded.call("_save_shape_is_supported", forged_payload)))
	var duplicate_station_payload: Dictionary = loaded.call("_to_dict")
	var duplicate_stations: Dictionary = duplicate_station_payload["interior_stations"][structure_id].duplicate(true)
	duplicate_stations["workbench_forged"] = duplicate_stations[placed["id"]].duplicate(true)
	duplicate_stations["workbench_forged"]["id"] = "workbench_forged"
	duplicate_station_payload["interior_stations"][structure_id] = duplicate_stations
	assert(not bool(loaded.call("_save_shape_is_supported", duplicate_station_payload)))
	print("WORKSHOP_FITOUT_TESTS_PASS")
	quit()
