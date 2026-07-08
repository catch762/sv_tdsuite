import sv
import td
from typing import Tuple

NODENAME_TOOLBAR = "svag_toolbar"

coordsys_toolbar = sv.CoordSystem()
	
def build_toolbar():
	print("Rebuilding toolbar")

	parent, name, existing = sv.process_projrel_path(NODENAME_TOOLBAR)
	sv.destroy_if_exists(existing)

	toolbar = parent.create(td.containerCOMP, name)
	sv.coordsys_proj.move_node(toolbar, 0)
	
	make_stripe(0)
	make_stripe(1)
	
def get_toolbar():
	return project.op(NODENAME_TOOLBAR)
	
def make_stripe(index: int):
	toolbar, name, existing_stripe = sv.process_projrel_path(f"{NODENAME_TOOLBAR}/svag_stripe_{index}")

	sv.destroy_if_exists(existing_stripe)
	
	stripe = toolbar.create(td.containerCOMP, name)
	coordsys_toolbar.move_node(stripe, 0, 2 * index)