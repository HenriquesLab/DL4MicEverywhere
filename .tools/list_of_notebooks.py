import os
from urllib.request import urlretrieve
import pandas as pd

# Link to the markdown with all the information about ZCDL4M
save_dir = '../docs/NOTEBOOKS.md'


zcdl4m_url = "https://github.com/HenriquesLab/ZeroCostDL4Mic/wiki/Home.md"
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

# remove the temporary files
os.remove("Home.md")

# Clean non desired columns from the table
col = [c for c in nd.columns if c.__contains__("Colab")]
nd = nd.drop(columns=col)
notebooks = nd.to_markdown(index=False)
with open(save_dir, 'w') as f:
    f.write(notebooks)
print(f"Notebook markdown stored at {save_dir}")

