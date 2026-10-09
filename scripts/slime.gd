extends CharacterBody2D

const SPEED: int = 100
const KNOCKBACK_FORCE: int = 200
const DROP_CHANCE: float = 0.5

var is_alive: bool = true
var health: int = 100
var strength: int = 10
var target = null
var target_in_range: bool = false

var health_pickup_scene = preload("res://scenes/health_pickup.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var health_bar: Node2D = $HealthBar
@onready var attack_timer: Timer = $AttackTimer

func _physics_process(delta: float) -> void:

	if is_alive and target:
		_attack(delta)

func _attack(delta: float) -> void:
	var direction = (target.position - position).normalized()
	position += direction * SPEED * delta
	animated_sprite_2d.play("attack")

func take_damage(damage: int, attacker_postion: Vector2) -> void:
	health_bar.visible = true
	health -= damage
	health_bar.update_health(health)
	take_damage_sound.pitch_scale = randf_range(1, 2)
	take_damage_sound.play()
	# Knockback
	var knockback_direction = (position - attacker_postion).normalized()
	var target_position = position + knockback_direction * KNOCKBACK_FORCE
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", target_position, 0.5)
		
	if health <= 0: ##<<<<< eu q coloquei aqui, deveria ser antes do som
		_die()

func _die() -> void:
	is_alive = false
	animated_sprite_2d.play("die")
	
	take_damage_sound.pitch_scale = 0.5
	take_damage_sound.play()
	
	# Disable Collision
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	health_bar.visible = false ##<<<<< eu q coloquei
	
	# Drop health pickup
	if randf() <= DROP_CHANCE:
		drop_item()

func drop_item():
	var drop = health_pickup_scene.instantiate()
	drop.position = position
	var level_root = get_parent().get_parent()
	var items_node = level_root.get_node("Items")
	items_node.call_deferred("add_child", drop)
	
func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target = null
		animated_sprite_2d.play("idle")

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = true
		body.take_damage(strength)
		attack_timer.start()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = false
		attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	if target and target_in_range:
		target.take_damage(strength)
