extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var anim: AnimationPlayer = $AnimationPlayer


func set_face_texture(tex: Texture2D) -> void:
	if texture_rect:
		texture_rect.texture = tex


func play_flip() -> void:
	if anim and anim.has_animation("flip"):
		anim.play("flip")
