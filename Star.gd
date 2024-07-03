extends RigidBody2D
class_name Star

var g; # game object

var bigG=  3000

var display_step = 0.1
var max_distance_allowed = 20000	

func _ready():
	g = get_parent()
	
	# set GRAVITY from this object
	$Gravity.gravity = mass*bigG

func _process(_delta):
	# set GRAVITY from this object
	$Gravity.gravity = mass*bigG	

func _on_HeatZone_body_entered(body:RigidBody2D):
	if body.is_in_group('planet'):
		g.logMsg("Damage from Star: "+body.name)
		body.get_node('Sprite2D').modulate = Color(1, .5, .5)
		
		mass += body.mass*0.1
		body.remove_mass_and_resize(body.mass*0.1)

func _on_HeatZone_body_exited(body:RigidBody2D):
	if body.is_in_group('planet'):
		body.get_node('Sprite2D').modulate = Color(1, 1, 1)


