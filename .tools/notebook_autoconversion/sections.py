
def calculate_next_section(current_section):
    """
    Generates the next section based on the current section. The section needs to follow
    the format X.X. (e.g. 1.1., 2., 3.1.2., etc.)

    Args:
        current_section (str): The current section to calculate the next section from.

    Returns:
        str: The next section.
    """
    current_section_parts = current_section.split('.')
    next_section_parts = current_section_parts.copy()
    next_section_parts[-2] = str(int(next_section_parts[-2]) + 1)
    next_section = '.'.join(next_section_parts)
    return next_section

def find_matching_prefix(string1, string2):
    """
    Find the longest common prefix between two strings.
    
    Args:
        string1 (str): The first string.
        string2 (str): The second string.
    
    Returns:
        str: The longest common prefix between the two strings.
    """
    matching_prefix = ""
    for i in range(min(len(string1), len(string2))):
        if string1[i] == string2[i]:
            matching_prefix += string1[i]
        else:
            break
    return matching_prefix

def update_cell_sections(cells, section_localizer, section_to_rmv, next_section):
    """
    Updates the cell sections in the given list of cells.

    Args:
        cells (list): A list of cells to be updated.
        section_localizer (dict): A dictionary mapping section names to their corresponding cell indices.
        section_to_rmv (str): The section to be removed.
        next_section (str): The section that will follow the removed section.

    Returns:
        tuple: A tuple containing the updated list of cells and the updated section localizer dictionary.
    """
    # Copy the cells and sections (that will be modified)
    updated_cells = cells.copy()
    updated_section_localizer = section_localizer.copy()

    # Get the number of cells that will be removed
    num_removed_cells = section_localizer[next_section] - section_localizer[section_to_rmv]
    matching_section = find_matching_prefix(section_to_rmv, next_section)

    # Look all the sections and remove the matching section
    for section in section_localizer:
        if section.startswith(section_to_rmv):
            updated_section_localizer.pop(section)
    
    # The numbers of sections after the removed section need to be updated
    since_section = next_section.replace(matching_section, '', 1)
    since_section_part = since_section.split('.')
    for section in section_localizer:
        if section.startswith(matching_section):
            acual_section = section.replace(matching_section, '', 1)
            acual_section_part = acual_section.split('.')
            if acual_section_part[0] >= since_section_part[0]:
                cell_id = updated_section_localizer.pop(section)
                updated_section = matching_section + '.'.join([str(int(acual_section_part[0])-1)] + acual_section_part[1:])
                updated_section_localizer[updated_section] = cell_id - num_removed_cells
                updated_cells[cell_id - num_removed_cells].source = updated_cells[cell_id - num_removed_cells].source.replace(section, updated_section, 1)


    return updated_cells, updated_section_localizer

def remove_section(cells, section_localizer, section_to_rmv):
    """
    Remove a section of cells from a list of cells based on the section localizer and the section to remove.

    Parameters:
        cells (list): A list of cells.
        section_localizer (dict): A dictionary mapping section names to cell indices.
        section_to_rmv (str): The name of the section to remove.

    Returns:
        tuple: A tuple containing the updated list of cells and the updated section localizer.
    """
    # Get the index of the section to remove
    cell_idx_to_rmv = section_localizer[section_to_rmv]

    # Calculate the name of the next section
    next_section = calculate_next_section(section_to_rmv)

    # Find the next section that exists in the section localizer
    while next_section not in section_localizer:
        # Calculate the name of the new next section
        new_next_section = '.'.join(next_section.split('.')[:-2]) + '.'
        if new_next_section == '.':
            next_section = section_to_rmv
        next_section = calculate_next_section(new_next_section)
        
    # Get the index of the next section
    next_section_cell_idx = section_localizer[next_section]

    # Remove the section from the list of cells
    reduced_cells = cells[:cell_idx_to_rmv] + cells[next_section_cell_idx:]

    # Update the cell sections and section localizer
    updated_cells, updated_section_localizer = update_cell_sections(reduced_cells, section_localizer, 
                                                                    section_to_rmv, next_section)
    return updated_cells, updated_section_localizer

def remove_section_list(cells, section_localizer, section_list):
    """
    Remove sections from a list of cells and their localizers.

    Parameters:
        cells (list): A list of cells.
        section_localizer (dict): A dictionary mapping section IDs to their localizers.
        section_list (list): A list of section IDs to be removed.

    Returns:
        tuple: A tuple containing the modified list of cells and the updated section localizer dictionary.
    """
    sorted_sections = sorted(section_list, key=lambda x: [int(num) for num in x.split('.')[:-1]], reverse=True)
    for section in sorted_sections:
        cells, section_localizer = remove_section(cells.copy(), section_localizer.copy(), section)

    return cells, section_localizer 