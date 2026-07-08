# This is the most common utils module!!!

import os
import td
from typing import Any, Tuple

# Input: 	proj_relative_filepath is a file path relative to the project folder.
# 		 	If it starts with a slash, it will be ignored.
#
# Returns: 	python expression, that will look into current project
# 			folder and point to this file
def project_relative_file_path_to_expression(proj_relative_filepath : str) -> str:
	assert proj_relative_filepath and proj_relative_filepath.strip(), "proj_relative_filepath cannot be empty"
	proj_relative_filepath = proj_relative_filepath.strip()
	
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
def process_abs_path(absolutePath : str) -> Tuple[Any, str, Any] | None:
	assert absolutePath.startswith('/'), f"absolutePath bad value [{fullPath}], must start with slash /"
	
	parent_node_path, node_name = os.path.split(absolutePath)
	parent_node = td.op(parent_node_path) if parent_node_path else td.root
	
	end_node = td.op(absolutePath)
	
	return parent_node, node_name, end_node

# in root
OPNAME_OF_DAT_WITH_PROJECT_NAME = "svag_projname"
def save_projname(project_node_name : str, node_pos : Tuple[int, int]):
	assert project_node_name and project_node_name.strip(), "project_node_name cannot be empty"
	
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