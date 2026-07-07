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

4.	Optional: if you want to rerun it, you can do it with simpler command:
	
		op('/sv_tdsuite_init').module.init()

"""

import os
import td

def init():
	print("sv_tdsuite initializing begin...")
	
	add_python_dat("sv_tdsuite/py/sv_tdsuite_init.py", "sv_tdsuite_init")
	add_python_dat("sv_tdsuite/py/sv.py", "sv")
	add_python_dat("sv_tdsuite/py/sv_qtouch.py", "sv_qtouch")
	
	print("sv_tdsuite initializing completed.")
	
def add_python_dat(proj_relative_filepath: str, op_name: str) -> td.textDAT:

	assert proj_relative_filepath and proj_relative_filepath.strip(), "projRelativeFilePath cannot be empty"
	assert op_name and op_name.strip(), "opName cannot be empty"

	# Find and destroy the old node if it exists
	existing_dat = td.root.op(op_name)
	if existing_dat is not None:
		print(f"   add_python_dat: op {op_name} already exists, deleting")
		existing_dat.destroy()

	# Clean the input path to normalize slashes and remove leading/trailing slashes
	clean_relative_path: str = os.path.normpath(proj_relative_filepath).strip("/\\")

	expression_string: str = f"project.folder + '/{clean_relative_path}'"

	# Create the node and assign the expression
	new_dat: td.textDAT = td.root.create(td.textDAT, op_name)
	new_dat.par.file.expr = expression_string
	new_dat.par.syncfile = True
	return new_dat