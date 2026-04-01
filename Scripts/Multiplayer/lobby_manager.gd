extends Node
class_name LobbyManager

signal lobby_request_started(endpoint: String)
signal lobby_request_finished(endpoint: String, success: bool, data: Dictionary)
signal room_registered(room_data: Dictionary)
signal rooms_received(rooms: Array)
signal room_received(room_data: Dictionary)
signal room_removed(room_id: String)
signal heartbeat_sent(room_id: String)
signal public_ip_received(ip: String)
signal lobby_error(endpoint: String, message: String)

const JSON_HEADERS := [
	"Content-Type: application/json"
]

@export var base_url: String = "http://136.115.54.229:3000"
@export var request_timeout := 10.0

var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = request_timeout
	add_child(_http)


func set_base_url(url: String) -> void:
	base_url = url.strip_edges().trim_suffix("/")


func register_room(payload: Dictionary) -> Dictionary:
	var endpoint := "/rooms"
	var result = await _request_json(endpoint, HTTPClient.METHOD_POST, payload)

	if result["ok"]:
		var room_data: Dictionary = result.get("data", {})
		emit_signal("room_registered", room_data)

	return result


func list_rooms() -> Dictionary:
	var endpoint := "/rooms"
	var result = await _request_json(endpoint, HTTPClient.METHOD_GET)

	if result["ok"]:
		var data = result.get("data", {})
		var rooms: Array = data.get("rooms", [])
		emit_signal("rooms_received", rooms)

	return result


func get_room(room_id: String) -> Dictionary:
	var endpoint := "/rooms/%s" % room_id
	var result = await _request_json(endpoint, HTTPClient.METHOD_GET)

	if result["ok"]:
		var room_data: Dictionary = result.get("data", {})
		emit_signal("room_received", room_data)

	return result


func remove_room(room_id: String) -> Dictionary:
	var endpoint := "/rooms/%s" % room_id
	var result = await _request_json(endpoint, HTTPClient.METHOD_DELETE)

	if result["ok"]:
		emit_signal("room_removed", room_id)

	return result


func send_heartbeat(room_id: String, payload: Dictionary = {}) -> Dictionary:
	var endpoint := "/rooms/%s/heartbeat" % room_id
	var result = await _request_json(endpoint, HTTPClient.METHOD_POST, payload)

	if result["ok"]:
		emit_signal("heartbeat_sent", room_id)

	return result


func get_public_ip() -> Dictionary:
	var full_url := "https://api.ipify.org?format=json"
	var endpoint := "public_ip"

	emit_signal("lobby_request_started", endpoint)

	var err = _http.request(full_url, [], HTTPClient.METHOD_GET)
	if err != OK:
		var fail_result = _fail("Failed to request public IP. Error code: %s" % err)
		emit_signal("lobby_error", endpoint, fail_result["error"])
		emit_signal("lobby_request_finished", endpoint, false, fail_result)
		return fail_result

	var response = await _http.request_completed
	var parsed = _parse_http_response(endpoint, response)

	if parsed["ok"]:
		var ip = parsed.get("data", {}).get("ip", "")
		emit_signal("public_ip_received", ip)

	return parsed


func join_room_lookup(room_id: String) -> Dictionary:
	# Convenience wrapper.
	# Use this to ask GCP which host IP/port to join.
	return await get_room(room_id)


func _request_json(endpoint: String, method: int, body: Dictionary = {}) -> Dictionary:
	var url := "%s%s" % [base_url.trim_suffix("/"), endpoint]
	var request_body := ""

	if method in [HTTPClient.METHOD_POST, HTTPClient.METHOD_PUT, HTTPClient.METHOD_PATCH]:
		request_body = JSON.stringify(body)

	emit_signal("lobby_request_started", endpoint)

	var err = _http.request(url, JSON_HEADERS, method, request_body)
	if err != OK:
		var fail_result = _fail("Failed to send request to %s. Error code: %s" % [url, err])
		emit_signal("lobby_error", endpoint, fail_result["error"])
		emit_signal("lobby_request_finished", endpoint, false, fail_result)
		return fail_result

	var response = await _http.request_completed
	return _parse_http_response(endpoint, response)


func _parse_http_response(endpoint: String, response: Array) -> Dictionary:
	var result_code: int = response[0]
	var response_code: int = response[1]
	var headers: PackedStringArray = response[2]
	var body: PackedByteArray = response[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		var fail_result = _fail("Lobby request failed. Transport result: %s" % result_code)
		emit_signal("lobby_error", endpoint, fail_result["error"])
		emit_signal("lobby_request_finished", endpoint, false, fail_result)
		return fail_result

	var body_text := body.get_string_from_utf8()
	var parsed_json: Variant = {}

	if body_text.strip_edges() != "":
		var json = JSON.new()
		var parse_err = json.parse(body_text)
		if parse_err != OK:
			var fail_result = _fail("Invalid JSON response from lobby: %s" % body_text)
			emit_signal("lobby_error", endpoint, fail_result["error"])
			emit_signal("lobby_request_finished", endpoint, false, fail_result)
			return fail_result

		parsed_json = json.data

	if response_code < 200 or response_code >= 300:
		var message := "Lobby request failed with HTTP %s" % response_code
		if parsed_json is Dictionary and parsed_json.has("error"):
			message = str(parsed_json["error"])

		var fail_result = {
			"ok": false,
			"error": message,
			"http_code": response_code,
			"headers": headers,
			"data": parsed_json if parsed_json is Dictionary else {}
		}
		emit_signal("lobby_error", endpoint, fail_result["error"])
		emit_signal("lobby_request_finished", endpoint, false, fail_result)
		return fail_result

	var success_result = {
		"ok": true,
		"http_code": response_code,
		"headers": headers,
		"data": parsed_json if parsed_json is Dictionary else {}
	}

	emit_signal("lobby_request_finished", endpoint, true, success_result)
	return success_result


func _fail(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message
	}
