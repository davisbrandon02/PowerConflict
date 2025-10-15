class_name UIManager
extends Control

@export var action_manager: ActionManager

# This function updates the entire UI based on the data of a single map tile.
func show_tile_information(map_tile: MapManager.MapTile):
	# Safety check: If the tile data is invalid, hide both panels.
	if not is_instance_valid(map_tile):
		%UnitInfoPanel.visible = false
		%TileInfoPanel.visible = false
		return

	# --------------------------------------------------------------------------
	# --- Handle Ground and Obstacle Information (TileInfoPanel) ---
	# --------------------------------------------------------------------------
	
	%TileInfoPanel.visible = true
	
	# Display Ground Information
	if map_tile.ground != null:
		%GroundTypeLabel.text = map_tile.ground.name
		# GroundType has no combat stats, so we hide the stats label.
		%GroundStatsLabel.visible = false
	
	# Display Obstacle Information
	if map_tile.obstacle != null:
		%ObstacleNameLabel.visible = true
		%ObstacleStatsLabel.visible = true
		
		var obstacle: Obstacle = map_tile.obstacle
		
		# Assumes 'Entity' base class has a get_health_percentage() method.
		var hp_percent = round(obstacle.get_health_percentage() * 100.0) if obstacle.has_method("get_health_percentage") else 100
		
		# Set the name and HP (e.g., "Forest (75%)")
		%ObstacleNameLabel.text = "%s (%s%%)" % [obstacle.obstacle_name, hp_percent]
		
		# Display multipliers as a percentage difference (e.g., "+0%", "+50%")
		var attack_mod_text = "%+.0f%%" % ((obstacle.attack_multiplier - 1.0) * 100.0)
		var defense_mod_text = "%+.0f%%" % ((obstacle.defense_multiplier - 1.0) * 100.0)
		
		%ObstacleStatsLabel.text = "Attack: %s Defense: %s" % [attack_mod_text, defense_mod_text]
	else:
		# Hide obstacle specific labels if the tile is clear
		%ObstacleNameLabel.visible = false
		%ObstacleStatsLabel.visible = false


	# --------------------------------------------------------------------------
	# --- Handle Unit Information (UnitInfoPanel) ---
	# --------------------------------------------------------------------------
	
	if map_tile.unit != null:
		%UnitInfoPanel.visible = true
		var unit: Unit = map_tile.unit
		
		# Set unit name
		%UnitNameLabel.text = unit.entity_name
		
		# Set the main stats line: "Initiative: # Defense: # Armor: #"
		%UnitStatsLabel.text = "Initiative: %s Defense: %s Armor: %s" % [unit.initiative, unit.defense, unit.armor]
		
		%WeaponsHeader.visible = true
		
		# Create a detailed list of all weapons the unit possesses.
		var weapon_info = []
		for weapon in unit.weapons:
			var info_string = "%s  " % weapon.name
			weapon_info.append(info_string)
		
		# Join each weapon's info string with a newline for a clean list.
		%WeaponsLabel.text = "\n".join(weapon_info)
	else:
		# Hide the entire unit panel if there are no units
		%UnitInfoPanel.visible = false

# This function sets and makes the controls visible for the active player-controlled unit.
func show_unit_controls(unit: Unit):
	# Show the control panel
	%ControlPanel.visible = true
	
	# Update weapon buttons based on available weapons
	if unit.weapons.size() > 0:
		%WeaponButton1.text = "%s (1)\nS: %s | H: %s | P: %s" % [unit.weapons[0].name, unit.weapons[0].soft_damage, unit.weapons[0].hard_damage, unit.weapons[0].armor_piercing]
		%WeaponButton1.visible = true
	else:
		%WeaponButton1.visible = false
	
	if unit.weapons.size() > 1:
		%WeaponButton2.text = "%s (2)\nS: %s | H: %s | P: %s" % [unit.weapons[1].name, unit.weapons[1].soft_damage, unit.weapons[1].hard_damage, unit.weapons[1].armor_piercing]
		%WeaponButton2.visible = true
	else:
		%WeaponButton2.visible = false
	
	# Enable the End Turn button
	%EndTurnButton.visible = true
	%EndTurnButton.disabled = false

# Hide controls when no player unit is active
func hide_unit_controls():
	%ControlPanel.visible = false
	%EndTurnButton.visible = false

# Called when the End Turn button is pressed
func _on_end_turn_button_pressed():
	print("UI: End Turn button pressed")
	if action_manager:
		action_manager.end_current_turn()
	else:
		print("UI ERROR: ActionManager not connected to UIManager")

# Input handling for keyboard shortcuts
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:  # End Turn
				if %EndTurnButton.visible and not %EndTurnButton.disabled:
					_on_end_turn_button_pressed()
			KEY_M:  # Move
				print("Move command (M) pressed")
				# Implement move mode
			KEY_Q:  # Attack
				print("Attack command (Q) pressed") 
				# Implement attack mode
			KEY_F:  # Hurry
				print("Hurry command (F) pressed")
				# Implement hurry action
			KEY_R:  # Reverse
				print("Reverse command (R) pressed")
				# Implement reverse facing
