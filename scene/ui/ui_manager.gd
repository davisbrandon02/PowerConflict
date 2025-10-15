class_name UIManager
extends Control

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
	
	if not map_tile.units.is_empty():
		%UnitInfoPanel.visible = true
		var unit: Unit = map_tile.units[0] # Focus on the top unit

		# Assumes Unit inherits 'name' from Entity base class.
		%UnitNameLabel.text = unit.entity_name
		
		# Determine attack value from the equipped weapon (first one in the array).
		var attack_value = "N/A"
		if not unit.weapons.is_empty():
			var equipped_weapon: WeaponType = unit.weapons[0]
			attack_value = str(equipped_weapon.hard_damage)
		
		# Set the main stats line: "Attack: # Defense: # Armor: #"
		%UnitStatsLabel.text = "Attack: %s Defense: %s Armor: %s" % [attack_value, unit.defense, unit.armor]
		
		%WeaponsHeader.visible = true
		
		# Create a detailed list of all weapons the unit possesses.
		var weapon_info = []
		for weapon in unit.weapons:
			# Format: [Name] (S:X/H:Y/AP:Z)
			var info_string = "%s (S:%s/H:%s/AP:%s)" % [weapon.name, weapon.soft_damage, weapon.hard_damage, weapon.armor_piercing]
			weapon_info.append(info_string)
		
		# Join each weapon's info string with a newline for a clean list.
		%WeaponsLabel.text = "\n".join(weapon_info)
	else:
		# Hide the entire unit panel if there are no units
		%UnitInfoPanel.visible = false
