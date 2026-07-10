import sv
import td
from typing import Tuple

NODENAME_TOOLBAR = "svag_toolbar"
NODENAME_TOOLBARSETUP = "svags_toolbarsetup"

YINDEXES_PER_STRIPE = 4

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
	
def add_stripe(index: int):
	stripe, _ = sv.make_if_needed_abs(stripe_abs_path(index), td.containerCOMP)
	coordsys_toolbar.move_node(stripe, 0, YINDEXES_PER_STRIPE * index)	
	
def toolbarsetup_abspath():
	return sv.proj_relative_path_to_abs(NODENAME_TOOLBARSETUP)
	
#this goes to panel exec	
def make_code_to_call_this_callback_as_OffToOn(function_offtoon_from_toolbarsetup):
	return f"""
def onOffToOn(panelValue):
	tbs = mod(op('{toolbarsetup_abspath()}'))
	tbs.{function_offtoon_from_toolbarsetup.__name__}()
	"""
	
#this goes to par exec	
def make_code_to_call_this_callback_as_ValueChange(function_valchange_from_toolbarsetup):
	return f"""
def onValueChange(par, prev):
	tbs = mod(op('{toolbarsetup_abspath()}'))
	tbs.{function_valchange_from_toolbarsetup.__name__}(par.eval(), prev)
	"""

	
def add_momentary_button(stripeindex: int, nodename: str, function_offtoon_from_toolbarsetup):
	btn, panexec = sv.make_momentary_button(item_abs_path(nodename), make_code_to_call_this_callback_as_OffToOn(function_offtoon_from_toolbarsetup))
	
	yindex = YINDEXES_PER_STRIPE * stripeindex + 1
	xindex = 0
	
	coordsys_toolbar.move_node(btn, xindex, yindex)
	coordsys_toolbar.move_node(panexec, xindex, yindex + 1)
	return btn
	
def add_radio_button(stripeindex: int, nodename: str, list_of_radiogroup_entries, function_valuechange_from_toolbarsetup):
	btn, panexec = sv.make_radio_button(item_abs_path(nodename), list_of_radiogroup_entries,  make_code_to_call_this_callback_as_ValueChange(function_valuechange_from_toolbarsetup))
	
	yindex = YINDEXES_PER_STRIPE * stripeindex + 1
	xindex = 1
	
	coordsys_toolbar.move_node(btn, xindex, yindex)
	coordsys_toolbar.move_node(panexec, xindex, yindex+1)
	return btn
	
def init_toolbarsetup_py_node_if_not_exists():
	toolbarsetupnode, took_existing = sv.make_if_needed_abs(toolbarsetup_abspath(), td.textDAT)
	
	if took_existing:
		#we dont make any changes then
		return toolbarsetupnode
	
	code = f"""
def hellohandler():	
	print("hellohandler")
def radhandler(val, prev):	
	print(f"radhandler {{val}} {{prev}}")
	
def setup_toolbar():
	tb = mod(op("/sv_toolbar"))
	tb.add_stripe(0)
	tb.add_stripe(1)
	tb.add_stripe(2)
	tb.add_momentary_button(1, "hello", hellohandler)
	tb.add_radio_button(1, "radiooo", ['a', 'bbbb', 'cccc'], radhandler)
	"""
	
	toolbarsetupnode.text = code
	
	sv.coordsys_proj.move_node(toolbarsetupnode, 1)
	
	return toolbarsetupnode

def make_panel_execute(	panel_abspath : str,
						node_list_to_listen : str,
						code = None,
						enable_valuechange : bool = False, #
						enable_offtoon : bool = False,
						enable_ontooff : bool = False ):
	panexec, _ = make_if_needed_abs(panel_abspath, td.panelexecuteDAT)
	panexec.par.panel = node_list_to_listen    # Path to the panel component to watch
	panexec.par.valuechange = int(enable_valuechange)          # Enable Value Change trigger
	panexec.par.offtoon = int(enable_offtoon)
	panexec.par.ontooff = int(enable_ontooff)
	if code is not None:
		panexec.text = code
	return panexec

def make_par_execute(	abspath : str,
						ops : str,
						params : str,
						code : str):
	parexec, _ = make_if_needed_abs(abspath, td.parameterexecuteDAT)
	parexec.par.op = ops    # Path to the panel component to watch
	parexec.par.pars = params    # Path to the panel component to watch
	parexec.par.valuechange = 1
	parexec.text = code
	return parexec
	
STD_WIDTH = 50	
STD_HEIGHT = 24

#panexeccode better contain only func "def onOffToOn(panelValue):"
def make_momentary_button(abspath: str, panexeccode: str):
	btn, _ = make_if_needed_abs(abspath, td.buttonCOMP)
	
	btn.par.buttontype = 'momentary'
	btn.par.w = STD_WIDTH
	btn.par.h = STD_HEIGHT
	btn.par.label = btn.name
	
	panexec = make_panel_execute(abspath + "_panexec", btn.name, panexeccode, enable_offtoon = True)
	
	return btn, panexec
	

	
def make_radio_button(abspath: str, list_of_radiogroup_entries, panexeccode: str):
	parent_node, node_name, existing_node = process_abs_path(abspath)
	destroy_if_exists(existing_node)

	radio_from_palette = op('/basicWidgets/buttonRadio')
	btn = parent_node.copy(radio_from_palette, name=node_name)

	formatted_labels = " ".join([f'"{b}"' if " " in b else b for b in list_of_radiogroup_entries])
	btn.par.Radiolabels = formatted_labels
	btn.par.Value0 = 0
	
	btn.par.Labelwidth = STD_WIDTH
	btn.par.w = STD_WIDTH * 2
	btn.par.h = STD_HEIGHT
	
	panexec = make_par_execute(abspath + "_panexec", btn.name, "Value0", panexeccode)
	return btn, panexec