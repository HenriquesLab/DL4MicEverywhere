# Index

- [code_utils_one_cell.py](#code_utils_one_cell.py)
    - [param_to_widget](#param_to_widget)
    - [extract_values_from_variables](#extract_values_from_variables)
    - [clear_excesive_empty_lines](#clear_excesive_empty_lines)
    - [is_only_comments](#is_only_comments)
    - [count_spaces](#count_spaces)
    - [code_to_cell](#code_to_cell)
- [markdown_utils.py](#markdown_utils.py)
    - [markdown_to_cell](#markdown_to_cell)
- [sections.py](#sections.py)
- [transform.py](#transform.py)
---
---

## [code_utils_one_cell.py](../../../../.tools/notebook_autoconversion/code_utils_one_cell.py) <a name="code_utils_one_cell.py"></a>

### param_to_widget(`code`) <a name="param_to_widget"></a>
Goes through the given `code` string and applies the following changes:
1. Extracts the components from the lines that contain `@param` (Google Colab's way of indicating a form/widget).
2. Using the information from the extracted components, replaces them with `ipywidgets` with the same functionality.

### extract_values_from_variables(`variable_list`) <a name="extract_values_from_variables"></a>
Goes trough each `{variable}` on the given `valriable_list` and creates a string where the values of their widgets are extracted and stored on the variables.

```
{variable} = widget_{variable}.value
```

### clear_excesive_empty_lines(`data`) <a name="clear_excesive_empty_lines"></a>
Removes excessive empty lines from the given `data` string. If there are two or more consecutive empty lines, these are transformed into a single empty line. This function is mainly thought for the code cells where pip installation lines where removed and this led to multiple empty lines.

### is_only_comments(`code`) <a name="is_only_comments"></a>
Checks if the given `code` consists only of Python comments. Goes through all the lines and check if they are empty or a comment `# ...`. Returns if it is true or false. This function is mainly though for the code cells that were full of pip installation lines that were removed, letting to a useless code cell.

### count_spaces(`sentence`) <a name="count_spaces"></a>
Counts the number of leading spaces in a given `sentence`. 

### code_to_cell(`code`, `time_imported`, `ipywidget_imported`, `function_name`) <a name="code_to_cell"></a>
Main function on this `code_utils_one_cell.py` file. 

1. It takes the `code` string as input. 
2. Goes line by line of the code and process it in different cases:

    a) If it is an installation line: keep it if it is an installation from the requirements file from a repository and remove it instead.

    b) If it is markdown line: keep it with `display(Markdown(...))` to be rendered in the same conditions.

    c) If it is contain `@param` (Google Colab's way of indicating a form/widget): use the [param_to_widget](#param_to_widget) function to convert it into `ipywidget` code.

    d) Otherwise keep the line. The variables names and the function names are detected and stored.

3. Assemble all the new formatted lines into a single string. 

    a) If it is a code cell with widgets, check `time_imported` and `ipywidget_imported` and if it is needed import `time`and `ipywidgets`respectively imported. Additionally, it creates all the functions and variables necessary to work.

    b) Otherwise, if it is code without widgets, add some prints for showing how the running progress is going.

4. Finally, create a cell with that string using `nbformat`.

## [markdown_utils.py](../../../../.tools/notebook_autoconversion/markdown_utils.py) <a name="markdown_utils.py"></a>

### markdown_to_cell(`text`, `section_localizer`, `cell_idx`) <a name="markdown_to_cell"></a>

Takes the text from a markdown cell and updates the section localizer if necessary. 

## [sections.py](../../../../.tools/notebook_autoconversion/sections.py) <a name="sections.py"></a>

### calculate_next_section(`current_section`) <a name="calculate_next_section"></a>

Generates the next section based on the given `current_section`. The section needs to follow the format `X.X.` (e.g. `1.1.`, `2.`, `3.1.2.`, etc.).

For example, if `1.1.` is given, `calculate_next_section` will return `1.2.`. If `2.`is given, it will return `3.`.

### find_matching_prefix(`string1`, `string2`) <a name="find_matching_prefix"></a>

Given two strings, this function returns the longest common prefix between them. This function is used to detect the longest common prefix on the sections number. For example: on `1.1.3.4.` and `1.1.4.4.` it would return `1.1.`.

### update_cell_sections(`cells`, `section_localizer`, `section_to_rmv`, `next_section`) <a name="update_cell_sections"></a>

Given the list with all the code/markdown cells in a notebook (`cells`) and the dictionary with each section localizer (`section_localizer`), this function removes the given the section number to remove (`section_to_rmv`) and the next section that would be after that (`next_section`), this function updates and returns the list of cells and section localizer based on the `section_to_rmv` and updates the sections from the `next_section` until it is necessary.

### remove_section(`cells`, `section_localizer`, `section_to_rmv`) <a name="remove_section"></a>

Given the list with all the code/markdown cells in a notebook (`cells`) and the dictionary with each section localizer (`section_localizer`), this function removes the given section number (`section_to_rmv`). The `section_localizer`is a dictionary where the keys are the section number and the values the id's of the cells where those sections are located. Additionally, by using `update_cell_sections`, this function updates the section number's of all the sections that need it. Returns a tuple with list of cells and dictionary with section localizer, both updated based on the removed section.

### remove_section_list(`cells`, `section_localizer`, `section_list`) <a name="remove_section_list"></a>

Using [`remove_section`](#remove_section), this function removes a given list of section numbers (`section_list`) from the `cells` and `section_localizer`. Returns a tuple with list of cells and dictionary with section localizer, both updated based on the removed list of sections.

## [transform.py](../../../../.tools/notebook_autoconversion/transform.py) <a name="transform.py"></a>

This is the main Python file on this module, the one that applies the transformation from a ZeroCostDL4Mic's style Colab oriented notebook to a 'colabless' version of it.

### transform_nb(`path_original_nb`, `path_new_nb`, `remove_sections`) <a name="transform_nb"></a>

Given a notebook located on `path_original_nb`, it will convert it into a 'colabless' format and save it on `path_new_nb`. The transformation consist on the steps:

1. Go through the notebook to get the localizer of each section.
2. Remove the sections specified by `remove_sections`using the [`remove_section_list`](#remove_section_list) function. 
3. Go through the notebook, transforming the code cells using [`code_to_cell`](#code_to_cell) and the markdown cells using [`markdown_to_cell`](#markdown_to_cell). Additionally, ff during the transformation of code cells, new cells are required, they will also be added into the new notebook. 

### main() 

Main function that parses the arguments and calls the [`transform_nb`](#transform_nb) function with them. The arguments are:

    -p : Path to the folder where the notebook is stored.
    -n : Name of the notebook file you want to transform.
    -s : List of the sections that you want to remove in the notebook. The sections need to follow the X.X.X. format and be separated with spaces. If you don't want to remove any section, let this argument empty.
