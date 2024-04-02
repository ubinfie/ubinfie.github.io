---
layout: page
title: About
permalink: /about/
---

The µbinfie blog is a peer-reviewed collection of thing we microbial bioinformaticians have thought worth writing down for posterity.

## Editorial Board

<div style="display: flex; flex-wrap: wrap;">
{% for c in site.data.CONTRIBUTORS %}
{% assign x = c[0] %}
{% include contributor-badge.html id=x %}
{% endfor %}
</div>

### Tasks of the Board

- Suggesting new post topics and ideas
- Reviewing new posts

### Joining

Please let us know in #mmicro-blogsite that you wish to join the editorial board.
(Don't know where to find this? Then this message probably isn't for you!)

### Leaving

If you no longer have time to volunteer for this blogsite, please let us know and we will remove you! Thank you for your contributions.
