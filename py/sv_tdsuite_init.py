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
from typing import Tuple

NODE_OFFSET_DISTANCE: int = 200

# project_container_name assumed to be in root, just plain name, no slashes
def init(project_container_name: str = "project1"):
	print("sv_tdsuite initializing begin...")
	
	assert project_container_name and project_container_name.strip(), "project_container_name cannot be empty"
	
	project_container = td.root.op(project_container_name)
	if project_container is None:
		print(f"Error: project_container '{project_container_name}' does not exist in root.")
		return
	
	add_python_dat_nodes()
	add_glsl_dat_nodes(project_container_name)
	
	print("sv_tdsuite initializing completed.")
	
def add_python_dat_nodes():
	start_pos: Tuple[int, int] = (0, 600) 
	
	py_module_names = [
		"sv_tdsuite_init", "sv", "sv_qtouch"
	]
	
	for index, name in enumerate(py_module_names):
		filepath = f"sv_tdsuite/py/{name}.py"
		full_op_path = name
		add_python_dat(filepath, full_op_path, index, start_pos)

def add_glsl_dat_nodes(project_container_name):
	start_pos: Tuple[int, int] = (0, 600) 
	
	glsl_module_names = [
		"sv_common", "sv_sdfcommon", "sv_sdfinterm", "sv_sup", "sv_iqn"
	]
	
	for index, name in enumerate(glsl_module_names):
		filepath = f"sv_tdsuite/glsl/{name}.glsl"
		full_op_path = f"/{project_container_name}/{name}" 
		add_python_dat(filepath, full_op_path, index, start_pos)
	
# If such op exists in root, it will be deleted and remade.
def add_python_dat(
	proj_relative_filepath: str, # Relative to project folder, for example, "sv_tdsuite/py/sv.py"
	full_op_path: str, #something like "/project1/text_node" or just "node" for root level
	index: int, 
	initial_pos: Tuple[int, int]
) -> td.textDAT:

	assert proj_relative_filepath and proj_relative_filepath.strip(), "proj_relative_filepath cannot be empty"
	assert full_op_path and full_op_path.strip(), "full_op_path cannot be empty"

	# find and destroy the old node if it exists
	existing_dat = td.op(full_op_path)
	if existing_dat is not None:
		print(f"   add_python_dat: op {full_op_path} already exists, deleting")
		existing_dat.destroy()

	# clean the input path to normalize slashes and remove leading/trailing slashes
	clean_relative_path: str = os.path.normpath(proj_relative_filepath).strip("/\\")

	expression_string: str = f"project.folder + '/{clean_relative_path}'"

	
	parent_network_path, node_name = os.path.split(full_op_path)
	parent_network = td.op(parent_network_path) if parent_network_path else td.root
	
	assert parent_network is not None, f"Target container network '{parent_network_path}' does not exist!"

	# 4. Use the simplified TouchDesigner design pattern to create the operator
	new_dat: td.textDAT = parent_network.create(td.textDAT, node_name)
	new_dat.par.file.expr = expression_string
	new_dat.par.syncfile = True
	
	# position:
	new_dat.nodeX = initial_pos[0] + (index * NODE_OFFSET_DISTANCE)
	new_dat.nodeY = initial_pos[1]
	
	return new_dat