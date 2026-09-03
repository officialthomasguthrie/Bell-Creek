extends Node2D
func _ready() -> void:
	if "--host" in OS.get_cmdline_user_args():
		Net.host()
		Net.shout()
		print("PROBE shouting, code=", Net.my_code())
		await get_tree().create_timer(8.0).timeout
	else:
		Net.browse(true)
		await get_tree().create_timer(5.0).timeout
		var out := []
		for ip in Net.found.keys():
			out.append("%s (%s)" % [ip, Net.code_for(ip)])
		print("PROBE found=", out)
	get_tree().quit()
