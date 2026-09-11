extends Building

func _ready():
	super()
	
	$Sprite2D.frame = randi()%2
