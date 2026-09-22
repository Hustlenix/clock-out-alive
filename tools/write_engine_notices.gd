extends SceneTree

func _initialize() -> void:
	var file = FileAccess.open("res://GODOT_NOTICES.txt", FileAccess.WRITE)
	file.store_string("Godot " + Engine.get_version_info().string + "\n\n" + Engine.get_license_text() + "\n\n")
	for component in Engine.get_copyright_info():
		file.store_string(str(component.name) + "\n")
		for part in component.parts:
			file.store_string("Files: " + ", ".join(part.files) + "\n")
			file.store_string("Copyright: " + "; ".join(part.copyright) + "\nLicense: " + str(part.license) + "\n")
		file.store_string("\n")
	var licenses = Engine.get_license_info()
	for name in licenses:
		file.store_string(str(name) + "\n" + str(licenses[name]) + "\n\n")
	file.close()
	quit()
