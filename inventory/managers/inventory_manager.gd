extends Node


## Variables ##
@export var player_data: Player_Data


var inventory_groups: Dictionary = {}
var item_offset = Vector2.ZERO
var is_shop_open = false


## Built-in ##
func _ready():
	add_inventory(player_data.equipment)
	add_inventory(player_data.inventory_left)
	add_inventory(player_data.inventory_right)
	
	%item_void.gui_input.connect(_on_void_gui_input)
	SignalManager.upgrade_item.connect(_on_upgrade_item)


func _input(event: InputEvent):
	if event is InputEventMouseMotion and %item_in_hand.item:
		%item_in_hand.position = %item_in_hand.get_global_mouse_position() - item_offset

## Functions ##

# Set the position of the dragged item.
func set_hand_position(pos):
	set_item_void_filter()
	
	if %item_in_hand:
		%item_in_hand.position = (pos - item_offset)


# Set the control that will catch if you drop an item.
func set_item_void_filter():
	%item_void.mouse_filter = Control.MOUSE_FILTER_STOP if %item_in_hand.item else Control.MOUSE_FILTER_IGNORE


# Return if there is enough space for items in a inventory group.
func has_space_for_items(items_data, group_id):
	var items = ItemManager.get_items(items_data)
	
	for inv in inventory_groups[group_id]:
		items = inv.try_place_stack_items(items)
	
	for inv in inventory_groups[group_id]:
		items = inv.accept_items(items)

	return items.size() <= 0


# Add multiple items to an inventory group.
func add_items(items, group_id):
	for item in items:
		for inv in inventory_groups[group_id]:
			item = inv.add_item(item)
			if item == null: break


# Add an inventory to a group, or create a new group.
func add_inventory(inv) -> void:
	inv.content_changed.connect(_on_inventory_content_changed)
	
	for g in inv.groups:
		if not inventory_groups.has(g):
			inventory_groups[g] = []
		inventory_groups[g].append(inv)


# Gets the inventory in a group, ex: crafting
func get_inventories_from_group(group_id):
	return inventory_groups[group_id]


# Gets the items in the group that can be upgraded
func get_upgradable_items(group_id):
	var valid_items = []

	for i in inventory_groups[group_id]:
		for s in i.slots:
			if s.item and s.item.type == Game_Enums.ITEM_TYPE.EQUIPMENT and s.item.rarity < Game_Enums.RARITY.RARE:
				valid_items.append(s.item)

	return valid_items

# Return if the inventory group contains upgradable items.
func has_upgradable_items(group_id):
	for i in inventory_groups[group_id]:
		if i.has_upgradable_items:
			return true

	return false


# Return if the items_data are present in the inventory group.
func has_items(items_data, group_id) -> bool:
	for item_data in items_data:
		if get_item_count(item_data.id, group_id) < item_data.quantity:
			return false

	return true


# Return the the quantity of item_id contained in the inventory group.
func get_item_count(id, group_id) -> int:
	var count = 0

	for inv in inventory_groups[group_id]:
		count += inv.get_item_count(id)

	return count


# Remove the items from the inventory groups.
func remove_items(items, group_id) -> void:
	for item in items:
		for inv in inventory_groups[group_id]:
			item.quantity = inv.remove_item_quantity(item.id, item.quantity)
			if item.quantity == 0: break


# Return the Inventory from it's name.
func get_inventory_by_name(inv_name):
	if inv_name == "Equipment":
		return player_data.equipment

	if inv_name == "Left Pocket":
		return player_data.inventory_left

	if inv_name == "Right Pocket":
		return player_data.inventory_right


# Split the item stack in the slot.
func split(slot_node, event_position):
	var quantity = ceil(slot_node.slot.item.quantity / 2)
	slot_node.slot.item.quantity -= quantity
	var new_item = ItemManager.get_item(slot_node.slot.item.id)
	new_item.quantity = quantity
	%item_in_hand.item = new_item
	set_hand_position(event_position)


# When an item is clicked in the void, drop it.
func _on_void_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SignalManager.item_dropped.emit(%item_in_hand.item)
		%item_in_hand.item = null
		set_item_void_filter()


# Show item info when mouse hover.
func _on_mouse_entered_slot(slot_node):
	if slot_node.slot.item:
		%item_info.display(slot_node)


# Hide the item info.
func _on_mouse_exited_slot():
	%item_info.hide()


# Detect and process the differenet clicks on an inventory slot node.
# Shift + Right Click = Split the stack.
# Left Click = Pick up / Place Items.
# Right Click = Open Action Menu.
func _on_gui_input_slot(event: InputEvent, slot_node: Inventory_Slot_Node):
	var event_position = %item_in_hand.get_global_mouse_position()
	var slot = slot_node.slot

	if slot.item and slot.item.quantity > 1 and %item_in_hand.item == null and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and Input.is_key_pressed(KEY_SHIFT):
		split(slot_node, event_position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var had_empty_hand = %item_in_hand.item == null

			%item_in_hand.item = slot.put_item(%item_in_hand.item)

			if %item_in_hand.item and had_empty_hand:
				item_offset = event_position - slot_node.global_position

			set_hand_position(event_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and slot.item:
			%item_action_menu.display(slot_node)
		elif event.button_index == MOUSE_BUTTON_RIGHT and slot.item and slot.item.components.has("usable"):
			slot.item.components.usable.use()

	if slot.item:
		slot_node.mouse_entered.emit()
	else:
		slot_node.mouse_exited.emit()


# Emit a signal when the content of an inventory has changed.
# Ex: Enable the craft button if the crafting inventories has the required items.
func _on_inventory_content_changed(groups):
	SignalManager.inventory_group_content_changed.emit(groups)


# Upgrade an item on the player.
# Normal -> Magic -> Rare.
func _on_upgrade_item():
	var valid_items = get_upgradable_items("player")
	valid_items.shuffle()

	var item = valid_items[0]

	ItemManager.generate_rarity(item, item.level, item.rarity + 1)
	item.slot.item_changed.emit()
