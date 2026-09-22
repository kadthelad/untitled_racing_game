class_name RacerHitboxController
extends Node

## Player will be blocked by a runner if too close behind them, player's speed will
## drastically go low and target speed will be equal to the blocking runner's speed.
func _on_blocked_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.

## Player will obtain a slight acceleration, velocity and endurance boost when behind a runner with
## enough distance if player has required skill.
func _on_slipstream_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.

## When trying to pass a runner during the last spurt stage of the race, this may activate
## some skills that require to be in a duel.
func _on_duelling_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.

## When coming close to another runner to its side, the player can bump them if they have 20% more
## strength than their opponent. The opponent may suffer stamina and fatigue damage if heir strength
## is too low.
## Bumping a runner will push them away if their strength is 35% lower than player's, on the other hand,
## if the player has 5% less strength, the player will get pushed and will suffer consequences.
## If both player have quite similar strenght, they both get slightly pushed away from each other and they
## both suffer a slight debuff.
## Willpower and Intelligence can help reduce the debuff taken when bumped (but not the push).
func _on_bump_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
