class_name GdUnitTcpClient
extends Node

signal connection_succeeded(message)
signal connection_failed(message)

# connetion timeout in ms
var _connection_timeout = 2.000
var _timer :Timer

var _host :String
var _port :int
var _client_id :int
var _connected :bool
var _stream :StreamPeerTCP

func _ready():
	_connected = false
	_stream = StreamPeerTCP.new()
	_stream.set_big_endian(true)
	_timer = Timer.new()
	add_child(_timer)
	_timer.set_one_shot(true)
	var _x = _timer.connect('timeout', Callable(self, '_connecting_timeout'))

func stop() -> void:
	console("Client: disconnect from server")
	if _stream != null:
		rpc_send(RPCClientDisconnect.new().with_id(_client_id))
	if _stream != null:
		_stream.disconnect_from_host()
	_connected = false

func start(host :String, port :int) -> Result:
	_host = host
	_port = port
	if _connected:
		return Result.warn("Client already connected ... %s:%d" % [_host, _port])
	
	# Connect client to server
	if not _stream.is_connected_to_host():
		var err := _stream.connect_to_host(host, port)
		prints("connect_to_host", host, port, err)
		if err != OK:
			return Result.error("GdUnit3: Can't establish client, error code: %s" % err)
	return Result.success("GdUnit3: Client connected on port %d" % port)

func _process(_delta):
	match _stream.get_status():
		StreamPeerTCP.STATUS_NONE:
			return
		
		StreamPeerTCP.STATUS_CONNECTING:
			console("Connecting...  %s:%d" % [_host, _port])
			set_process(false)
			# wait until client is connected to server
			for retry in 10:
				console("wait to connect ..")
				if _stream.get_status() == StreamPeerTCP.STATUS_CONNECTING:
					await get_tree().create_timer(0.500).timeout
				if _stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
					set_process(true)
					return
			set_process(true)
			_stream.disconnect_from_host()
			console("connection failed")
			emit_signal("connection_failed", "Connect to TCP Server %s:%d faild!" % [_host, _port])
		
		StreamPeerTCP.STATUS_CONNECTED:
			if not _connected:
				var rpc
				set_process(false)
				while rpc == null:
					await get_tree().create_timer(0.500).timeout
					rpc = rpc_receive()
				set_process(true)
				_client_id = rpc.client_id()
				console("Connected to Server: %d" % _client_id)
				emit_signal("connection_succeeded", "Connect to TCP Server %s:%d success." % [_host, _port])
				_connected = true
			process_rpc()
		
		StreamPeerTCP.STATUS_ERROR:
			console("connection failed")
			_stream.disconnect_from_host()
			emit_signal("connection_failed", "Connect to TCP Server %s:%d faild!" % [_host, _port])
			return

func is_client_connected() -> bool:
	return _connected

func process_rpc() -> void:
	if _stream.get_available_bytes() > 0:
		var rpc = rpc_receive()
		if rpc is RPCClientDisconnect:
			stop()

func rpc_send(rpc :RPC) -> void:
	if _stream != null:
		var data := GdUnitServerConstants.JSON_RESPONSE_DELIMITER + rpc.serialize() + GdUnitServerConstants.JSON_RESPONSE_DELIMITER
		_stream.put_data(data.to_ascii_buffer())

func rpc_receive() -> RPC:
	if _stream != null:
		while _stream.get_available_bytes() > 0:
			var available_bytes := _stream.get_available_bytes()
			var data = _stream.get_data(available_bytes);
			var received_data := data[1] as PackedByteArray
			# data send by Godot has this magic header of 12 bytes
			var header := Array(received_data.subarray(0,3))
			if header == [0, 0, 0, 112]:
				received_data = received_data.subarray(12, available_bytes-1)
			var decoded := received_data.get_string_from_ascii()
			return RPC.deserialize(decoded)
	return null

func console(message :String) -> void:
	prints("TCP Client:", message)
	pass

func _on_connection_failed(message :String):
	console("connection faild: " + message)

func _on_connection_succeeded(message :String):
	console("connected: " + message)
