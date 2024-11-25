# [code_utils_one_cell.py](../../../../.tools/notebook_autoconversion/code_utils_one_cell.py)

### param_to_widget(`code`) <a name="param_to_widget"></a>
Goes through the `code` string and applies the following changes:
1. Extracts the components from the lines that contain `@param` (Google Colab's way of indicating a form/widget).
2. Using the information from the extracted components, replaces them with `ipywidgets` with the same functionality.

### extract_values_from_variables(`variable_list`)
Goes trough each `{variable}` on the given `valriable_list` and creates a string where the values of their widgets are extracted and stored on the variables.

```
{variable} = widget_{variable}.value
```

### clear_excesive_empty_lines(`data`)
Removes excessive empty lines from the given `data` string.

### is_only_comments(`code`)
Checks if the given `code` consists only of Python comments.

### count_spaces(`sentence`)
Counts the number of leading spaces in a given `sentence`.

### code_to_cell(`code`, `time_imported`, `ipywidget_imported`, `function_name`)
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

# [markdown_utils.py](../../../../.tools/notebook_autoconversion/markdown_utils.py)

### markdown_to_cell(`text`, `section_localizer`, `cell_idx`)

Takes the text from a markdown cell and updates the section localizer if necessary. 

# [sections.py](../../../../.tools/notebook_autoconversion/sections.py)

### calculate_next_section(`current_section`)

Generates the next section based on the given `current_section`. The section needs to follow the format `X.X.` (e.g. `1.1.`, `2.`, `3.1.2.`, etc.).

For example, if `1.1.` is given, `calculate_next_section` will return `1.2.`. If `2.`is given, it will return `3.`.

# [transform.py](../../../../.tools/notebook_autoconversion/transform.py)