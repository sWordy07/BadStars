extends Control

class_name gameUI

var maxAmmo:int

func _ready():
	pass
	
func setupUI(maxHealth:int, maxA:int):
	
	$Health.max_value = maxHealth
	$Health.value = maxHealth
	$Health/AccurateAmount.text = String(maxHealth)
	
	maxAmmo = maxA
	$Ammo.text = "Ammo: " + String(maxAmmo) + "/" + String(maxAmmo)
	
	pass
	
func setHealth(health:int):
	
	$Health.value = health
	$Health/AccurateAmount.text = String(health)
	
	pass
	
func setAmmo(ammo:int):
	$Ammo.text = "Ammo: " + String(ammo) + "/" + String(maxAmmo)
	pass


func _on_Disconnect_pressed():
	if get_tree().is_network_server():
		Network.disconnectServer()
	else:
		Network.disconnectedFromHost()


func _on_Pause_pressed():
	$PauseMenu.popup()
