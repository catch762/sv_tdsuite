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