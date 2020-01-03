extends Node

const PORT = 2500
const MAX_PLAYERS = 10

signal allPlayersReady()

var searchPeer = PacketPeerUDP.new()

var broadcastAddress = "255.255.255.255"

var gameStarted = false

var playerInfo = {
	
	"name":"EpicDude54",
	"character":Globals.characters.CLOT,
	"ready":false,
	
	}
	
var players = {}

var joinableGames = {}

var broadcastTimer = Timer.new()

var starting = false


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(broadcastTimer)
	pass

func host(gameName:String):
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
	
	searchPeer.set_dest_address(broadcastAddress, PORT)
	searchPeer.put_var([gameName, IP.get_local_addresses()[1]])
	get_tree().connect("network_peer_connected", self, "playerConnected")
	get_tree().connect("network_peer_disconnected", self, "playerDiconnected")
	
	broadcastTimer.wait_time = 2
	broadcastTimer.connect("timeout", self, "sendBroadcast", [gameName])
	broadcastTimer.start()
	
	players[1] = playerInfo
	
	pass


func join(ip:String):
	
	searchPeer.close()
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, PORT)
	get_tree().network_peer = peer
	get_tree().connect("connected_to_server", self, "connectedToHost")
	get_tree().connect("connection_failed", self, "disconnectedFromHost")
	get_tree().connect("server_disconnected", self, "disconnectedFromHost")
	
	pass
	
	
func find():
	
	searchPeer.set_dest_address(broadcastAddress, PORT)
	searchPeer.listen(PORT)
	
	pass
	
	
func _process(delta):
	
	
	if searchPeer.is_listening():
		
		var packet = searchPeer.get_var()
		
		if packet:
			joinableGames[packet[0]] = packet[1]
			
	
	if get_tree().network_peer:
		
		if get_tree().is_network_server():
			
			if starting:
				
				var allReady = true
				
				for player in players.keys():
					
					if not players[player].ready:
						allReady = false
						break
						
				if allReady:
					
					emit_signal("allPlayersReady")
					
					pass
			
			
	
	pass
	
func sendBroadcast(gameName:String):
	searchPeer.set_dest_address(broadcastAddress, PORT)
	searchPeer.put_var([gameName, IP.get_local_addresses()[1]])
	pass
	
func connectedToHost():
	
	get_tree().change_scene("res://Scenes/Screens/JoinScreen.tscn")
	
	pass
	
remote func sendInfoToServer():
	rpc_id(1, "addPlayerInfo", get_tree().get_network_unique_id(), playerInfo)
	pass
	
func disconnectedFromHost():
	get_tree().change_scene("res://Scenes/Screens/MainMenu.tscn")
	get_tree().network_peer = null
	pass
	
func playerConnected(id:int):
	
	rpc_id(id, "sendInfoToServer")
	
	pass
	
func playerDisconnected(id:int):
	
	players.erase(id)
	
	pass
	
remote func addPlayerInfo(id:int, info:Dictionary):
	players[id] = info
	rpc("updatePlayersInfo", players)
	pass
	
remote func updatePlayersInfo(info:Dictionary):
	
	players = info
	
	pass
	
func disconnectServer():
	get_tree().network_peer.close_connection()
	get_tree().network_peer = null
	pass
	
remote func readyPlayer(id:int):
	
	players[id].ready = true
	
	pass
	
remotesync func startGame(mode=""):
	
	get_tree().paused = true
	
	get_tree().change_scene("res://Scenes/GameModes/BadRoyale.tscn")
	starting = true
	
	pass
	