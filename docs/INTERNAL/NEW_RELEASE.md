# How to make a new release?
Instead of the classic way of creating a new release:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/INTERNAL_DOCUMENTATION/Draft_new_release.png" alt="Regular draft new release." width="60%" height="60%" />

You need to follow these steps to correctly create the release with the executable launcher uploaded within it:

1. First, create a Markdown file in the CHANGELOG folder.

    * The name of the Markdown file should follow the version `X.X.X` format (e.g., `2.0.1.md`).
    * Everything you write in this file will appear in the release notes.

2. Next, create a new tag with the same version name as the one used in the CHANGELOG file. (Look below to know how to create the tag).

3. Finally, push the commit with the newly created tag.
    * This will trigger the CI process to create the release.
    * Note: The CI will fail if the corresponding CHANGELOG file has not been created, so ensure the file is in place beforehand.

## Create a tag on GitHub

### Use the terminal

First of all you need to create the new tag:

```bash
git tag X.X.X
```

This will create a local tag with the current state of the branch you are on. When pushing to your remote repository, tags are NOT included by default. You will need to explicitly say that you want to push your tags to your remote repository.

You can push all the tags:

```bash
git push origin --tags
```

Or a single tag:
```bash
git push origin X.X.X
```

### Use GitHub Desktop

You can read the amazing [official GitHub documentation](https://docs.github.com/en/desktop/managing-commits/managing-tags-in-github-desktop) on how to manage tags.