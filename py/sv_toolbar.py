import sv
from typing import Tuple

NODENAME_TOOLBAR = "svag_toolbar"
	
def build_toolbar():
	parent, name, existing = sv.process_projrel_path(NODENAME_TOOLBAR)
	sv.destroy_if_exists(existing)

	toolbar = parent.create(td.containerCOMP, name)
	
	
	
	pass