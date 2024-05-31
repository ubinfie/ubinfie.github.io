---
title: Interactive bioinformatics
tags: hci interactivity teaching citizen-science
contributors:
- ammaraziz
reviewers:
- hexylena
---

This blog was inspired by a question on gamification of bioinformatics. So buckle up as we look at a wide range of very cool educational tools and projects!

## Educational

Getting students to try out the command line isn't an easy task, especially in younger generations they are too used to the world of apps, and educators may encounter challenges to teaching these concepts to students who aren't familiar with "files" and "folders" and "hierarchies".

There are a number of educational, interactive games which can be used to help make this process a bit more entertaining and engaging for students:


Resource | About
--- | ---
[Full spectrum Bioinformatics](https://github.com/zaneveld/full_spectrum_bioinformatics) | Little Brother is Missing: Learn how to navigate folders and files through the CLI by playing a spooky game.
[Bashcrawl](https://gitlab.com/slackermedia/bashcrawl) | Learn CLI by playing a dungeon crawler, fight monsters, and pick up spells to help you explore along the way
[PonyLinux](https://github.com/NCGAS/PonyLinux) | Another CLI game but with Ponys! 🎠

Leaving the terminal and moving to bioinformatics itself, there are other interactive resources that can make learning a bit more fun such as:

- [TeachEnG - Illinois Unversity](https://teacheng.illinois.edu/), which provides a collection of interactive web-based games for learning sequence alignment, dot plots and phylogenetic trees.
- [The Great Clade Race - Zombie Island Edition](https://serc.carleton.edu/teachearth/activities/238347.html),
learn cladistics theory through a fun game zombie game. This is particularly interesting as it's more DnD-like.

## Bioinformatics in the Browser

[sandbox.bio](https://sandbox.bio/) is a very cool new resource which runs bioinformatics tools directly in the browser! You can perform actual bioinformatics tasks such as alignment and variant calling all in the browser. Several tutorials on alignment, variant calling, CLI and even jq. All through the [magic of wasm](https://biowasm.com/). The exploration sandboxes are worth checking out if you want to grok how some algorithms work. Note that it will work best on laptops and desktops that have the memory and cpu to allocate to these tools. While WASM is constantly improving there is overhead to trying to run everything in the browser.

## Games for Science

The follow list of games utilise video games to solve biological questions. By playing the game, you're helping science!

- [**Fold it**](https://fold.it/): Learn how protein folding works, compete against other players and help predict protein folding all at once.
- [**EyeWire**](https://eyewire.org/): Traverse real brain scans to mark neurons in 3D space. The music is fantastic but be warned, it's not easy!
- [**EteRNA**](https://eternagame.org/): A fun RNA molecule building game with a nice community. Avaliable on mobile phones as well.

Both of the below projects are from McGill School of Science. Their website and blogs https://dnapuzzles.org details their adventures. 

- [**Zooniverse**](https://www.zooniverse.org/projects): A large collection of citizen science projects that harnse people to find patterns in biological data, identify animals through visual or sound, or mark astroids and space objects.
- **Project Discovery/Borderlands Science** ({% cite SarrazinGendron2024 %}): In-game minigames in EVE Online and Borderlands Science respectively. A site note on EVE Online: If you like tracking things in spreadsheets, checkout EVE Online. 

## Hardcore

[Rosalind.info](https://rosalind.info) is a fantastic way to get your hands dirty solving real world computational problems relating to molecular biology. From counting number of nucleotides to computing HMM profiles, its super fun and educational. The difficult ramps up fast.

## Not bioinformatics related but worthy of a mention:

- [seeing-theory.brown.edu](https://seeing-theory.brown.edu/) Learn statistics through visuals
- [setosa.io/ev/principal-component-analysis/](https://setosa.io/ev/principal-component-analysis/) Understanding PCA 
- [pair-code.github.io/understanding-umap/](https://pair-code.github.io/understanding-umap/) the same for UMAP
- [algorithm-visualizer.org](https://algorithm-visualizer.org/) algorthm visualiser
- [carpentries.org](https://carpentries.org/) for learning to pair-code
- [regexone.com](https://regexone.com) - learn regex through interactive sessions
- [Swirl](https://swirlstats.com/) (Learn R in R)

## Future Work

If you were looking for an MSc project for a student, it would be a wonderful thing to have more free, open-source, interactive games like these that can be embedded in bioinformatics websites everywhere!

Do you have any other resources you'd recommend? Comment below.
