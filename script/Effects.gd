class_name Effects
extends RefCounted

func _init(initialValue) -> void:
	_value = initialValue
const _empty_effect :Callable = max
static var _current_effect: Callable = _empty_effect;
var _effects: Dictionary[Callable, Object] = {}
var _value:Variant = null

var value:Variant:
	get:
		if _current_effect and \
			_current_effect.is_valid() and \
			_current_effect != _empty_effect:
				if _current_effect not in _effects:
					_effects[_current_effect] = null
		return _value
	set(new_value):
		if _value == new_value:
			return
		_value = new_value
		var cleanup_effects :Array[Callable] = []
		for effect in _effects:
			if !effect or !effect.is_valid:
				if not effect in cleanup_effects:
					cleanup_effects.append(effect)
			else:
				apply_effect(effect)
		for invalid_effect in cleanup_effects:
			_effects.erase(invalid_effect)

func apply_effect(effect:Callable) -> void:
	if effect && effect.is_valid():
		if effect.get_argument_count() == 1:
			effect.call(self)
		else:
			effect.call()

func use_effect(effect:Callable) -> void:
	if effect && effect.is_valid():
		_current_effect = effect
		apply_effect(effect)
		_current_effect = _empty_effect
func use_effects(...callableEffects) -> Effects:
	if callableEffects and callableEffects is Array and callableEffects.size() > 0:
		for callableEffect in callableEffects:
			self.use_effect(callableEffect)
	return self

static func computed(getter_func: Callable, ...callableEffects) -> Effects:
	var computed_signal = Effects.new(null)
	computed_signal.use_effect(func():
		computed_signal.value = getter_func.call()
	)
	
	computed_signal.use_effects.callv(callableEffects)
	
	return computed_signal

func clear_effects() -> void:
	_effects.clear()
