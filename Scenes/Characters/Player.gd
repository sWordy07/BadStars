extends KinematicBody2D

export var maxHealth = 400
onready var health = maxHealth

export var moveSpeed = 200

export(Globals.characters) var character = 0

export var weaponPath:NodePath = "Gun"
onready var weapon = get_node(weaponPath)

var ghostTexture = preload("res://Graphics/Characters/Ghost.png")

var velocity = Vector2()

var mobileControls:Control
var ui:gameUI

var dead = false

func _ready():
	pass
	
func initialize(id:int):
	set_network_master(id)
	name = String(id)
	
	add_to_group("Ally"+String(id))
	
	$NameTag/CenterContainer/Label.text = Network.players[id].name
	
	if is_network_master():
		$Camera.current = true
		
		if Globals.mobile:
			var controls = load("res://Scenes/UI/MobileControls.tscn")
			mobileControls = controls.instance()
			$UI.add_child(mobileControls)
			
		var uiScene = preload("res://Scenes/UI/GameUI.tscn")
		ui = uiScene.instance()
		$UI.add_child(ui)
		
		ui.setupUI(maxHealth, weapon.maxAmmo)
		
		weapon.connect("reloaded", ui, "setAmmo")
		
	else:
		pass
	pass
	
func _physics_process(delta):
	if Network.gameStarted:
	
		if not dead:
			actions()
		movement()
			
	
	pass
	
	
func movement():
	
	if is_network_master():
		
		var dir = Vector2()
		
		if Globals.mobile:
			
			dir = Globals.leftStickAxis
			
		else:
			
			if Input.is_action_pressed("left"):
				dir.x = -1
			elif Input.is_action_pressed("right"):
				dir.x = 1
			else:
				dir.x = 0
				
			if Input.is_action_pressed("up"):
				dir.y = -1
			elif Input.is_action_pressed("down"):
				dir.y = 1
			else:
				dir.y = 0
			
		dir = dir.normalized()
		
		velocity = dir*moveSpeed
		
		velocity = move_and_slide(velocity)
		
		rpc_unreliable("setPosition", global_position)
		
	pass
	
func actions():
	
	if is_network_master():
		
		
		if Globals.mobile:
			
			if mobileControls.autoaim:
				autoaim()
				weapon.aim(false)
				mobileControls.autoaim = false
			else:
			
				if mobileControls.rightStickGrabbed and not mobileControls.deadzoned:
					
					if weapon.canShoot:
						rpc("aimGun", Globals.rightStickAxis.angle())
						weapon.aim(true)
				else:
					weapon.aim(false)
					
				if mobileControls.shot:
					mobileControls.shot = false
					shoot()
			
		else:
			if Input.is_action_just_pressed("autoaim"):
				autoaim()
			else:
				if Input.is_action_pressed("shoot"):
					if weapon.canShoot:
						rpc("aimGun", get_angle_to(get_global_mouse_position()))
						weapon.aim(true)
			
				elif Input.is_action_just_released("shoot"):
					shoot()
					pass
				else:
					weapon.aim(false)
	
	pass
	
func autoaim():
	
	weapon.aim(false)
	
	var closestBody:Node2D
	
	for body in $AutoaimRange.get_overlapping_bodies():
		
		if body.is_in_group("Shootable") and not body.is_in_group("Ally"+String(get_tree().get_network_unique_id())):
			if closestBody:
				if global_position.distance_to(body.global_position) < global_position.distance_to(closestBody.global_position):
					closestBody = body
			else:
				closestBody = body
				
			pass
			
	if closestBody:
		rpc("aimGun", get_angle_to(closestBody.global_position))
		shoot()
		
		pass
	pass
	
func shoot():
	
	if weapon.canShoot and not weapon.ammo <= 0:
		weapon.rpc("shoot", get_tree().get_network_unique_id(), ObjectPool.getAvailableObjectIndex(ObjectPool.pools[get_tree().get_network_unique_id()].bullets))
		weapon.ammo -= 1
		ui.setAmmo(weapon.ammo)
		weapon.get_node("Cooldown").start()
		weapon.canShoot = false
		if weapon.get_node("Reload").is_stopped():
			weapon.get_node("Reload").start()
		
	pass
	
remotesync func hit(damage:int, id:int, super=false):
	
	health -= damage
	if is_network_master():
		ui.setHealth(health)
	else:
		pass
		
	if health <= 0:
		
		if get_tree().get_network_unique_id() == 1:
			rpc("die")
		
		pass
		
	pass
		
remotesync func die():
	
	modulate = Color(1, 1, 1, 0.7)
	$Sprite.scale = Vector2(2, 2)
	$Sprite.rotation = 0
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite.texture = ghostTexture
	dead = true
	weapon.visible = false
	
	pass
	
	
	
	
remotesync func aimGun(direction:float):
	weapon.global_rotation = direction
	pass
	
	
puppet func setPosition(pos:Vector2):
	global_position = pos
	pass
	
