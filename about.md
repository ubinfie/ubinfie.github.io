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
