import re 

# Usefull regular expressions 
heading_regex = r'^(#+)(.*)$'
section_regex = r'^#+\s*\**([\d.]+)'

def markdown_to_cell(text, section_localizer, cell_idx):
    """
    Converts markdown text into a cell representation and updates the section localizer.

    Args:
        text (str): The markdown text to be converted.
        section_localizer (dict): A dictionary mapping section names to cell indices.
        cell_idx (int): The index of the current cell.

    Returns:
        tuple: A tuple containing the converted text and the updated section localizer.
    """
    lines = text.split('\n')
    new_text = ''
    for line in lines:
        heading_match = re.match(heading_regex, line)
        if heading_match:
            section_match = re.match(section_regex, line)
            if section_match:
                section_localizer[section_match.group(1)] = cell_idx
        new_text += line + '\n'
    return new_text, section_localizer