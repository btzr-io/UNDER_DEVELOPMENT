extends Node2D

var connections = []
var _connections = Utils.Connection_manager.new()

onready var line_connection_scene = preload("res://scenes/Line_connection.tscn")

func connect_target(target, origin):
	_connections.add(target.name, origin.name)
	
func disconnect_target(target, origin):
	_connections.remove(target, origin)


func destroy_connections():
	Utils.remove_all_children($Input)
	Utils.remove_all_children($output)

func render_connections(target_parent, connections):
	pass
	
func _old_render_connections(target_parent, connections):
	Utils.remove_all_children(target_parent)
	for connection_origin in connections:
		var new_connection = line_connection_scene.instance()
		new_connection.single_line = true
		new_connection.modulate.a = 0.5
		new_connection.connect_target(LM.selected_entity, connection_origin)
		target_parent.call_deferred("add_child", new_connection)


func render_input_connections():
	render_connections($Input, LM.selected_entity )
