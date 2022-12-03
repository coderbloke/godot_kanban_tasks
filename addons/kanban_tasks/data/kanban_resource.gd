extends RefCounted

## Base class for kanban tasks data structures.


## Emitted when the resource changed. The properties are updated before emitting.
signal changed()


func _init() -> void:
	pass


## Serializes the object as json.
func to_json() -> Dictionary:
	push_error("Method to_json not implemented.")
	return {}


## Deserializes the object from json.
func from_json(json: Dictionary) -> void:
	push_error("Method from_json not implemented.")
