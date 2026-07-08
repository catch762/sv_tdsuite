# This is the most common utils module!!!

import os
import td
from typing import Any, Tuple

def cleanstr(string : str) -> str:
	assert string, "String must be non-empty!"
	stripped_version = string.strip()
	assert stripped_version, "String must be non-empty after strip!"
	return stripped_version
	

# Input: 	proj_relative_filepath is a file path relative to the project folder.
# 		 	If it starts with a slash, it will be ignored.
#
# Returns: 	python expression, that will look into current project
# 			folder and point to this file
def project_relative_file_path_to_expression(proj_relative_filepath : str) -> str:
	proj_relative_filepath = cleanstr(proj_relative_filepath)
	
	# clean the input path to normalize slashes and remove leading/trailing slashes
	clean_relative_path: str = os.path.normpath(proj_relative_filepath).strip("/\\")
	expression_string: str = f"project.folder + '/{clean_relative_path}'"
	return expression_string

# Expects full path, never relative. Must start with slash /
#
# Example:
# 	Input: 		"/project1/hello/world"
# 	Returns: 	[parent_node = op for node at "/project1/hello" if it exists,
#				 node_name 	 = "world",
#				 end_node 	 = op for node at "/project1/hello/world" if it exists]
def process_abs_path(absolute_path : str) -> Tuple[Any, str, Any] | None:
	absolute_path = cleanstr(absolute_path)
	assert absolute_path.startswith('/'), f"absolute_path bad value [{fullPath}], must start with slash /"
	
	parent_node_path, node_name = os.path.split(absolute_path)
	parent_node = td.op(parent_node_path) if parent_node_path else td.root
	
	end_node = td.op(absolute_path)
	
	return parent_node, node_name, end_node

def process_projrel_path(proj_relative_path : str) -> Tuple[Any, str, Any] | None:
	return process_abs_path(proj_relative_path_to_abs(proj_relative_path))
	
def proj_relative_path_to_abs(proj_relative_path : str):
	proj_relative_path = cleanstr(proj_relative_path)
	return f"/{projname()}/{proj_relative_path}"

#returns True if node was found and deleted, otherwise False
def destroy_if_exists(node):
	if node is not None:
		node.destroy()
		return True
	else:
		return False

# in root
OPNAME_OF_DAT_WITH_PROJECT_NAME = "svag_projname"
def save_projname(project_node_name : str, node_pos : Tuple[int, int]):
	project_node_name = cleanstr(project_node_name)
	
	existing_dat_node = td.root.op(OPNAME_OF_DAT_WITH_PROJECT_NAME)
	if existing_dat_node is not None:
		existing_dat_node.destroy()
		
	dat_node: td.textDAT = td.root.create(td.textDAT, OPNAME_OF_DAT_WITH_PROJECT_NAME)
	dat_node.text = project_node_name
	dat_node.nodeX = node_pos[0]
	dat_node.nodeY = node_pos[1]
	print(f"Saved project name: [{projname()}]")
	
def projname() -> str | None:
	dat_node = td.root.op(OPNAME_OF_DAT_WITH_PROJECT_NAME)
	if dat_node is None:
		print(f"Couldnt get proj name, because didnt find dat node [{OPNAME_OF_DAT_WITH_PROJECT_NAME}]")
		return None
	
	return dat_node.text