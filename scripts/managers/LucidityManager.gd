extends Node

signal lucidity_points_changed(points: int)

var lucidity_points: int = 0
var max_lucidity_points: int = 100

func _ready():
	reset_lucidity_points()

# Adiciona pontos de lucidez
func add_lucidity_point(amount: int = 1) -> void:
	lucidity_points = min(lucidity_points + amount, max_lucidity_points)
	emit_signal("lucidity_points_changed", lucidity_points)
	print("Pontos de lucidez atualizados: ", lucidity_points)

# Usa pontos de lucidez
func use_lucidity_point(amount: int = 1) -> bool:
	if lucidity_points >= amount:
		lucidity_points -= amount
		emit_signal("lucidity_points_changed", lucidity_points)
		print("Pontos de lucidez usados: ", amount)
		return true
	return false

# Retorna os pontos de lucidez atuais
func get_lucidity_points() -> int:
	return lucidity_points

# Retorna o máximo de pontos de lucidez
func get_max_lucidity_points() -> int:
	return max_lucidity_points

# Define o máximo de pontos de lucidez
func set_max_lucidity_points(max_points: int) -> void:
	max_lucidity_points = max(1, max_points)
	lucidity_points = min(lucidity_points, max_lucidity_points)
	emit_signal("lucidity_points_changed", lucidity_points)

# Reseta os pontos de lucidez
func reset_lucidity_points() -> void:
	lucidity_points = 0
	emit_signal("lucidity_points_changed", lucidity_points)
	print("Pontos de lucidez resetados") 