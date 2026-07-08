"""
	Setting up your project to use sv_tdsuite:

1. 	You must put sv_tdsuite folder in your project folder.
	(the one where your .toe proj file is)
	
	Best way to do it is, assuming your project folder is a git
	repo itself, is to execute this in your system terminal:
	
		cd your_project_folder
		git submodule add https://github.com/catch762/sv_tdsuite
		git submodule update --init --recursive

2.	Then you create or open a TD project, make sure its .toe file
	is in same folder as sv_tdsuite.
	
3.	Then you run this one-line command in TD Texport Terminal:

		import sys, os, importlib; sys.path.append(os.path.join(project.folder, 'sv_tdsuite/py')); import sv_tdsuite_init; importlib.reload(sv_tdsuite_init); sv_tdsuite_init.init()

4.	Optional: if you want to rerun it later, after previous command was run,
	you can do it with simpler command:
	
		op('/sv_tdsuite_init').module.init()

"""

import os
import td
import sys
import importlib
from typing import Tuple

pyfolder = os.path.join(td.project.folder, 'sv_tdsuite/py')
if pyfolder not in sys.path:
    sys.path.append(pyfolder)

import sv
import sv_toolbar

# project_container_name assumed to be in root, just plain name, no slashes
def init(project_container_name: str = "project1"):
	print("sv_tdsuite initializing begin...")
	
	project_container_name = sv.cleanstr(project_container_name)
	
	# now everywhere in project u can refer to it with sv.projname()
	sv.save_projname(project_container_name, sv.coordsys_root.pos_for(0, 1))
	
	project_container = td.root.op(project_container_name)
	if project_container is None:
		print(f"Error: project_container '{project_container_name}' does not exist in root.")
		return
	
	add_python_dat_nodes()
	add_glsl_dat_nodes()
	
	sv_toolbar.build_toolbar()
	
	print("sv_tdsuite initializing completed.")
	
def add_python_dat_nodes():
	# I have to include all my code here, if i just import some internal py files,
	# without creating node like this, there will be caching issues
	py_module_names = [
		"sv_tdsuite_init", "sv", "sv_qtouch", "sv_toolbar"
	]
	
	for index, name in enumerate(py_module_names):
		filepath = f"sv_tdsuite/py/{name}.py"
		full_op_path = f"/{name}"
		add_text_dat_for_file(filepath, full_op_path, index)

def add_glsl_dat_nodes():
	glsl_module_names = [
		"sv_common", "sv_sdfcommon", "sv_sdfinterm", "sv_sup", "sv_iqn"
	]
	
	for index, name in enumerate(glsl_module_names):
		filepath = f"sv_tdsuite/glsl/{name}.glsl"
		full_op_path = f"/{sv.projname()}/{name}_glsl" 
		add_text_dat_for_file(filepath, full_op_path, index)
	
# If such op exists in root, it will be deleted and remade.
def add_text_dat_for_file(
	proj_relative_filepath: str, # Relative to project folder, for example, "sv_tdsuite/py/sv.py"
	full_op_path: str, #something like "/project1/text_node" or just "node" for root level
	index: int
) -> td.textDAT:
	proj_relative_filepath = sv.cleanstr(proj_relative_filepath)
	full_op_path = sv.cleanstr(full_op_path)

	parent_node, this_node_name, this_node = sv.process_abs_path(full_op_path)
	sv.destroy_if_exists(this_node)

	assert parent_node is not None, f"parent_node for '{full_op_path}' does not exist!"

	expression_string: str = sv.project_relative_file_path_to_expression(proj_relative_filepath)

	this_node: td.textDAT = parent_node.create(td.textDAT, this_node_name)
	this_node.par.file.expr = expression_string
	this_node.par.syncfile = True

	sv.coordsys_root.move_node(this_node, index)
	
	return this_node
	
