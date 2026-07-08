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
	toolbar, name, existing_stripe = sv.process_abs_path(stripe_abs_path(index))

	sv.destroy_if_exists(existing_stripe)
	
	stripe = toolbar.create(td.containerCOMP, name)
	coordsys_toolbar.move_node(stripe, 0, 2 * index)
	
def make_momentary_button(stripeindex: int, name: str):
	toolbar, _, existing_item = sv.process_abs_path(item_abs_path(name))
	
	sv.destroy_if_exists(existing_item)
	
	#bug: it adds 1 to the name, even though its 100% not there, fucker
	btn = toolbar.create(td.buttonCOMP, name)
	#well at least the fix is easy:
	btn.name = name
	assert btn.name == name
	
	btn.par.buttontype = 0             # 0 = Momentary type
	btn.par.w = 50
	btn.par.h = STD_HEIGHT
	
	btn.par.label = name
	coordsys_toolbar.move_node(btn, 0, 2 * stripeindex + 1)
	
	
		complete this:
	
	
	# Create a Panel Execute DAT to handle clicks
    panel_exec_name = name + "_panelExec"
    if op(container, panel_exec_name) is None:
        panel_exec = td.createOperator(container, 'panelexec', panel_exec_name)
    else:
        panel_exec = op(container, panel_exec_name)
    
    # Configure Panel Execute DAT
    panel_exec.par.Panels = button.name
    panel_exec.par.OffToOn = 1    # trigger on press
    panel_exec.par.OnOffToOn = 1
    
    # Build the onOffToOn function
    if action_code is None:
        action_code = "print('Button clicked!')"
    
    code = f"""
def onOffToOn(panelValue):
    # panelValue is 1 when pressed (for momentary)
    {action_code}
    return
"""
    
    panel_exec.text = code
    