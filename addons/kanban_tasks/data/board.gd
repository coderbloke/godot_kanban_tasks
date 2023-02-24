@tool
extends RefCounted

## Manages the loading and saving of other data.


const __UUID := preload("res://addons/kanban_tasks/uuid/uuid.gd")
const __Category := preload("category.gd")
const __Layout := preload("layout.gd")
const __Stage := preload("stage.gd")
const __Task := preload("task.gd")
const __KanbanResource := preload("kanban_resource.gd")

var layout: __Layout
var __categories: Dictionary
var __stages: Dictionary
var __tasks: Dictionary


## Generates a json representation of the board.
func to_json() -> Dictionary:
	var dict := {}

	var category_data := __propagate_uuid_dict(__categories)
	dict["categories"] = category_data

	var stage_data := __propagate_uuid_dict(__stages)
	dict["stages"] = stage_data

	var task_data := __propagate_uuid_dict(__tasks)
	dict["tasks"] = task_data

	dict["layout"] = layout.to_json()

	return dict


## Save the board at `path`.
func save(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Error " + str(FileAccess.get_open_error()) + " while opening file for saving board data at " + path)
		return

	var string := JSON.stringify(to_json(), "\t", false)
	file.store_string(string)


## Initializes the board state from json data.
func from_json(json: Dictionary) -> void:
	__instantiate_uuid_array(json.get("categories", null), __Category, __add_category)
	__instantiate_uuid_array(json.get("stages", null), __Stage, __add_stage)
	__instantiate_uuid_array(json.get("tasks", null), __Task, __add_task)

	layout = __Layout.new([])
	if json.get("layout", null) is Dictionary:
		layout.from_json(json["layout"])
	else:
		push_warning("Loading incomplete board data which is missing layout data.")


## Loads the data from `path` into the current instance.
func load(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Error " + str(FileAccess.get_open_error()) + " while opening file for loading board data at " + path)
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	if err != OK:
		push_error("Error " + str(err) + " while parsing board at " + path + " to json. At line " + str(json.get_error_line()) + " the following problem occured:\n" + json.get_error_message())
		return

	from_json(json.data)


## Adds a category and returns the uuid which is associated with it.
func add_category(category: __Category) -> String:
	return __add_category(category)

## Returns the category associated with the given uuid or `null` if there is none.
func get_category(uuid: String) -> __Category:
	if not __categories.has(uuid) and uuid != "":
		push_warning('There is no category with the uuid "' + uuid + '".')
	return __categories.get(uuid, null)

## Returns the count of categories.
func get_category_count() -> int:
	return len(__categories)

## Returns the uuid's of all categories.
func get_categories() -> Array[String]:
	var temp: Array[String] = []
	temp.assign(__categories.keys())
	return temp

## Removes a category by uuid.
func remove_category(uuid: String) -> void:
	if __categories.has(uuid):
		__categories.erase(uuid)
	else:
		push_warning("Trying to remove uuid wich is not associated with a category.")


## Adds a stage and returns the uuid which is associated with it.
func add_stage(stage: __Stage) -> String:
	return __add_stage(stage)

## Returns the stage associated with the given uuid or `null` if there is none.
func get_stage(uuid: String) -> __Stage:
	if not __stages.has(uuid) and uuid != "":
		push_warning('There is no stage with the uuid "' + uuid + '".')
	return __stages.get(uuid, null)

## Returns the count of stages.
func get_stage_count() -> int:
	return len(__stages)

## Returns the uuid's of all stages.
func get_stages() -> Array[String]:
	return __stages.keys()

## Removes a stage by uuid.
func remove_stage(uuid: String) -> void:
	if __stages.has(uuid):
		__stages.erase(uuid)
	else:
		push_warning("Trying to remove uuid wich is not associated with a stage.")


## Adds a task and returns the uuid which is associated with it.
func add_task(task: __Task) -> String:
	return __add_task(task)

## Returns the task associated with the given uuid or `null` if there is none.
func get_task(uuid: String) -> __Task:
	if not __tasks.has(uuid) and uuid != "":
		push_warning('There is no task with the uuid "' + uuid + '".')
	return __tasks.get(uuid, null)

## Returns the count of tasks.
func get_task_count() -> int:
	return len(__tasks)

## Returns the uuid's of all tasks.
func get_tasks() -> Array[String]:
	var temp: Array[String] = []
	temp.assign(__tasks.keys())
	return temp

## Removes a task by uuid.
func remove_task(uuid: String) -> void:
	if __tasks.has(uuid):
		__tasks.erase(uuid)
	else:
		push_warning("Trying to remove uuid wich is not associated with a task.")


# Internal version of `add_category` which can be provided with an uuid suggestion.
# The uuid that is passed can be altered by the board if it is already used by
# an other category. Therefore always use the returned uuid.
func __add_category(category: __Category, uuid: String = "") -> String:
	if __categories.has(uuid):
		push_warning("The uuid " + uuid + ' is already used. A new one will be generated for the category "' + category.title + '".')

	if uuid == "":
		uuid = __UUID.v4()

	while uuid in __categories.keys():
		uuid = __UUID.v4()

	__categories[uuid] = category
	return uuid


# Internal version of `add_stage` which can be provided with an uuid suggestion.
func __add_stage(stage: __Stage, uuid: String = "") -> String:
	if __stages.has(uuid):
		push_warning("The uuid " + uuid + ' is already used. A new one will be generated for the stage "' + stage.title + '".')

	if uuid == "":
		uuid = __UUID.v4()

	while uuid in __stages.keys():
		uuid = __UUID.v4()

	__stages[uuid] = stage
	return uuid


# Internal version of `add_task` which can be provided with an uuid suggestion.
func __add_task(task: __Task, uuid: String = "") -> String:
	if __tasks.has(uuid):
		push_warning("The uuid " + uuid + ' is already used. A new one will be generated for the task "' + task.title + '".')

	if uuid == "":
		uuid = __UUID.v4()

	while uuid in __tasks.keys():
		uuid = __UUID.v4()

	__tasks[uuid] = task
	return uuid


# HACK: `array` should have the type `Array` but then `null` could not be passed.
func __instantiate_uuid_array(array, type: Script, add_callback: Callable) -> void:
	if array == null:
		push_warning("Loading incomplete board data which is missing data for '" + type.resource_path + "'.")
		return

	for data in array:
		var instance: __KanbanResource = type.new()
		instance.from_json(data)
		add_callback.call(instance, data.get("uuid", ""))


# Converts a dictionary with (uuid, kanban_resource) pairs into a list
# json representations with the uuid added.
func __propagate_uuid_dict(dict: Dictionary) -> Array:
	var res := []
	for key in dict.keys():
		var json: Dictionary = {"uuid": key}
		json.merge(dict[key].to_json())
		res.append(json)
	return res
