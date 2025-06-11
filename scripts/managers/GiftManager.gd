extends Node

signal gift_collected(gift_type: String)

var gifts: Dictionary = {
	"negacao": 0,
	"raiva": 0,
	"barganha": 0,
	"depressao": 0,
	"aceitacao": 0
}

func _ready():
	reset_gifts()

# Adiciona um gift
func add_gift(gift_type: String, amount: int = 1) -> void:
	if gift_type in gifts:
		gifts[gift_type] += amount
		emit_signal("gift_collected", gift_type)
		print("Gift collected: %s (Total: %d)" % [gift_type, gifts[gift_type]])

# Usa um gift
func use_gift(gift_type: String, amount: int = 1) -> bool:
	if gift_type in gifts and gifts[gift_type] >= amount:
		gifts[gift_type] -= amount
		print("Gift used: %s (Remaining: %d)" % [gift_type, gifts[gift_type]])
		return true
	return false

# Retorna a quantidade de um gift específico
func get_gift_count(gift_type: String) -> int:
	return gifts.get(gift_type, 0)

# Retorna todos os gifts
func get_all_gifts() -> Dictionary:
	return gifts.duplicate()

# Reseta todos os gifts
func reset_gifts() -> void:
	for gift_type in gifts:
		gifts[gift_type] = 0
	print("Gifts reset") 