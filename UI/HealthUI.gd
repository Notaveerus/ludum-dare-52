extends Control

var hearts = 4 setget set_hearts
var max_hearts = 4 setget set_max_hearts

onready var heartUIFull = $HeartUIFull
onready var heartUIEmpty = $HeartUIEmpty
onready var partsCounter = $PartsCounter

func set_hearts(value):
	hearts = clamp(value, 0, max_hearts)
	if heartUIFull:
		heartUIFull.rect_size.x = hearts * 16
	
func set_max_hearts(value):
	max_hearts = max(value, 1)
	if heartUIEmpty:
		heartUIEmpty.rect_size.x = max_hearts * 16

func set_parts(value):
	if partsCounter:
		partsCounter.text = str(value)

func _ready():
	self.max_hearts = PlayerStats.max_health
	self.hearts = PlayerStats.health
	PlayerStats.connect("health_changed", self,"set_hearts")
	PlayerStats.connect("max_health_changed",self,"set_max_hearts")
	PlayerStats.connect("parts_harvested_changed",self, "set_parts")
	
