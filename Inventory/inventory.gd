class_name Inventory
extends Resource

## The maximum number of slots in this inventory.
@export var capacity: int = 20: set = set_capacity
## Array of [InventorySlot] resources.
@export var slots: Array[InventorySlot] = []

func _init() -> void:
	if slots.is_empty(): set_capacity(capacity)

## Updates capacity and ensures all slots are initialized as [InventorySlot] resources.
func set_capacity(new_capacity: int) -> void:
	capacity = maxi(1, new_capacity)
	var old_size := slots.size()
	slots.resize(capacity)
	for i in range(old_size, capacity): slots[i] = InventorySlot.new()
	emit_changed()

## Adds [param amount] of [param item] to the inventory. 
## Returns the number of items that could NOT be added.
func add_item(item: ItemData, amount: int = 1) -> int:
	if amount <= 0 or not item: return amount
	var rem := amount
	# 1. Fill existing stacks
	for slot in slots:
		if slot.item and slot.item.id == item.id:
			rem -= slot.add(item, rem)
			if rem <= 0: break
	# 2. Fill empty slots
	if rem > 0:
		for slot in slots:
			if slot.is_empty():
				rem -= slot.add(item, rem)
				if rem <= 0: break
	if rem < amount: emit_changed()
	return rem

## Returns the total quantity of a specific item by its [param item_id].
func get_item_count(item_id: String) -> int:
	var count := 0
	for slot in slots:
		if slot.item and slot.item.id == item_id:
			count += slot.quantity
	return count

## Returns true if the inventory contains at least one instance of [param item_id].
func has_item(item_id: String) -> bool:
	return slots.any(func(s): return s.item and s.item.id == item_id)

## Removes [param amount] of [param item_id] from the inventory.
## Returns the actual number of items removed.
func remove_item(item_id: String, amount: int) -> int:
	var to_remove := amount
	for slot in slots:
		if slot.item and slot.item.id == item_id:
			to_remove -= slot.remove(to_remove)
			if to_remove <= 0: break
	if to_remove < amount: emit_changed()
	return amount - to_remove
