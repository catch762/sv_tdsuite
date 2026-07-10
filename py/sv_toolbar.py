import sv
import td
from typing import Tuple

NODENAME_TOOLBAR = "svag_toolbar"

coordsys_toolbar = sv.CoordSystem()

STD_HEIGHT = 24
	
def build_toolbar():
	print("Rebuilding toolbar")

	parent, name, existing = sv.process_projrel_path(NODENAME_TOOLBAR)
	sv.destroy_if_exists(existing)

	toolbar = parent.create(td.containerCOMP, name)
	sv.coordsys_proj.move_node(toolbar, 0)
	
	make_stripe(0)
	make_stripe(1)
	
	make_momentary_button(0, "hi")
	
def item_abs_path(item_in_toolbar_comp: str) -> str:
	return sv.proj_relative_path_to_abs(f"{NODENAME_TOOLBAR}/{item_in_toolbar_comp}")
	
def stripe_abs_path(index: int) -> str:
	return item_abs_path(f"svag_stripe_{index}")
	
def make_stripe(index: int):
	stripe = sv.make_if_needed_abs(stripe_abs_path(index), td.containerCOMP)
	coordsys_toolbar.move_node(stripe, 0, 2 * index)	
	
def make_momentary_button(stripeindex: int, name: str):
	btn = sv.make_if_needed_abs(item_abs_path(name), td.buttonCOMP)
	
	btn.par.buttontype = 0             # 0 = Momentary type
	btn.par.w = 50
	btn.par.h = STD_HEIGHT
	btn.par.label = name
	coordsys_toolbar.move_node(btn, 0, 2 * stripeindex + 1)