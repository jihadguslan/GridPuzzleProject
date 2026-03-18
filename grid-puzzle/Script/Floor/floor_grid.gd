extends StaticBody3D

enum floor_type{SAFE, BLOCK, DIE}
@export var type_floor = floor_type.SAFE

enum floor_variant{GRASS, STONE, DIRT, WOOD, METAL}
@export var variant_floor = floor_variant.GRASS

@onready var mid_point: Marker3D = $MidPoint
