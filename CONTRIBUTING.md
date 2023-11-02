# Contributing to DL4MicEverywhere 

We welcome contributions to help improve and expand DL4MicEverywhere! Here are some ways you can get involved:

## Reporting bugs and issues

If you encounter any bugs or problems with the software, please open a GitHub issue detailing the problem. Include steps to reproduce the issue if applicable. Screenshots are also helpful. This provides a trackable way to get things fixed.

## Suggesting new features

Have an idea for a new feature or improvement? Open an issue to describe your proposal and start a discussion. Focus on the problem to be solved rather than prescribing a specific implementation. 

## Contributing code

Code contributions are welcome via pull requests. Please follow these guidelines:

- Fork the repo and create a new branch for your contribution
- Write clear, concise commit messages documenting your changes 
- Ensure your code follows existing style and conventions
- Add/update any relevant documentation like docstrings, comments etc
- Open a PR with details on the change and tag reviewers

Ensure your code passes all existing tests and linting checks. Adding new test cases is highly encouraged.

## Adding new notebooks

If you wish to contribute a new Jupyter notebook to DL4MicEverywhere, kindly adhere to the following guidelines:

- First have a look at the [Notebook Types](docs/NOTEBOOK_TYPES.md) to understand the different types of notebooks supported.
- The contribution guidelines for notebooks are similar to those of [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic/wiki/How-to-contribute/)
- The notebooks should be self-explanatory and do not require end users to have coding expertise to run them. They should include a graphical user interface (GUI) for easy parameter configuration by users. You can refer to the [U-Net 2D](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/U-Net_2D_ZeroCostDL4Mic.ipynb) notebook as an example.
- The notebooks should include comprehensive documentation and instructions. They should also acknowledge and cite any related publications.

Once you have a working notebook, create a YAML config file under `notebooks/configs` using existing files as a template. Specify the notebook URL, resource requirements, and other metadata. Open a PR with your config - once merged, an automated workflow will handle building and testing the notebook Docker image.

Consider first contributing the base notebook to [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) and then benefit from our automated conversion process.

## Helping with documentation

The docs could always use improvement! Spelling/grammar fixes, clarifications, new sections etc. Just open PRs against the `docs/` files. 

## Engaging with the community

Join the discussions on GitHub issues and PRs. Share your experience and expertise. Help new users get started. The more people engaged, the better this resource becomes!

## Authorship Expectations

The default way to recognize contributions is via the [contributors](https://github.com/HenriquesLab/DL4MicEverywhere/graphs/contributors) section of the repository. The attribution of authorship to future publications derived from the DL4MicEverywhere project are not given "automatically" to contributors and follow the guidelines:

- Authorship roles and expectations are discussed early on in the project and ultimately decided by the senior project leads (Ricardo Henriques and Estibaliz Gomez de Mariscal). This is often an ongoing conversation throughout the project, as roles and contributions may change over time.  
- All authors are expected to contribute significantly to the project. This includes conception, design, development of functionality, data acquisition, analysis and interpretation, and drafting and revising the manuscripts. These contributions are done with prior discussion and agreement of the senior project lead and core development team.

## Code of Conduct

Please note that this project follows a [Contributor Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating in this project you agree to abide by its terms.

Thank you for considering contributing to DL4MicEverywhere!