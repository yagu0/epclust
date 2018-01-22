# Clustering of EDF power curves from Linky data

Joint work with [Jairo Cugliari](http://eric.univ-lyon2.fr/~jcugliari/),
[Yannig Goude](https://scholar.google.com/citations?user=D-OLEG4AAAAJ&hl=fr) and
[Jean-Michel Poggi](http://www.math.u-psud.fr/~poggi/)

---

This program takes N time-series in input and is divided in two stages:
  1. (Heuristic) k-medoids algorithm in parallel to obtain K1 centers, K1 &#8810; N
  2. Clustering from WER distances to obtain the final K2 &lt; K1 group representations

See ?epclust once the package is loaded.
