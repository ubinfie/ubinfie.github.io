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

If you have any questions, you can reach us using in #mmicro-blogsite.

# How can I contribute?

You can report mistakes or errors, create more contents, etc. Whatever is your background, there is probably a way to do it: via the GitHub website, via command-line. If you feel it is too much, you can even write it with any text editor and contact us: we will work together to integrate it.


# How do I add new content?

1. In the [`_posts`](https://github.com/ubinfie/ubinfie.github.io/tree/main/_posts) folder
1. Click "Add a new file" in the top right
1. Add your contents
1. Commit those changes to a new branch (or a fork if you don't have access.)
1. Open a pull request
1https://github.com/ubinfie/ubinfie.github.io/tree/main/_posts. We will review and merge it.

# Running the website locally

1. We recommend using [`rvm`](https://rvm.io/rvm/install) to setup a Ruby installation
1. Install a recent Ruby (e.g. 3.2.0) via `rvm install ruby-3.2.0`
1. Run `gem install bundler`
1. `bundle install` will install this repository's dependencies
1. `bundle exec jekyll serve --livereload` will run the website and dynamically reload it upon changes.
