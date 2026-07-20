class_name InventorySlot
extends Resource

## The item data stored in this slot.
@export var item: ItemData: set = set_item
## The current quantity of the item in this slot.
@export var quantity: int = 0: set = set_quantity

## If empty, accepts any item. Otherwise only items matching these categories.
@export var allowed_categories: Array[String] = []

## Returns true if the slot can accept the specified [param new_item].
func accepts_item(new_item: ItemData) -> bool:
	if not new_item: return false
	if allowed_categories.is_empty(): return true
	return new_item.categories.any(func(c): return c in allowed_categories)

## Returns true if the slot is empty or contains no items.
func is_empty() -> bool:
	return item == null or quantity <= 0

## Adds [param amount] of [param new_item] to this slot.
## Returns the number of items successfully added.
func add(new_item: ItemData, amount: int = 1) -> int:
	if not new_item or amount <= 0 or not accepts_item(new_item): return 0
	
	if is_empty():
		item = new_item
		quantity = 0
	elif item.id != new_item.id:
		return 0
	
	var space := item.max_stack - quantity
	var added := mini(amount, space)
	quantity += added
	return added

## Removes [param amount] from this slot and returns the quantity removed.
func remove(amount: int = 1) -> int:
	var removed := mini(amount, quantity)
	quantity -= removed
	return removed

## Clears the slot, removing the item and resetting the quantity.
func clear() -> void:
	item = null
	quantity = 0

# ==============================================================================
# Setters
# ==============================================================================

func set_item(new_item: ItemData) -> void:
	if item == new_item: return
	if new_item and not accepts_item(new_item):
		push_warning("InventorySlot: Item rejected.")
		return
	
	item = new_item
	if item and quantity == 0: quantity = 1
	elif not item: quantity = 0
	emit_changed()

func set_quantity(new_quantity: int) -> void:
	if not item:
		quantity = 0
		return
	
	var old_quantity := quantity
	quantity = clampi(new_quantity, 0, item.max_stack)
	
	if quantity == 0:
		item = null # Triggers set_item logic to clear state
	elif old_quantity != quantity:
		emit_changed()
