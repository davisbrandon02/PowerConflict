class_name TacticalOrder
extends Resource

# Represents a command from a player or tactical AI to a unit
enum OrderType {
	ADVANCE,        # Move toward objective, engage enemies
	ASSAULT,        # Aggressive attack on specific target
	DEFEND,         # Hold position, fortify
	FLANK,          # Move to flanking position
	SUPPRESS,       # Provide covering fire
	RETREAT,        # Fall back to safer position
	RECON,          # Scout ahead carefully
	DRONE_STRIKE,   # Call in drone support
	AMBUSH          # Set up ambush position
}

@export var order_type: OrderType
@export var primary_target: Vector2i  # Main objective position
@export var secondary_target: Vector2i  # Optional secondary target
var target_unit: Unit  # Specific unit to engage (no export needed)
@export var aggression_level: float = 0.5  # 0-1 scale
@export var urgency: int = 1  # 1-3 scale (low, medium, high)
@export var expires_in_turns: int = 3  # Order validity duration

func _init(type: OrderType, target_pos: Vector2i, aggression: float = 0.5):
	order_type = type
	primary_target = target_pos
	aggression_level = aggression

func get_order_description() -> String:
	var descriptions = {
		OrderType.ADVANCE: "Advance to position %s",
		OrderType.ASSAULT: "Assault target at %s", 
		OrderType.DEFEND: "Defend position %s",
		OrderType.FLANK: "Flank through %s",
		OrderType.SUPPRESS: "Provide suppressing fire at %s",
		OrderType.RETREAT: "Retreat to %s",
		OrderType.RECON: "Reconnaissance toward %s",
		OrderType.DRONE_STRIKE: "Coordinate drone strike at %s",
		OrderType.AMBUSH: "Set ambush at %s"
	}
	return descriptions[order_type] % [primary_target]

func is_expired(current_turn: int) -> bool:
	return expires_in_turns <= 0

func set_target_unit(unit: Unit):
	target_unit = unit
