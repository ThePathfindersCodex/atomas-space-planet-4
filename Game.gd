extends Node2D

var bigG=  3000

var max_planets=25

var planetSceneTemplate = preload("res://Planet.tscn")
var display_step = 0.1
var new_planet_start_mass = 10

var zoomLevel = .5
var zoomLevelIncrement = .025
var zoomLevelCamera = 0
var zoomMinVal  = .010
var zoomMaxVal  = 0.75

func _ready():
#	Engine.time_scale =  0.25
	$CanvasLayer/labelTimeScale.text = str(Engine.time_scale)
	
	# set initial estimated veloc for each starting planet based on distance to star
	for member in get_tree().get_nodes_in_group("planet"):
		member.g = self
		#member.apply_impulse(circle_orbit($Star,member), Vector2.ZERO) 		
		member.linear_velocity = circle_orbit($Star,member)	
	
	zoomLevelCamera = dynamic_zoom_level(zoomLevel)
	$Camera2D.zoom = Vector2(zoomLevelCamera,zoomLevelCamera)
	
func dynamic_width_zoom(zoom):
	var mult= 1
	if ( zoom >.7 ):
		mult= 4
	elif ( zoom <= .7 && zoom > .3 ):
		mult= 8
	elif ( zoom <= .3 && zoom > .2 ):
		mult= 16
	elif ( zoom <= .2 && zoom > .1 ):
		mult= 32
	elif ( zoom <= .1 && zoom > .05 ):
		mult= 64
	elif ( zoom < .05 ):
		mult= 128
	return mult * pow(2, zoom)

func dynamic_zoom_level(z):
	#return remap(z,zoomMinVal,zoomMaxVal,0,1)
	return remap(z,0,1,zoomMinVal,zoomMaxVal)

func zoomIn():
	zoomLevel += zoomLevelIncrement
	if zoomMaxVal < zoomLevel:
		zoomLevel = zoomMaxVal
	zoomLevelCamera = dynamic_zoom_level(zoomLevel)
	$Camera2D.zoom = Vector2(zoomLevelCamera,zoomLevelCamera)
	#print(zoomLevel)
	
func zoomOut():	
	zoomLevel -= zoomLevelIncrement
	if zoomMinVal > zoomLevel:
		zoomLevel = zoomMinVal
	zoomLevelCamera = dynamic_zoom_level(zoomLevel)
	$Camera2D.zoom = Vector2(zoomLevelCamera,zoomLevelCamera)
	#print(zoomLevel)

func circle_orbit(b1,b2):
#		print("sm  ",b1.mass)		
#		print("pm  ",b2.mass)		

		var direction = b2.global_position.direction_to(b1.global_position)
#		print(direction)

		var distance = b2.global_position.distance_to(b1.global_position)
#		print("dis  ",distance)		

		var dir_tangent=direction.orthogonal()
		dir_tangent = dir_tangent # super.rotated(deg_to_rad(30) )
#		print("tan  ",dir_tangent)
		
		var mag:float = circle_orbit_veloc(b1.mass,b2.mass,distance)
#		print("mag  ", mag)	

		var velo=dir_tangent * mag
#		print("velo ", velo)		

		return velo

func circle_orbit_veloc(m1,m2,d):
#		var bigG:float = 6.6743 * pow(10, -11)  # soo low
#		var bigG=  98
#		var bigG=  1
#		print("G   ", bigG)	
		var mag:float= sqrt(bigG * (m1 + m2)/d) 
#		print("mag  ", mag)		
#		var accf:float=(bigG*(m1+m2))/(d*d)  # not used currently
#		print("acc  ", accf)		
		return mag

var totalDelta	= 0.0	
var gameTick = 0
func _process(delta):
	totalDelta += delta
	
	if gameTick < int(totalDelta):
		gameTick =  int(totalDelta)
		doGameTick()

	$CanvasLayer/labelTotalDelta.text = str(gameTick)
	$Camera2D.position = $Star.global_position	
	
var emitted=false
func doGameTick():
	pass
	var new_mass=5

	if !emitted:
		if int(gameTick % 2) == 0:
			
			var direction = $Area2DEmitter.position.direction_to($Star.position)
			var distance = $Area2DEmitter.position.distance_to($Star.position)
			var dir_tangent=direction.orthogonal() 
			# dir_tangent = dir_tangent.tangent().tangent()  
			var mag = circle_orbit_veloc($Star.mass,new_mass,distance)
			var velo=dir_tangent * mag
			add_planet(new_mass, $Area2DEmitter.position, velo)
			emitted=true
	else:
		$Area2DEmitter.visible=false

func add_planet(mass, pos:Vector2, linvel:Vector2):
	
	if get_tree().get_nodes_in_group("planet").size() < max_planets:
		var newp = planetSceneTemplate.instantiate()
		newp.g = self	
		newp.mass=mass
		newp.position=pos
		newp.linear_velocity=linvel
	
		call_deferred("add_child", newp)
		
		if linvel == Vector2.ZERO:
			logMsg("Added body: "+str(newp.mass) )
		else:
			logMsg("Added body with orbit: "+str(newp.mass) )
	
func _on_HSlider_value_changed(value):
	$CanvasLayer/labelTimeScale.text = str(value)
	Engine.time_scale = value

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			add_planet(new_planet_start_mass, get_global_mouse_position(), Vector2.ZERO)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var direction = get_global_mouse_position().direction_to($Star.position)
			var distance = get_global_mouse_position().distance_to($Star.position)
			var dir_tangent=direction.orthogonal() 
#			dir_tangent = dir_tangent.tangent().tangent()  
			
			var new_mass=new_planet_start_mass
			var mag = circle_orbit_veloc($Star.mass,new_mass,distance)

			var velo=dir_tangent * mag
			add_planet(new_mass, get_global_mouse_position(), velo)

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoomIn()
	
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoomOut()
	
var logMsgs = Array()
var logMaxMsgs = 30
func logMsg(msg,clear_first=false):
	if clear_first:
		logMsgs.clear()
	logMsgs.append(msg)
	if logMsgs.size() > logMaxMsgs:
		logMsgs.remove_at(0)
	$CanvasLayer/LogPanel/labelLog.text = "\n".join(PackedStringArray(logMsgs))


func _on_Area2DVelocDamp_body_entered(body):
	body.PushRetrograde(10*body.mass)
func _on_Area2DVelocDamp_body_exited(_body):
	pass
	
func _on_Area2DVelocBump_body_entered(body):
	body.PushPrograde(10*body.mass)
func _on_Area2DVelocBump_body_exited(_body):
	pass

func _on_Area2DVoid_body_entered(body):
	body.EnterVoid()
func _on_Area2DVoid_body_exited(_body):
	pass # Replace with function body.


func _on_Game_draw():
	draw_arc($Star.global_position, $Star.max_distance_allowed, 0, TAU, 1000, Color.WHITE)

