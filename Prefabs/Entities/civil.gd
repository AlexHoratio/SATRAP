extends Building

func _ready():
	super()
	$Sprite2D.frame = randi()%3

func _process(delta: float):
	super(delta)
