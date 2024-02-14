import re
import nbformat

# Usefull regular expressions 
installation_regex = r'(pip|conda) install (.*)'
float_regex = r"[-+]?\d*\.\d+|[-+]?\d+"
ipywidget_style = "{'description_width': 'initial'}"
param_regex = r"(\w+)\s*=\s*([\S\s]+?)\s*#@param\s*(.+)"

assignation_regex =  r'^\s*([a-zA-Z_]\w*(?:\s*,\s*[a-zA-Z_]\w*)*)\s*=\s*.*$'
function_regex = r"^\s*def\s+([a-zA-Z_]\w*)\s*\(.+\)\s*:\s*$"

raw_regex = r"\{type:\"raw\"\}"
comment_after_param_regex = r"(\[[^\]]*\]|\{[^}]*\})(?: [^#]*)?(\[[^\]]*\]|\{[^}]*\})* *#.*"

ipywidget_imported_code = ("import ipywidgets as widgets\n" 
                        "from IPython.display import display, clear_output\n"
                        "import yaml as yaml_library\n"
                        "import os\n"
                        "\n"
                        "ipywidgets_edit_yaml_config_path = os.path.join(os.getcwd(), 'results', 'widget_prev_settings.yaml')\n"
                        "\n"
                        "def ipywidgets_edit_yaml(yaml_path, key, value):\n"
                        "    if os.path.exists(yaml_path):\n"
                        "        with open(yaml_path, 'r') as f:\n"
                        "            config_data = yaml_library.safe_load(f)\n"
                        "    else:\n"
                        "        config_data = {}\n"   
                        "    config_data[key] = value\n"
                        "    with open(yaml_path, 'w') as new_f:\n"
                        "        yaml_library.safe_dump(config_data, new_f, width=10e10, default_flow_style=False)\n"
                        "\n"
                        "def ipywidgets_read_yaml(yaml_path, key):\n"
                        "    if os.path.exists(yaml_path):\n"
                        "        with open(yaml_path, 'r') as f:\n"
                        "            config_data = yaml_library.safe_load(f)\n"
                        "        value = config_data.get(key, '')\n"
                        "        return value\n"
                        "    else:\n"
                        "        return ''\n"
                        "\n")    

def param_to_widget(code):
    """
    Extracts components from a line with @param and creates ipywidgets based on the extracted information.
    Parameters:
        code (str): The line of code containing the @param component.

    Returns:
        str: The generated widget code.
        str: The name of the variable associated with the widget.
    """
    # Flag to check if the value needs to be evaluated
    needs_to_be_evaluated = False

    # Extract the components from a line with @param component
    match_param = re.search(param_regex, code)
    var_name = match_param.group(1)
    default_value = match_param.group(2)
    post_param = match_param.group(3)
    
    # Remove whitespaces at the beginning and at the end
    default_value = default_value.strip()

    if re.match(comment_after_param_regex, post_param):
        # In case is the strange scenario with comment after @param 
        # And after it will be treated as raw parameter

        if default_value[0] in ['\"', '\''] and default_value[0] == default_value[-1]:
            result = f'widget_{var_name} = widgets.Text(value={default_value}, style={ipywidget_style}, description="{var_name}:")\n'
        else:
            if '\"' in default_value or '\'' in default_value:
                result = f'widget_{var_name} = widgets.Text(value="""({default_value})""", style={ipywidget_style}, description="{var_name}:")\n'
            else:
                result = f'widget_{var_name} = widgets.Text(value="""{default_value}""", style={ipywidget_style}, description="{var_name}:")\n'

        # As it is a raw parameter, the value needs to be evaluated
        needs_to_be_evaluated = True

    else:
        # Extract the type of the @param
        match_type = re.findall(r"{type:\s*\"(\w+)\".*}", post_param)
        param_type = match_type[0] if match_type else None

        # Extract and check if instead of a type, a list is defined 
        match_list = re.findall(r"(\[.*?\])", post_param)
        if match_list:
            possible_values = match_list[0]

            if re.findall(r"{allow-input:\s*true}", post_param):
                # In case the variable allow-input is found, a Combobox ipywidget is added (allowing new inputs)
                result = f'widget_{var_name} = widgets.Combobox(options={possible_values}, placeholder={default_value}, style={ipywidget_style}, description="{var_name}:")\n'
            else:
                # If not, a Dropdown ipywidget is added

                # In case the default value is not in the given list of possible values the first one will be selected
                # For that we need to extract the list of possible values and then check if it is in there
                if ',' in possible_values:
                    list_possible_values = [item.strip() for item in possible_values.strip('[]').split(',')]
                else:
                    list_possible_values =  [possible_values.strip('[]').strip()]
                default_value = default_value if default_value in list_possible_values else list_possible_values[0]

                # In case its a raw parameter, a Dropdown ipywidget is added that will be then evaluated with eval()
                if param_type is not None and param_type == "raw":
                    possible_values = [str(i.strip('\'\"')) for i in list_possible_values]

                    if default_value[0] in ['\"', '\''] and default_value[0] == default_value[-1]:
                        result = f'widget_{var_name} = widgets.Dropdown(options={possible_values}, value={default_value}, style={ipywidget_style}, description="{var_name}:")\n'
                    else:
                        if '\"' in default_value or '\'' in default_value:
                            result = f'widget_{var_name} = widgets.Dropdown(options={possible_values}, value="""({default_value})""", style={ipywidget_style}, description="{var_name}:")\n'
                        else:
                            result = f'widget_{var_name} = widgets.Dropdown(options={possible_values}, value="""{default_value}""", style={ipywidget_style}, description="{var_name}:")\n'

                     # As it is a raw parameter, the value needs to be evaluated
                    needs_to_be_evaluated = True
                    
                else:
                    result = f'widget_{var_name} = widgets.Dropdown(options={possible_values}, value={default_value}, style={ipywidget_style}, description="{var_name}:")\n'

        elif param_type is not None:
            # If it is not a list a list of values, it would be one of the following types (adding ipywidgets based on the type)
            if param_type == "slider":
                min, max, step = re.findall(f"\s*min:({float_regex}),\s*max:({float_regex}),\s*step:({float_regex})", post_param)[0]
                try:
                    min, max, step = int(min), int(max), int(step)
                    result = f'widget_{var_name} = widgets.IntSlider(value={default_value}, min={min}, max={max}, step={step}, style={ipywidget_style}, description="{var_name}:")\n'
                except:
                    min, max, step = float(min), float(max), float(step)
                    result = f'widget_{var_name} = widgets.FloatSlider(value={default_value}, min={min}, max={max}, step={step}, style={ipywidget_style}, description="{var_name}:")\n'

            if param_type == "integer":
                result = f'widget_{var_name} = widgets.IntText(value={default_value}, style={ipywidget_style}, description="{var_name}:")\n'
            elif param_type == "number":
                
                if '.' in default_value:
                    result = f'widget_{var_name} = widgets.FloatText(value={default_value}, style={ipywidget_style}, description="{var_name}:")\n'
                else:
                    result = f'widget_{var_name} = widgets.IntText(value={default_value}, style={ipywidget_style}, description="{var_name}:")\n'
            
            elif param_type == "boolean":
                result = f'widget_{var_name} = widgets.Checkbox(value={default_value}, style={ipywidget_style}, description="{var_name}:")\n'
            elif param_type == "string" or param_type == "raw":

                if param_type == "raw":
                    # If it is raw type, needs to be evaluated
                    needs_to_be_evaluated = True

                if default_value[0] in ['\"', '\''] and default_value[0] == default_value[-1]:
                    result = f'widget_{var_name} = widgets.Text(value={default_value}, style={ipywidget_style}, description="{var_name}:")\n'
                else:
                    # In case the default value is not an string, that means that needs to be evaluated
                    if '\"' in default_value or '\'' in default_value:
                        result = f'widget_{var_name} = widgets.Text(value="""({default_value})""", style={ipywidget_style}, description="{var_name}:")\n'
                    else:
                        result = f'widget_{var_name} = widgets.Text(value="""{default_value}""", style={ipywidget_style}, description="{var_name}:")\n'
                    needs_to_be_evaluated = True
                
            elif param_type == "date":
                result = ('from datetime import datetime\n'
                        f'widget_{var_name} = widgets.DatePicker(value=datetime.strptime({default_value}, "%Y-%m-%d"),style={ipywidget_style}, description="{var_name}:")\n'
                        )
                
        else:
            # Even if it has #@param, it does not follow colab param format
            return code, '', needs_to_be_evaluated
            
    # In case it has colab param format 
    result += f'display(widget_{var_name})'
    return result, var_name, needs_to_be_evaluated

def extract_values_from_variables(variable_list):
    """
    Extracts the selected values from the given list of variables.
    Parameters:
        variable_list (list): A list of variables.
    Returns:
        str: A string containing the extracted values.
    """
    
    result = '# Run this cell to extract the selected values in previuous cell\n'
    for var in variable_list:
        result += f"{var} = widget_{var}.value\n"
    return result

def clear_excesive_empty_lines(data):
    """
    Remove excessive empty lines from the given string.
    Parameters:
    - data (str): The input string.

    Returns:
    - str: The string with excessive empty lines removed.
    """

    # Split the string into a list of lines
    lines = data.splitlines()

    # Remove consecutive empty lines
    new_lines = []
    for i, line in enumerate(lines):
        if i == 0 or line.strip() or lines[i-1].strip():
            new_lines.append(line)

    # Join the lines back into a string
    new_string = "\n".join(new_lines)

    return new_string

def is_only_comments(code):
    """
    Check if the given code consists only of comments.
    Parameters:
    - code (str): The code to be checked.
    Returns:
    - is_only_comments (bool): True if the code consists only of comments, False otherwise.
    """
    
    is_only_comments = all(line.strip().startswith('#') or not line.strip() for line in code.split('\n'))
    return is_only_comments

def count_spaces(sentence):
    """
    Count the number of leading spaces in a given sentence.
    Parameters:
        sentence (str): The sentence to count the leading spaces in.
    Returns:
        int: The number of leading spaces in the sentence.
    """
    
    match = re.match(r'^\s*', sentence)
    if match:
        return len(match.group(0))
    else:
        return 0

def code_to_cell(code, time_imported, ipywidget_imported, function_name):
    """
    Generates a list of code cells for a Jupyter notebook based on the given code.
    Parameters:
    - code (str): The code to be converted into code cells.
    - ipywidget_imported (bool): Indicates whether the `ipywidgets` library has already been imported.
    - function_name (str): The name of the function to be created.
    Returns:
    - new_cells (list): A list of code cells generated from the given code.
    - ipywidget_imported (bool): An updated value indicating whether the `ipywidgets` library has been imported.
    """
    
    # Future lines of code that are based on widgets or not
    widget_code = ''
    non_widget_code = ''
    cache_code = ''
    futute_imports = ''
    
    # List of variables and functions that need to be defined as global
    widget_var_list = []
    var_list = []
    func_list = []

    # We are going line by line analyzing them
    lines = code.split('\n')  
    for line in lines:
        installation_match = re.search(installation_regex, line)
        if installation_match:
            library_name = installation_match.group(2)

            # Remove the comment
            if '#' in library_name:
                library_name = library_name[:library_name.index('#')]

            # Only the installation lines of an external library are kept
            if '-r ' in library_name or '--requirement ' in library_name or '-e ' in library_name or '--editable ' in library_name or library_name=='.':
                widget_code += line + '\n'
                
        elif re.search(param_regex, line):
            # The lines with #@param are replaced with ipywidgets based on the parameters
            new_line, var_name, needs_to_be_evaluated = param_to_widget(line)
            if var_name != "" and var_name not in widget_var_list:
                widget_var_list.append(var_name)
            widget_code += new_line + '\n'

            if needs_to_be_evaluated:
                # It needs to be evaluated
                non_widget_code += ' ' * count_spaces(line) + f"{var_name} = eval(widget_{var_name}.value)\n"
                non_widget_code += ' '*count_spaces(line) + f"ipywidgets_edit_yaml(ipywidgets_edit_yaml_config_path, '{function_name}_{var_name}', eval(widget_{var_name}.value))\n" 
            else:
                non_widget_code += ' '*count_spaces(line) + f"{var_name} = widget_{var_name}.value\n"
                non_widget_code += ' '*count_spaces(line) + f"ipywidgets_edit_yaml(ipywidgets_edit_yaml_config_path, '{function_name}_{var_name}', widget_{var_name}.value)\n" 

            cache_code += f"cache_{var_name} = ipywidgets_read_yaml(ipywidgets_edit_yaml_config_path, '{function_name}_{var_name}')\n"
            cache_code += f"if cache_{var_name} != '':\n"
            cache_code += f"    widget_{var_name}.value = cache_{var_name}\n\n"
            
        else:
            # In the other the variable and function names are extracted
            assign_match = re.match(assignation_regex, line)
            if assign_match:
                possible_variables = assign_match.group(1).split(',')
                for var in possible_variables:
                    var_list.append(var)
            
            function_match = re.match(function_regex, line)
            if function_match:
                func_list.append(function_match.group(1))

            # And the line is added as it is
            if re.match("from __future__ import.*", line) or re.match("import __future__.*", line):
                # In case it is a future import, it is added to the future imports
                futute_imports += line + '\n'
            else:
                # In case it is not a future import, it is added to the non widget code
                non_widget_code += line + '\n'

    new_cells = []

    if widget_var_list:
        # In case a param was found, everything will be encapsulated in a function

        # For that all the code needs to be tabbed inside the function
        tabbed_non_widget_code = ""

        for line in non_widget_code.split('\n'):
            tabbed_non_widget_code += " "*4 + line + '\n'

        tabbed_cache_code = ""
        for line in cache_code.split('\n'):
            tabbed_cache_code += " "*4 + line + '\n'

        # Global variables that will be inside the function in order to be accesible in the notebook
        global_widgets_var = "".join([" "*4 + f"global {var}\n" for var in widget_var_list])
        global_var = "".join([" "*4 + f"global {var}\n" for var in var_list])
        global_func = "".join([" "*4 + f"global {var}\n" for var in func_list])

        global_variables = global_widgets_var + '\n' + global_var + '\n' + global_func

        # All the new lines of code are ensambled
        code_cell = "# Run this cell to visualize the parameters and click the button to execute the code\n"
        code_cell +=  futute_imports
        if not time_imported:
            # In case the time library have not been imported yet
            code_cell += ("from datetime import datetime\n")       
            time_imported = True
        # Print running and store the initial_time
        code_cell += ("internal_aux_initial_time=datetime.now()\n")  
                    
        if not ipywidget_imported:
            # In case the ipywidgets library have not been imported yet
            code_cell += ipywidget_imported_code
            ipywidget_imported = True

        code_cell += ("clear_output()\n\n" # In orther to renew the ipywidgets
                    ) + widget_code + ( # Add the code with the widgets at the begining of the cell
                    f"\ndef {function_name}(output_widget):\n" # The function that will be called whwn clicking the button
                    "  output_widget.clear_output()\n" # Clear the output that was displayed when calling the function
                    "  with output_widget:\n" # In order to display the output
                    ) + global_variables + '\n' + tabbed_non_widget_code + ( # Add the global variables and the non widget code
                    "    plt.show()\n" # Add plt.show() in case there is any plot in tab_non_widget_code, so that it can be displayed
                    f"\ndef {function_name}_cache(output_widget):\n"
                    ) + global_variables + '\n' + tabbed_cache_code + (
                    "\n"
                    f"button_{function_name} = widgets.Button(description='Load and run')\n" # Add the button that calls the function
                    f"cache_button_{function_name} = widgets.Button(description='Load prev. settings')\n" # Add the button that calls the cache function
                    f"output_{function_name} = widgets.Output()\n"
                    f"display(widgets.HBox((button_{function_name}, cache_button_{function_name})), output_{function_name})\n"
                    f"def aux_{function_name}(_):\n" 
                    f"  return {function_name}(output_{function_name})\n\n"
                    f"def aux_{function_name}_cache(_):\n" 
                    f"  return {function_name}_cache(output_{function_name})\n\n"
                    f"button_{function_name}.on_click(aux_{function_name})\n"
                    f"cache_button_{function_name}.on_click(aux_{function_name}_cache)\n"
                    )
        
        # Print finnished and final time
        code_cell += ("print('--------------------------------------------------------------')\n"
                      "print('^ Introduce the arguments and click \"Load and run\". ^')\n"
                      "print('^ Or first click \"Load prev. settings\" if any previous ^')\n"
                      "print('^ settings have been saved and then click \"Load and run\". ^')\n") 

    else:
        # Otherwise, just add the code
        code_cell = "# Run this cell to execute the code\n" 
        code_cell +=  futute_imports
        
        # We want the imports to be in the first cell, even if it does not have ipywidgets
        if not time_imported:
            # In case the time library have not been imported yet
            code_cell += ("from datetime import datetime\n")       
            time_imported = True
        if not ipywidget_imported:
            # In case the ipywidgets library have not been imported yet
            code_cell += ipywidget_imported_code
            ipywidget_imported = True    
            
        # Print running and store the initial_time
        code_cell += ("internal_aux_initial_time=datetime.now()\n" 
                      "print('Runnning...')\n"
                      "print('--------------------------------------')\n")
        code_cell +=  non_widget_code
        
        code_cell += ("print('--------------------------------------')\n"
                      "print(f'Finnished. Duration: {datetime.now() - internal_aux_initial_time}')\n") 

    #Create the code cell
    aux_cell = nbformat.v4.new_code_cell(clear_excesive_empty_lines(code_cell))
    # Hides the content in the code cells
    aux_cell.metadata["cellView"] = "form"
    aux_cell.metadata["collapsed"] = False
    aux_cell.metadata["jupyter"] = {"source_hidden": True}
            
    new_cells.append(aux_cell)
    
    return new_cells, time_imported, ipywidget_imported
