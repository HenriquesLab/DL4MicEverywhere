import os
from urllib.request import urlretrieve
import pandas as pd

# Link to the markdown with all the information about ZCDL4M
save_dir = 'docs/NOTEBOOKS.md'


zcdl4m_url = "https://raw.github.com/wiki/HenriquesLab/ZeroCostDL4Mic/Home.md"
# Recover the text information from the wiki
urlretrieve(zcdl4m_url, 'Home.md')

# Load all the text data from ZCDL4M wiki into memory
home = open('Home.md', 'r')
fileString = home.readlines()
print(f"Number of lines to process {len(fileString)}. ")

nd = pd.DataFrame()
l = 0
nd = None
while l < len(fileString):
    if fileString[l].__contains__("| Network | "):
        # Count the numnber of lines in thable
        k = l
        while fileString[k].__contains__("|"):
            k += 1

        # Store the table
        notebooks_task = fileString[l:k] # save the entire table
        del notebooks_task[1] # Remove the table delimiter from markdown
        # Write a text file that will be loaded as a pandas dataframe
        with open(save_dir, 'w') as f:
            for line in notebooks_task:
                f.write(line)
        # load the notebooks information as a pandas dataframe
        notebooks_task = pd.read_table(save_dir, sep="|", header=0, skipinitialspace=True).dropna(axis=1, how='all')
        # Increment the dataframe with the new notebooks
        if nd is None:
            nd = notebooks_task
        else:
            nd = pd.concat([nd, notebooks_task])
        l = k
    # Stop searching for further tables
    elif fileString[l].__contains__("BioImage.io notebooks"):
        l=len(fileString)
    else:
        l += 1



# Get the relative paths and urls in the wiki
l = 0
dict_list = []
while l < len(fileString):
    # Identify the very first line where references start
    if fileString[l].__contains__("  [1]:"):
        for k in range(l, len(fileString)):
            # Only check those defining something
            if fileString[k].__contains__("]:"):

                string = fileString[k].split("[")[1]
                ref = string.split("]: ")[0]
                ref_url = string.split("]: ")[1]
                ref_url = ref_url.split("\n")[0]

                dict_list.append((ref, ref_url))
        l = k
    else:
        l += 1
# Make a dictionary
Dict = dict(dict_list)
# remove the temporary files
os.remove("Home.md")
# Clean non desired columns from the table
col = [c for c in nd.columns if c.__contains__("Colab")]
nd = nd.drop(columns=col)
# Create a text file with markdown format (i.e. text)
notebooks = nd.to_markdown(index=False)
# Replace all the referenced links
for ref, ref_url in Dict.items():
    notebooks = notebooks.replace(f"[{ref}]", f"({ref_url})")
# Store the text as a markdown
with open(save_dir, 'w') as f:
    f.write(notebooks)
print(f"Notebook markdown stored at {save_dir}")

