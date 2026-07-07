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

def init(project_container_name: str = "project1"):
	print("sv_tdsuite initializing begin...")
	
	assert project_container_name and project_container_name.strip(), "project_container_name cannot be empty"
	
	project_container = td.root.op(project_container_name)
	if project_container is None:
		print(f"Error: project_container '{project_container_name}' does not exist in root.")
		return
	
	add_python_dat_nodes()
	
	print("sv_tdsuite initializing completed.")
	
def add_python_dat_nodes():
	# Define where the very first node should sit in the network editor
	start_pos: Tuple[int, int] = (0, 600) 
	
	scripts = [
		("sv_tdsuite/py/sv_tdsuite_init.py", "sv_tdsuite_init"),
		("sv_tdsuite/py/sv.py", "sv"),
		("sv_tdsuite/py/sv_qtouch.py", "sv_qtouch")
	]
	
	for index, (filepath, name) in enumerate(scripts):
		add_python_dat(filepath, name, index, start_pos)
	
# If such op exists in root, it will be deleted and remade.
def add_python_dat(
	proj_relative_filepath: str, # for example, "sv_tdsuite/py/sv.py"
	op_name: str, 
	index: int, 
	initial_pos: Tuple[int, int]
) -> td.textDAT:

	assert proj_relative_filepath and proj_relative_filepath.strip(), "proj_relative_filepath cannot be empty"
	assert op_name and op_name.strip(), "op_name cannot be empty"

	# find and destroy the old node if it exists
	existing_dat = td.root.op(op_name)
	if existing_dat is not None:
		print(f"   add_python_dat: op {op_name} already exists, deleting")
		existing_dat.destroy()

	# clean the input path to normalize slashes and remove leading/trailing slashes
	clean_relative_path: str = os.path.normpath(proj_relative_filepath).strip("/\\")

	expression_string: str = f"project.folder + '/{clean_relative_path}'"

	# create the node and assign the expression
	new_dat: td.textDAT = td.root.create(td.textDAT, op_name)
	new_dat.par.file.expr = expression_string
	new_dat.par.syncfile = True
	
	# position:
	new_dat.nodeX = initial_pos[0] + (index * NODE_OFFSET_DISTANCE)
	new_dat.nodeY = initial_pos[1]
	
	return new_dat