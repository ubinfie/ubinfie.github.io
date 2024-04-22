---
layout: page
title: Contributing
---

The µbinfie blog is a peer-reviewed collection of thing we microbial bioinformaticians have thought worth writing down for posterity.

🎉 First off, thanks for taking the time to contribute! 🎉

The following is a set of guidelines for contributing to this training material on GitHub.

# Table of contents

- [What should I know before I get started?](#what-should-i-know-before-i-get-started)
- [How can I contribute?](#how-can-i-contribute)
- [How do I add new content?](#how-do-i-add-new-content)
- [How is the training material maintained?](#how-is-the-training-material-maintained)

# What should I know before I get started?

By contributing, you agree that we may redistribute your work under [this repository's license](LICENSE).

We will address your issues and/or assess your change proposal as promptly as we can, and help you become a member of our community.

If you have any questions, you can reach us using GitHub issues, or another manner.

# How can I contribute?

You can report mistakes or errors, create more contents, etc. Whatever is your background, there is probably a way to do it: via the GitHub website, via command-line. If you feel it is too much, you can even write it with any text editor and contact us: we will work together to integrate it.


# How do I add new content?

1. In the [`_posts`](https://github.com/ubinfie/ubinfie.github.io/tree/main/_posts) folder
1. Click "Add a new file" in the top right
1. Add your contents
1. Commit those changes to a new branch (or a fork if you don't have access.)
1. Open a pull request. We will review and merge it.

# Writing collaboratively
A good methoded of writing a new post with multiple authors simultaneously is the online editor [HackMD.io](https://hackmd.io/new),
where authors can edit the same document in real-time.
Optionally, it is possible to log-in using your GitHub or Google account, which allows for adding comments to the document.
Once the text is written, just copy and paste it to the new post as described above.

# Running the website locally

1. We recommend using [`rvm`](https://rvm.io/rvm/install) to setup a Ruby installation
1. Install a recent Ruby (e.g. 3.2.0) via `rvm install ruby-3.2.0`
1. Run `gem install bundler`
1. `bundle install` will install this repository's dependencies
1. `bundle exec jekyll serve --livereload` will run the website and dynamically reload it upon changes.

# Running the website using Docker

1. [Install Docker](https://docs.docker.com/engine/install/) if you have not already done so.
1. Run the `./serve.sh` script in the top level of the repository. This will download the Ruby 3.2 Docker image and use it to serve the website on `https://localhost:4000`.

# Post Metadata

Each post should have a metadata block at the top of the file. This is used to generate the post's page and should look like:

```yaml
---
title: Welcome to the µbinfie blog
tags: news blog meta
contributors:
- hexylena
---
```

The tags can be provided as space separated, or as a proper yaml list. Contributors should be referenced in `CONTRIBUTORS.yaml`.

If you wish to link to an external blog post, please format it like this:

```
---
title: An external blog post
external: https://example.org
---
```

# Writing Markdown

This uses standard markdown so all of your favourite constructs are available like **bold** and *italic* and ~~struck~~ text.

## Mentioning People

Simply write their username `@ username` (without the space) and it'll be rendered: @happykhan

## Code Highlighting

Code syntax highlighting is available when you tag the language you're using:

````
```perl
$a = 0;
```
````

will produce:

```perl
$a = 0;
```

## Citing

Citations are possible with `{% raw %}{% cite Bankevich2012 %}{% endraw %}`, which render like: {% cite Bankevich2012 %}. They will appear at the bottom of the page and be appropriately hyperlinked.
The BibTeX formatted citation should be placed in `references.bib`, we suggest using [doi2bib](https://www.doi2bib.org/) to convert your publication into the appropriate format.
