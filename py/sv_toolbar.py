import sv
import td
from typing import Tuple

NODENAME_TOOLBAR = "svag_toolbar"
NODENAME_TOOLBARSETUP = "svags_toolbarsetup"

coordsys_toolbar = sv.CoordSystem()


	
def build_toolbar():
	print("Rebuilding toolbar")

	toolbar, _ = sv.make_if_needed_abs(sv.proj_relative_path_to_abs(NODENAME_TOOLBAR), td.containerCOMP)
	sv.coordsys_proj.move_node(toolbar, 0)

	toolbarsetupnode = init_toolbarsetup_py_node_if_not_exists()

	toolbarsetupnode.module.setup_toolbar()

	#make_stripe(0)
	#make_stripe(1)
	#make_momentary_button(0, "hi")
	
def item_abs_path(item_in_toolbar_comp: str) -> str:
	return sv.proj_relative_path_to_abs(f"{NODENAME_TOOLBAR}/{item_in_toolbar_comp}")
	
def stripe_abs_path(index: int) -> str:
	return item_abs_path(f"svag_stripe_{index}")
	
def make_stripe(index: int):
	stripe, _ = sv.make_if_needed_abs(stripe_abs_path(index), td.containerCOMP)
	coordsys_toolbar.move_node(stripe, 0, 2 * index)	
	
def make_momentary_button(stripeindex: int, name: str):
	btn, _ = sv.make_if_needed_abs(item_abs_path(name), td.buttonCOMP)
	
	btn.par.buttontype = 0             # 0 = Momentary type
	btn.par.w = 50
	btn.par.h = STD_HEIGHT
	btn.par.label = name
	coordsys_toolbar.move_node(btn, 0, 2 * stripeindex + 1)
	
def init_toolbarsetup_py_node_if_not_exists():
	abspath = sv.proj_relative_path_to_abs(NODENAME_TOOLBARSETUP)
	
	toolbarsetupnode, took_existing = sv.make_if_needed_abs(abspath, td.textDAT)
	
	if took_existing:
		#we dont make any changes then
		return toolbarsetupnode
	
	code = f"""
def setup_toolbar():
	tb = mod(op("/sv_toolbar"))
	tb.make_stripe(0)
	tb.make_stripe(1)
	tb.make_stripe(2)
	"""
	
	toolbarsetupnode.text = code
	
	sv.coordsys_proj.move_node(toolbarsetupnode, 1)
	
	return toolbarsetupnode