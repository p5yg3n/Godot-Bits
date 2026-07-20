class_name ItemData
extends Resource

## The unique identifier for this item.
@export var id: String = ""
## The display name of the item.
@export var name: String = ""
## A detailed description of the item.
@export_multiline var description: String = ""
## Categories used for filtering in [InventorySlot].
@export var categories: Array[String] = []
## The icon texture used for UI display.
@export var icon: Texture2D
## The maximum number of this item that can be held in a single stack.
@export_range(1, 999) var max_stack: int = 1
## The rarity tier of the item.
@export var rarity: Rarity = Rarity.COMMON
## The monetary value of the item.
@export var value: int = 0

## Defines the rarity levels for items.
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
