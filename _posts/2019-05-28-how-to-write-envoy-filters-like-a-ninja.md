---
layout: post
current: post
cover: assets/images/2019-05-28-how-to-write-envoy-filters-like-a-ninja/banner.jpg
navigation: True
title: How to Write Envoy Filters Like a Ninja!
date: 2019-05-28 10:40:00
tags: [Distributed Systems]
class: post-template
subclass: 'post tag-distributed-systems'
author: venilnoronha
---

[Envoy](https://envoyproxy.io) is a programmable L3/L4 and L7 proxy that powers
today’s service mesh solutions including [Istio](https://istio.io), [AWS App
Mesh](https://aws.amazon.com/app-mesh/), [Consul Connect](https://www.consul.io/docs/connect/index.html),
etc. At Envoy’s core lie several filters that provide a rich set of features for
observing, securing, and routing network traffic to microservices.

<p style="text-align: center;">
  <img src="assets/images/2019-05-28-how-to-write-envoy-filters-like-a-ninja/envoy-logo.png" alt="Envoy" style="width: 500px; display: inline-block;" />
</p>

In these set of posts, we’ll have a look at the basics of Envoy filters and
learn how to extend Envoy by implementing custom filters to create useful
features!

##### [Part 1 - Introduction](https://blog.envoyproxy.io/how-to-write-envoy-filters-like-a-ninja-part-1-d166e5abec09?sk=4a62447b92c5889d2b57cc6ca9e5ccac)

-----

**Disclaimer:** My postings are my own and don't necessarily represent VMware's positions, strategies or opinions.
