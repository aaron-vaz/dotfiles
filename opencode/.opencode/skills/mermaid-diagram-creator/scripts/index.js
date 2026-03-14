import { createRequire } from "node:module";
var __create = Object.create;
var __getProtoOf = Object.getPrototypeOf;
var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __toESM = (mod, isNodeMode, target) => {
  target = mod != null ? __create(__getProtoOf(mod)) : {};
  const to = isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target;
  for (let key of __getOwnPropNames(mod))
    if (!__hasOwnProp.call(to, key))
      __defProp(to, key, {
        get: () => mod[key],
        enumerable: true
      });
  return to;
};
var __commonJS = (cb, mod) => () => (mod || cb((mod = { exports: {} }).exports, mod), mod.exports);
var __require = /* @__PURE__ */ createRequire(import.meta.url);

// node_modules/@dagrejs/dagre/dist/dagre.js
var require_dagre = __commonJS((exports, module) => {
  (function(f) {
    if (typeof exports === "object" && typeof module !== "undefined") {
      module.exports = f();
    } else if (typeof define === "function" && define.amd) {
      define([], f);
    } else {
      var g;
      if (typeof window !== "undefined") {
        g = window;
      } else if (typeof global !== "undefined") {
        g = global;
      } else if (typeof self !== "undefined") {
        g = self;
      } else {
        g = this;
      }
      g.dagre = f();
    }
  })(function() {
    var define2, module2, exports2;
    return function() {
      function r(e, n, t) {
        function o(i2, f) {
          if (!n[i2]) {
            if (!e[i2]) {
              var c = __require;
              if (!f && c)
                return c(i2, true);
              if (u)
                return u(i2, true);
              var a = new Error("Cannot find module '" + i2 + "'");
              throw a.code = "MODULE_NOT_FOUND", a;
            }
            var p = n[i2] = { exports: {} };
            e[i2][0].call(p.exports, function(r2) {
              var n2 = e[i2][1][r2];
              return o(n2 || r2);
            }, p, p.exports, r, e, n, t);
          }
          return n[i2].exports;
        }
        for (var u = __require, i = 0;i < t.length; i++)
          o(t[i]);
        return o;
      }
      return r;
    }()({ 1: [function(require2, module3, exports3) {
      module3.exports = {
        graphlib: require2("@dagrejs/graphlib"),
        layout: require2("./lib/layout"),
        debug: require2("./lib/debug"),
        util: {
          time: require2("./lib/util").time,
          notime: require2("./lib/util").notime
        },
        version: require2("./lib/version")
      };
    }, { "./lib/debug": 6, "./lib/layout": 8, "./lib/util": 27, "./lib/version": 28, "@dagrejs/graphlib": 29 }], 2: [function(require2, module3, exports3) {
      let greedyFAS = require2("./greedy-fas");
      let uniqueId = require2("./util").uniqueId;
      module3.exports = {
        run,
        undo
      };
      function run(g) {
        let fas = g.graph().acyclicer === "greedy" ? greedyFAS(g, weightFn(g)) : dfsFAS(g);
        fas.forEach((e) => {
          let label = g.edge(e);
          g.removeEdge(e);
          label.forwardName = e.name;
          label.reversed = true;
          g.setEdge(e.w, e.v, label, uniqueId("rev"));
        });
        function weightFn(g2) {
          return (e) => {
            return g2.edge(e).weight;
          };
        }
      }
      function dfsFAS(g) {
        let fas = [];
        let stack = {};
        let visited = {};
        function dfs(v) {
          if (Object.hasOwn(visited, v)) {
            return;
          }
          visited[v] = true;
          stack[v] = true;
          g.outEdges(v).forEach((e) => {
            if (Object.hasOwn(stack, e.w)) {
              fas.push(e);
            } else {
              dfs(e.w);
            }
          });
          delete stack[v];
        }
        g.nodes().forEach(dfs);
        return fas;
      }
      function undo(g) {
        g.edges().forEach((e) => {
          let label = g.edge(e);
          if (label.reversed) {
            g.removeEdge(e);
            let forwardName = label.forwardName;
            delete label.reversed;
            delete label.forwardName;
            g.setEdge(e.w, e.v, label, forwardName);
          }
        });
      }
    }, { "./greedy-fas": 7, "./util": 27 }], 3: [function(require2, module3, exports3) {
      let util = require2("./util");
      module3.exports = addBorderSegments;
      function addBorderSegments(g) {
        function dfs(v) {
          let children = g.children(v);
          let node = g.node(v);
          if (children.length) {
            children.forEach(dfs);
          }
          if (Object.hasOwn(node, "minRank")) {
            node.borderLeft = [];
            node.borderRight = [];
            for (let rank = node.minRank, maxRank = node.maxRank + 1;rank < maxRank; ++rank) {
              addBorderNode(g, "borderLeft", "_bl", v, node, rank);
              addBorderNode(g, "borderRight", "_br", v, node, rank);
            }
          }
        }
        g.children().forEach(dfs);
      }
      function addBorderNode(g, prop, prefix, sg, sgNode, rank) {
        let label = { width: 0, height: 0, rank, borderType: prop };
        let prev = sgNode[prop][rank - 1];
        let curr = util.addDummyNode(g, "border", label, prefix);
        sgNode[prop][rank] = curr;
        g.setParent(curr, sg);
        if (prev) {
          g.setEdge(prev, curr, { weight: 1 });
        }
      }
    }, { "./util": 27 }], 4: [function(require2, module3, exports3) {
      module3.exports = {
        adjust,
        undo
      };
      function adjust(g) {
        let rankDir = g.graph().rankdir.toLowerCase();
        if (rankDir === "lr" || rankDir === "rl") {
          swapWidthHeight(g);
        }
      }
      function undo(g) {
        let rankDir = g.graph().rankdir.toLowerCase();
        if (rankDir === "bt" || rankDir === "rl") {
          reverseY(g);
        }
        if (rankDir === "lr" || rankDir === "rl") {
          swapXY(g);
          swapWidthHeight(g);
        }
      }
      function swapWidthHeight(g) {
        g.nodes().forEach((v) => swapWidthHeightOne(g.node(v)));
        g.edges().forEach((e) => swapWidthHeightOne(g.edge(e)));
      }
      function swapWidthHeightOne(attrs) {
        let w = attrs.width;
        attrs.width = attrs.height;
        attrs.height = w;
      }
      function reverseY(g) {
        g.nodes().forEach((v) => reverseYOne(g.node(v)));
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          edge.points.forEach(reverseYOne);
          if (Object.hasOwn(edge, "y")) {
            reverseYOne(edge);
          }
        });
      }
      function reverseYOne(attrs) {
        attrs.y = -attrs.y;
      }
      function swapXY(g) {
        g.nodes().forEach((v) => swapXYOne(g.node(v)));
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          edge.points.forEach(swapXYOne);
          if (Object.hasOwn(edge, "x")) {
            swapXYOne(edge);
          }
        });
      }
      function swapXYOne(attrs) {
        let x = attrs.x;
        attrs.x = attrs.y;
        attrs.y = x;
      }
    }, {}], 5: [function(require2, module3, exports3) {

      class List {
        constructor() {
          let sentinel = {};
          sentinel._next = sentinel._prev = sentinel;
          this._sentinel = sentinel;
        }
        dequeue() {
          let sentinel = this._sentinel;
          let entry = sentinel._prev;
          if (entry !== sentinel) {
            unlink(entry);
            return entry;
          }
        }
        enqueue(entry) {
          let sentinel = this._sentinel;
          if (entry._prev && entry._next) {
            unlink(entry);
          }
          entry._next = sentinel._next;
          sentinel._next._prev = entry;
          sentinel._next = entry;
          entry._prev = sentinel;
        }
        toString() {
          let strs = [];
          let sentinel = this._sentinel;
          let curr = sentinel._prev;
          while (curr !== sentinel) {
            strs.push(JSON.stringify(curr, filterOutLinks));
            curr = curr._prev;
          }
          return "[" + strs.join(", ") + "]";
        }
      }
      function unlink(entry) {
        entry._prev._next = entry._next;
        entry._next._prev = entry._prev;
        delete entry._next;
        delete entry._prev;
      }
      function filterOutLinks(k, v) {
        if (k !== "_next" && k !== "_prev") {
          return v;
        }
      }
      module3.exports = List;
    }, {}], 6: [function(require2, module3, exports3) {
      let util = require2("./util");
      let Graph = require2("@dagrejs/graphlib").Graph;
      module3.exports = {
        debugOrdering
      };
      function debugOrdering(g) {
        let layerMatrix = util.buildLayerMatrix(g);
        let h = new Graph({ compound: true, multigraph: true }).setGraph({});
        g.nodes().forEach((v) => {
          h.setNode(v, { label: v });
          h.setParent(v, "layer" + g.node(v).rank);
        });
        g.edges().forEach((e) => h.setEdge(e.v, e.w, {}, e.name));
        layerMatrix.forEach((layer, i) => {
          let layerV = "layer" + i;
          h.setNode(layerV, { rank: "same" });
          layer.reduce((u, v) => {
            h.setEdge(u, v, { style: "invis" });
            return v;
          });
        });
        return h;
      }
    }, { "./util": 27, "@dagrejs/graphlib": 29 }], 7: [function(require2, module3, exports3) {
      let Graph = require2("@dagrejs/graphlib").Graph;
      let List = require2("./data/list");
      module3.exports = greedyFAS;
      let DEFAULT_WEIGHT_FN = () => 1;
      function greedyFAS(g, weightFn) {
        if (g.nodeCount() <= 1) {
          return [];
        }
        let state = buildState(g, weightFn || DEFAULT_WEIGHT_FN);
        let results = doGreedyFAS(state.graph, state.buckets, state.zeroIdx);
        return results.flatMap((e) => g.outEdges(e.v, e.w));
      }
      function doGreedyFAS(g, buckets, zeroIdx) {
        let results = [];
        let sources = buckets[buckets.length - 1];
        let sinks = buckets[0];
        let entry;
        while (g.nodeCount()) {
          while (entry = sinks.dequeue()) {
            removeNode(g, buckets, zeroIdx, entry);
          }
          while (entry = sources.dequeue()) {
            removeNode(g, buckets, zeroIdx, entry);
          }
          if (g.nodeCount()) {
            for (let i = buckets.length - 2;i > 0; --i) {
              entry = buckets[i].dequeue();
              if (entry) {
                results = results.concat(removeNode(g, buckets, zeroIdx, entry, true));
                break;
              }
            }
          }
        }
        return results;
      }
      function removeNode(g, buckets, zeroIdx, entry, collectPredecessors) {
        let results = collectPredecessors ? [] : undefined;
        g.inEdges(entry.v).forEach((edge) => {
          let weight = g.edge(edge);
          let uEntry = g.node(edge.v);
          if (collectPredecessors) {
            results.push({ v: edge.v, w: edge.w });
          }
          uEntry.out -= weight;
          assignBucket(buckets, zeroIdx, uEntry);
        });
        g.outEdges(entry.v).forEach((edge) => {
          let weight = g.edge(edge);
          let w = edge.w;
          let wEntry = g.node(w);
          wEntry["in"] -= weight;
          assignBucket(buckets, zeroIdx, wEntry);
        });
        g.removeNode(entry.v);
        return results;
      }
      function buildState(g, weightFn) {
        let fasGraph = new Graph;
        let maxIn = 0;
        let maxOut = 0;
        g.nodes().forEach((v) => {
          fasGraph.setNode(v, { v, in: 0, out: 0 });
        });
        g.edges().forEach((e) => {
          let prevWeight = fasGraph.edge(e.v, e.w) || 0;
          let weight = weightFn(e);
          let edgeWeight = prevWeight + weight;
          fasGraph.setEdge(e.v, e.w, edgeWeight);
          maxOut = Math.max(maxOut, fasGraph.node(e.v).out += weight);
          maxIn = Math.max(maxIn, fasGraph.node(e.w)["in"] += weight);
        });
        let buckets = range(maxOut + maxIn + 3).map(() => new List);
        let zeroIdx = maxIn + 1;
        fasGraph.nodes().forEach((v) => {
          assignBucket(buckets, zeroIdx, fasGraph.node(v));
        });
        return { graph: fasGraph, buckets, zeroIdx };
      }
      function assignBucket(buckets, zeroIdx, entry) {
        if (!entry.out) {
          buckets[0].enqueue(entry);
        } else if (!entry["in"]) {
          buckets[buckets.length - 1].enqueue(entry);
        } else {
          buckets[entry.out - entry["in"] + zeroIdx].enqueue(entry);
        }
      }
      function range(limit) {
        const range2 = [];
        for (let i = 0;i < limit; i++) {
          range2.push(i);
        }
        return range2;
      }
    }, { "./data/list": 5, "@dagrejs/graphlib": 29 }], 8: [function(require2, module3, exports3) {
      let acyclic = require2("./acyclic");
      let normalize = require2("./normalize");
      let rank = require2("./rank");
      let normalizeRanks = require2("./util").normalizeRanks;
      let parentDummyChains = require2("./parent-dummy-chains");
      let removeEmptyRanks = require2("./util").removeEmptyRanks;
      let nestingGraph = require2("./nesting-graph");
      let addBorderSegments = require2("./add-border-segments");
      let coordinateSystem = require2("./coordinate-system");
      let order = require2("./order");
      let position = require2("./position");
      let util = require2("./util");
      let Graph = require2("@dagrejs/graphlib").Graph;
      module3.exports = layout;
      function layout(g, opts) {
        let time = opts && opts.debugTiming ? util.time : util.notime;
        time("layout", () => {
          let layoutGraph = time("  buildLayoutGraph", () => buildLayoutGraph(g));
          time("  runLayout", () => runLayout(layoutGraph, time, opts));
          time("  updateInputGraph", () => updateInputGraph(g, layoutGraph));
        });
      }
      function runLayout(g, time, opts) {
        time("    makeSpaceForEdgeLabels", () => makeSpaceForEdgeLabels(g));
        time("    removeSelfEdges", () => removeSelfEdges(g));
        time("    acyclic", () => acyclic.run(g));
        time("    nestingGraph.run", () => nestingGraph.run(g));
        time("    rank", () => rank(util.asNonCompoundGraph(g)));
        time("    injectEdgeLabelProxies", () => injectEdgeLabelProxies(g));
        time("    removeEmptyRanks", () => removeEmptyRanks(g));
        time("    nestingGraph.cleanup", () => nestingGraph.cleanup(g));
        time("    normalizeRanks", () => normalizeRanks(g));
        time("    assignRankMinMax", () => assignRankMinMax(g));
        time("    removeEdgeLabelProxies", () => removeEdgeLabelProxies(g));
        time("    normalize.run", () => normalize.run(g));
        time("    parentDummyChains", () => parentDummyChains(g));
        time("    addBorderSegments", () => addBorderSegments(g));
        time("    order", () => order(g, opts));
        time("    insertSelfEdges", () => insertSelfEdges(g));
        time("    adjustCoordinateSystem", () => coordinateSystem.adjust(g));
        time("    position", () => position(g));
        time("    positionSelfEdges", () => positionSelfEdges(g));
        time("    removeBorderNodes", () => removeBorderNodes(g));
        time("    normalize.undo", () => normalize.undo(g));
        time("    fixupEdgeLabelCoords", () => fixupEdgeLabelCoords(g));
        time("    undoCoordinateSystem", () => coordinateSystem.undo(g));
        time("    translateGraph", () => translateGraph(g));
        time("    assignNodeIntersects", () => assignNodeIntersects(g));
        time("    reversePoints", () => reversePointsForReversedEdges(g));
        time("    acyclic.undo", () => acyclic.undo(g));
      }
      function updateInputGraph(inputGraph, layoutGraph) {
        inputGraph.nodes().forEach((v) => {
          let inputLabel = inputGraph.node(v);
          let layoutLabel = layoutGraph.node(v);
          if (inputLabel) {
            inputLabel.x = layoutLabel.x;
            inputLabel.y = layoutLabel.y;
            inputLabel.rank = layoutLabel.rank;
            if (layoutGraph.children(v).length) {
              inputLabel.width = layoutLabel.width;
              inputLabel.height = layoutLabel.height;
            }
          }
        });
        inputGraph.edges().forEach((e) => {
          let inputLabel = inputGraph.edge(e);
          let layoutLabel = layoutGraph.edge(e);
          inputLabel.points = layoutLabel.points;
          if (Object.hasOwn(layoutLabel, "x")) {
            inputLabel.x = layoutLabel.x;
            inputLabel.y = layoutLabel.y;
          }
        });
        inputGraph.graph().width = layoutGraph.graph().width;
        inputGraph.graph().height = layoutGraph.graph().height;
      }
      let graphNumAttrs = ["nodesep", "edgesep", "ranksep", "marginx", "marginy"];
      let graphDefaults = { ranksep: 50, edgesep: 20, nodesep: 50, rankdir: "tb" };
      let graphAttrs = ["acyclicer", "ranker", "rankdir", "align"];
      let nodeNumAttrs = ["width", "height", "rank"];
      let nodeDefaults = { width: 0, height: 0 };
      let edgeNumAttrs = ["minlen", "weight", "width", "height", "labeloffset"];
      let edgeDefaults = {
        minlen: 1,
        weight: 1,
        width: 0,
        height: 0,
        labeloffset: 10,
        labelpos: "r"
      };
      let edgeAttrs = ["labelpos"];
      function buildLayoutGraph(inputGraph) {
        let g = new Graph({ multigraph: true, compound: true });
        let graph = canonicalize(inputGraph.graph());
        g.setGraph(Object.assign({}, graphDefaults, selectNumberAttrs(graph, graphNumAttrs), util.pick(graph, graphAttrs)));
        inputGraph.nodes().forEach((v) => {
          let node = canonicalize(inputGraph.node(v));
          const newNode = selectNumberAttrs(node, nodeNumAttrs);
          Object.keys(nodeDefaults).forEach((k) => {
            if (newNode[k] === undefined) {
              newNode[k] = nodeDefaults[k];
            }
          });
          g.setNode(v, newNode);
          g.setParent(v, inputGraph.parent(v));
        });
        inputGraph.edges().forEach((e) => {
          let edge = canonicalize(inputGraph.edge(e));
          g.setEdge(e, Object.assign({}, edgeDefaults, selectNumberAttrs(edge, edgeNumAttrs), util.pick(edge, edgeAttrs)));
        });
        return g;
      }
      function makeSpaceForEdgeLabels(g) {
        let graph = g.graph();
        graph.ranksep /= 2;
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          edge.minlen *= 2;
          if (edge.labelpos.toLowerCase() !== "c") {
            if (graph.rankdir === "TB" || graph.rankdir === "BT") {
              edge.width += edge.labeloffset;
            } else {
              edge.height += edge.labeloffset;
            }
          }
        });
      }
      function injectEdgeLabelProxies(g) {
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          if (edge.width && edge.height) {
            let v = g.node(e.v);
            let w = g.node(e.w);
            let label = { rank: (w.rank - v.rank) / 2 + v.rank, e };
            util.addDummyNode(g, "edge-proxy", label, "_ep");
          }
        });
      }
      function assignRankMinMax(g) {
        let maxRank = 0;
        g.nodes().forEach((v) => {
          let node = g.node(v);
          if (node.borderTop) {
            node.minRank = g.node(node.borderTop).rank;
            node.maxRank = g.node(node.borderBottom).rank;
            maxRank = Math.max(maxRank, node.maxRank);
          }
        });
        g.graph().maxRank = maxRank;
      }
      function removeEdgeLabelProxies(g) {
        g.nodes().forEach((v) => {
          let node = g.node(v);
          if (node.dummy === "edge-proxy") {
            g.edge(node.e).labelRank = node.rank;
            g.removeNode(v);
          }
        });
      }
      function translateGraph(g) {
        let minX = Number.POSITIVE_INFINITY;
        let maxX = 0;
        let minY = Number.POSITIVE_INFINITY;
        let maxY = 0;
        let graphLabel = g.graph();
        let marginX = graphLabel.marginx || 0;
        let marginY = graphLabel.marginy || 0;
        function getExtremes(attrs) {
          let x = attrs.x;
          let y = attrs.y;
          let w = attrs.width;
          let h = attrs.height;
          minX = Math.min(minX, x - w / 2);
          maxX = Math.max(maxX, x + w / 2);
          minY = Math.min(minY, y - h / 2);
          maxY = Math.max(maxY, y + h / 2);
        }
        g.nodes().forEach((v) => getExtremes(g.node(v)));
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          if (Object.hasOwn(edge, "x")) {
            getExtremes(edge);
          }
        });
        minX -= marginX;
        minY -= marginY;
        g.nodes().forEach((v) => {
          let node = g.node(v);
          node.x -= minX;
          node.y -= minY;
        });
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          edge.points.forEach((p) => {
            p.x -= minX;
            p.y -= minY;
          });
          if (Object.hasOwn(edge, "x")) {
            edge.x -= minX;
          }
          if (Object.hasOwn(edge, "y")) {
            edge.y -= minY;
          }
        });
        graphLabel.width = maxX - minX + marginX;
        graphLabel.height = maxY - minY + marginY;
      }
      function assignNodeIntersects(g) {
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          let nodeV = g.node(e.v);
          let nodeW = g.node(e.w);
          let p1, p2;
          if (!edge.points) {
            edge.points = [];
            p1 = nodeW;
            p2 = nodeV;
          } else {
            p1 = edge.points[0];
            p2 = edge.points[edge.points.length - 1];
          }
          edge.points.unshift(util.intersectRect(nodeV, p1));
          edge.points.push(util.intersectRect(nodeW, p2));
        });
      }
      function fixupEdgeLabelCoords(g) {
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          if (Object.hasOwn(edge, "x")) {
            if (edge.labelpos === "l" || edge.labelpos === "r") {
              edge.width -= edge.labeloffset;
            }
            switch (edge.labelpos) {
              case "l":
                edge.x -= edge.width / 2 + edge.labeloffset;
                break;
              case "r":
                edge.x += edge.width / 2 + edge.labeloffset;
                break;
            }
          }
        });
      }
      function reversePointsForReversedEdges(g) {
        g.edges().forEach((e) => {
          let edge = g.edge(e);
          if (edge.reversed) {
            edge.points.reverse();
          }
        });
      }
      function removeBorderNodes(g) {
        g.nodes().forEach((v) => {
          if (g.children(v).length) {
            let node = g.node(v);
            let t = g.node(node.borderTop);
            let b = g.node(node.borderBottom);
            let l = g.node(node.borderLeft[node.borderLeft.length - 1]);
            let r = g.node(node.borderRight[node.borderRight.length - 1]);
            node.width = Math.abs(r.x - l.x);
            node.height = Math.abs(b.y - t.y);
            node.x = l.x + node.width / 2;
            node.y = t.y + node.height / 2;
          }
        });
        g.nodes().forEach((v) => {
          if (g.node(v).dummy === "border") {
            g.removeNode(v);
          }
        });
      }
      function removeSelfEdges(g) {
        g.edges().forEach((e) => {
          if (e.v === e.w) {
            var node = g.node(e.v);
            if (!node.selfEdges) {
              node.selfEdges = [];
            }
            node.selfEdges.push({ e, label: g.edge(e) });
            g.removeEdge(e);
          }
        });
      }
      function insertSelfEdges(g) {
        var layers = util.buildLayerMatrix(g);
        layers.forEach((layer) => {
          var orderShift = 0;
          layer.forEach((v, i) => {
            var node = g.node(v);
            node.order = i + orderShift;
            (node.selfEdges || []).forEach((selfEdge) => {
              util.addDummyNode(g, "selfedge", {
                width: selfEdge.label.width,
                height: selfEdge.label.height,
                rank: node.rank,
                order: i + ++orderShift,
                e: selfEdge.e,
                label: selfEdge.label
              }, "_se");
            });
            delete node.selfEdges;
          });
        });
      }
      function positionSelfEdges(g) {
        g.nodes().forEach((v) => {
          var node = g.node(v);
          if (node.dummy === "selfedge") {
            var selfNode = g.node(node.e.v);
            var x = selfNode.x + selfNode.width / 2;
            var y = selfNode.y;
            var dx = node.x - x;
            var dy = selfNode.height / 2;
            g.setEdge(node.e, node.label);
            g.removeNode(v);
            node.label.points = [
              { x: x + 2 * dx / 3, y: y - dy },
              { x: x + 5 * dx / 6, y: y - dy },
              { x: x + dx, y },
              { x: x + 5 * dx / 6, y: y + dy },
              { x: x + 2 * dx / 3, y: y + dy }
            ];
            node.label.x = node.x;
            node.label.y = node.y;
          }
        });
      }
      function selectNumberAttrs(obj, attrs) {
        return util.mapValues(util.pick(obj, attrs), Number);
      }
      function canonicalize(attrs) {
        var newAttrs = {};
        if (attrs) {
          Object.entries(attrs).forEach(([k, v]) => {
            if (typeof k === "string") {
              k = k.toLowerCase();
            }
            newAttrs[k] = v;
          });
        }
        return newAttrs;
      }
    }, { "./acyclic": 2, "./add-border-segments": 3, "./coordinate-system": 4, "./nesting-graph": 9, "./normalize": 10, "./order": 15, "./parent-dummy-chains": 20, "./position": 22, "./rank": 24, "./util": 27, "@dagrejs/graphlib": 29 }], 9: [function(require2, module3, exports3) {
      let util = require2("./util");
      module3.exports = {
        run,
        cleanup
      };
      function run(g) {
        let root = util.addDummyNode(g, "root", {}, "_root");
        let depths = treeDepths(g);
        let depthsArr = Object.values(depths);
        let height = util.applyWithChunking(Math.max, depthsArr) - 1;
        let nodeSep = 2 * height + 1;
        g.graph().nestingRoot = root;
        g.edges().forEach((e) => g.edge(e).minlen *= nodeSep);
        let weight = sumWeights(g) + 1;
        g.children().forEach((child) => dfs(g, root, nodeSep, weight, height, depths, child));
        g.graph().nodeRankFactor = nodeSep;
      }
      function dfs(g, root, nodeSep, weight, height, depths, v) {
        let children = g.children(v);
        if (!children.length) {
          if (v !== root) {
            g.setEdge(root, v, { weight: 0, minlen: nodeSep });
          }
          return;
        }
        let top = util.addBorderNode(g, "_bt");
        let bottom = util.addBorderNode(g, "_bb");
        let label = g.node(v);
        g.setParent(top, v);
        label.borderTop = top;
        g.setParent(bottom, v);
        label.borderBottom = bottom;
        children.forEach((child) => {
          dfs(g, root, nodeSep, weight, height, depths, child);
          let childNode = g.node(child);
          let childTop = childNode.borderTop ? childNode.borderTop : child;
          let childBottom = childNode.borderBottom ? childNode.borderBottom : child;
          let thisWeight = childNode.borderTop ? weight : 2 * weight;
          let minlen = childTop !== childBottom ? 1 : height - depths[v] + 1;
          g.setEdge(top, childTop, {
            weight: thisWeight,
            minlen,
            nestingEdge: true
          });
          g.setEdge(childBottom, bottom, {
            weight: thisWeight,
            minlen,
            nestingEdge: true
          });
        });
        if (!g.parent(v)) {
          g.setEdge(root, top, { weight: 0, minlen: height + depths[v] });
        }
      }
      function treeDepths(g) {
        var depths = {};
        function dfs2(v, depth) {
          var children = g.children(v);
          if (children && children.length) {
            children.forEach((child) => dfs2(child, depth + 1));
          }
          depths[v] = depth;
        }
        g.children().forEach((v) => dfs2(v, 1));
        return depths;
      }
      function sumWeights(g) {
        return g.edges().reduce((acc, e) => acc + g.edge(e).weight, 0);
      }
      function cleanup(g) {
        var graphLabel = g.graph();
        g.removeNode(graphLabel.nestingRoot);
        delete graphLabel.nestingRoot;
        g.edges().forEach((e) => {
          var edge = g.edge(e);
          if (edge.nestingEdge) {
            g.removeEdge(e);
          }
        });
      }
    }, { "./util": 27 }], 10: [function(require2, module3, exports3) {
      let util = require2("./util");
      module3.exports = {
        run,
        undo
      };
      function run(g) {
        g.graph().dummyChains = [];
        g.edges().forEach((edge) => normalizeEdge(g, edge));
      }
      function normalizeEdge(g, e) {
        let v = e.v;
        let vRank = g.node(v).rank;
        let w = e.w;
        let wRank = g.node(w).rank;
        let name = e.name;
        let edgeLabel = g.edge(e);
        let labelRank = edgeLabel.labelRank;
        if (wRank === vRank + 1)
          return;
        g.removeEdge(e);
        let dummy, attrs, i;
        for (i = 0, ++vRank;vRank < wRank; ++i, ++vRank) {
          edgeLabel.points = [];
          attrs = {
            width: 0,
            height: 0,
            edgeLabel,
            edgeObj: e,
            rank: vRank
          };
          dummy = util.addDummyNode(g, "edge", attrs, "_d");
          if (vRank === labelRank) {
            attrs.width = edgeLabel.width;
            attrs.height = edgeLabel.height;
            attrs.dummy = "edge-label";
            attrs.labelpos = edgeLabel.labelpos;
          }
          g.setEdge(v, dummy, { weight: edgeLabel.weight }, name);
          if (i === 0) {
            g.graph().dummyChains.push(dummy);
          }
          v = dummy;
        }
        g.setEdge(v, w, { weight: edgeLabel.weight }, name);
      }
      function undo(g) {
        g.graph().dummyChains.forEach((v) => {
          let node = g.node(v);
          let origLabel = node.edgeLabel;
          let w;
          g.setEdge(node.edgeObj, origLabel);
          while (node.dummy) {
            w = g.successors(v)[0];
            g.removeNode(v);
            origLabel.points.push({ x: node.x, y: node.y });
            if (node.dummy === "edge-label") {
              origLabel.x = node.x;
              origLabel.y = node.y;
              origLabel.width = node.width;
              origLabel.height = node.height;
            }
            v = w;
            node = g.node(v);
          }
        });
      }
    }, { "./util": 27 }], 11: [function(require2, module3, exports3) {
      module3.exports = addSubgraphConstraints;
      function addSubgraphConstraints(g, cg, vs) {
        let prev = {}, rootPrev;
        vs.forEach((v) => {
          let child = g.parent(v), parent, prevChild;
          while (child) {
            parent = g.parent(child);
            if (parent) {
              prevChild = prev[parent];
              prev[parent] = child;
            } else {
              prevChild = rootPrev;
              rootPrev = child;
            }
            if (prevChild && prevChild !== child) {
              cg.setEdge(prevChild, child);
              return;
            }
            child = parent;
          }
        });
      }
    }, {}], 12: [function(require2, module3, exports3) {
      module3.exports = barycenter;
      function barycenter(g, movable = []) {
        return movable.map((v) => {
          let inV = g.inEdges(v);
          if (!inV.length) {
            return { v };
          } else {
            let result = inV.reduce((acc, e) => {
              let edge = g.edge(e), nodeU = g.node(e.v);
              return {
                sum: acc.sum + edge.weight * nodeU.order,
                weight: acc.weight + edge.weight
              };
            }, { sum: 0, weight: 0 });
            return {
              v,
              barycenter: result.sum / result.weight,
              weight: result.weight
            };
          }
        });
      }
    }, {}], 13: [function(require2, module3, exports3) {
      let Graph = require2("@dagrejs/graphlib").Graph;
      let util = require2("../util");
      module3.exports = buildLayerGraph;
      function buildLayerGraph(g, rank, relationship, nodesWithRank) {
        if (!nodesWithRank) {
          nodesWithRank = g.nodes();
        }
        let root = createRootNode(g), result = new Graph({ compound: true }).setGraph({ root }).setDefaultNodeLabel((v) => g.node(v));
        nodesWithRank.forEach((v) => {
          let node = g.node(v), parent = g.parent(v);
          if (node.rank === rank || node.minRank <= rank && rank <= node.maxRank) {
            result.setNode(v);
            result.setParent(v, parent || root);
            g[relationship](v).forEach((e) => {
              let u = e.v === v ? e.w : e.v, edge = result.edge(u, v), weight = edge !== undefined ? edge.weight : 0;
              result.setEdge(u, v, { weight: g.edge(e).weight + weight });
            });
            if (Object.hasOwn(node, "minRank")) {
              result.setNode(v, {
                borderLeft: node.borderLeft[rank],
                borderRight: node.borderRight[rank]
              });
            }
          }
        });
        return result;
      }
      function createRootNode(g) {
        var v;
        while (g.hasNode(v = util.uniqueId("_root")))
          ;
        return v;
      }
    }, { "../util": 27, "@dagrejs/graphlib": 29 }], 14: [function(require2, module3, exports3) {
      let zipObject = require2("../util").zipObject;
      module3.exports = crossCount;
      function crossCount(g, layering) {
        let cc = 0;
        for (let i = 1;i < layering.length; ++i) {
          cc += twoLayerCrossCount(g, layering[i - 1], layering[i]);
        }
        return cc;
      }
      function twoLayerCrossCount(g, northLayer, southLayer) {
        let southPos = zipObject(southLayer, southLayer.map((v, i) => i));
        let southEntries = northLayer.flatMap((v) => {
          return g.outEdges(v).map((e) => {
            return { pos: southPos[e.w], weight: g.edge(e).weight };
          }).sort((a, b) => a.pos - b.pos);
        });
        let firstIndex = 1;
        while (firstIndex < southLayer.length)
          firstIndex <<= 1;
        let treeSize = 2 * firstIndex - 1;
        firstIndex -= 1;
        let tree = new Array(treeSize).fill(0);
        let cc = 0;
        southEntries.forEach((entry) => {
          let index = entry.pos + firstIndex;
          tree[index] += entry.weight;
          let weightSum = 0;
          while (index > 0) {
            if (index % 2) {
              weightSum += tree[index + 1];
            }
            index = index - 1 >> 1;
            tree[index] += entry.weight;
          }
          cc += entry.weight * weightSum;
        });
        return cc;
      }
    }, { "../util": 27 }], 15: [function(require2, module3, exports3) {
      let initOrder = require2("./init-order");
      let crossCount = require2("./cross-count");
      let sortSubgraph = require2("./sort-subgraph");
      let buildLayerGraph = require2("./build-layer-graph");
      let addSubgraphConstraints = require2("./add-subgraph-constraints");
      let Graph = require2("@dagrejs/graphlib").Graph;
      let util = require2("../util");
      module3.exports = order;
      function order(g, opts) {
        if (opts && typeof opts.customOrder === "function") {
          opts.customOrder(g, order);
          return;
        }
        let maxRank = util.maxRank(g), downLayerGraphs = buildLayerGraphs(g, util.range(1, maxRank + 1), "inEdges"), upLayerGraphs = buildLayerGraphs(g, util.range(maxRank - 1, -1, -1), "outEdges");
        let layering = initOrder(g);
        assignOrder(g, layering);
        if (opts && opts.disableOptimalOrderHeuristic) {
          return;
        }
        let bestCC = Number.POSITIVE_INFINITY, best;
        for (let i = 0, lastBest = 0;lastBest < 4; ++i, ++lastBest) {
          sweepLayerGraphs(i % 2 ? downLayerGraphs : upLayerGraphs, i % 4 >= 2);
          layering = util.buildLayerMatrix(g);
          let cc = crossCount(g, layering);
          if (cc < bestCC) {
            lastBest = 0;
            best = Object.assign({}, layering);
            bestCC = cc;
          }
        }
        assignOrder(g, best);
      }
      function buildLayerGraphs(g, ranks, relationship) {
        const nodesByRank = new Map;
        const addNodeToRank = (rank, node) => {
          if (!nodesByRank.has(rank)) {
            nodesByRank.set(rank, []);
          }
          nodesByRank.get(rank).push(node);
        };
        for (const v of g.nodes()) {
          const node = g.node(v);
          if (typeof node.rank === "number") {
            addNodeToRank(node.rank, v);
          }
          if (typeof node.minRank === "number" && typeof node.maxRank === "number") {
            for (let r = node.minRank;r <= node.maxRank; r++) {
              if (r !== node.rank) {
                addNodeToRank(r, v);
              }
            }
          }
        }
        return ranks.map(function(rank) {
          return buildLayerGraph(g, rank, relationship, nodesByRank.get(rank) || []);
        });
      }
      function sweepLayerGraphs(layerGraphs, biasRight) {
        let cg = new Graph;
        layerGraphs.forEach(function(lg) {
          let root = lg.graph().root;
          let sorted = sortSubgraph(lg, root, cg, biasRight);
          sorted.vs.forEach((v, i) => lg.node(v).order = i);
          addSubgraphConstraints(lg, cg, sorted.vs);
        });
      }
      function assignOrder(g, layering) {
        Object.values(layering).forEach((layer) => layer.forEach((v, i) => g.node(v).order = i));
      }
    }, { "../util": 27, "./add-subgraph-constraints": 11, "./build-layer-graph": 13, "./cross-count": 14, "./init-order": 16, "./sort-subgraph": 18, "@dagrejs/graphlib": 29 }], 16: [function(require2, module3, exports3) {
      let util = require2("../util");
      module3.exports = initOrder;
      function initOrder(g) {
        let visited = {};
        let simpleNodes = g.nodes().filter((v) => !g.children(v).length);
        let simpleNodesRanks = simpleNodes.map((v) => g.node(v).rank);
        let maxRank = util.applyWithChunking(Math.max, simpleNodesRanks);
        let layers = util.range(maxRank + 1).map(() => []);
        function dfs(v) {
          if (visited[v])
            return;
          visited[v] = true;
          let node = g.node(v);
          layers[node.rank].push(v);
          g.successors(v).forEach(dfs);
        }
        let orderedVs = simpleNodes.sort((a, b) => g.node(a).rank - g.node(b).rank);
        orderedVs.forEach(dfs);
        return layers;
      }
    }, { "../util": 27 }], 17: [function(require2, module3, exports3) {
      let util = require2("../util");
      module3.exports = resolveConflicts;
      function resolveConflicts(entries, cg) {
        let mappedEntries = {};
        entries.forEach((entry, i) => {
          let tmp = mappedEntries[entry.v] = {
            indegree: 0,
            in: [],
            out: [],
            vs: [entry.v],
            i
          };
          if (entry.barycenter !== undefined) {
            tmp.barycenter = entry.barycenter;
            tmp.weight = entry.weight;
          }
        });
        cg.edges().forEach((e) => {
          let entryV = mappedEntries[e.v];
          let entryW = mappedEntries[e.w];
          if (entryV !== undefined && entryW !== undefined) {
            entryW.indegree++;
            entryV.out.push(mappedEntries[e.w]);
          }
        });
        let sourceSet = Object.values(mappedEntries).filter((entry) => !entry.indegree);
        return doResolveConflicts(sourceSet);
      }
      function doResolveConflicts(sourceSet) {
        let entries = [];
        function handleIn(vEntry) {
          return (uEntry) => {
            if (uEntry.merged) {
              return;
            }
            if (uEntry.barycenter === undefined || vEntry.barycenter === undefined || uEntry.barycenter >= vEntry.barycenter) {
              mergeEntries(vEntry, uEntry);
            }
          };
        }
        function handleOut(vEntry) {
          return (wEntry) => {
            wEntry["in"].push(vEntry);
            if (--wEntry.indegree === 0) {
              sourceSet.push(wEntry);
            }
          };
        }
        while (sourceSet.length) {
          let entry = sourceSet.pop();
          entries.push(entry);
          entry["in"].reverse().forEach(handleIn(entry));
          entry.out.forEach(handleOut(entry));
        }
        return entries.filter((entry) => !entry.merged).map((entry) => {
          return util.pick(entry, ["vs", "i", "barycenter", "weight"]);
        });
      }
      function mergeEntries(target, source) {
        let sum = 0;
        let weight = 0;
        if (target.weight) {
          sum += target.barycenter * target.weight;
          weight += target.weight;
        }
        if (source.weight) {
          sum += source.barycenter * source.weight;
          weight += source.weight;
        }
        target.vs = source.vs.concat(target.vs);
        target.barycenter = sum / weight;
        target.weight = weight;
        target.i = Math.min(source.i, target.i);
        source.merged = true;
      }
    }, { "../util": 27 }], 18: [function(require2, module3, exports3) {
      let barycenter = require2("./barycenter");
      let resolveConflicts = require2("./resolve-conflicts");
      let sort = require2("./sort");
      module3.exports = sortSubgraph;
      function sortSubgraph(g, v, cg, biasRight) {
        let movable = g.children(v);
        let node = g.node(v);
        let bl = node ? node.borderLeft : undefined;
        let br = node ? node.borderRight : undefined;
        let subgraphs = {};
        if (bl) {
          movable = movable.filter((w) => w !== bl && w !== br);
        }
        let barycenters = barycenter(g, movable);
        barycenters.forEach((entry) => {
          if (g.children(entry.v).length) {
            let subgraphResult = sortSubgraph(g, entry.v, cg, biasRight);
            subgraphs[entry.v] = subgraphResult;
            if (Object.hasOwn(subgraphResult, "barycenter")) {
              mergeBarycenters(entry, subgraphResult);
            }
          }
        });
        let entries = resolveConflicts(barycenters, cg);
        expandSubgraphs(entries, subgraphs);
        let result = sort(entries, biasRight);
        if (bl) {
          result.vs = [bl, result.vs, br].flat(true);
          if (g.predecessors(bl).length) {
            let blPred = g.node(g.predecessors(bl)[0]), brPred = g.node(g.predecessors(br)[0]);
            if (!Object.hasOwn(result, "barycenter")) {
              result.barycenter = 0;
              result.weight = 0;
            }
            result.barycenter = (result.barycenter * result.weight + blPred.order + brPred.order) / (result.weight + 2);
            result.weight += 2;
          }
        }
        return result;
      }
      function expandSubgraphs(entries, subgraphs) {
        entries.forEach((entry) => {
          entry.vs = entry.vs.flatMap((v) => {
            if (subgraphs[v]) {
              return subgraphs[v].vs;
            }
            return v;
          });
        });
      }
      function mergeBarycenters(target, other) {
        if (target.barycenter !== undefined) {
          target.barycenter = (target.barycenter * target.weight + other.barycenter * other.weight) / (target.weight + other.weight);
          target.weight += other.weight;
        } else {
          target.barycenter = other.barycenter;
          target.weight = other.weight;
        }
      }
    }, { "./barycenter": 12, "./resolve-conflicts": 17, "./sort": 19 }], 19: [function(require2, module3, exports3) {
      let util = require2("../util");
      module3.exports = sort;
      function sort(entries, biasRight) {
        let parts = util.partition(entries, (entry) => {
          return Object.hasOwn(entry, "barycenter");
        });
        let sortable = parts.lhs, unsortable = parts.rhs.sort((a, b) => b.i - a.i), vs = [], sum = 0, weight = 0, vsIndex = 0;
        sortable.sort(compareWithBias(!!biasRight));
        vsIndex = consumeUnsortable(vs, unsortable, vsIndex);
        sortable.forEach((entry) => {
          vsIndex += entry.vs.length;
          vs.push(entry.vs);
          sum += entry.barycenter * entry.weight;
          weight += entry.weight;
          vsIndex = consumeUnsortable(vs, unsortable, vsIndex);
        });
        let result = { vs: vs.flat(true) };
        if (weight) {
          result.barycenter = sum / weight;
          result.weight = weight;
        }
        return result;
      }
      function consumeUnsortable(vs, unsortable, index) {
        let last;
        while (unsortable.length && (last = unsortable[unsortable.length - 1]).i <= index) {
          unsortable.pop();
          vs.push(last.vs);
          index++;
        }
        return index;
      }
      function compareWithBias(bias) {
        return (entryV, entryW) => {
          if (entryV.barycenter < entryW.barycenter) {
            return -1;
          } else if (entryV.barycenter > entryW.barycenter) {
            return 1;
          }
          return !bias ? entryV.i - entryW.i : entryW.i - entryV.i;
        };
      }
    }, { "../util": 27 }], 20: [function(require2, module3, exports3) {
      module3.exports = parentDummyChains;
      function parentDummyChains(g) {
        let postorderNums = postorder(g);
        g.graph().dummyChains.forEach((v) => {
          let node = g.node(v);
          let edgeObj = node.edgeObj;
          let pathData = findPath(g, postorderNums, edgeObj.v, edgeObj.w);
          let path = pathData.path;
          let lca = pathData.lca;
          let pathIdx = 0;
          let pathV = path[pathIdx];
          let ascending = true;
          while (v !== edgeObj.w) {
            node = g.node(v);
            if (ascending) {
              while ((pathV = path[pathIdx]) !== lca && g.node(pathV).maxRank < node.rank) {
                pathIdx++;
              }
              if (pathV === lca) {
                ascending = false;
              }
            }
            if (!ascending) {
              while (pathIdx < path.length - 1 && g.node(pathV = path[pathIdx + 1]).minRank <= node.rank) {
                pathIdx++;
              }
              pathV = path[pathIdx];
            }
            g.setParent(v, pathV);
            v = g.successors(v)[0];
          }
        });
      }
      function findPath(g, postorderNums, v, w) {
        let vPath = [];
        let wPath = [];
        let low = Math.min(postorderNums[v].low, postorderNums[w].low);
        let lim = Math.max(postorderNums[v].lim, postorderNums[w].lim);
        let parent;
        let lca;
        parent = v;
        do {
          parent = g.parent(parent);
          vPath.push(parent);
        } while (parent && (postorderNums[parent].low > low || lim > postorderNums[parent].lim));
        lca = parent;
        parent = w;
        while ((parent = g.parent(parent)) !== lca) {
          wPath.push(parent);
        }
        return { path: vPath.concat(wPath.reverse()), lca };
      }
      function postorder(g) {
        let result = {};
        let lim = 0;
        function dfs(v) {
          let low = lim;
          g.children(v).forEach(dfs);
          result[v] = { low, lim: lim++ };
        }
        g.children().forEach(dfs);
        return result;
      }
    }, {}], 21: [function(require2, module3, exports3) {
      let Graph = require2("@dagrejs/graphlib").Graph;
      let util = require2("../util");
      module3.exports = {
        positionX,
        findType1Conflicts,
        findType2Conflicts,
        addConflict,
        hasConflict,
        verticalAlignment,
        horizontalCompaction,
        alignCoordinates,
        findSmallestWidthAlignment,
        balance
      };
      function findType1Conflicts(g, layering) {
        let conflicts = {};
        function visitLayer(prevLayer, layer) {
          let k0 = 0, scanPos = 0, prevLayerLength = prevLayer.length, lastNode = layer[layer.length - 1];
          layer.forEach((v, i) => {
            let w = findOtherInnerSegmentNode(g, v), k1 = w ? g.node(w).order : prevLayerLength;
            if (w || v === lastNode) {
              layer.slice(scanPos, i + 1).forEach((scanNode) => {
                g.predecessors(scanNode).forEach((u) => {
                  let uLabel = g.node(u), uPos = uLabel.order;
                  if ((uPos < k0 || k1 < uPos) && !(uLabel.dummy && g.node(scanNode).dummy)) {
                    addConflict(conflicts, u, scanNode);
                  }
                });
              });
              scanPos = i + 1;
              k0 = k1;
            }
          });
          return layer;
        }
        layering.length && layering.reduce(visitLayer);
        return conflicts;
      }
      function findType2Conflicts(g, layering) {
        let conflicts = {};
        function scan(south, southPos, southEnd, prevNorthBorder, nextNorthBorder) {
          let v;
          util.range(southPos, southEnd).forEach((i) => {
            v = south[i];
            if (g.node(v).dummy) {
              g.predecessors(v).forEach((u) => {
                let uNode = g.node(u);
                if (uNode.dummy && (uNode.order < prevNorthBorder || uNode.order > nextNorthBorder)) {
                  addConflict(conflicts, u, v);
                }
              });
            }
          });
        }
        function visitLayer(north, south) {
          let prevNorthPos = -1, nextNorthPos, southPos = 0;
          south.forEach((v, southLookahead) => {
            if (g.node(v).dummy === "border") {
              let predecessors = g.predecessors(v);
              if (predecessors.length) {
                nextNorthPos = g.node(predecessors[0]).order;
                scan(south, southPos, southLookahead, prevNorthPos, nextNorthPos);
                southPos = southLookahead;
                prevNorthPos = nextNorthPos;
              }
            }
            scan(south, southPos, south.length, nextNorthPos, north.length);
          });
          return south;
        }
        layering.length && layering.reduce(visitLayer);
        return conflicts;
      }
      function findOtherInnerSegmentNode(g, v) {
        if (g.node(v).dummy) {
          return g.predecessors(v).find((u) => g.node(u).dummy);
        }
      }
      function addConflict(conflicts, v, w) {
        if (v > w) {
          let tmp = v;
          v = w;
          w = tmp;
        }
        let conflictsV = conflicts[v];
        if (!conflictsV) {
          conflicts[v] = conflictsV = {};
        }
        conflictsV[w] = true;
      }
      function hasConflict(conflicts, v, w) {
        if (v > w) {
          let tmp = v;
          v = w;
          w = tmp;
        }
        return !!conflicts[v] && Object.hasOwn(conflicts[v], w);
      }
      function verticalAlignment(g, layering, conflicts, neighborFn) {
        let root = {}, align = {}, pos = {};
        layering.forEach((layer) => {
          layer.forEach((v, order) => {
            root[v] = v;
            align[v] = v;
            pos[v] = order;
          });
        });
        layering.forEach((layer) => {
          let prevIdx = -1;
          layer.forEach((v) => {
            let ws = neighborFn(v);
            if (ws.length) {
              ws = ws.sort((a, b) => pos[a] - pos[b]);
              let mp = (ws.length - 1) / 2;
              for (let i = Math.floor(mp), il = Math.ceil(mp);i <= il; ++i) {
                let w = ws[i];
                if (align[v] === v && prevIdx < pos[w] && !hasConflict(conflicts, v, w)) {
                  align[w] = v;
                  align[v] = root[v] = root[w];
                  prevIdx = pos[w];
                }
              }
            }
          });
        });
        return { root, align };
      }
      function horizontalCompaction(g, layering, root, align, reverseSep) {
        let xs = {}, blockG = buildBlockGraph(g, layering, root, reverseSep), borderType = reverseSep ? "borderLeft" : "borderRight";
        function iterate(setXsFunc, nextNodesFunc) {
          let stack = blockG.nodes();
          let elem = stack.pop();
          let visited = {};
          while (elem) {
            if (visited[elem]) {
              setXsFunc(elem);
            } else {
              visited[elem] = true;
              stack.push(elem);
              stack = stack.concat(nextNodesFunc(elem));
            }
            elem = stack.pop();
          }
        }
        function pass1(elem) {
          xs[elem] = blockG.inEdges(elem).reduce((acc, e) => {
            return Math.max(acc, xs[e.v] + blockG.edge(e));
          }, 0);
        }
        function pass2(elem) {
          let min = blockG.outEdges(elem).reduce((acc, e) => {
            return Math.min(acc, xs[e.w] - blockG.edge(e));
          }, Number.POSITIVE_INFINITY);
          let node = g.node(elem);
          if (min !== Number.POSITIVE_INFINITY && node.borderType !== borderType) {
            xs[elem] = Math.max(xs[elem], min);
          }
        }
        iterate(pass1, blockG.predecessors.bind(blockG));
        iterate(pass2, blockG.successors.bind(blockG));
        Object.keys(align).forEach((v) => xs[v] = xs[root[v]]);
        return xs;
      }
      function buildBlockGraph(g, layering, root, reverseSep) {
        let blockGraph = new Graph, graphLabel = g.graph(), sepFn = sep(graphLabel.nodesep, graphLabel.edgesep, reverseSep);
        layering.forEach((layer) => {
          let u;
          layer.forEach((v) => {
            let vRoot = root[v];
            blockGraph.setNode(vRoot);
            if (u) {
              var uRoot = root[u], prevMax = blockGraph.edge(uRoot, vRoot);
              blockGraph.setEdge(uRoot, vRoot, Math.max(sepFn(g, v, u), prevMax || 0));
            }
            u = v;
          });
        });
        return blockGraph;
      }
      function findSmallestWidthAlignment(g, xss) {
        return Object.values(xss).reduce((currentMinAndXs, xs) => {
          let max = Number.NEGATIVE_INFINITY;
          let min = Number.POSITIVE_INFINITY;
          Object.entries(xs).forEach(([v, x]) => {
            let halfWidth = width(g, v) / 2;
            max = Math.max(x + halfWidth, max);
            min = Math.min(x - halfWidth, min);
          });
          const newMin = max - min;
          if (newMin < currentMinAndXs[0]) {
            currentMinAndXs = [newMin, xs];
          }
          return currentMinAndXs;
        }, [Number.POSITIVE_INFINITY, null])[1];
      }
      function alignCoordinates(xss, alignTo) {
        let alignToVals = Object.values(alignTo), alignToMin = util.applyWithChunking(Math.min, alignToVals), alignToMax = util.applyWithChunking(Math.max, alignToVals);
        ["u", "d"].forEach((vert) => {
          ["l", "r"].forEach((horiz) => {
            let alignment = vert + horiz, xs = xss[alignment];
            if (xs === alignTo)
              return;
            let xsVals = Object.values(xs);
            let delta = alignToMin - util.applyWithChunking(Math.min, xsVals);
            if (horiz !== "l") {
              delta = alignToMax - util.applyWithChunking(Math.max, xsVals);
            }
            if (delta) {
              xss[alignment] = util.mapValues(xs, (x) => x + delta);
            }
          });
        });
      }
      function balance(xss, align) {
        return util.mapValues(xss.ul, (num, v) => {
          if (align) {
            return xss[align.toLowerCase()][v];
          } else {
            let xs = Object.values(xss).map((xs2) => xs2[v]).sort((a, b) => a - b);
            return (xs[1] + xs[2]) / 2;
          }
        });
      }
      function positionX(g) {
        let layering = util.buildLayerMatrix(g);
        let conflicts = Object.assign(findType1Conflicts(g, layering), findType2Conflicts(g, layering));
        let xss = {};
        let adjustedLayering;
        ["u", "d"].forEach((vert) => {
          adjustedLayering = vert === "u" ? layering : Object.values(layering).reverse();
          ["l", "r"].forEach((horiz) => {
            if (horiz === "r") {
              adjustedLayering = adjustedLayering.map((inner) => {
                return Object.values(inner).reverse();
              });
            }
            let neighborFn = (vert === "u" ? g.predecessors : g.successors).bind(g);
            let align = verticalAlignment(g, adjustedLayering, conflicts, neighborFn);
            let xs = horizontalCompaction(g, adjustedLayering, align.root, align.align, horiz === "r");
            if (horiz === "r") {
              xs = util.mapValues(xs, (x) => -x);
            }
            xss[vert + horiz] = xs;
          });
        });
        let smallestWidth = findSmallestWidthAlignment(g, xss);
        alignCoordinates(xss, smallestWidth);
        return balance(xss, g.graph().align);
      }
      function sep(nodeSep, edgeSep, reverseSep) {
        return (g, v, w) => {
          let vLabel = g.node(v);
          let wLabel = g.node(w);
          let sum = 0;
          let delta;
          sum += vLabel.width / 2;
          if (Object.hasOwn(vLabel, "labelpos")) {
            switch (vLabel.labelpos.toLowerCase()) {
              case "l":
                delta = -vLabel.width / 2;
                break;
              case "r":
                delta = vLabel.width / 2;
                break;
            }
          }
          if (delta) {
            sum += reverseSep ? delta : -delta;
          }
          delta = 0;
          sum += (vLabel.dummy ? edgeSep : nodeSep) / 2;
          sum += (wLabel.dummy ? edgeSep : nodeSep) / 2;
          sum += wLabel.width / 2;
          if (Object.hasOwn(wLabel, "labelpos")) {
            switch (wLabel.labelpos.toLowerCase()) {
              case "l":
                delta = wLabel.width / 2;
                break;
              case "r":
                delta = -wLabel.width / 2;
                break;
            }
          }
          if (delta) {
            sum += reverseSep ? delta : -delta;
          }
          delta = 0;
          return sum;
        };
      }
      function width(g, v) {
        return g.node(v).width;
      }
    }, { "../util": 27, "@dagrejs/graphlib": 29 }], 22: [function(require2, module3, exports3) {
      let util = require2("../util");
      let positionX = require2("./bk").positionX;
      module3.exports = position;
      function position(g) {
        g = util.asNonCompoundGraph(g);
        positionY(g);
        Object.entries(positionX(g)).forEach(([v, x]) => g.node(v).x = x);
      }
      function positionY(g) {
        let layering = util.buildLayerMatrix(g);
        let rankSep = g.graph().ranksep;
        let prevY = 0;
        layering.forEach((layer) => {
          const maxHeight = layer.reduce((acc, v) => {
            const height = g.node(v).height;
            if (acc > height) {
              return acc;
            } else {
              return height;
            }
          }, 0);
          layer.forEach((v) => g.node(v).y = prevY + maxHeight / 2);
          prevY += maxHeight + rankSep;
        });
      }
    }, { "../util": 27, "./bk": 21 }], 23: [function(require2, module3, exports3) {
      var Graph = require2("@dagrejs/graphlib").Graph;
      var slack = require2("./util").slack;
      module3.exports = feasibleTree;
      function feasibleTree(g) {
        var t = new Graph({ directed: false });
        var start = g.nodes()[0];
        var size = g.nodeCount();
        t.setNode(start, {});
        var edge, delta;
        while (tightTree(t, g) < size) {
          edge = findMinSlackEdge(t, g);
          delta = t.hasNode(edge.v) ? slack(g, edge) : -slack(g, edge);
          shiftRanks(t, g, delta);
        }
        return t;
      }
      function tightTree(t, g) {
        function dfs(v) {
          g.nodeEdges(v).forEach((e) => {
            var edgeV = e.v, w = v === edgeV ? e.w : edgeV;
            if (!t.hasNode(w) && !slack(g, e)) {
              t.setNode(w, {});
              t.setEdge(v, w, {});
              dfs(w);
            }
          });
        }
        t.nodes().forEach(dfs);
        return t.nodeCount();
      }
      function findMinSlackEdge(t, g) {
        const edges = g.edges();
        return edges.reduce((acc, edge) => {
          let edgeSlack = Number.POSITIVE_INFINITY;
          if (t.hasNode(edge.v) !== t.hasNode(edge.w)) {
            edgeSlack = slack(g, edge);
          }
          if (edgeSlack < acc[0]) {
            return [edgeSlack, edge];
          }
          return acc;
        }, [Number.POSITIVE_INFINITY, null])[1];
      }
      function shiftRanks(t, g, delta) {
        t.nodes().forEach((v) => g.node(v).rank += delta);
      }
    }, { "./util": 26, "@dagrejs/graphlib": 29 }], 24: [function(require2, module3, exports3) {
      var rankUtil = require2("./util");
      var longestPath = rankUtil.longestPath;
      var feasibleTree = require2("./feasible-tree");
      var networkSimplex = require2("./network-simplex");
      module3.exports = rank;
      function rank(g) {
        var ranker = g.graph().ranker;
        if (ranker instanceof Function) {
          return ranker(g);
        }
        switch (g.graph().ranker) {
          case "network-simplex":
            networkSimplexRanker(g);
            break;
          case "tight-tree":
            tightTreeRanker(g);
            break;
          case "longest-path":
            longestPathRanker(g);
            break;
          case "none":
            break;
          default:
            networkSimplexRanker(g);
        }
      }
      var longestPathRanker = longestPath;
      function tightTreeRanker(g) {
        longestPath(g);
        feasibleTree(g);
      }
      function networkSimplexRanker(g) {
        networkSimplex(g);
      }
    }, { "./feasible-tree": 23, "./network-simplex": 25, "./util": 26 }], 25: [function(require2, module3, exports3) {
      var feasibleTree = require2("./feasible-tree");
      var slack = require2("./util").slack;
      var initRank = require2("./util").longestPath;
      var preorder = require2("@dagrejs/graphlib").alg.preorder;
      var postorder = require2("@dagrejs/graphlib").alg.postorder;
      var simplify = require2("../util").simplify;
      module3.exports = networkSimplex;
      networkSimplex.initLowLimValues = initLowLimValues;
      networkSimplex.initCutValues = initCutValues;
      networkSimplex.calcCutValue = calcCutValue;
      networkSimplex.leaveEdge = leaveEdge;
      networkSimplex.enterEdge = enterEdge;
      networkSimplex.exchangeEdges = exchangeEdges;
      function networkSimplex(g) {
        g = simplify(g);
        initRank(g);
        var t = feasibleTree(g);
        initLowLimValues(t);
        initCutValues(t, g);
        var e, f;
        while (e = leaveEdge(t)) {
          f = enterEdge(t, g, e);
          exchangeEdges(t, g, e, f);
        }
      }
      function initCutValues(t, g) {
        var vs = postorder(t, t.nodes());
        vs = vs.slice(0, vs.length - 1);
        vs.forEach((v) => assignCutValue(t, g, v));
      }
      function assignCutValue(t, g, child) {
        var childLab = t.node(child);
        var parent = childLab.parent;
        t.edge(child, parent).cutvalue = calcCutValue(t, g, child);
      }
      function calcCutValue(t, g, child) {
        var childLab = t.node(child);
        var parent = childLab.parent;
        var childIsTail = true;
        var graphEdge = g.edge(child, parent);
        var cutValue = 0;
        if (!graphEdge) {
          childIsTail = false;
          graphEdge = g.edge(parent, child);
        }
        cutValue = graphEdge.weight;
        g.nodeEdges(child).forEach((e) => {
          var isOutEdge = e.v === child, other = isOutEdge ? e.w : e.v;
          if (other !== parent) {
            var pointsToHead = isOutEdge === childIsTail, otherWeight = g.edge(e).weight;
            cutValue += pointsToHead ? otherWeight : -otherWeight;
            if (isTreeEdge(t, child, other)) {
              var otherCutValue = t.edge(child, other).cutvalue;
              cutValue += pointsToHead ? -otherCutValue : otherCutValue;
            }
          }
        });
        return cutValue;
      }
      function initLowLimValues(tree, root) {
        if (arguments.length < 2) {
          root = tree.nodes()[0];
        }
        dfsAssignLowLim(tree, {}, 1, root);
      }
      function dfsAssignLowLim(tree, visited, nextLim, v, parent) {
        var low = nextLim;
        var label = tree.node(v);
        visited[v] = true;
        tree.neighbors(v).forEach((w) => {
          if (!Object.hasOwn(visited, w)) {
            nextLim = dfsAssignLowLim(tree, visited, nextLim, w, v);
          }
        });
        label.low = low;
        label.lim = nextLim++;
        if (parent) {
          label.parent = parent;
        } else {
          delete label.parent;
        }
        return nextLim;
      }
      function leaveEdge(tree) {
        return tree.edges().find((e) => tree.edge(e).cutvalue < 0);
      }
      function enterEdge(t, g, edge) {
        var v = edge.v;
        var w = edge.w;
        if (!g.hasEdge(v, w)) {
          v = edge.w;
          w = edge.v;
        }
        var vLabel = t.node(v);
        var wLabel = t.node(w);
        var tailLabel = vLabel;
        var flip = false;
        if (vLabel.lim > wLabel.lim) {
          tailLabel = wLabel;
          flip = true;
        }
        var candidates = g.edges().filter((edge2) => {
          return flip === isDescendant(t, t.node(edge2.v), tailLabel) && flip !== isDescendant(t, t.node(edge2.w), tailLabel);
        });
        return candidates.reduce((acc, edge2) => {
          if (slack(g, edge2) < slack(g, acc)) {
            return edge2;
          }
          return acc;
        });
      }
      function exchangeEdges(t, g, e, f) {
        var v = e.v;
        var w = e.w;
        t.removeEdge(v, w);
        t.setEdge(f.v, f.w, {});
        initLowLimValues(t);
        initCutValues(t, g);
        updateRanks(t, g);
      }
      function updateRanks(t, g) {
        var root = t.nodes().find((v) => !g.node(v).parent);
        var vs = preorder(t, root);
        vs = vs.slice(1);
        vs.forEach((v) => {
          var parent = t.node(v).parent, edge = g.edge(v, parent), flipped = false;
          if (!edge) {
            edge = g.edge(parent, v);
            flipped = true;
          }
          g.node(v).rank = g.node(parent).rank + (flipped ? edge.minlen : -edge.minlen);
        });
      }
      function isTreeEdge(tree, u, v) {
        return tree.hasEdge(u, v);
      }
      function isDescendant(tree, vLabel, rootLabel) {
        return rootLabel.low <= vLabel.lim && vLabel.lim <= rootLabel.lim;
      }
    }, { "../util": 27, "./feasible-tree": 23, "./util": 26, "@dagrejs/graphlib": 29 }], 26: [function(require2, module3, exports3) {
      const { applyWithChunking } = require2("../util");
      module3.exports = {
        longestPath,
        slack
      };
      function longestPath(g) {
        var visited = {};
        function dfs(v) {
          var label = g.node(v);
          if (Object.hasOwn(visited, v)) {
            return label.rank;
          }
          visited[v] = true;
          let outEdgesMinLens = g.outEdges(v).map((e) => {
            if (e == null) {
              return Number.POSITIVE_INFINITY;
            }
            return dfs(e.w) - g.edge(e).minlen;
          });
          var rank = applyWithChunking(Math.min, outEdgesMinLens);
          if (rank === Number.POSITIVE_INFINITY) {
            rank = 0;
          }
          return label.rank = rank;
        }
        g.sources().forEach(dfs);
      }
      function slack(g, e) {
        return g.node(e.w).rank - g.node(e.v).rank - g.edge(e).minlen;
      }
    }, { "../util": 27 }], 27: [function(require2, module3, exports3) {
      let Graph = require2("@dagrejs/graphlib").Graph;
      module3.exports = {
        addBorderNode,
        addDummyNode,
        applyWithChunking,
        asNonCompoundGraph,
        buildLayerMatrix,
        intersectRect,
        mapValues,
        maxRank,
        normalizeRanks,
        notime,
        partition,
        pick,
        predecessorWeights,
        range,
        removeEmptyRanks,
        simplify,
        successorWeights,
        time,
        uniqueId,
        zipObject
      };
      function addDummyNode(g, type, attrs, name) {
        var v = name;
        while (g.hasNode(v)) {
          v = uniqueId(name);
        }
        attrs.dummy = type;
        g.setNode(v, attrs);
        return v;
      }
      function simplify(g) {
        let simplified = new Graph().setGraph(g.graph());
        g.nodes().forEach((v) => simplified.setNode(v, g.node(v)));
        g.edges().forEach((e) => {
          let simpleLabel = simplified.edge(e.v, e.w) || { weight: 0, minlen: 1 };
          let label = g.edge(e);
          simplified.setEdge(e.v, e.w, {
            weight: simpleLabel.weight + label.weight,
            minlen: Math.max(simpleLabel.minlen, label.minlen)
          });
        });
        return simplified;
      }
      function asNonCompoundGraph(g) {
        let simplified = new Graph({ multigraph: g.isMultigraph() }).setGraph(g.graph());
        g.nodes().forEach((v) => {
          if (!g.children(v).length) {
            simplified.setNode(v, g.node(v));
          }
        });
        g.edges().forEach((e) => {
          simplified.setEdge(e, g.edge(e));
        });
        return simplified;
      }
      function successorWeights(g) {
        let weightMap = g.nodes().map((v) => {
          let sucs = {};
          g.outEdges(v).forEach((e) => {
            sucs[e.w] = (sucs[e.w] || 0) + g.edge(e).weight;
          });
          return sucs;
        });
        return zipObject(g.nodes(), weightMap);
      }
      function predecessorWeights(g) {
        let weightMap = g.nodes().map((v) => {
          let preds = {};
          g.inEdges(v).forEach((e) => {
            preds[e.v] = (preds[e.v] || 0) + g.edge(e).weight;
          });
          return preds;
        });
        return zipObject(g.nodes(), weightMap);
      }
      function intersectRect(rect, point) {
        let x = rect.x;
        let y = rect.y;
        let dx = point.x - x;
        let dy = point.y - y;
        let w = rect.width / 2;
        let h = rect.height / 2;
        if (!dx && !dy) {
          throw new Error("Not possible to find intersection inside of the rectangle");
        }
        let sx, sy;
        if (Math.abs(dy) * w > Math.abs(dx) * h) {
          if (dy < 0) {
            h = -h;
          }
          sx = h * dx / dy;
          sy = h;
        } else {
          if (dx < 0) {
            w = -w;
          }
          sx = w;
          sy = w * dy / dx;
        }
        return { x: x + sx, y: y + sy };
      }
      function buildLayerMatrix(g) {
        let layering = range(maxRank(g) + 1).map(() => []);
        g.nodes().forEach((v) => {
          let node = g.node(v);
          let rank = node.rank;
          if (rank !== undefined) {
            layering[rank][node.order] = v;
          }
        });
        return layering;
      }
      function normalizeRanks(g) {
        let nodeRanks = g.nodes().map((v) => {
          let rank = g.node(v).rank;
          if (rank === undefined) {
            return Number.MAX_VALUE;
          }
          return rank;
        });
        let min = applyWithChunking(Math.min, nodeRanks);
        g.nodes().forEach((v) => {
          let node = g.node(v);
          if (Object.hasOwn(node, "rank")) {
            node.rank -= min;
          }
        });
      }
      function removeEmptyRanks(g) {
        let nodeRanks = g.nodes().map((v) => g.node(v).rank);
        let offset = applyWithChunking(Math.min, nodeRanks);
        let layers = [];
        g.nodes().forEach((v) => {
          let rank = g.node(v).rank - offset;
          if (!layers[rank]) {
            layers[rank] = [];
          }
          layers[rank].push(v);
        });
        let delta = 0;
        let nodeRankFactor = g.graph().nodeRankFactor;
        Array.from(layers).forEach((vs, i) => {
          if (vs === undefined && i % nodeRankFactor !== 0) {
            --delta;
          } else if (vs !== undefined && delta) {
            vs.forEach((v) => g.node(v).rank += delta);
          }
        });
      }
      function addBorderNode(g, prefix, rank, order) {
        let node = {
          width: 0,
          height: 0
        };
        if (arguments.length >= 4) {
          node.rank = rank;
          node.order = order;
        }
        return addDummyNode(g, "border", node, prefix);
      }
      function splitToChunks(array, chunkSize = CHUNKING_THRESHOLD) {
        const chunks = [];
        for (let i = 0;i < array.length; i += chunkSize) {
          const chunk = array.slice(i, i + chunkSize);
          chunks.push(chunk);
        }
        return chunks;
      }
      const CHUNKING_THRESHOLD = 65535;
      function applyWithChunking(fn, argsArray) {
        if (argsArray.length > CHUNKING_THRESHOLD) {
          const chunks = splitToChunks(argsArray);
          return fn.apply(null, chunks.map((chunk) => fn.apply(null, chunk)));
        } else {
          return fn.apply(null, argsArray);
        }
      }
      function maxRank(g) {
        const nodes = g.nodes();
        const nodeRanks = nodes.map((v) => {
          let rank = g.node(v).rank;
          if (rank === undefined) {
            return Number.MIN_VALUE;
          }
          return rank;
        });
        return applyWithChunking(Math.max, nodeRanks);
      }
      function partition(collection, fn) {
        let result = { lhs: [], rhs: [] };
        collection.forEach((value) => {
          if (fn(value)) {
            result.lhs.push(value);
          } else {
            result.rhs.push(value);
          }
        });
        return result;
      }
      function time(name, fn) {
        let start = Date.now();
        try {
          return fn();
        } finally {
          console.log(name + " time: " + (Date.now() - start) + "ms");
        }
      }
      function notime(name, fn) {
        return fn();
      }
      let idCounter = 0;
      function uniqueId(prefix) {
        var id = ++idCounter;
        return prefix + ("" + id);
      }
      function range(start, limit, step = 1) {
        if (limit == null) {
          limit = start;
          start = 0;
        }
        let endCon = (i) => i < limit;
        if (step < 0) {
          endCon = (i) => limit < i;
        }
        const range2 = [];
        for (let i = start;endCon(i); i += step) {
          range2.push(i);
        }
        return range2;
      }
      function pick(source, keys) {
        const dest = {};
        for (const key of keys) {
          if (source[key] !== undefined) {
            dest[key] = source[key];
          }
        }
        return dest;
      }
      function mapValues(obj, funcOrProp) {
        let func = funcOrProp;
        if (typeof funcOrProp === "string") {
          func = (val) => val[funcOrProp];
        }
        return Object.entries(obj).reduce((acc, [k, v]) => {
          acc[k] = func(v, k);
          return acc;
        }, {});
      }
      function zipObject(props, values) {
        return props.reduce((acc, key, i) => {
          acc[key] = values[i];
          return acc;
        }, {});
      }
    }, { "@dagrejs/graphlib": 29 }], 28: [function(require2, module3, exports3) {
      module3.exports = "1.1.8";
    }, {}], 29: [function(require2, module3, exports3) {
      var lib = require2("./lib");
      module3.exports = {
        Graph: lib.Graph,
        json: require2("./lib/json"),
        alg: require2("./lib/alg"),
        version: lib.version
      };
    }, { "./lib": 45, "./lib/alg": 36, "./lib/json": 46 }], 30: [function(require2, module3, exports3) {
      module3.exports = components;
      function components(g) {
        var visited = {};
        var cmpts = [];
        var cmpt;
        function dfs(v) {
          if (Object.hasOwn(visited, v))
            return;
          visited[v] = true;
          cmpt.push(v);
          g.successors(v).forEach(dfs);
          g.predecessors(v).forEach(dfs);
        }
        g.nodes().forEach(function(v) {
          cmpt = [];
          dfs(v);
          if (cmpt.length) {
            cmpts.push(cmpt);
          }
        });
        return cmpts;
      }
    }, {}], 31: [function(require2, module3, exports3) {
      module3.exports = dfs;
      function dfs(g, vs, order) {
        if (!Array.isArray(vs)) {
          vs = [vs];
        }
        var navigation = g.isDirected() ? (v) => g.successors(v) : (v) => g.neighbors(v);
        var orderFunc = order === "post" ? postOrderDfs : preOrderDfs;
        var acc = [];
        var visited = {};
        vs.forEach((v) => {
          if (!g.hasNode(v)) {
            throw new Error("Graph does not have node: " + v);
          }
          orderFunc(v, navigation, visited, acc);
        });
        return acc;
      }
      function postOrderDfs(v, navigation, visited, acc) {
        var stack = [[v, false]];
        while (stack.length > 0) {
          var curr = stack.pop();
          if (curr[1]) {
            acc.push(curr[0]);
          } else {
            if (!Object.hasOwn(visited, curr[0])) {
              visited[curr[0]] = true;
              stack.push([curr[0], true]);
              forEachRight(navigation(curr[0]), (w) => stack.push([w, false]));
            }
          }
        }
      }
      function preOrderDfs(v, navigation, visited, acc) {
        var stack = [v];
        while (stack.length > 0) {
          var curr = stack.pop();
          if (!Object.hasOwn(visited, curr)) {
            visited[curr] = true;
            acc.push(curr);
            forEachRight(navigation(curr), (w) => stack.push(w));
          }
        }
      }
      function forEachRight(array, iteratee) {
        var length = array.length;
        while (length--) {
          iteratee(array[length], length, array);
        }
        return array;
      }
    }, {}], 32: [function(require2, module3, exports3) {
      var dijkstra = require2("./dijkstra");
      module3.exports = dijkstraAll;
      function dijkstraAll(g, weightFunc, edgeFunc) {
        return g.nodes().reduce(function(acc, v) {
          acc[v] = dijkstra(g, v, weightFunc, edgeFunc);
          return acc;
        }, {});
      }
    }, { "./dijkstra": 33 }], 33: [function(require2, module3, exports3) {
      var PriorityQueue = require2("../data/priority-queue");
      module3.exports = dijkstra;
      var DEFAULT_WEIGHT_FUNC = () => 1;
      function dijkstra(g, source, weightFn, edgeFn) {
        return runDijkstra(g, String(source), weightFn || DEFAULT_WEIGHT_FUNC, edgeFn || function(v) {
          return g.outEdges(v);
        });
      }
      function runDijkstra(g, source, weightFn, edgeFn) {
        var results = {};
        var pq = new PriorityQueue;
        var v, vEntry;
        var updateNeighbors = function(edge) {
          var w = edge.v !== v ? edge.v : edge.w;
          var wEntry = results[w];
          var weight = weightFn(edge);
          var distance = vEntry.distance + weight;
          if (weight < 0) {
            throw new Error("dijkstra does not allow negative edge weights. " + "Bad edge: " + edge + " Weight: " + weight);
          }
          if (distance < wEntry.distance) {
            wEntry.distance = distance;
            wEntry.predecessor = v;
            pq.decrease(w, distance);
          }
        };
        g.nodes().forEach(function(v2) {
          var distance = v2 === source ? 0 : Number.POSITIVE_INFINITY;
          results[v2] = { distance };
          pq.add(v2, distance);
        });
        while (pq.size() > 0) {
          v = pq.removeMin();
          vEntry = results[v];
          if (vEntry.distance === Number.POSITIVE_INFINITY) {
            break;
          }
          edgeFn(v).forEach(updateNeighbors);
        }
        return results;
      }
    }, { "../data/priority-queue": 43 }], 34: [function(require2, module3, exports3) {
      var tarjan = require2("./tarjan");
      module3.exports = findCycles;
      function findCycles(g) {
        return tarjan(g).filter(function(cmpt) {
          return cmpt.length > 1 || cmpt.length === 1 && g.hasEdge(cmpt[0], cmpt[0]);
        });
      }
    }, { "./tarjan": 41 }], 35: [function(require2, module3, exports3) {
      module3.exports = floydWarshall;
      var DEFAULT_WEIGHT_FUNC = () => 1;
      function floydWarshall(g, weightFn, edgeFn) {
        return runFloydWarshall(g, weightFn || DEFAULT_WEIGHT_FUNC, edgeFn || function(v) {
          return g.outEdges(v);
        });
      }
      function runFloydWarshall(g, weightFn, edgeFn) {
        var results = {};
        var nodes = g.nodes();
        nodes.forEach(function(v) {
          results[v] = {};
          results[v][v] = { distance: 0 };
          nodes.forEach(function(w) {
            if (v !== w) {
              results[v][w] = { distance: Number.POSITIVE_INFINITY };
            }
          });
          edgeFn(v).forEach(function(edge) {
            var w = edge.v === v ? edge.w : edge.v;
            var d = weightFn(edge);
            results[v][w] = { distance: d, predecessor: v };
          });
        });
        nodes.forEach(function(k) {
          var rowK = results[k];
          nodes.forEach(function(i) {
            var rowI = results[i];
            nodes.forEach(function(j) {
              var ik = rowI[k];
              var kj = rowK[j];
              var ij = rowI[j];
              var altDistance = ik.distance + kj.distance;
              if (altDistance < ij.distance) {
                ij.distance = altDistance;
                ij.predecessor = kj.predecessor;
              }
            });
          });
        });
        return results;
      }
    }, {}], 36: [function(require2, module3, exports3) {
      module3.exports = {
        components: require2("./components"),
        dijkstra: require2("./dijkstra"),
        dijkstraAll: require2("./dijkstra-all"),
        findCycles: require2("./find-cycles"),
        floydWarshall: require2("./floyd-warshall"),
        isAcyclic: require2("./is-acyclic"),
        postorder: require2("./postorder"),
        preorder: require2("./preorder"),
        prim: require2("./prim"),
        tarjan: require2("./tarjan"),
        topsort: require2("./topsort")
      };
    }, { "./components": 30, "./dijkstra": 33, "./dijkstra-all": 32, "./find-cycles": 34, "./floyd-warshall": 35, "./is-acyclic": 37, "./postorder": 38, "./preorder": 39, "./prim": 40, "./tarjan": 41, "./topsort": 42 }], 37: [function(require2, module3, exports3) {
      var topsort = require2("./topsort");
      module3.exports = isAcyclic;
      function isAcyclic(g) {
        try {
          topsort(g);
        } catch (e) {
          if (e instanceof topsort.CycleException) {
            return false;
          }
          throw e;
        }
        return true;
      }
    }, { "./topsort": 42 }], 38: [function(require2, module3, exports3) {
      var dfs = require2("./dfs");
      module3.exports = postorder;
      function postorder(g, vs) {
        return dfs(g, vs, "post");
      }
    }, { "./dfs": 31 }], 39: [function(require2, module3, exports3) {
      var dfs = require2("./dfs");
      module3.exports = preorder;
      function preorder(g, vs) {
        return dfs(g, vs, "pre");
      }
    }, { "./dfs": 31 }], 40: [function(require2, module3, exports3) {
      var Graph = require2("../graph");
      var PriorityQueue = require2("../data/priority-queue");
      module3.exports = prim;
      function prim(g, weightFunc) {
        var result = new Graph;
        var parents = {};
        var pq = new PriorityQueue;
        var v;
        function updateNeighbors(edge) {
          var w = edge.v === v ? edge.w : edge.v;
          var pri = pq.priority(w);
          if (pri !== undefined) {
            var edgeWeight = weightFunc(edge);
            if (edgeWeight < pri) {
              parents[w] = v;
              pq.decrease(w, edgeWeight);
            }
          }
        }
        if (g.nodeCount() === 0) {
          return result;
        }
        g.nodes().forEach(function(v2) {
          pq.add(v2, Number.POSITIVE_INFINITY);
          result.setNode(v2);
        });
        pq.decrease(g.nodes()[0], 0);
        var init = false;
        while (pq.size() > 0) {
          v = pq.removeMin();
          if (Object.hasOwn(parents, v)) {
            result.setEdge(v, parents[v]);
          } else if (init) {
            throw new Error("Input graph is not connected: " + g);
          } else {
            init = true;
          }
          g.nodeEdges(v).forEach(updateNeighbors);
        }
        return result;
      }
    }, { "../data/priority-queue": 43, "../graph": 44 }], 41: [function(require2, module3, exports3) {
      module3.exports = tarjan;
      function tarjan(g) {
        var index = 0;
        var stack = [];
        var visited = {};
        var results = [];
        function dfs(v) {
          var entry = visited[v] = {
            onStack: true,
            lowlink: index,
            index: index++
          };
          stack.push(v);
          g.successors(v).forEach(function(w2) {
            if (!Object.hasOwn(visited, w2)) {
              dfs(w2);
              entry.lowlink = Math.min(entry.lowlink, visited[w2].lowlink);
            } else if (visited[w2].onStack) {
              entry.lowlink = Math.min(entry.lowlink, visited[w2].index);
            }
          });
          if (entry.lowlink === entry.index) {
            var cmpt = [];
            var w;
            do {
              w = stack.pop();
              visited[w].onStack = false;
              cmpt.push(w);
            } while (v !== w);
            results.push(cmpt);
          }
        }
        g.nodes().forEach(function(v) {
          if (!Object.hasOwn(visited, v)) {
            dfs(v);
          }
        });
        return results;
      }
    }, {}], 42: [function(require2, module3, exports3) {
      function topsort(g) {
        var visited = {};
        var stack = {};
        var results = [];
        function visit(node) {
          if (Object.hasOwn(stack, node)) {
            throw new CycleException;
          }
          if (!Object.hasOwn(visited, node)) {
            stack[node] = true;
            visited[node] = true;
            g.predecessors(node).forEach(visit);
            delete stack[node];
            results.push(node);
          }
        }
        g.sinks().forEach(visit);
        if (Object.keys(visited).length !== g.nodeCount()) {
          throw new CycleException;
        }
        return results;
      }

      class CycleException extends Error {
        constructor() {
          super(...arguments);
        }
      }
      module3.exports = topsort;
      topsort.CycleException = CycleException;
    }, {}], 43: [function(require2, module3, exports3) {

      class PriorityQueue {
        _arr = [];
        _keyIndices = {};
        size() {
          return this._arr.length;
        }
        keys() {
          return this._arr.map(function(x) {
            return x.key;
          });
        }
        has(key) {
          return Object.hasOwn(this._keyIndices, key);
        }
        priority(key) {
          var index = this._keyIndices[key];
          if (index !== undefined) {
            return this._arr[index].priority;
          }
        }
        min() {
          if (this.size() === 0) {
            throw new Error("Queue underflow");
          }
          return this._arr[0].key;
        }
        add(key, priority) {
          var keyIndices = this._keyIndices;
          key = String(key);
          if (!Object.hasOwn(keyIndices, key)) {
            var arr = this._arr;
            var index = arr.length;
            keyIndices[key] = index;
            arr.push({ key, priority });
            this._decrease(index);
            return true;
          }
          return false;
        }
        removeMin() {
          this._swap(0, this._arr.length - 1);
          var min = this._arr.pop();
          delete this._keyIndices[min.key];
          this._heapify(0);
          return min.key;
        }
        decrease(key, priority) {
          var index = this._keyIndices[key];
          if (priority > this._arr[index].priority) {
            throw new Error("New priority is greater than current priority. " + "Key: " + key + " Old: " + this._arr[index].priority + " New: " + priority);
          }
          this._arr[index].priority = priority;
          this._decrease(index);
        }
        _heapify(i) {
          var arr = this._arr;
          var l = 2 * i;
          var r = l + 1;
          var largest = i;
          if (l < arr.length) {
            largest = arr[l].priority < arr[largest].priority ? l : largest;
            if (r < arr.length) {
              largest = arr[r].priority < arr[largest].priority ? r : largest;
            }
            if (largest !== i) {
              this._swap(i, largest);
              this._heapify(largest);
            }
          }
        }
        _decrease(index) {
          var arr = this._arr;
          var priority = arr[index].priority;
          var parent;
          while (index !== 0) {
            parent = index >> 1;
            if (arr[parent].priority < priority) {
              break;
            }
            this._swap(index, parent);
            index = parent;
          }
        }
        _swap(i, j) {
          var arr = this._arr;
          var keyIndices = this._keyIndices;
          var origArrI = arr[i];
          var origArrJ = arr[j];
          arr[i] = origArrJ;
          arr[j] = origArrI;
          keyIndices[origArrJ.key] = i;
          keyIndices[origArrI.key] = j;
        }
      }
      module3.exports = PriorityQueue;
    }, {}], 44: [function(require2, module3, exports3) {
      var DEFAULT_EDGE_NAME = "\x00";
      var GRAPH_NODE = "\x00";
      var EDGE_KEY_DELIM = "\x01";

      class Graph {
        _isDirected = true;
        _isMultigraph = false;
        _isCompound = false;
        _label;
        _defaultNodeLabelFn = () => {
          return;
        };
        _defaultEdgeLabelFn = () => {
          return;
        };
        _nodes = {};
        _in = {};
        _preds = {};
        _out = {};
        _sucs = {};
        _edgeObjs = {};
        _edgeLabels = {};
        _nodeCount = 0;
        _edgeCount = 0;
        _parent;
        _children;
        constructor(opts) {
          if (opts) {
            this._isDirected = Object.hasOwn(opts, "directed") ? opts.directed : true;
            this._isMultigraph = Object.hasOwn(opts, "multigraph") ? opts.multigraph : false;
            this._isCompound = Object.hasOwn(opts, "compound") ? opts.compound : false;
          }
          if (this._isCompound) {
            this._parent = {};
            this._children = {};
            this._children[GRAPH_NODE] = {};
          }
        }
        isDirected() {
          return this._isDirected;
        }
        isMultigraph() {
          return this._isMultigraph;
        }
        isCompound() {
          return this._isCompound;
        }
        setGraph(label) {
          this._label = label;
          return this;
        }
        graph() {
          return this._label;
        }
        setDefaultNodeLabel(newDefault) {
          this._defaultNodeLabelFn = newDefault;
          if (typeof newDefault !== "function") {
            this._defaultNodeLabelFn = () => newDefault;
          }
          return this;
        }
        nodeCount() {
          return this._nodeCount;
        }
        nodes() {
          return Object.keys(this._nodes);
        }
        sources() {
          var self2 = this;
          return this.nodes().filter((v) => Object.keys(self2._in[v]).length === 0);
        }
        sinks() {
          var self2 = this;
          return this.nodes().filter((v) => Object.keys(self2._out[v]).length === 0);
        }
        setNodes(vs, value) {
          var args = arguments;
          var self2 = this;
          vs.forEach(function(v) {
            if (args.length > 1) {
              self2.setNode(v, value);
            } else {
              self2.setNode(v);
            }
          });
          return this;
        }
        setNode(v, value) {
          if (Object.hasOwn(this._nodes, v)) {
            if (arguments.length > 1) {
              this._nodes[v] = value;
            }
            return this;
          }
          this._nodes[v] = arguments.length > 1 ? value : this._defaultNodeLabelFn(v);
          if (this._isCompound) {
            this._parent[v] = GRAPH_NODE;
            this._children[v] = {};
            this._children[GRAPH_NODE][v] = true;
          }
          this._in[v] = {};
          this._preds[v] = {};
          this._out[v] = {};
          this._sucs[v] = {};
          ++this._nodeCount;
          return this;
        }
        node(v) {
          return this._nodes[v];
        }
        hasNode(v) {
          return Object.hasOwn(this._nodes, v);
        }
        removeNode(v) {
          var self2 = this;
          if (Object.hasOwn(this._nodes, v)) {
            var removeEdge = (e) => self2.removeEdge(self2._edgeObjs[e]);
            delete this._nodes[v];
            if (this._isCompound) {
              this._removeFromParentsChildList(v);
              delete this._parent[v];
              this.children(v).forEach(function(child) {
                self2.setParent(child);
              });
              delete this._children[v];
            }
            Object.keys(this._in[v]).forEach(removeEdge);
            delete this._in[v];
            delete this._preds[v];
            Object.keys(this._out[v]).forEach(removeEdge);
            delete this._out[v];
            delete this._sucs[v];
            --this._nodeCount;
          }
          return this;
        }
        setParent(v, parent) {
          if (!this._isCompound) {
            throw new Error("Cannot set parent in a non-compound graph");
          }
          if (parent === undefined) {
            parent = GRAPH_NODE;
          } else {
            parent += "";
            for (var ancestor = parent;ancestor !== undefined; ancestor = this.parent(ancestor)) {
              if (ancestor === v) {
                throw new Error("Setting " + parent + " as parent of " + v + " would create a cycle");
              }
            }
            this.setNode(parent);
          }
          this.setNode(v);
          this._removeFromParentsChildList(v);
          this._parent[v] = parent;
          this._children[parent][v] = true;
          return this;
        }
        _removeFromParentsChildList(v) {
          delete this._children[this._parent[v]][v];
        }
        parent(v) {
          if (this._isCompound) {
            var parent = this._parent[v];
            if (parent !== GRAPH_NODE) {
              return parent;
            }
          }
        }
        children(v = GRAPH_NODE) {
          if (this._isCompound) {
            var children = this._children[v];
            if (children) {
              return Object.keys(children);
            }
          } else if (v === GRAPH_NODE) {
            return this.nodes();
          } else if (this.hasNode(v)) {
            return [];
          }
        }
        predecessors(v) {
          var predsV = this._preds[v];
          if (predsV) {
            return Object.keys(predsV);
          }
        }
        successors(v) {
          var sucsV = this._sucs[v];
          if (sucsV) {
            return Object.keys(sucsV);
          }
        }
        neighbors(v) {
          var preds = this.predecessors(v);
          if (preds) {
            const union = new Set(preds);
            for (var succ of this.successors(v)) {
              union.add(succ);
            }
            return Array.from(union.values());
          }
        }
        isLeaf(v) {
          var neighbors;
          if (this.isDirected()) {
            neighbors = this.successors(v);
          } else {
            neighbors = this.neighbors(v);
          }
          return neighbors.length === 0;
        }
        filterNodes(filter) {
          var copy = new this.constructor({
            directed: this._isDirected,
            multigraph: this._isMultigraph,
            compound: this._isCompound
          });
          copy.setGraph(this.graph());
          var self2 = this;
          Object.entries(this._nodes).forEach(function([v, value]) {
            if (filter(v)) {
              copy.setNode(v, value);
            }
          });
          Object.values(this._edgeObjs).forEach(function(e) {
            if (copy.hasNode(e.v) && copy.hasNode(e.w)) {
              copy.setEdge(e, self2.edge(e));
            }
          });
          var parents = {};
          function findParent(v) {
            var parent = self2.parent(v);
            if (parent === undefined || copy.hasNode(parent)) {
              parents[v] = parent;
              return parent;
            } else if (parent in parents) {
              return parents[parent];
            } else {
              return findParent(parent);
            }
          }
          if (this._isCompound) {
            copy.nodes().forEach((v) => copy.setParent(v, findParent(v)));
          }
          return copy;
        }
        setDefaultEdgeLabel(newDefault) {
          this._defaultEdgeLabelFn = newDefault;
          if (typeof newDefault !== "function") {
            this._defaultEdgeLabelFn = () => newDefault;
          }
          return this;
        }
        edgeCount() {
          return this._edgeCount;
        }
        edges() {
          return Object.values(this._edgeObjs);
        }
        setPath(vs, value) {
          var self2 = this;
          var args = arguments;
          vs.reduce(function(v, w) {
            if (args.length > 1) {
              self2.setEdge(v, w, value);
            } else {
              self2.setEdge(v, w);
            }
            return w;
          });
          return this;
        }
        setEdge() {
          var v, w, name, value;
          var valueSpecified = false;
          var arg0 = arguments[0];
          if (typeof arg0 === "object" && arg0 !== null && "v" in arg0) {
            v = arg0.v;
            w = arg0.w;
            name = arg0.name;
            if (arguments.length === 2) {
              value = arguments[1];
              valueSpecified = true;
            }
          } else {
            v = arg0;
            w = arguments[1];
            name = arguments[3];
            if (arguments.length > 2) {
              value = arguments[2];
              valueSpecified = true;
            }
          }
          v = "" + v;
          w = "" + w;
          if (name !== undefined) {
            name = "" + name;
          }
          var e = edgeArgsToId(this._isDirected, v, w, name);
          if (Object.hasOwn(this._edgeLabels, e)) {
            if (valueSpecified) {
              this._edgeLabels[e] = value;
            }
            return this;
          }
          if (name !== undefined && !this._isMultigraph) {
            throw new Error("Cannot set a named edge when isMultigraph = false");
          }
          this.setNode(v);
          this.setNode(w);
          this._edgeLabels[e] = valueSpecified ? value : this._defaultEdgeLabelFn(v, w, name);
          var edgeObj = edgeArgsToObj(this._isDirected, v, w, name);
          v = edgeObj.v;
          w = edgeObj.w;
          Object.freeze(edgeObj);
          this._edgeObjs[e] = edgeObj;
          incrementOrInitEntry(this._preds[w], v);
          incrementOrInitEntry(this._sucs[v], w);
          this._in[w][e] = edgeObj;
          this._out[v][e] = edgeObj;
          this._edgeCount++;
          return this;
        }
        edge(v, w, name) {
          var e = arguments.length === 1 ? edgeObjToId(this._isDirected, arguments[0]) : edgeArgsToId(this._isDirected, v, w, name);
          return this._edgeLabels[e];
        }
        edgeAsObj() {
          const edge = this.edge(...arguments);
          if (typeof edge !== "object") {
            return { label: edge };
          }
          return edge;
        }
        hasEdge(v, w, name) {
          var e = arguments.length === 1 ? edgeObjToId(this._isDirected, arguments[0]) : edgeArgsToId(this._isDirected, v, w, name);
          return Object.hasOwn(this._edgeLabels, e);
        }
        removeEdge(v, w, name) {
          var e = arguments.length === 1 ? edgeObjToId(this._isDirected, arguments[0]) : edgeArgsToId(this._isDirected, v, w, name);
          var edge = this._edgeObjs[e];
          if (edge) {
            v = edge.v;
            w = edge.w;
            delete this._edgeLabels[e];
            delete this._edgeObjs[e];
            decrementOrRemoveEntry(this._preds[w], v);
            decrementOrRemoveEntry(this._sucs[v], w);
            delete this._in[w][e];
            delete this._out[v][e];
            this._edgeCount--;
          }
          return this;
        }
        inEdges(v, u) {
          var inV = this._in[v];
          if (inV) {
            var edges = Object.values(inV);
            if (!u) {
              return edges;
            }
            return edges.filter((edge) => edge.v === u);
          }
        }
        outEdges(v, w) {
          var outV = this._out[v];
          if (outV) {
            var edges = Object.values(outV);
            if (!w) {
              return edges;
            }
            return edges.filter((edge) => edge.w === w);
          }
        }
        nodeEdges(v, w) {
          var inEdges = this.inEdges(v, w);
          if (inEdges) {
            return inEdges.concat(this.outEdges(v, w));
          }
        }
      }
      function incrementOrInitEntry(map, k) {
        if (map[k]) {
          map[k]++;
        } else {
          map[k] = 1;
        }
      }
      function decrementOrRemoveEntry(map, k) {
        if (!--map[k]) {
          delete map[k];
        }
      }
      function edgeArgsToId(isDirected, v_, w_, name) {
        var v = "" + v_;
        var w = "" + w_;
        if (!isDirected && v > w) {
          var tmp = v;
          v = w;
          w = tmp;
        }
        return v + EDGE_KEY_DELIM + w + EDGE_KEY_DELIM + (name === undefined ? DEFAULT_EDGE_NAME : name);
      }
      function edgeArgsToObj(isDirected, v_, w_, name) {
        var v = "" + v_;
        var w = "" + w_;
        if (!isDirected && v > w) {
          var tmp = v;
          v = w;
          w = tmp;
        }
        var edgeObj = { v, w };
        if (name) {
          edgeObj.name = name;
        }
        return edgeObj;
      }
      function edgeObjToId(isDirected, edgeObj) {
        return edgeArgsToId(isDirected, edgeObj.v, edgeObj.w, edgeObj.name);
      }
      module3.exports = Graph;
    }, {}], 45: [function(require2, module3, exports3) {
      module3.exports = {
        Graph: require2("./graph"),
        version: require2("./version")
      };
    }, { "./graph": 44, "./version": 47 }], 46: [function(require2, module3, exports3) {
      var Graph = require2("./graph");
      module3.exports = {
        write,
        read
      };
      function write(g) {
        var json = {
          options: {
            directed: g.isDirected(),
            multigraph: g.isMultigraph(),
            compound: g.isCompound()
          },
          nodes: writeNodes(g),
          edges: writeEdges(g)
        };
        if (g.graph() !== undefined) {
          json.value = structuredClone(g.graph());
        }
        return json;
      }
      function writeNodes(g) {
        return g.nodes().map(function(v) {
          var nodeValue = g.node(v);
          var parent = g.parent(v);
          var node = { v };
          if (nodeValue !== undefined) {
            node.value = nodeValue;
          }
          if (parent !== undefined) {
            node.parent = parent;
          }
          return node;
        });
      }
      function writeEdges(g) {
        return g.edges().map(function(e) {
          var edgeValue = g.edge(e);
          var edge = { v: e.v, w: e.w };
          if (e.name !== undefined) {
            edge.name = e.name;
          }
          if (edgeValue !== undefined) {
            edge.value = edgeValue;
          }
          return edge;
        });
      }
      function read(json) {
        var g = new Graph(json.options).setGraph(json.value);
        json.nodes.forEach(function(entry) {
          g.setNode(entry.v, entry.value);
          if (entry.parent) {
            g.setParent(entry.v, entry.parent);
          }
        });
        json.edges.forEach(function(entry) {
          g.setEdge({ v: entry.v, w: entry.w, name: entry.name }, entry.value);
        });
        return g;
      }
    }, { "./graph": 44 }], 47: [function(require2, module3, exports3) {
      module3.exports = "2.2.4";
    }, {}] }, {}, [1])(1);
  });
});

// node_modules/beautiful-mermaid/dist/index.js
var import_dagre = __toESM(require_dagre(), 1);
function parseMermaid(text) {
  const lines = text.split(`
`).map((l) => l.trim()).filter((l) => l.length > 0 && !l.startsWith("%%"));
  if (lines.length === 0) {
    throw new Error("Empty mermaid diagram");
  }
  const header = lines[0];
  if (/^stateDiagram(-v2)?\s*$/i.test(header)) {
    return parseStateDiagram(lines);
  }
  return parseFlowchart(lines);
}
function parseFlowchart(lines) {
  const headerMatch = lines[0].match(/^(?:graph|flowchart)\s+(TD|TB|LR|BT|RL)\s*$/i);
  if (!headerMatch) {
    throw new Error(`Invalid mermaid header: "${lines[0]}". Expected "graph TD", "flowchart LR", "stateDiagram-v2", etc.`);
  }
  const direction = headerMatch[1].toUpperCase();
  const graph = {
    direction,
    nodes: /* @__PURE__ */ new Map,
    edges: [],
    subgraphs: [],
    classDefs: /* @__PURE__ */ new Map,
    classAssignments: /* @__PURE__ */ new Map,
    nodeStyles: /* @__PURE__ */ new Map
  };
  const subgraphStack = [];
  for (let i = 1;i < lines.length; i++) {
    const line = lines[i];
    const classDefMatch = line.match(/^classDef\s+(\w+)\s+(.+)$/);
    if (classDefMatch) {
      const name = classDefMatch[1];
      const propsStr = classDefMatch[2];
      const props = parseStyleProps(propsStr);
      graph.classDefs.set(name, props);
      continue;
    }
    const classAssignMatch = line.match(/^class\s+([\w,-]+)\s+(\w+)$/);
    if (classAssignMatch) {
      const nodeIds = classAssignMatch[1].split(",").map((s) => s.trim());
      const className = classAssignMatch[2];
      for (const id of nodeIds) {
        graph.classAssignments.set(id, className);
      }
      continue;
    }
    const styleMatch = line.match(/^style\s+([\w,-]+)\s+(.+)$/);
    if (styleMatch) {
      const nodeIds = styleMatch[1].split(",").map((s) => s.trim());
      const props = parseStyleProps(styleMatch[2]);
      for (const id of nodeIds) {
        graph.nodeStyles.set(id, { ...graph.nodeStyles.get(id), ...props });
      }
      continue;
    }
    const dirMatch = line.match(/^direction\s+(TD|TB|LR|BT|RL)\s*$/i);
    if (dirMatch && subgraphStack.length > 0) {
      subgraphStack[subgraphStack.length - 1].direction = dirMatch[1].toUpperCase();
      continue;
    }
    const subgraphMatch = line.match(/^subgraph\s+(.+)$/);
    if (subgraphMatch) {
      const rest = subgraphMatch[1].trim();
      const bracketMatch = rest.match(/^([\w-]+)\s*\[(.+)\]$/);
      let id;
      let label;
      if (bracketMatch) {
        id = bracketMatch[1];
        label = bracketMatch[2];
      } else {
        label = rest;
        id = rest.replace(/\s+/g, "_").replace(/[^\w]/g, "");
      }
      const sg = { id, label, nodeIds: [], children: [] };
      subgraphStack.push(sg);
      continue;
    }
    if (line === "end") {
      const completed = subgraphStack.pop();
      if (completed) {
        if (subgraphStack.length > 0) {
          subgraphStack[subgraphStack.length - 1].children.push(completed);
        } else {
          graph.subgraphs.push(completed);
        }
      }
      continue;
    }
    parseEdgeLine(line, graph, subgraphStack);
  }
  return graph;
}
function parseStateDiagram(lines) {
  const graph = {
    direction: "TD",
    nodes: /* @__PURE__ */ new Map,
    edges: [],
    subgraphs: [],
    classDefs: /* @__PURE__ */ new Map,
    classAssignments: /* @__PURE__ */ new Map,
    nodeStyles: /* @__PURE__ */ new Map
  };
  const compositeStack = [];
  let startCount = 0;
  let endCount = 0;
  for (let i = 1;i < lines.length; i++) {
    const line = lines[i];
    const dirMatch = line.match(/^direction\s+(TD|TB|LR|BT|RL)\s*$/i);
    if (dirMatch) {
      if (compositeStack.length > 0) {
        compositeStack[compositeStack.length - 1].direction = dirMatch[1].toUpperCase();
      } else {
        graph.direction = dirMatch[1].toUpperCase();
      }
      continue;
    }
    const compositeMatch = line.match(/^state\s+(?:"([^"]+)"\s+as\s+)?(\w+)\s*\{$/);
    if (compositeMatch) {
      const label = compositeMatch[1] ?? compositeMatch[2];
      const id = compositeMatch[2];
      const sg = { id, label, nodeIds: [], children: [] };
      compositeStack.push(sg);
      continue;
    }
    if (line === "}") {
      const completed = compositeStack.pop();
      if (completed) {
        if (compositeStack.length > 0) {
          compositeStack[compositeStack.length - 1].children.push(completed);
        } else {
          graph.subgraphs.push(completed);
        }
      }
      continue;
    }
    const stateAliasMatch = line.match(/^state\s+"([^"]+)"\s+as\s+(\w+)\s*$/);
    if (stateAliasMatch) {
      const label = stateAliasMatch[1];
      const id = stateAliasMatch[2];
      registerStateNode(graph, compositeStack, { id, label, shape: "rounded" });
      continue;
    }
    const transitionMatch = line.match(/^(\[\*\]|[\w-]+)\s*(-->)\s*(\[\*\]|[\w-]+)(?:\s*:\s*(.+))?$/);
    if (transitionMatch) {
      let sourceId = transitionMatch[1];
      let targetId = transitionMatch[3];
      const edgeLabel = transitionMatch[4]?.trim() || undefined;
      if (sourceId === "[*]") {
        startCount++;
        sourceId = `_start${startCount > 1 ? startCount : ""}`;
        registerStateNode(graph, compositeStack, { id: sourceId, label: "", shape: "state-start" });
      } else {
        ensureStateNode(graph, compositeStack, sourceId);
      }
      if (targetId === "[*]") {
        endCount++;
        targetId = `_end${endCount > 1 ? endCount : ""}`;
        registerStateNode(graph, compositeStack, { id: targetId, label: "", shape: "state-end" });
      } else {
        ensureStateNode(graph, compositeStack, targetId);
      }
      graph.edges.push({
        source: sourceId,
        target: targetId,
        label: edgeLabel,
        style: "solid",
        hasArrowStart: false,
        hasArrowEnd: true
      });
      continue;
    }
    const stateDescMatch = line.match(/^([\w-]+)\s*:\s*(.+)$/);
    if (stateDescMatch) {
      const id = stateDescMatch[1];
      const label = stateDescMatch[2].trim();
      registerStateNode(graph, compositeStack, { id, label, shape: "rounded" });
      continue;
    }
  }
  return graph;
}
function registerStateNode(graph, compositeStack, node) {
  const isNew = !graph.nodes.has(node.id);
  if (isNew) {
    graph.nodes.set(node.id, node);
  }
  if (compositeStack.length > 0) {
    const current = compositeStack[compositeStack.length - 1];
    if (!current.nodeIds.includes(node.id)) {
      current.nodeIds.push(node.id);
    }
  }
}
function ensureStateNode(graph, compositeStack, id) {
  if (!graph.nodes.has(id)) {
    registerStateNode(graph, compositeStack, { id, label: id, shape: "rounded" });
  } else {
    if (compositeStack.length > 0) {
      const current = compositeStack[compositeStack.length - 1];
      if (!current.nodeIds.includes(id)) {
        current.nodeIds.push(id);
      }
    }
  }
}
function parseStyleProps(propsStr) {
  const props = {};
  for (const pair of propsStr.split(",")) {
    const colonIdx = pair.indexOf(":");
    if (colonIdx > 0) {
      const key = pair.slice(0, colonIdx).trim();
      const val = pair.slice(colonIdx + 1).trim();
      if (key && val) {
        props[key] = val;
      }
    }
  }
  return props;
}
var ARROW_REGEX = /^(<)?(-->|-.->|==>|---|-\.-|===)(?:\|([^|]*)\|)?/;
var NODE_PATTERNS = [
  { regex: /^([\w-]+)\(\(\((.+?)\)\)\)/, shape: "doublecircle" },
  { regex: /^([\w-]+)\(\[(.+?)\]\)/, shape: "stadium" },
  { regex: /^([\w-]+)\(\((.+?)\)\)/, shape: "circle" },
  { regex: /^([\w-]+)\[\[(.+?)\]\]/, shape: "subroutine" },
  { regex: /^([\w-]+)\[\((.+?)\)\]/, shape: "cylinder" },
  { regex: /^([\w-]+)\[\/(.+?)\\\]/, shape: "trapezoid" },
  { regex: /^([\w-]+)\[\\(.+?)\/\]/, shape: "trapezoid-alt" },
  { regex: /^([\w-]+)>(.+?)\]/, shape: "asymmetric" },
  { regex: /^([\w-]+)\{\{(.+?)\}\}/, shape: "hexagon" },
  { regex: /^([\w-]+)\[(.+?)\]/, shape: "rectangle" },
  { regex: /^([\w-]+)\((.+?)\)/, shape: "rounded" },
  { regex: /^([\w-]+)\{(.+?)\}/, shape: "diamond" }
];
var BARE_NODE_REGEX = /^([\w-]+)/;
var CLASS_SHORTHAND_REGEX = /^:::([\w][\w-]*)/;
function parseEdgeLine(line, graph, subgraphStack) {
  let remaining = line.trim();
  const firstGroup = consumeNodeGroup(remaining, graph, subgraphStack);
  if (!firstGroup || firstGroup.ids.length === 0)
    return;
  remaining = firstGroup.remaining.trim();
  let prevGroupIds = firstGroup.ids;
  while (remaining.length > 0) {
    const arrowMatch = remaining.match(ARROW_REGEX);
    if (!arrowMatch)
      break;
    const hasArrowStart = Boolean(arrowMatch[1]);
    const arrowOp = arrowMatch[2];
    const edgeLabel = arrowMatch[3]?.trim() || undefined;
    remaining = remaining.slice(arrowMatch[0].length).trim();
    const style = arrowStyleFromOp(arrowOp);
    const hasArrowEnd = arrowOp.endsWith(">");
    const nextGroup = consumeNodeGroup(remaining, graph, subgraphStack);
    if (!nextGroup || nextGroup.ids.length === 0)
      break;
    remaining = nextGroup.remaining.trim();
    for (const sourceId of prevGroupIds) {
      for (const targetId of nextGroup.ids) {
        graph.edges.push({
          source: sourceId,
          target: targetId,
          label: edgeLabel,
          style,
          hasArrowStart,
          hasArrowEnd
        });
      }
    }
    prevGroupIds = nextGroup.ids;
  }
}
function consumeNodeGroup(text, graph, subgraphStack) {
  const first = consumeNode(text, graph, subgraphStack);
  if (!first)
    return null;
  const ids = [first.id];
  let remaining = first.remaining.trim();
  while (remaining.startsWith("&")) {
    remaining = remaining.slice(1).trim();
    const next = consumeNode(remaining, graph, subgraphStack);
    if (!next)
      break;
    ids.push(next.id);
    remaining = next.remaining.trim();
  }
  return { ids, remaining };
}
function consumeNode(text, graph, subgraphStack) {
  let id = null;
  let remaining = text;
  for (const { regex, shape } of NODE_PATTERNS) {
    const match = text.match(regex);
    if (match) {
      id = match[1];
      const label = match[2];
      registerNode(graph, subgraphStack, { id, label, shape });
      remaining = text.slice(match[0].length);
      break;
    }
  }
  if (id === null) {
    const bareMatch = text.match(BARE_NODE_REGEX);
    if (bareMatch) {
      id = bareMatch[1];
      if (!graph.nodes.has(id)) {
        registerNode(graph, subgraphStack, { id, label: id, shape: "rectangle" });
      } else {
        trackInSubgraph(subgraphStack, id);
      }
      remaining = text.slice(bareMatch[0].length);
    }
  }
  if (id === null)
    return null;
  const classMatch = remaining.match(CLASS_SHORTHAND_REGEX);
  if (classMatch) {
    graph.classAssignments.set(id, classMatch[1]);
    remaining = remaining.slice(classMatch[0].length);
  }
  return { id, remaining };
}
function registerNode(graph, subgraphStack, node) {
  const isNew = !graph.nodes.has(node.id);
  if (isNew) {
    graph.nodes.set(node.id, node);
  }
  trackInSubgraph(subgraphStack, node.id);
}
function trackInSubgraph(subgraphStack, nodeId) {
  if (subgraphStack.length > 0) {
    const current = subgraphStack[subgraphStack.length - 1];
    if (!current.nodeIds.includes(nodeId)) {
      current.nodeIds.push(nodeId);
    }
  }
}
function arrowStyleFromOp(op) {
  if (op === "-.->")
    return "dotted";
  if (op === "-.-")
    return "dotted";
  if (op === "==>")
    return "thick";
  if (op === "===")
    return "thick";
  return "solid";
}
var Up = { x: 1, y: 0 };
var Down = { x: 1, y: 2 };
var Left = { x: 0, y: 1 };
var Right = { x: 2, y: 1 };
var UpperRight = { x: 2, y: 0 };
var UpperLeft = { x: 0, y: 0 };
var LowerRight = { x: 2, y: 2 };
var LowerLeft = { x: 0, y: 2 };
var Middle = { x: 1, y: 1 };
function gridCoordEquals(a, b) {
  return a.x === b.x && a.y === b.y;
}
function drawingCoordEquals(a, b) {
  return a.x === b.x && a.y === b.y;
}
function gridCoordDirection(c, dir) {
  return { x: c.x + dir.x, y: c.y + dir.y };
}
function gridKey(c) {
  return `${c.x},${c.y}`;
}
var EMPTY_STYLE = { name: "", styles: {} };
function mkCanvas(x, y) {
  const canvas = [];
  for (let i = 0;i <= x; i++) {
    const col = [];
    for (let j = 0;j <= y; j++) {
      col.push(" ");
    }
    canvas.push(col);
  }
  return canvas;
}
function copyCanvas(source) {
  const [maxX, maxY] = getCanvasSize(source);
  return mkCanvas(maxX, maxY);
}
function getCanvasSize(canvas) {
  return [canvas.length - 1, (canvas[0]?.length ?? 1) - 1];
}
function increaseSize(canvas, newX, newY) {
  const [currX, currY] = getCanvasSize(canvas);
  const targetX = Math.max(newX, currX);
  const targetY = Math.max(newY, currY);
  const grown = mkCanvas(targetX, targetY);
  for (let x = 0;x < grown.length; x++) {
    for (let y = 0;y < grown[0].length; y++) {
      if (x < canvas.length && y < canvas[0].length) {
        grown[x][y] = canvas[x][y];
      }
    }
  }
  canvas.length = 0;
  canvas.push(...grown);
  return canvas;
}
var JUNCTION_CHARS = /* @__PURE__ */ new Set([
  "─",
  "│",
  "┌",
  "┐",
  "└",
  "┘",
  "├",
  "┤",
  "┬",
  "┴",
  "┼",
  "╴",
  "╵",
  "╶",
  "╷"
]);
function isJunctionChar(c) {
  return JUNCTION_CHARS.has(c);
}
var JUNCTION_MAP = {
  "─": { "│": "┼", "┌": "┬", "┐": "┬", "└": "┴", "┘": "┴", "├": "┼", "┤": "┼", "┬": "┬", "┴": "┴" },
  "│": { "─": "┼", "┌": "├", "┐": "┤", "└": "├", "┘": "┤", "├": "├", "┤": "┤", "┬": "┼", "┴": "┼" },
  "┌": { "─": "┬", "│": "├", "┐": "┬", "└": "├", "┘": "┼", "├": "├", "┤": "┼", "┬": "┬", "┴": "┼" },
  "┐": { "─": "┬", "│": "┤", "┌": "┬", "└": "┼", "┘": "┤", "├": "┼", "┤": "┤", "┬": "┬", "┴": "┼" },
  "└": { "─": "┴", "│": "├", "┌": "├", "┐": "┼", "┘": "┴", "├": "├", "┤": "┼", "┬": "┼", "┴": "┴" },
  "┘": { "─": "┴", "│": "┤", "┌": "┼", "┐": "┤", "└": "┴", "├": "┼", "┤": "┤", "┬": "┼", "┴": "┴" },
  "├": { "─": "┼", "│": "├", "┌": "├", "┐": "┼", "└": "├", "┘": "┼", "┤": "┼", "┬": "┼", "┴": "┼" },
  "┤": { "─": "┼", "│": "┤", "┌": "┼", "┐": "┤", "└": "┼", "┘": "┤", "├": "┼", "┬": "┼", "┴": "┼" },
  "┬": { "─": "┬", "│": "┼", "┌": "┬", "┐": "┬", "└": "┼", "┘": "┼", "├": "┼", "┤": "┼", "┴": "┼" },
  "┴": { "─": "┴", "│": "┼", "┌": "┼", "┐": "┼", "└": "┴", "┘": "┴", "├": "┼", "┤": "┼", "┬": "┼" }
};
function mergeJunctions(c1, c2) {
  return JUNCTION_MAP[c1]?.[c2] ?? c1;
}
function mergeCanvases(base, offset, useAscii, ...overlays) {
  let [maxX, maxY] = getCanvasSize(base);
  for (const overlay of overlays) {
    const [oX, oY] = getCanvasSize(overlay);
    maxX = Math.max(maxX, oX + offset.x);
    maxY = Math.max(maxY, oY + offset.y);
  }
  const merged = mkCanvas(maxX, maxY);
  for (let x = 0;x <= maxX; x++) {
    for (let y = 0;y <= maxY; y++) {
      if (x < base.length && y < base[0].length) {
        merged[x][y] = base[x][y];
      }
    }
  }
  for (const overlay of overlays) {
    for (let x = 0;x < overlay.length; x++) {
      for (let y = 0;y < overlay[0].length; y++) {
        const c = overlay[x][y];
        if (c !== " ") {
          const mx = x + offset.x;
          const my = y + offset.y;
          const current = merged[mx][my];
          if (!useAscii && isJunctionChar(c) && isJunctionChar(current)) {
            merged[mx][my] = mergeJunctions(current, c);
          } else {
            merged[mx][my] = c;
          }
        }
      }
    }
  }
  return merged;
}
function canvasToString(canvas) {
  const [maxX, maxY] = getCanvasSize(canvas);
  const lines = [];
  for (let y = 0;y <= maxY; y++) {
    let line = "";
    for (let x = 0;x <= maxX; x++) {
      line += canvas[x][y];
    }
    lines.push(line);
  }
  return lines.join(`
`);
}
var VERTICAL_FLIP_MAP = {
  "▲": "▼",
  "▼": "▲",
  "◤": "◣",
  "◣": "◤",
  "◥": "◢",
  "◢": "◥",
  "^": "v",
  v: "^",
  "┌": "└",
  "└": "┌",
  "┐": "┘",
  "┘": "┐",
  "┬": "┴",
  "┴": "┬",
  "╵": "╷",
  "╷": "╵"
};
function flipCanvasVertically(canvas) {
  for (const col of canvas) {
    col.reverse();
  }
  for (const col of canvas) {
    for (let y = 0;y < col.length; y++) {
      const flipped = VERTICAL_FLIP_MAP[col[y]];
      if (flipped)
        col[y] = flipped;
    }
  }
  return canvas;
}
function drawText(canvas, start, text) {
  increaseSize(canvas, start.x + text.length, start.y);
  for (let i = 0;i < text.length; i++) {
    canvas[start.x + i][start.y] = text[i];
  }
}
function setCanvasSizeToGrid(canvas, columnWidth, rowHeight) {
  let maxX = 0;
  let maxY = 0;
  for (const w of columnWidth.values())
    maxX += w;
  for (const h of rowHeight.values())
    maxY += h;
  increaseSize(canvas, maxX - 1, maxY - 1);
}
function convertToAsciiGraph(parsed, config) {
  const nodeMap = /* @__PURE__ */ new Map;
  let index = 0;
  for (const [id, mNode] of parsed.nodes) {
    const asciiNode = {
      name: id,
      displayLabel: mNode.label,
      index,
      gridCoord: null,
      drawingCoord: null,
      drawing: null,
      drawn: false,
      styleClassName: "",
      styleClass: EMPTY_STYLE
    };
    nodeMap.set(id, asciiNode);
    index++;
  }
  const nodes = [...nodeMap.values()];
  const edges = [];
  for (const mEdge of parsed.edges) {
    const from = nodeMap.get(mEdge.source);
    const to = nodeMap.get(mEdge.target);
    if (!from || !to)
      continue;
    edges.push({
      from,
      to,
      text: mEdge.label ?? "",
      path: [],
      labelLine: [],
      startDir: { x: 0, y: 0 },
      endDir: { x: 0, y: 0 }
    });
  }
  const subgraphs = [];
  for (const mSg of parsed.subgraphs) {
    convertSubgraph(mSg, null, nodeMap, subgraphs);
  }
  deduplicateSubgraphNodes(parsed.subgraphs, subgraphs, nodeMap);
  for (const [nodeId, className] of parsed.classAssignments) {
    const node = nodeMap.get(nodeId);
    const classDef = parsed.classDefs.get(className);
    if (node && classDef) {
      node.styleClassName = className;
      node.styleClass = { name: className, styles: classDef };
    }
  }
  return {
    nodes,
    edges,
    canvas: mkCanvas(0, 0),
    grid: /* @__PURE__ */ new Map,
    columnWidth: /* @__PURE__ */ new Map,
    rowHeight: /* @__PURE__ */ new Map,
    subgraphs,
    config,
    offsetX: 0,
    offsetY: 0
  };
}
function convertSubgraph(mSg, parent, nodeMap, allSubgraphs) {
  const sg = {
    name: mSg.label,
    nodes: [],
    parent,
    children: [],
    minX: 0,
    minY: 0,
    maxX: 0,
    maxY: 0
  };
  for (const nodeId of mSg.nodeIds) {
    const node = nodeMap.get(nodeId);
    if (node)
      sg.nodes.push(node);
  }
  allSubgraphs.push(sg);
  for (const childMSg of mSg.children) {
    const child = convertSubgraph(childMSg, sg, nodeMap, allSubgraphs);
    sg.children.push(child);
    for (const childNode of child.nodes) {
      if (!sg.nodes.includes(childNode)) {
        sg.nodes.push(childNode);
      }
    }
  }
  return sg;
}
function deduplicateSubgraphNodes(mermaidSubgraphs, asciiSubgraphs, nodeMap, parsed) {
  const sgMap = /* @__PURE__ */ new Map;
  buildSgMap(mermaidSubgraphs, asciiSubgraphs, sgMap);
  const nodeOwner = /* @__PURE__ */ new Map;
  function claimNodes(mSg) {
    const asciiSg = sgMap.get(mSg);
    if (!asciiSg)
      return;
    for (const child of mSg.children) {
      claimNodes(child);
    }
    for (const nodeId of mSg.nodeIds) {
      if (!nodeOwner.has(nodeId)) {
        nodeOwner.set(nodeId, asciiSg);
      }
    }
  }
  for (const mSg of mermaidSubgraphs) {
    claimNodes(mSg);
  }
  for (const asciiSg of asciiSubgraphs) {
    asciiSg.nodes = asciiSg.nodes.filter((node) => {
      let nodeId;
      for (const [id, n] of nodeMap) {
        if (n === node) {
          nodeId = id;
          break;
        }
      }
      if (!nodeId)
        return false;
      const owner = nodeOwner.get(nodeId);
      if (!owner)
        return true;
      return isAncestorOrSelf(asciiSg, owner);
    });
  }
}
function isAncestorOrSelf(candidate, target) {
  let current = target;
  while (current !== null) {
    if (current === candidate)
      return true;
    current = current.parent;
  }
  return false;
}
function buildSgMap(mSgs, aSgs, result) {
  const flatMermaid = [];
  function flatten(sgs) {
    for (const sg of sgs) {
      flatMermaid.push(sg);
      flatten(sg.children);
    }
  }
  flatten(mSgs);
  for (let i = 0;i < flatMermaid.length && i < aSgs.length; i++) {
    result.set(flatMermaid[i], aSgs[i]);
  }
}
var MinHeap = class {
  items = [];
  get length() {
    return this.items.length;
  }
  push(item) {
    this.items.push(item);
    this.bubbleUp(this.items.length - 1);
  }
  pop() {
    if (this.items.length === 0)
      return;
    const top = this.items[0];
    const last = this.items.pop();
    if (this.items.length > 0) {
      this.items[0] = last;
      this.sinkDown(0);
    }
    return top;
  }
  bubbleUp(i) {
    while (i > 0) {
      const parent = i - 1 >> 1;
      if (this.items[i].priority < this.items[parent].priority) {
        [this.items[i], this.items[parent]] = [this.items[parent], this.items[i]];
        i = parent;
      } else {
        break;
      }
    }
  }
  sinkDown(i) {
    const n = this.items.length;
    while (true) {
      let smallest = i;
      const left = 2 * i + 1;
      const right = 2 * i + 2;
      if (left < n && this.items[left].priority < this.items[smallest].priority) {
        smallest = left;
      }
      if (right < n && this.items[right].priority < this.items[smallest].priority) {
        smallest = right;
      }
      if (smallest !== i) {
        [this.items[i], this.items[smallest]] = [this.items[smallest], this.items[i]];
        i = smallest;
      } else {
        break;
      }
    }
  }
};
function heuristic(a, b) {
  const absX = Math.abs(a.x - b.x);
  const absY = Math.abs(a.y - b.y);
  if (absX === 0 || absY === 0) {
    return absX + absY;
  }
  return absX + absY + 1;
}
var MOVE_DIRS = [
  { x: 1, y: 0 },
  { x: -1, y: 0 },
  { x: 0, y: 1 },
  { x: 0, y: -1 }
];
function isFreeInGrid(grid, c) {
  if (c.x < 0 || c.y < 0)
    return false;
  return !grid.has(gridKey(c));
}
function getPath(grid, from, to) {
  const pq = new MinHeap;
  pq.push({ coord: from, priority: 0 });
  const costSoFar = /* @__PURE__ */ new Map;
  costSoFar.set(gridKey(from), 0);
  const cameFrom = /* @__PURE__ */ new Map;
  cameFrom.set(gridKey(from), null);
  while (pq.length > 0) {
    const current = pq.pop().coord;
    if (gridCoordEquals(current, to)) {
      const path = [];
      let c = current;
      while (c !== null) {
        path.unshift(c);
        c = cameFrom.get(gridKey(c)) ?? null;
      }
      return path;
    }
    const currentCost = costSoFar.get(gridKey(current));
    for (const dir of MOVE_DIRS) {
      const next = { x: current.x + dir.x, y: current.y + dir.y };
      if (!isFreeInGrid(grid, next) && !gridCoordEquals(next, to)) {
        continue;
      }
      const newCost = currentCost + 1;
      const nextKey = gridKey(next);
      const existingCost = costSoFar.get(nextKey);
      if (existingCost === undefined || newCost < existingCost) {
        costSoFar.set(nextKey, newCost);
        const priority = newCost + heuristic(next, to);
        pq.push({ coord: next, priority });
        cameFrom.set(nextKey, current);
      }
    }
  }
  return null;
}
function mergePath(path) {
  if (path.length <= 2)
    return path;
  const toRemove = /* @__PURE__ */ new Set;
  let step0 = path[0];
  let step1 = path[1];
  for (let idx = 2;idx < path.length; idx++) {
    const step2 = path[idx];
    const prevDx = step1.x - step0.x;
    const prevDy = step1.y - step0.y;
    const dx = step2.x - step1.x;
    const dy = step2.y - step1.y;
    if (prevDx === dx && prevDy === dy) {
      toRemove.add(idx - 1);
    }
    step0 = step1;
    step1 = step2;
  }
  return path.filter((_, i) => !toRemove.has(i));
}
function getOpposite(d) {
  if (d === Up)
    return Down;
  if (d === Down)
    return Up;
  if (d === Left)
    return Right;
  if (d === Right)
    return Left;
  if (d === UpperRight)
    return LowerLeft;
  if (d === UpperLeft)
    return LowerRight;
  if (d === LowerRight)
    return UpperLeft;
  if (d === LowerLeft)
    return UpperRight;
  return Middle;
}
function dirEquals(a, b) {
  return a.x === b.x && a.y === b.y;
}
function determineDirection(from, to) {
  if (from.x === to.x) {
    return from.y < to.y ? Down : Up;
  } else if (from.y === to.y) {
    return from.x < to.x ? Right : Left;
  } else if (from.x < to.x) {
    return from.y < to.y ? LowerRight : UpperRight;
  } else {
    return from.y < to.y ? LowerLeft : UpperLeft;
  }
}
function selfReferenceDirection(graphDirection) {
  if (graphDirection === "LR")
    return [Right, Down, Down, Right];
  return [Down, Right, Right, Down];
}
function determineStartAndEndDir(edge, graphDirection) {
  if (edge.from === edge.to)
    return selfReferenceDirection(graphDirection);
  const d = determineDirection(edge.from.gridCoord, edge.to.gridCoord);
  let preferredDir;
  let preferredOppositeDir;
  let alternativeDir;
  let alternativeOppositeDir;
  const isBackwards = graphDirection === "LR" ? dirEquals(d, Left) || dirEquals(d, UpperLeft) || dirEquals(d, LowerLeft) : dirEquals(d, Up) || dirEquals(d, UpperLeft) || dirEquals(d, UpperRight);
  if (dirEquals(d, LowerRight)) {
    if (graphDirection === "LR") {
      preferredDir = Down;
      preferredOppositeDir = Left;
      alternativeDir = Right;
      alternativeOppositeDir = Up;
    } else {
      preferredDir = Right;
      preferredOppositeDir = Up;
      alternativeDir = Down;
      alternativeOppositeDir = Left;
    }
  } else if (dirEquals(d, UpperRight)) {
    if (graphDirection === "LR") {
      preferredDir = Up;
      preferredOppositeDir = Left;
      alternativeDir = Right;
      alternativeOppositeDir = Down;
    } else {
      preferredDir = Right;
      preferredOppositeDir = Down;
      alternativeDir = Up;
      alternativeOppositeDir = Left;
    }
  } else if (dirEquals(d, LowerLeft)) {
    if (graphDirection === "LR") {
      preferredDir = Down;
      preferredOppositeDir = Down;
      alternativeDir = Left;
      alternativeOppositeDir = Up;
    } else {
      preferredDir = Left;
      preferredOppositeDir = Up;
      alternativeDir = Down;
      alternativeOppositeDir = Right;
    }
  } else if (dirEquals(d, UpperLeft)) {
    if (graphDirection === "LR") {
      preferredDir = Down;
      preferredOppositeDir = Down;
      alternativeDir = Left;
      alternativeOppositeDir = Down;
    } else {
      preferredDir = Right;
      preferredOppositeDir = Right;
      alternativeDir = Up;
      alternativeOppositeDir = Right;
    }
  } else if (isBackwards) {
    if (graphDirection === "LR" && dirEquals(d, Left)) {
      preferredDir = Down;
      preferredOppositeDir = Down;
      alternativeDir = Left;
      alternativeOppositeDir = Right;
    } else if (graphDirection === "TD" && dirEquals(d, Up)) {
      preferredDir = Right;
      preferredOppositeDir = Right;
      alternativeDir = Up;
      alternativeOppositeDir = Down;
    } else {
      preferredDir = d;
      preferredOppositeDir = getOpposite(d);
      alternativeDir = d;
      alternativeOppositeDir = getOpposite(d);
    }
  } else {
    preferredDir = d;
    preferredOppositeDir = getOpposite(d);
    alternativeDir = d;
    alternativeOppositeDir = getOpposite(d);
  }
  return [preferredDir, preferredOppositeDir, alternativeDir, alternativeOppositeDir];
}
function determinePath(graph, edge) {
  const [preferredDir, preferredOppositeDir, alternativeDir, alternativeOppositeDir] = determineStartAndEndDir(edge, graph.config.graphDirection);
  const prefFrom = gridCoordDirection(edge.from.gridCoord, preferredDir);
  const prefTo = gridCoordDirection(edge.to.gridCoord, preferredOppositeDir);
  let preferredPath = getPath(graph.grid, prefFrom, prefTo);
  if (preferredPath === null) {
    edge.startDir = alternativeDir;
    edge.endDir = alternativeOppositeDir;
    edge.path = [];
    return;
  }
  preferredPath = mergePath(preferredPath);
  const altFrom = gridCoordDirection(edge.from.gridCoord, alternativeDir);
  const altTo = gridCoordDirection(edge.to.gridCoord, alternativeOppositeDir);
  let alternativePath = getPath(graph.grid, altFrom, altTo);
  if (alternativePath === null) {
    edge.startDir = preferredDir;
    edge.endDir = preferredOppositeDir;
    edge.path = preferredPath;
    return;
  }
  alternativePath = mergePath(alternativePath);
  if (preferredPath.length <= alternativePath.length) {
    edge.startDir = preferredDir;
    edge.endDir = preferredOppositeDir;
    edge.path = preferredPath;
  } else {
    edge.startDir = alternativeDir;
    edge.endDir = alternativeOppositeDir;
    edge.path = alternativePath;
  }
}
function determineLabelLine(graph, edge) {
  if (edge.text.length === 0)
    return;
  const lenLabel = edge.text.length;
  let prevStep = edge.path[0];
  let largestLine = [prevStep, edge.path[1]];
  let largestLineSize = 0;
  for (let i = 1;i < edge.path.length; i++) {
    const step = edge.path[i];
    const line = [prevStep, step];
    const lineWidth = calculateLineWidth(graph, line);
    if (lineWidth >= lenLabel) {
      largestLine = line;
      break;
    } else if (lineWidth > largestLineSize) {
      largestLineSize = lineWidth;
      largestLine = line;
    }
    prevStep = step;
  }
  const minX = Math.min(largestLine[0].x, largestLine[1].x);
  const maxX = Math.max(largestLine[0].x, largestLine[1].x);
  const middleX = minX + Math.floor((maxX - minX) / 2);
  const current = graph.columnWidth.get(middleX) ?? 0;
  graph.columnWidth.set(middleX, Math.max(current, lenLabel + 2));
  edge.labelLine = [largestLine[0], largestLine[1]];
}
function calculateLineWidth(graph, line) {
  let total = 0;
  const startX = Math.min(line[0].x, line[1].x);
  const endX = Math.max(line[0].x, line[1].x);
  for (let x = startX;x <= endX; x++) {
    total += graph.columnWidth.get(x) ?? 0;
  }
  return total;
}
function drawBox(node, graph) {
  const gc = node.gridCoord;
  const useAscii = graph.config.useAscii;
  let w = 0;
  for (let i = 0;i < 2; i++) {
    w += graph.columnWidth.get(gc.x + i) ?? 0;
  }
  let h = 0;
  for (let i = 0;i < 2; i++) {
    h += graph.rowHeight.get(gc.y + i) ?? 0;
  }
  const from = { x: 0, y: 0 };
  const to = { x: w, y: h };
  const box = mkCanvas(Math.max(from.x, to.x), Math.max(from.y, to.y));
  if (!useAscii) {
    for (let x = from.x + 1;x < to.x; x++)
      box[x][from.y] = "─";
    for (let x = from.x + 1;x < to.x; x++)
      box[x][to.y] = "─";
    for (let y = from.y + 1;y < to.y; y++)
      box[from.x][y] = "│";
    for (let y = from.y + 1;y < to.y; y++)
      box[to.x][y] = "│";
    box[from.x][from.y] = "┌";
    box[to.x][from.y] = "┐";
    box[from.x][to.y] = "└";
    box[to.x][to.y] = "┘";
  } else {
    for (let x = from.x + 1;x < to.x; x++)
      box[x][from.y] = "-";
    for (let x = from.x + 1;x < to.x; x++)
      box[x][to.y] = "-";
    for (let y = from.y + 1;y < to.y; y++)
      box[from.x][y] = "|";
    for (let y = from.y + 1;y < to.y; y++)
      box[to.x][y] = "|";
    box[from.x][from.y] = "+";
    box[to.x][from.y] = "+";
    box[from.x][to.y] = "+";
    box[to.x][to.y] = "+";
  }
  const label = node.displayLabel;
  const textY = from.y + Math.floor(h / 2);
  const textX = from.x + Math.floor(w / 2) - Math.ceil(label.length / 2) + 1;
  for (let i = 0;i < label.length; i++) {
    box[textX + i][textY] = label[i];
  }
  return box;
}
function drawMultiBox(sections, useAscii, padding = 1) {
  let maxTextWidth = 0;
  for (const section of sections) {
    for (const line of section) {
      maxTextWidth = Math.max(maxTextWidth, line.length);
    }
  }
  const innerWidth = maxTextWidth + 2 * padding;
  const boxWidth = innerWidth + 2;
  let totalLines = 0;
  for (const section of sections) {
    totalLines += Math.max(section.length, 1);
  }
  const numDividers = sections.length - 1;
  const boxHeight = totalLines + numDividers + 2;
  const hLine = useAscii ? "-" : "─";
  const vLine = useAscii ? "|" : "│";
  const tl = useAscii ? "+" : "┌";
  const tr = useAscii ? "+" : "┐";
  const bl = useAscii ? "+" : "└";
  const br = useAscii ? "+" : "┘";
  const divL = useAscii ? "+" : "├";
  const divR = useAscii ? "+" : "┤";
  const canvas = mkCanvas(boxWidth - 1, boxHeight - 1);
  canvas[0][0] = tl;
  for (let x = 1;x < boxWidth - 1; x++)
    canvas[x][0] = hLine;
  canvas[boxWidth - 1][0] = tr;
  canvas[0][boxHeight - 1] = bl;
  for (let x = 1;x < boxWidth - 1; x++)
    canvas[x][boxHeight - 1] = hLine;
  canvas[boxWidth - 1][boxHeight - 1] = br;
  for (let y = 1;y < boxHeight - 1; y++) {
    canvas[0][y] = vLine;
    canvas[boxWidth - 1][y] = vLine;
  }
  let row = 1;
  for (let s = 0;s < sections.length; s++) {
    const section = sections[s];
    const lines = section.length > 0 ? section : [""];
    for (const line of lines) {
      const startX = 1 + padding;
      for (let i = 0;i < line.length; i++) {
        canvas[startX + i][row] = line[i];
      }
      row++;
    }
    if (s < sections.length - 1) {
      canvas[0][row] = divL;
      for (let x = 1;x < boxWidth - 1; x++)
        canvas[x][row] = hLine;
      canvas[boxWidth - 1][row] = divR;
      row++;
    }
  }
  return canvas;
}
function drawLine(canvas, from, to, offsetFrom, offsetTo, useAscii) {
  const dir = determineDirection(from, to);
  const drawnCoords = [];
  const hChar = useAscii ? "-" : "─";
  const vChar = useAscii ? "|" : "│";
  const bslash = useAscii ? "\\" : "╲";
  const fslash = useAscii ? "/" : "╱";
  if (dirEquals(dir, Up)) {
    for (let y = from.y - offsetFrom;y >= to.y - offsetTo; y--) {
      drawnCoords.push({ x: from.x, y });
      canvas[from.x][y] = vChar;
    }
  } else if (dirEquals(dir, Down)) {
    for (let y = from.y + offsetFrom;y <= to.y + offsetTo; y++) {
      drawnCoords.push({ x: from.x, y });
      canvas[from.x][y] = vChar;
    }
  } else if (dirEquals(dir, Left)) {
    for (let x = from.x - offsetFrom;x >= to.x - offsetTo; x--) {
      drawnCoords.push({ x, y: from.y });
      canvas[x][from.y] = hChar;
    }
  } else if (dirEquals(dir, Right)) {
    for (let x = from.x + offsetFrom;x <= to.x + offsetTo; x++) {
      drawnCoords.push({ x, y: from.y });
      canvas[x][from.y] = hChar;
    }
  } else if (dirEquals(dir, UpperLeft)) {
    for (let x = from.x, y = from.y - offsetFrom;x >= to.x - offsetTo && y >= to.y - offsetTo; x--, y--) {
      drawnCoords.push({ x, y });
      canvas[x][y] = bslash;
    }
  } else if (dirEquals(dir, UpperRight)) {
    for (let x = from.x, y = from.y - offsetFrom;x <= to.x + offsetTo && y >= to.y - offsetTo; x++, y--) {
      drawnCoords.push({ x, y });
      canvas[x][y] = fslash;
    }
  } else if (dirEquals(dir, LowerLeft)) {
    for (let x = from.x, y = from.y + offsetFrom;x >= to.x - offsetTo && y <= to.y + offsetTo; x--, y++) {
      drawnCoords.push({ x, y });
      canvas[x][y] = fslash;
    }
  } else if (dirEquals(dir, LowerRight)) {
    for (let x = from.x, y = from.y + offsetFrom;x <= to.x + offsetTo && y <= to.y + offsetTo; x++, y++) {
      drawnCoords.push({ x, y });
      canvas[x][y] = bslash;
    }
  }
  return drawnCoords;
}
function drawArrow(graph, edge) {
  if (edge.path.length === 0) {
    const empty = copyCanvas(graph.canvas);
    return [empty, empty, empty, empty, empty];
  }
  const labelCanvas = drawArrowLabel(graph, edge);
  const [pathCanvas, linesDrawn, lineDirs] = drawPath(graph, edge.path);
  const boxStartCanvas = drawBoxStart(graph, edge.path, linesDrawn[0]);
  const arrowHeadCanvas = drawArrowHead(graph, linesDrawn[linesDrawn.length - 1], lineDirs[lineDirs.length - 1]);
  const cornersCanvas = drawCorners(graph, edge.path);
  return [pathCanvas, boxStartCanvas, arrowHeadCanvas, cornersCanvas, labelCanvas];
}
function drawPath(graph, path) {
  const canvas = copyCanvas(graph.canvas);
  let previousCoord = path[0];
  const linesDrawn = [];
  const lineDirs = [];
  for (let i = 1;i < path.length; i++) {
    const nextCoord = path[i];
    const prevDC = gridToDrawingCoord(graph, previousCoord);
    const nextDC = gridToDrawingCoord(graph, nextCoord);
    if (drawingCoordEquals(prevDC, nextDC)) {
      previousCoord = nextCoord;
      continue;
    }
    const dir = determineDirection(previousCoord, nextCoord);
    const segment = drawLine(canvas, prevDC, nextDC, 1, -1, graph.config.useAscii);
    if (segment.length === 0)
      segment.push(prevDC);
    linesDrawn.push(segment);
    lineDirs.push(dir);
    previousCoord = nextCoord;
  }
  return [canvas, linesDrawn, lineDirs];
}
function drawBoxStart(graph, path, firstLine) {
  const canvas = copyCanvas(graph.canvas);
  if (graph.config.useAscii)
    return canvas;
  const from = firstLine[0];
  const dir = determineDirection(path[0], path[1]);
  if (dirEquals(dir, Up))
    canvas[from.x][from.y + 1] = "┴";
  else if (dirEquals(dir, Down))
    canvas[from.x][from.y - 1] = "┬";
  else if (dirEquals(dir, Left))
    canvas[from.x + 1][from.y] = "┤";
  else if (dirEquals(dir, Right))
    canvas[from.x - 1][from.y] = "├";
  return canvas;
}
function drawArrowHead(graph, lastLine, fallbackDir) {
  const canvas = copyCanvas(graph.canvas);
  if (lastLine.length === 0)
    return canvas;
  const from = lastLine[0];
  const lastPos = lastLine[lastLine.length - 1];
  let dir = determineDirection(from, lastPos);
  if (lastLine.length === 1 || dirEquals(dir, Middle))
    dir = fallbackDir;
  let char;
  if (!graph.config.useAscii) {
    if (dirEquals(dir, Up))
      char = "▲";
    else if (dirEquals(dir, Down))
      char = "▼";
    else if (dirEquals(dir, Left))
      char = "◄";
    else if (dirEquals(dir, Right))
      char = "►";
    else if (dirEquals(dir, UpperRight))
      char = "◥";
    else if (dirEquals(dir, UpperLeft))
      char = "◤";
    else if (dirEquals(dir, LowerRight))
      char = "◢";
    else if (dirEquals(dir, LowerLeft))
      char = "◣";
    else {
      if (dirEquals(fallbackDir, Up))
        char = "▲";
      else if (dirEquals(fallbackDir, Down))
        char = "▼";
      else if (dirEquals(fallbackDir, Left))
        char = "◄";
      else if (dirEquals(fallbackDir, Right))
        char = "►";
      else if (dirEquals(fallbackDir, UpperRight))
        char = "◥";
      else if (dirEquals(fallbackDir, UpperLeft))
        char = "◤";
      else if (dirEquals(fallbackDir, LowerRight))
        char = "◢";
      else if (dirEquals(fallbackDir, LowerLeft))
        char = "◣";
      else
        char = "●";
    }
  } else {
    if (dirEquals(dir, Up))
      char = "^";
    else if (dirEquals(dir, Down))
      char = "v";
    else if (dirEquals(dir, Left))
      char = "<";
    else if (dirEquals(dir, Right))
      char = ">";
    else {
      if (dirEquals(fallbackDir, Up))
        char = "^";
      else if (dirEquals(fallbackDir, Down))
        char = "v";
      else if (dirEquals(fallbackDir, Left))
        char = "<";
      else if (dirEquals(fallbackDir, Right))
        char = ">";
      else
        char = "*";
    }
  }
  canvas[lastPos.x][lastPos.y] = char;
  return canvas;
}
function drawCorners(graph, path) {
  const canvas = copyCanvas(graph.canvas);
  for (let idx = 1;idx < path.length - 1; idx++) {
    const coord = path[idx];
    const dc = gridToDrawingCoord(graph, coord);
    const prevDir = determineDirection(path[idx - 1], coord);
    const nextDir = determineDirection(coord, path[idx + 1]);
    let corner;
    if (!graph.config.useAscii) {
      if (dirEquals(prevDir, Right) && dirEquals(nextDir, Down) || dirEquals(prevDir, Up) && dirEquals(nextDir, Left)) {
        corner = "┐";
      } else if (dirEquals(prevDir, Right) && dirEquals(nextDir, Up) || dirEquals(prevDir, Down) && dirEquals(nextDir, Left)) {
        corner = "┘";
      } else if (dirEquals(prevDir, Left) && dirEquals(nextDir, Down) || dirEquals(prevDir, Up) && dirEquals(nextDir, Right)) {
        corner = "┌";
      } else if (dirEquals(prevDir, Left) && dirEquals(nextDir, Up) || dirEquals(prevDir, Down) && dirEquals(nextDir, Right)) {
        corner = "└";
      } else {
        corner = "+";
      }
    } else {
      corner = "+";
    }
    canvas[dc.x][dc.y] = corner;
  }
  return canvas;
}
function drawArrowLabel(graph, edge) {
  const canvas = copyCanvas(graph.canvas);
  if (edge.text.length === 0)
    return canvas;
  const drawingLine = lineToDrawing(graph, edge.labelLine);
  drawTextOnLine(canvas, drawingLine, edge.text);
  return canvas;
}
function drawTextOnLine(canvas, line, label) {
  if (line.length < 2)
    return;
  const minX = Math.min(line[0].x, line[1].x);
  const maxX = Math.max(line[0].x, line[1].x);
  const minY = Math.min(line[0].y, line[1].y);
  const maxY = Math.max(line[0].y, line[1].y);
  const middleX = minX + Math.floor((maxX - minX) / 2);
  const middleY = minY + Math.floor((maxY - minY) / 2);
  const startX = middleX - Math.floor(label.length / 2);
  drawText(canvas, { x: startX, y: middleY }, label);
}
function drawSubgraphBox(sg, graph) {
  const width = sg.maxX - sg.minX;
  const height = sg.maxY - sg.minY;
  if (width <= 0 || height <= 0)
    return mkCanvas(0, 0);
  const from = { x: 0, y: 0 };
  const to = { x: width, y: height };
  const canvas = mkCanvas(width, height);
  if (!graph.config.useAscii) {
    for (let x = from.x + 1;x < to.x; x++)
      canvas[x][from.y] = "─";
    for (let x = from.x + 1;x < to.x; x++)
      canvas[x][to.y] = "─";
    for (let y = from.y + 1;y < to.y; y++)
      canvas[from.x][y] = "│";
    for (let y = from.y + 1;y < to.y; y++)
      canvas[to.x][y] = "│";
    canvas[from.x][from.y] = "┌";
    canvas[to.x][from.y] = "┐";
    canvas[from.x][to.y] = "└";
    canvas[to.x][to.y] = "┘";
  } else {
    for (let x = from.x + 1;x < to.x; x++)
      canvas[x][from.y] = "-";
    for (let x = from.x + 1;x < to.x; x++)
      canvas[x][to.y] = "-";
    for (let y = from.y + 1;y < to.y; y++)
      canvas[from.x][y] = "|";
    for (let y = from.y + 1;y < to.y; y++)
      canvas[to.x][y] = "|";
    canvas[from.x][from.y] = "+";
    canvas[to.x][from.y] = "+";
    canvas[from.x][to.y] = "+";
    canvas[to.x][to.y] = "+";
  }
  return canvas;
}
function drawSubgraphLabel(sg, graph) {
  const width = sg.maxX - sg.minX;
  const height = sg.maxY - sg.minY;
  if (width <= 0 || height <= 0)
    return [mkCanvas(0, 0), { x: 0, y: 0 }];
  const canvas = mkCanvas(width, height);
  const labelY = 1;
  let labelX = Math.floor(width / 2) - Math.floor(sg.name.length / 2);
  if (labelX < 1)
    labelX = 1;
  for (let i = 0;i < sg.name.length; i++) {
    if (labelX + i < width) {
      canvas[labelX + i][labelY] = sg.name[i];
    }
  }
  return [canvas, { x: sg.minX, y: sg.minY }];
}
function sortSubgraphsByDepth(subgraphs) {
  function getDepth(sg) {
    return sg.parent === null ? 0 : 1 + getDepth(sg.parent);
  }
  const sorted = [...subgraphs];
  sorted.sort((a, b) => getDepth(a) - getDepth(b));
  return sorted;
}
function drawGraph(graph) {
  const useAscii = graph.config.useAscii;
  const sortedSgs = sortSubgraphsByDepth(graph.subgraphs);
  for (const sg of sortedSgs) {
    const sgCanvas = drawSubgraphBox(sg, graph);
    const offset = { x: sg.minX, y: sg.minY };
    graph.canvas = mergeCanvases(graph.canvas, offset, useAscii, sgCanvas);
  }
  for (const node of graph.nodes) {
    if (!node.drawn && node.drawingCoord && node.drawing) {
      graph.canvas = mergeCanvases(graph.canvas, node.drawingCoord, useAscii, node.drawing);
      node.drawn = true;
    }
  }
  const lineCanvases = [];
  const cornerCanvases = [];
  const arrowHeadCanvases = [];
  const boxStartCanvases = [];
  const labelCanvases = [];
  for (const edge of graph.edges) {
    const [pathC, boxStartC, arrowHeadC, cornersC, labelC] = drawArrow(graph, edge);
    lineCanvases.push(pathC);
    cornerCanvases.push(cornersC);
    arrowHeadCanvases.push(arrowHeadC);
    boxStartCanvases.push(boxStartC);
    labelCanvases.push(labelC);
  }
  const zero = { x: 0, y: 0 };
  graph.canvas = mergeCanvases(graph.canvas, zero, useAscii, ...lineCanvases);
  graph.canvas = mergeCanvases(graph.canvas, zero, useAscii, ...cornerCanvases);
  graph.canvas = mergeCanvases(graph.canvas, zero, useAscii, ...arrowHeadCanvases);
  graph.canvas = mergeCanvases(graph.canvas, zero, useAscii, ...boxStartCanvases);
  graph.canvas = mergeCanvases(graph.canvas, zero, useAscii, ...labelCanvases);
  for (const sg of graph.subgraphs) {
    if (sg.nodes.length === 0)
      continue;
    const [labelCanvas, offset] = drawSubgraphLabel(sg);
    graph.canvas = mergeCanvases(graph.canvas, offset, useAscii, labelCanvas);
  }
  return graph.canvas;
}
function gridToDrawingCoord(graph, c, dir) {
  const target = c;
  let x = 0;
  for (let col = 0;col < target.x; col++) {
    x += graph.columnWidth.get(col) ?? 0;
  }
  let y = 0;
  for (let row = 0;row < target.y; row++) {
    y += graph.rowHeight.get(row) ?? 0;
  }
  const colW = graph.columnWidth.get(target.x) ?? 0;
  const rowH = graph.rowHeight.get(target.y) ?? 0;
  return {
    x: x + Math.floor(colW / 2) + graph.offsetX,
    y: y + Math.floor(rowH / 2) + graph.offsetY
  };
}
function lineToDrawing(graph, line) {
  return line.map((c) => gridToDrawingCoord(graph, c));
}
function reserveSpotInGrid(graph, node, requested) {
  if (graph.grid.has(gridKey(requested))) {
    if (graph.config.graphDirection === "LR") {
      return reserveSpotInGrid(graph, node, { x: requested.x, y: requested.y + 4 });
    } else {
      return reserveSpotInGrid(graph, node, { x: requested.x + 4, y: requested.y });
    }
  }
  for (let dx = 0;dx < 3; dx++) {
    for (let dy = 0;dy < 3; dy++) {
      const reserved = { x: requested.x + dx, y: requested.y + dy };
      graph.grid.set(gridKey(reserved), node);
    }
  }
  node.gridCoord = requested;
  return requested;
}
function setColumnWidth(graph, node) {
  const gc = node.gridCoord;
  const padding = graph.config.boxBorderPadding;
  const colWidths = [1, 2 * padding + node.displayLabel.length, 1];
  const rowHeights = [1, 1 + 2 * padding, 1];
  for (let idx = 0;idx < colWidths.length; idx++) {
    const xCoord = gc.x + idx;
    const current = graph.columnWidth.get(xCoord) ?? 0;
    graph.columnWidth.set(xCoord, Math.max(current, colWidths[idx]));
  }
  for (let idx = 0;idx < rowHeights.length; idx++) {
    const yCoord = gc.y + idx;
    const current = graph.rowHeight.get(yCoord) ?? 0;
    graph.rowHeight.set(yCoord, Math.max(current, rowHeights[idx]));
  }
  if (gc.x > 0) {
    const current = graph.columnWidth.get(gc.x - 1) ?? 0;
    graph.columnWidth.set(gc.x - 1, Math.max(current, graph.config.paddingX));
  }
  if (gc.y > 0) {
    let basePadding = graph.config.paddingY;
    if (hasIncomingEdgeFromOutsideSubgraph(graph, node)) {
      const subgraphOverhead = 4;
      basePadding += subgraphOverhead;
    }
    const current = graph.rowHeight.get(gc.y - 1) ?? 0;
    graph.rowHeight.set(gc.y - 1, Math.max(current, basePadding));
  }
}
function increaseGridSizeForPath(graph, path) {
  for (const c of path) {
    if (!graph.columnWidth.has(c.x)) {
      graph.columnWidth.set(c.x, Math.floor(graph.config.paddingX / 2));
    }
    if (!graph.rowHeight.has(c.y)) {
      graph.rowHeight.set(c.y, Math.floor(graph.config.paddingY / 2));
    }
  }
}
function isNodeInAnySubgraph(graph, node) {
  return graph.subgraphs.some((sg) => sg.nodes.includes(node));
}
function getNodeSubgraph(graph, node) {
  for (const sg of graph.subgraphs) {
    if (sg.nodes.includes(node))
      return sg;
  }
  return null;
}
function hasIncomingEdgeFromOutsideSubgraph(graph, node) {
  const nodeSg = getNodeSubgraph(graph, node);
  if (!nodeSg)
    return false;
  let hasExternalEdge = false;
  for (const edge of graph.edges) {
    if (edge.to === node) {
      const sourceSg = getNodeSubgraph(graph, edge.from);
      if (sourceSg !== nodeSg) {
        hasExternalEdge = true;
        break;
      }
    }
  }
  if (!hasExternalEdge)
    return false;
  for (const otherNode of nodeSg.nodes) {
    if (otherNode === node || !otherNode.gridCoord)
      continue;
    let otherHasExternal = false;
    for (const edge of graph.edges) {
      if (edge.to === otherNode) {
        const sourceSg = getNodeSubgraph(graph, edge.from);
        if (sourceSg !== nodeSg) {
          otherHasExternal = true;
          break;
        }
      }
    }
    if (otherHasExternal && otherNode.gridCoord.y < node.gridCoord.y) {
      return false;
    }
  }
  return true;
}
function calculateSubgraphBoundingBox(graph, sg) {
  if (sg.nodes.length === 0)
    return;
  let minX = 1e6;
  let minY = 1e6;
  let maxX = -1e6;
  let maxY = -1e6;
  for (const child of sg.children) {
    calculateSubgraphBoundingBox(graph, child);
    if (child.nodes.length > 0) {
      minX = Math.min(minX, child.minX);
      minY = Math.min(minY, child.minY);
      maxX = Math.max(maxX, child.maxX);
      maxY = Math.max(maxY, child.maxY);
    }
  }
  for (const node of sg.nodes) {
    if (!node.drawingCoord || !node.drawing)
      continue;
    const nodeMinX = node.drawingCoord.x;
    const nodeMinY = node.drawingCoord.y;
    const nodeMaxX = nodeMinX + node.drawing.length - 1;
    const nodeMaxY = nodeMinY + node.drawing[0].length - 1;
    minX = Math.min(minX, nodeMinX);
    minY = Math.min(minY, nodeMinY);
    maxX = Math.max(maxX, nodeMaxX);
    maxY = Math.max(maxY, nodeMaxY);
  }
  const subgraphPadding = 2;
  const subgraphLabelSpace = 2;
  sg.minX = minX - subgraphPadding;
  sg.minY = minY - subgraphPadding - subgraphLabelSpace;
  sg.maxX = maxX + subgraphPadding;
  sg.maxY = maxY + subgraphPadding;
}
function ensureSubgraphSpacing(graph) {
  const minSpacing = 1;
  const rootSubgraphs = graph.subgraphs.filter((sg) => sg.parent === null && sg.nodes.length > 0);
  for (let i = 0;i < rootSubgraphs.length; i++) {
    for (let j = i + 1;j < rootSubgraphs.length; j++) {
      const sg1 = rootSubgraphs[i];
      const sg2 = rootSubgraphs[j];
      if (sg1.minX < sg2.maxX && sg1.maxX > sg2.minX) {
        if (sg1.maxY >= sg2.minY - minSpacing && sg1.minY < sg2.minY) {
          sg2.minY = sg1.maxY + minSpacing + 1;
        } else if (sg2.maxY >= sg1.minY - minSpacing && sg2.minY < sg1.minY) {
          sg1.minY = sg2.maxY + minSpacing + 1;
        }
      }
      if (sg1.minY < sg2.maxY && sg1.maxY > sg2.minY) {
        if (sg1.maxX >= sg2.minX - minSpacing && sg1.minX < sg2.minX) {
          sg2.minX = sg1.maxX + minSpacing + 1;
        } else if (sg2.maxX >= sg1.minX - minSpacing && sg2.minX < sg1.minX) {
          sg1.minX = sg2.maxX + minSpacing + 1;
        }
      }
    }
  }
}
function calculateSubgraphBoundingBoxes(graph) {
  for (const sg of graph.subgraphs) {
    calculateSubgraphBoundingBox(graph, sg);
  }
  ensureSubgraphSpacing(graph);
}
function offsetDrawingForSubgraphs(graph) {
  if (graph.subgraphs.length === 0)
    return;
  let minX = 0;
  let minY = 0;
  for (const sg of graph.subgraphs) {
    minX = Math.min(minX, sg.minX);
    minY = Math.min(minY, sg.minY);
  }
  const offsetX = -minX;
  const offsetY = -minY;
  if (offsetX === 0 && offsetY === 0)
    return;
  graph.offsetX = offsetX;
  graph.offsetY = offsetY;
  for (const sg of graph.subgraphs) {
    sg.minX += offsetX;
    sg.minY += offsetY;
    sg.maxX += offsetX;
    sg.maxY += offsetY;
  }
  for (const node of graph.nodes) {
    if (node.drawingCoord) {
      node.drawingCoord.x += offsetX;
      node.drawingCoord.y += offsetY;
    }
  }
}
function createMapping(graph) {
  const dir = graph.config.graphDirection;
  const highestPositionPerLevel = new Array(100).fill(0);
  const nodesFound = /* @__PURE__ */ new Set;
  const rootNodes = [];
  for (const node of graph.nodes) {
    if (!nodesFound.has(node.name)) {
      rootNodes.push(node);
    }
    nodesFound.add(node.name);
    for (const child of getChildren(graph, node)) {
      nodesFound.add(child.name);
    }
  }
  let hasExternalRoots = false;
  let hasSubgraphRootsWithEdges = false;
  for (const node of rootNodes) {
    if (isNodeInAnySubgraph(graph, node)) {
      if (getChildren(graph, node).length > 0)
        hasSubgraphRootsWithEdges = true;
    } else {
      hasExternalRoots = true;
    }
  }
  const shouldSeparate = dir === "LR" && hasExternalRoots && hasSubgraphRootsWithEdges;
  let externalRootNodes;
  let subgraphRootNodes = [];
  if (shouldSeparate) {
    externalRootNodes = rootNodes.filter((n) => !isNodeInAnySubgraph(graph, n));
    subgraphRootNodes = rootNodes.filter((n) => isNodeInAnySubgraph(graph, n));
  } else {
    externalRootNodes = rootNodes;
  }
  for (const node of externalRootNodes) {
    const requested = dir === "LR" ? { x: 0, y: highestPositionPerLevel[0] } : { x: highestPositionPerLevel[0], y: 0 };
    reserveSpotInGrid(graph, graph.nodes[node.index], requested);
    highestPositionPerLevel[0] = highestPositionPerLevel[0] + 4;
  }
  if (shouldSeparate && subgraphRootNodes.length > 0) {
    const subgraphLevel = 4;
    for (const node of subgraphRootNodes) {
      const requested = dir === "LR" ? { x: subgraphLevel, y: highestPositionPerLevel[subgraphLevel] } : { x: highestPositionPerLevel[subgraphLevel], y: subgraphLevel };
      reserveSpotInGrid(graph, graph.nodes[node.index], requested);
      highestPositionPerLevel[subgraphLevel] = highestPositionPerLevel[subgraphLevel] + 4;
    }
  }
  for (const node of graph.nodes) {
    const gc = node.gridCoord;
    const childLevel = dir === "LR" ? gc.x + 4 : gc.y + 4;
    let highestPosition = highestPositionPerLevel[childLevel];
    for (const child of getChildren(graph, node)) {
      if (child.gridCoord !== null)
        continue;
      const requested = dir === "LR" ? { x: childLevel, y: highestPosition } : { x: highestPosition, y: childLevel };
      reserveSpotInGrid(graph, graph.nodes[child.index], requested);
      highestPositionPerLevel[childLevel] = highestPosition + 4;
      highestPosition = highestPositionPerLevel[childLevel];
    }
  }
  for (const node of graph.nodes) {
    setColumnWidth(graph, node);
  }
  for (const edge of graph.edges) {
    determinePath(graph, edge);
    increaseGridSizeForPath(graph, edge.path);
    determineLabelLine(graph, edge);
  }
  for (const node of graph.nodes) {
    node.drawingCoord = gridToDrawingCoord(graph, node.gridCoord);
    node.drawing = drawBox(node, graph);
  }
  setCanvasSizeToGrid(graph.canvas, graph.columnWidth, graph.rowHeight);
  calculateSubgraphBoundingBoxes(graph);
  offsetDrawingForSubgraphs(graph);
}
function getEdgesFromNode(graph, node) {
  return graph.edges.filter((e) => e.from.name === node.name);
}
function getChildren(graph, node) {
  return getEdgesFromNode(graph, node).map((e) => e.to);
}
function parseSequenceDiagram(lines) {
  const diagram = {
    actors: [],
    messages: [],
    blocks: [],
    notes: []
  };
  const actorIds = /* @__PURE__ */ new Set;
  const blockStack = [];
  for (let i = 1;i < lines.length; i++) {
    const line = lines[i];
    const actorMatch = line.match(/^(participant|actor)\s+(\S+?)(?:\s+as\s+(.+))?$/);
    if (actorMatch) {
      const type = actorMatch[1];
      const id = actorMatch[2];
      const label = actorMatch[3]?.trim() ?? id;
      if (!actorIds.has(id)) {
        actorIds.add(id);
        diagram.actors.push({ id, label, type });
      }
      continue;
    }
    const noteMatch = line.match(/^Note\s+(left of|right of|over)\s+([^:]+):\s*(.+)$/i);
    if (noteMatch) {
      const posStr = noteMatch[1].toLowerCase();
      const actorsStr = noteMatch[2].trim();
      const text = noteMatch[3].trim();
      const noteActorIds = actorsStr.split(",").map((s) => s.trim());
      for (const aid of noteActorIds) {
        ensureActor(diagram, actorIds, aid);
      }
      let position = "over";
      if (posStr === "left of")
        position = "left";
      else if (posStr === "right of")
        position = "right";
      diagram.notes.push({
        actorIds: noteActorIds,
        text,
        position,
        afterIndex: diagram.messages.length - 1
      });
      continue;
    }
    const blockMatch = line.match(/^(loop|alt|opt|par|critical|break|rect)\s*(.*)$/);
    if (blockMatch) {
      const blockType = blockMatch[1];
      const label = blockMatch[2]?.trim() ?? "";
      blockStack.push({
        type: blockType,
        label,
        startIndex: diagram.messages.length,
        dividers: []
      });
      continue;
    }
    const dividerMatch = line.match(/^(else|and)\s*(.*)$/);
    if (dividerMatch && blockStack.length > 0) {
      const label = dividerMatch[2]?.trim() ?? "";
      blockStack[blockStack.length - 1].dividers.push({
        index: diagram.messages.length,
        label
      });
      continue;
    }
    if (line === "end" && blockStack.length > 0) {
      const completed = blockStack.pop();
      diagram.blocks.push({
        type: completed.type,
        label: completed.label,
        startIndex: completed.startIndex,
        endIndex: Math.max(diagram.messages.length - 1, completed.startIndex),
        dividers: completed.dividers
      });
      continue;
    }
    const msgMatch = line.match(/^(\S+?)\s*(--?>?>|--?[)x]|--?>>|--?>)\s*([+-]?)(\S+?)\s*:\s*(.+)$/);
    if (msgMatch) {
      const from = msgMatch[1];
      const arrow = msgMatch[2];
      const activationMark = msgMatch[3];
      const to = msgMatch[4];
      const label = msgMatch[5].trim();
      ensureActor(diagram, actorIds, from);
      ensureActor(diagram, actorIds, to);
      const lineStyle = arrow.startsWith("--") ? "dashed" : "solid";
      const arrowHead = arrow.includes(">>") || arrow.includes("x") ? "filled" : "open";
      const msg = {
        from,
        to,
        label,
        lineStyle,
        arrowHead
      };
      if (activationMark === "+")
        msg.activate = true;
      if (activationMark === "-")
        msg.deactivate = true;
      diagram.messages.push(msg);
      continue;
    }
    const simpleMsgMatch = line.match(/^(\S+?)\s*(->>|-->>|-\)|--\)|-x|--x|->|-->)\s*([+-]?)(\S+?)\s*:\s*(.+)$/);
    if (simpleMsgMatch) {
      const from = simpleMsgMatch[1];
      const arrow = simpleMsgMatch[2];
      const activationMark = simpleMsgMatch[3];
      const to = simpleMsgMatch[4];
      const label = simpleMsgMatch[5].trim();
      ensureActor(diagram, actorIds, from);
      ensureActor(diagram, actorIds, to);
      const lineStyle = arrow.startsWith("--") ? "dashed" : "solid";
      const arrowHead = arrow.includes(">>") || arrow.includes("x") ? "filled" : "open";
      const msg = { from, to, label, lineStyle, arrowHead };
      if (activationMark === "+")
        msg.activate = true;
      if (activationMark === "-")
        msg.deactivate = true;
      diagram.messages.push(msg);
      continue;
    }
  }
  return diagram;
}
function ensureActor(diagram, actorIds, id) {
  if (!actorIds.has(id)) {
    actorIds.add(id);
    diagram.actors.push({ id, label: id, type: "participant" });
  }
}
function renderSequenceAscii(text, config) {
  const lines = text.split(`
`).map((l) => l.trim()).filter((l) => l.length > 0 && !l.startsWith("%%"));
  const diagram = parseSequenceDiagram(lines);
  if (diagram.actors.length === 0)
    return "";
  const useAscii = config.useAscii;
  const H = useAscii ? "-" : "─";
  const V = useAscii ? "|" : "│";
  const TL = useAscii ? "+" : "┌";
  const TR = useAscii ? "+" : "┐";
  const BL = useAscii ? "+" : "└";
  const BR = useAscii ? "+" : "┘";
  const JT = useAscii ? "+" : "┬";
  const JB = useAscii ? "+" : "┴";
  const JL = useAscii ? "+" : "├";
  const JR = useAscii ? "+" : "┤";
  const actorIdx = /* @__PURE__ */ new Map;
  diagram.actors.forEach((a, i) => actorIdx.set(a.id, i));
  const boxPad = 1;
  const actorBoxWidths = diagram.actors.map((a) => a.label.length + 2 * boxPad + 2);
  const halfBox = actorBoxWidths.map((w) => Math.ceil(w / 2));
  const actorBoxH = 3;
  const adjMaxWidth = new Array(Math.max(diagram.actors.length - 1, 0)).fill(0);
  for (const msg of diagram.messages) {
    const fi = actorIdx.get(msg.from);
    const ti = actorIdx.get(msg.to);
    if (fi === ti)
      continue;
    const lo = Math.min(fi, ti);
    const hi = Math.max(fi, ti);
    const needed = msg.label.length + 4;
    const numGaps = hi - lo;
    const perGap = Math.ceil(needed / numGaps);
    for (let g = lo;g < hi; g++) {
      adjMaxWidth[g] = Math.max(adjMaxWidth[g], perGap);
    }
  }
  const llX = [halfBox[0]];
  for (let i = 1;i < diagram.actors.length; i++) {
    const gap = Math.max(halfBox[i - 1] + halfBox[i] + 2, adjMaxWidth[i - 1] + 2, 10);
    llX[i] = llX[i - 1] + gap;
  }
  const msgArrowY = [];
  const msgLabelY = [];
  const blockStartY = /* @__PURE__ */ new Map;
  const blockEndY = /* @__PURE__ */ new Map;
  const divYMap = /* @__PURE__ */ new Map;
  const notePositions = [];
  let curY = actorBoxH;
  for (let m = 0;m < diagram.messages.length; m++) {
    for (let b = 0;b < diagram.blocks.length; b++) {
      if (diagram.blocks[b].startIndex === m) {
        curY += 2;
        blockStartY.set(b, curY - 1);
      }
    }
    for (let b = 0;b < diagram.blocks.length; b++) {
      for (let d = 0;d < diagram.blocks[b].dividers.length; d++) {
        if (diagram.blocks[b].dividers[d].index === m) {
          curY += 1;
          divYMap.set(`${b}:${d}`, curY);
          curY += 1;
        }
      }
    }
    curY += 1;
    const msg = diagram.messages[m];
    const isSelf = msg.from === msg.to;
    if (isSelf) {
      msgLabelY[m] = curY + 1;
      msgArrowY[m] = curY;
      curY += 3;
    } else {
      msgLabelY[m] = curY;
      msgArrowY[m] = curY + 1;
      curY += 2;
    }
    for (let n = 0;n < diagram.notes.length; n++) {
      if (diagram.notes[n].afterIndex === m) {
        curY += 1;
        const note = diagram.notes[n];
        const nLines = note.text.split("\\n");
        const nWidth = Math.max(...nLines.map((l) => l.length)) + 4;
        const nHeight = nLines.length + 2;
        const aIdx = actorIdx.get(note.actorIds[0]) ?? 0;
        let nx;
        if (note.position === "left") {
          nx = llX[aIdx] - nWidth - 1;
        } else if (note.position === "right") {
          nx = llX[aIdx] + 2;
        } else {
          if (note.actorIds.length >= 2) {
            const aIdx2 = actorIdx.get(note.actorIds[1]) ?? aIdx;
            nx = Math.floor((llX[aIdx] + llX[aIdx2]) / 2) - Math.floor(nWidth / 2);
          } else {
            nx = llX[aIdx] - Math.floor(nWidth / 2);
          }
        }
        nx = Math.max(0, nx);
        notePositions.push({ x: nx, y: curY, width: nWidth, height: nHeight, lines: nLines });
        curY += nHeight;
      }
    }
    for (let b = 0;b < diagram.blocks.length; b++) {
      if (diagram.blocks[b].endIndex === m) {
        curY += 1;
        blockEndY.set(b, curY);
        curY += 1;
      }
    }
  }
  curY += 1;
  const footerY = curY;
  const totalH = footerY + actorBoxH;
  const lastLL = llX[llX.length - 1] ?? 0;
  const lastHalf = halfBox[halfBox.length - 1] ?? 0;
  let totalW = lastLL + lastHalf + 2;
  for (let m = 0;m < diagram.messages.length; m++) {
    const msg = diagram.messages[m];
    if (msg.from === msg.to) {
      const fi = actorIdx.get(msg.from);
      const selfRight = llX[fi] + 6 + 2 + msg.label.length;
      totalW = Math.max(totalW, selfRight + 1);
    }
  }
  for (const np of notePositions) {
    totalW = Math.max(totalW, np.x + np.width + 1);
  }
  const canvas = mkCanvas(totalW, totalH - 1);
  function drawActorBox(cx, topY, label) {
    const w = label.length + 2 * boxPad + 2;
    const left = cx - Math.floor(w / 2);
    canvas[left][topY] = TL;
    for (let x = 1;x < w - 1; x++)
      canvas[left + x][topY] = H;
    canvas[left + w - 1][topY] = TR;
    canvas[left][topY + 1] = V;
    canvas[left + w - 1][topY + 1] = V;
    const ls = left + 1 + boxPad;
    for (let i = 0;i < label.length; i++)
      canvas[ls + i][topY + 1] = label[i];
    canvas[left][topY + 2] = BL;
    for (let x = 1;x < w - 1; x++)
      canvas[left + x][topY + 2] = H;
    canvas[left + w - 1][topY + 2] = BR;
  }
  for (let i = 0;i < diagram.actors.length; i++) {
    const x = llX[i];
    for (let y = actorBoxH;y <= footerY; y++) {
      canvas[x][y] = V;
    }
  }
  for (let i = 0;i < diagram.actors.length; i++) {
    const actor = diagram.actors[i];
    drawActorBox(llX[i], 0, actor.label);
    drawActorBox(llX[i], footerY, actor.label);
    if (!useAscii) {
      canvas[llX[i]][actorBoxH - 1] = JT;
      canvas[llX[i]][footerY] = JB;
    }
  }
  for (let m = 0;m < diagram.messages.length; m++) {
    const msg = diagram.messages[m];
    const fi = actorIdx.get(msg.from);
    const ti = actorIdx.get(msg.to);
    const fromX = llX[fi];
    const toX = llX[ti];
    const isSelf = fi === ti;
    const isDashed = msg.lineStyle === "dashed";
    const isFilled = msg.arrowHead === "filled";
    const lineChar = isDashed ? useAscii ? "." : "╌" : H;
    if (isSelf) {
      const y0 = msgArrowY[m];
      const loopW = Math.max(4, 4);
      canvas[fromX][y0] = JL;
      for (let x = fromX + 1;x < fromX + loopW; x++)
        canvas[x][y0] = lineChar;
      canvas[fromX + loopW][y0] = useAscii ? "+" : "┐";
      canvas[fromX + loopW][y0 + 1] = V;
      const labelX = fromX + loopW + 2;
      for (let i = 0;i < msg.label.length; i++) {
        if (labelX + i < totalW)
          canvas[labelX + i][y0 + 1] = msg.label[i];
      }
      const arrowChar = isFilled ? useAscii ? "<" : "◀" : useAscii ? "<" : "◁";
      canvas[fromX][y0 + 2] = arrowChar;
      for (let x = fromX + 1;x < fromX + loopW; x++)
        canvas[x][y0 + 2] = lineChar;
      canvas[fromX + loopW][y0 + 2] = useAscii ? "+" : "┘";
    } else {
      const labelY = msgLabelY[m];
      const arrowY = msgArrowY[m];
      const leftToRight = fromX < toX;
      const midX = Math.floor((fromX + toX) / 2);
      const labelStart = midX - Math.floor(msg.label.length / 2);
      for (let i = 0;i < msg.label.length; i++) {
        const lx = labelStart + i;
        if (lx >= 0 && lx < totalW)
          canvas[lx][labelY] = msg.label[i];
      }
      if (leftToRight) {
        for (let x = fromX + 1;x < toX; x++)
          canvas[x][arrowY] = lineChar;
        const ah = isFilled ? useAscii ? ">" : "▶" : useAscii ? ">" : "▷";
        canvas[toX][arrowY] = ah;
      } else {
        for (let x = toX + 1;x < fromX; x++)
          canvas[x][arrowY] = lineChar;
        const ah = isFilled ? useAscii ? "<" : "◀" : useAscii ? "<" : "◁";
        canvas[toX][arrowY] = ah;
      }
    }
  }
  for (let b = 0;b < diagram.blocks.length; b++) {
    const block = diagram.blocks[b];
    const topY = blockStartY.get(b);
    const botY = blockEndY.get(b);
    if (topY === undefined || botY === undefined)
      continue;
    let minLX = totalW;
    let maxLX = 0;
    for (let m = block.startIndex;m <= block.endIndex; m++) {
      if (m >= diagram.messages.length)
        break;
      const msg = diagram.messages[m];
      const f = actorIdx.get(msg.from) ?? 0;
      const t = actorIdx.get(msg.to) ?? 0;
      minLX = Math.min(minLX, llX[Math.min(f, t)]);
      maxLX = Math.max(maxLX, llX[Math.max(f, t)]);
    }
    const bLeft = Math.max(0, minLX - 4);
    const bRight = Math.min(totalW - 1, maxLX + 4);
    canvas[bLeft][topY] = TL;
    for (let x = bLeft + 1;x < bRight; x++)
      canvas[x][topY] = H;
    canvas[bRight][topY] = TR;
    const hdrLabel = block.label ? `${block.type} [${block.label}]` : block.type;
    for (let i = 0;i < hdrLabel.length && bLeft + 1 + i < bRight; i++) {
      canvas[bLeft + 1 + i][topY] = hdrLabel[i];
    }
    canvas[bLeft][botY] = BL;
    for (let x = bLeft + 1;x < bRight; x++)
      canvas[x][botY] = H;
    canvas[bRight][botY] = BR;
    for (let y = topY + 1;y < botY; y++) {
      canvas[bLeft][y] = V;
      canvas[bRight][y] = V;
    }
    for (let d = 0;d < block.dividers.length; d++) {
      const dY = divYMap.get(`${b}:${d}`);
      if (dY === undefined)
        continue;
      const dashChar = isDashedH();
      canvas[bLeft][dY] = JL;
      for (let x = bLeft + 1;x < bRight; x++)
        canvas[x][dY] = dashChar;
      canvas[bRight][dY] = JR;
      const dLabel = block.dividers[d].label;
      if (dLabel) {
        const dStr = `[${dLabel}]`;
        for (let i = 0;i < dStr.length && bLeft + 1 + i < bRight; i++) {
          canvas[bLeft + 1 + i][dY] = dStr[i];
        }
      }
    }
  }
  for (const np of notePositions) {
    increaseSize(canvas, np.x + np.width, np.y + np.height);
    canvas[np.x][np.y] = TL;
    for (let x = 1;x < np.width - 1; x++)
      canvas[np.x + x][np.y] = H;
    canvas[np.x + np.width - 1][np.y] = TR;
    for (let l = 0;l < np.lines.length; l++) {
      const ly = np.y + 1 + l;
      canvas[np.x][ly] = V;
      canvas[np.x + np.width - 1][ly] = V;
      for (let i = 0;i < np.lines[l].length; i++) {
        canvas[np.x + 2 + i][ly] = np.lines[l][i];
      }
    }
    const by = np.y + np.height - 1;
    canvas[np.x][by] = BL;
    for (let x = 1;x < np.width - 1; x++)
      canvas[np.x + x][by] = H;
    canvas[np.x + np.width - 1][by] = BR;
  }
  return canvasToString(canvas);
  function isDashedH() {
    return useAscii ? "-" : "╌";
  }
}
function parseClassDiagram(lines) {
  const diagram = {
    classes: [],
    relationships: [],
    namespaces: []
  };
  const classMap = /* @__PURE__ */ new Map;
  let currentNamespace = null;
  let currentClass = null;
  let braceDepth = 0;
  for (let i = 1;i < lines.length; i++) {
    const line = lines[i];
    if (currentClass && braceDepth > 0) {
      if (line === "}") {
        braceDepth--;
        if (braceDepth === 0) {
          currentClass = null;
        }
        continue;
      }
      const annotMatch = line.match(/^<<(\w+)>>$/);
      if (annotMatch) {
        currentClass.annotation = annotMatch[1];
        continue;
      }
      const member = parseMember(line);
      if (member) {
        if (member.isMethod) {
          currentClass.methods.push(member.member);
        } else {
          currentClass.attributes.push(member.member);
        }
      }
      continue;
    }
    const nsMatch = line.match(/^namespace\s+(\S+)\s*\{$/);
    if (nsMatch) {
      currentNamespace = { name: nsMatch[1], classIds: [] };
      continue;
    }
    if (line === "}" && currentNamespace) {
      diagram.namespaces.push(currentNamespace);
      currentNamespace = null;
      continue;
    }
    const classBlockMatch = line.match(/^class\s+(\S+?)(?:\s*~(\w+)~)?\s*\{$/);
    if (classBlockMatch) {
      const id = classBlockMatch[1];
      const generic = classBlockMatch[2];
      const cls = ensureClass(classMap, id);
      if (generic) {
        cls.label = `${id}<${generic}>`;
      }
      currentClass = cls;
      braceDepth = 1;
      if (currentNamespace) {
        currentNamespace.classIds.push(id);
      }
      continue;
    }
    const classOnlyMatch = line.match(/^class\s+(\S+?)(?:\s*~(\w+)~)?\s*$/);
    if (classOnlyMatch) {
      const id = classOnlyMatch[1];
      const generic = classOnlyMatch[2];
      const cls = ensureClass(classMap, id);
      if (generic) {
        cls.label = `${id}<${generic}>`;
      }
      if (currentNamespace) {
        currentNamespace.classIds.push(id);
      }
      continue;
    }
    const inlineAnnotMatch = line.match(/^class\s+(\S+?)\s*\{\s*<<(\w+)>>\s*\}$/);
    if (inlineAnnotMatch) {
      const cls = ensureClass(classMap, inlineAnnotMatch[1]);
      cls.annotation = inlineAnnotMatch[2];
      continue;
    }
    const inlineAttrMatch = line.match(/^(\S+?)\s*:\s*(.+)$/);
    if (inlineAttrMatch) {
      const rest = inlineAttrMatch[2];
      if (!rest.match(/<\|--|--|\*--|o--|-->|\.\.>|\.\.\|>/)) {
        const cls = ensureClass(classMap, inlineAttrMatch[1]);
        const member = parseMember(rest);
        if (member) {
          if (member.isMethod) {
            cls.methods.push(member.member);
          } else {
            cls.attributes.push(member.member);
          }
        }
        continue;
      }
    }
    const rel = parseRelationship(line);
    if (rel) {
      ensureClass(classMap, rel.from);
      ensureClass(classMap, rel.to);
      diagram.relationships.push(rel);
      continue;
    }
  }
  diagram.classes = [...classMap.values()];
  return diagram;
}
function ensureClass(classMap, id) {
  let cls = classMap.get(id);
  if (!cls) {
    cls = { id, label: id, attributes: [], methods: [] };
    classMap.set(id, cls);
  }
  return cls;
}
function parseMember(line) {
  const trimmed = line.trim().replace(/;$/, "");
  if (!trimmed)
    return null;
  let visibility = "";
  let rest = trimmed;
  if (/^[+\-#~]/.test(rest)) {
    visibility = rest[0];
    rest = rest.slice(1).trim();
  }
  const methodMatch = rest.match(/^(.+?)\(([^)]*)\)(?:\s*(.+))?$/);
  if (methodMatch) {
    const name2 = methodMatch[1].trim();
    const type2 = methodMatch[3]?.trim();
    const isStatic2 = name2.endsWith("$") || rest.includes("$");
    const isAbstract2 = name2.endsWith("*") || rest.includes("*");
    return {
      member: {
        visibility,
        name: name2.replace(/[$*]$/, ""),
        type: type2 || undefined,
        isStatic: isStatic2,
        isAbstract: isAbstract2
      },
      isMethod: true
    };
  }
  const parts = rest.split(/\s+/);
  let name;
  let type;
  if (parts.length >= 2) {
    type = parts[0];
    name = parts.slice(1).join(" ");
  } else {
    name = parts[0] ?? rest;
  }
  const isStatic = name.endsWith("$");
  const isAbstract = name.endsWith("*");
  return {
    member: {
      visibility,
      name: name.replace(/[$*]$/, ""),
      type: type || undefined,
      isStatic,
      isAbstract
    },
    isMethod: false
  };
}
function parseRelationship(line) {
  const match = line.match(/^(\S+?)\s+(?:"([^"]*?)"\s+)?(<\|--|<\|\.\.|\*--|o--|-->|--\*|--o|--|>\s*|\.\.>|\.\.\|>|--)\s+(?:"([^"]*?)"\s+)?(\S+?)(?:\s*:\s*(.+))?$/);
  if (!match)
    return null;
  const from = match[1];
  const fromCardinality = match[2] || undefined;
  const arrow = match[3].trim();
  const toCardinality = match[4] || undefined;
  const to = match[5];
  const label = match[6]?.trim() || undefined;
  const parsed = parseArrow(arrow);
  if (!parsed)
    return null;
  return { from, to, type: parsed.type, markerAt: parsed.markerAt, label, fromCardinality, toCardinality };
}
function parseArrow(arrow) {
  switch (arrow) {
    case "<|--":
      return { type: "inheritance", markerAt: "from" };
    case "<|..":
      return { type: "realization", markerAt: "from" };
    case "*--":
      return { type: "composition", markerAt: "from" };
    case "--*":
      return { type: "composition", markerAt: "to" };
    case "o--":
      return { type: "aggregation", markerAt: "from" };
    case "--o":
      return { type: "aggregation", markerAt: "to" };
    case "-->":
      return { type: "association", markerAt: "to" };
    case "..>":
      return { type: "dependency", markerAt: "to" };
    case "..|>":
      return { type: "realization", markerAt: "to" };
    case "--":
      return { type: "association", markerAt: "to" };
    default:
      return null;
  }
}
function formatMember(m) {
  const vis = m.visibility || "";
  const type = m.type ? `: ${m.type}` : "";
  return `${vis}${m.name}${type}`;
}
function buildClassSections(cls) {
  const header = [];
  if (cls.annotation)
    header.push(`<<${cls.annotation}>>`);
  header.push(cls.label);
  const attrs = cls.attributes.map(formatMember);
  const methods = cls.methods.map(formatMember);
  if (attrs.length === 0 && methods.length === 0)
    return [header];
  if (methods.length === 0)
    return [header, attrs];
  return [header, attrs, methods];
}
function getRelMarker(type, markerAt) {
  const dashed = type === "dependency" || type === "realization";
  return { type, markerAt, dashed };
}
function getMarkerShape(type, useAscii, direction) {
  switch (type) {
    case "inheritance":
    case "realization":
      if (direction === "down") {
        return useAscii ? "^" : "△";
      } else if (direction === "up") {
        return useAscii ? "v" : "▽";
      } else if (direction === "left") {
        return useAscii ? ">" : "◁";
      } else {
        return useAscii ? "<" : "▷";
      }
    case "composition":
      return useAscii ? "*" : "◆";
    case "aggregation":
      return useAscii ? "o" : "◇";
    case "association":
    case "dependency":
      if (direction === "down") {
        return useAscii ? "v" : "▼";
      } else if (direction === "up") {
        return useAscii ? "^" : "▲";
      } else if (direction === "left") {
        return useAscii ? "<" : "◀";
      } else {
        return useAscii ? ">" : "▶";
      }
  }
}
function renderClassAscii(text, config) {
  const lines = text.split(`
`).map((l) => l.trim()).filter((l) => l.length > 0 && !l.startsWith("%%"));
  const diagram = parseClassDiagram(lines);
  if (diagram.classes.length === 0)
    return "";
  const useAscii = config.useAscii;
  const hGap = 4;
  const vGap = 3;
  const classSections = /* @__PURE__ */ new Map;
  const classBoxW = /* @__PURE__ */ new Map;
  const classBoxH = /* @__PURE__ */ new Map;
  for (const cls of diagram.classes) {
    const sections = buildClassSections(cls);
    classSections.set(cls.id, sections);
    let maxTextW = 0;
    for (const section of sections) {
      for (const line of section)
        maxTextW = Math.max(maxTextW, line.length);
    }
    const boxW = maxTextW + 4;
    let totalLines = 0;
    for (const section of sections)
      totalLines += Math.max(section.length, 1);
    const boxH = totalLines + (sections.length - 1) + 2;
    classBoxW.set(cls.id, boxW);
    classBoxH.set(cls.id, boxH);
  }
  const classById = /* @__PURE__ */ new Map;
  for (const cls of diagram.classes)
    classById.set(cls.id, cls);
  const parents = /* @__PURE__ */ new Map;
  const children = /* @__PURE__ */ new Map;
  for (const rel of diagram.relationships) {
    const isHierarchical = rel.type === "inheritance" || rel.type === "realization";
    const parentId = isHierarchical && rel.markerAt === "to" ? rel.to : rel.from;
    const childId = isHierarchical && rel.markerAt === "to" ? rel.from : rel.to;
    if (!parents.has(childId))
      parents.set(childId, /* @__PURE__ */ new Set);
    parents.get(childId).add(parentId);
    if (!children.has(parentId))
      children.set(parentId, /* @__PURE__ */ new Set);
    children.get(parentId).add(childId);
  }
  const level = /* @__PURE__ */ new Map;
  const roots = diagram.classes.filter((c) => !parents.has(c.id) || parents.get(c.id).size === 0);
  const queue = roots.map((c) => c.id);
  for (const id of queue)
    level.set(id, 0);
  const levelCap = diagram.classes.length - 1;
  let qi = 0;
  while (qi < queue.length) {
    const id = queue[qi++];
    const childSet = children.get(id);
    if (!childSet)
      continue;
    for (const childId of childSet) {
      const newLevel = (level.get(id) ?? 0) + 1;
      if (newLevel > levelCap)
        continue;
      if (!level.has(childId) || level.get(childId) < newLevel) {
        level.set(childId, newLevel);
        queue.push(childId);
      }
    }
  }
  for (const cls of diagram.classes) {
    if (!level.has(cls.id))
      level.set(cls.id, 0);
  }
  const maxLevel = Math.max(...[...level.values()], 0);
  const levelGroups = Array.from({ length: maxLevel + 1 }, () => []);
  for (const cls of diagram.classes) {
    levelGroups[level.get(cls.id)].push(cls.id);
  }
  const placed = /* @__PURE__ */ new Map;
  let currentY = 0;
  for (let lv = 0;lv <= maxLevel; lv++) {
    const group = levelGroups[lv];
    if (group.length === 0)
      continue;
    let currentX = 0;
    let maxH = 0;
    for (const id of group) {
      const cls = classById.get(id);
      const w = classBoxW.get(id);
      const h = classBoxH.get(id);
      placed.set(id, {
        cls,
        sections: classSections.get(id),
        x: currentX,
        y: currentY,
        width: w,
        height: h
      });
      currentX += w + hGap;
      maxH = Math.max(maxH, h);
    }
    currentY += maxH + vGap;
  }
  let totalW = 0;
  let totalH = 0;
  for (const p of placed.values()) {
    totalW = Math.max(totalW, p.x + p.width);
    totalH = Math.max(totalH, p.y + p.height);
  }
  totalW += 4;
  totalH += 2;
  const canvas = mkCanvas(totalW - 1, totalH - 1);
  for (const p of placed.values()) {
    const boxCanvas = drawMultiBox(p.sections, useAscii);
    for (let bx = 0;bx < boxCanvas.length; bx++) {
      for (let by = 0;by < boxCanvas[0].length; by++) {
        const ch = boxCanvas[bx][by];
        if (ch !== " ") {
          const cx = p.x + bx;
          const cy = p.y + by;
          if (cx < totalW && cy < totalH) {
            canvas[cx][cy] = ch;
          }
        }
      }
    }
  }
  const H = useAscii ? "-" : "─";
  const V = useAscii ? "|" : "│";
  const dashH = useAscii ? "." : "╌";
  const dashV = useAscii ? ":" : "┊";
  for (const rel of diagram.relationships) {
    const fromP = placed.get(rel.from);
    const toP = placed.get(rel.to);
    if (!fromP || !toP)
      continue;
    const marker = getRelMarker(rel.type, rel.markerAt);
    const lineH = marker.dashed ? dashH : H;
    const lineV = marker.dashed ? dashV : V;
    const fromCX = fromP.x + Math.floor(fromP.width / 2);
    const fromBY = fromP.y + fromP.height - 1;
    const toCX = toP.x + Math.floor(toP.width / 2);
    const toTY = toP.y;
    if (fromBY < toTY) {
      const midY = fromBY + Math.floor((toTY - fromBY) / 2);
      for (let y = fromBY + 1;y <= midY; y++) {
        if (y < totalH)
          canvas[fromCX][y] = lineV;
      }
      if (fromCX !== toCX) {
        const lx = Math.min(fromCX, toCX);
        const rx = Math.max(fromCX, toCX);
        for (let x = lx;x <= rx; x++) {
          if (x < totalW && midY < totalH)
            canvas[x][midY] = lineH;
        }
        if (!useAscii && midY < totalH) {
          if (fromCX < toCX) {
            canvas[fromCX][midY] = "└";
            canvas[toCX][midY] = "┐";
          } else {
            canvas[fromCX][midY] = "┘";
            canvas[toCX][midY] = "┌";
          }
        }
      }
      for (let y = midY + 1;y < toTY; y++) {
        if (y < totalH)
          canvas[toCX][y] = lineV;
      }
      if (marker.markerAt === "to") {
        const markerChar = getMarkerShape(marker.type, useAscii, "down");
        const my = toTY - 1;
        if (my >= 0 && my < totalH) {
          for (let i = 0;i < markerChar.length; i++) {
            const mx = toCX - Math.floor(markerChar.length / 2) + i;
            if (mx >= 0 && mx < totalW)
              canvas[mx][my] = markerChar[i];
          }
        }
      }
      if (marker.markerAt === "from") {
        const markerChar = getMarkerShape(marker.type, useAscii, "down");
        const my = fromBY + 1;
        if (my < totalH) {
          for (let i = 0;i < markerChar.length; i++) {
            const mx = fromCX - Math.floor(markerChar.length / 2) + i;
            if (mx >= 0 && mx < totalW)
              canvas[mx][my] = markerChar[i];
          }
        }
      }
    } else if (toP.y + toP.height - 1 < fromP.y) {
      const fromTY = fromP.y;
      const toBY = toP.y + toP.height - 1;
      const midY = toBY + Math.floor((fromTY - toBY) / 2);
      for (let y = fromTY - 1;y >= midY; y--) {
        if (y >= 0 && y < totalH)
          canvas[fromCX][y] = lineV;
      }
      if (fromCX !== toCX) {
        const lx = Math.min(fromCX, toCX);
        const rx = Math.max(fromCX, toCX);
        for (let x = lx;x <= rx; x++) {
          if (x < totalW && midY >= 0 && midY < totalH)
            canvas[x][midY] = lineH;
        }
        if (!useAscii && midY >= 0 && midY < totalH) {
          if (fromCX < toCX) {
            canvas[fromCX][midY] = "┌";
            canvas[toCX][midY] = "┘";
          } else {
            canvas[fromCX][midY] = "┐";
            canvas[toCX][midY] = "└";
          }
        }
      }
      for (let y = midY - 1;y > toBY; y--) {
        if (y >= 0 && y < totalH)
          canvas[toCX][y] = lineV;
      }
      if (marker.markerAt === "from") {
        const markerChar = getMarkerShape(marker.type, useAscii, "up");
        const my = fromTY - 1;
        if (my >= 0 && my < totalH) {
          for (let i = 0;i < markerChar.length; i++) {
            const mx = fromCX - Math.floor(markerChar.length / 2) + i;
            if (mx >= 0 && mx < totalW)
              canvas[mx][my] = markerChar[i];
          }
        }
      }
      if (marker.markerAt === "to") {
        const isHierarchical = marker.type === "inheritance" || marker.type === "realization";
        const markerDir = isHierarchical ? "down" : "up";
        const markerChar = getMarkerShape(marker.type, useAscii, markerDir);
        const my = toBY + 1;
        if (my < totalH) {
          for (let i = 0;i < markerChar.length; i++) {
            const mx = toCX - Math.floor(markerChar.length / 2) + i;
            if (mx >= 0 && mx < totalW)
              canvas[mx][my] = markerChar[i];
          }
        }
      }
    } else {
      const detourY = Math.max(fromBY, toP.y + toP.height - 1) + 2;
      increaseSize(canvas, totalW, detourY + 1);
      for (let y = fromBY + 1;y <= detourY; y++) {
        canvas[fromCX][y] = lineV;
      }
      const lx = Math.min(fromCX, toCX);
      const rx = Math.max(fromCX, toCX);
      for (let x = lx;x <= rx; x++) {
        canvas[x][detourY] = lineH;
      }
      for (let y = detourY - 1;y >= toP.y + toP.height; y--) {
        canvas[toCX][y] = lineV;
      }
      if (marker.markerAt === "from") {
        const markerChar = getMarkerShape(marker.type, useAscii, "down");
        const my = fromBY + 1;
        if (my < totalH) {
          for (let i = 0;i < markerChar.length; i++) {
            const mx = fromCX - Math.floor(markerChar.length / 2) + i;
            if (mx >= 0 && mx < totalW)
              canvas[mx][my] = markerChar[i];
          }
        }
      }
      if (marker.markerAt === "to") {
        const markerChar = getMarkerShape(marker.type, useAscii, "up");
        const my = toP.y + toP.height;
        if (my < totalH) {
          for (let i = 0;i < markerChar.length; i++) {
            const mx = toCX - Math.floor(markerChar.length / 2) + i;
            if (mx >= 0 && mx < totalW)
              canvas[mx][my] = markerChar[i];
          }
        }
      }
    }
    if (rel.label) {
      const paddedLabel = ` ${rel.label} `;
      const midX = Math.floor((fromCX + toCX) / 2);
      let midY;
      if (fromBY < toTY) {
        midY = Math.floor((fromBY + 1 + toTY - 1) / 2);
      } else if (toP.y + toP.height - 1 < fromP.y) {
        const toBY = toP.y + toP.height - 1;
        midY = Math.floor((toBY + 1 + fromP.y - 1) / 2);
      } else {
        midY = Math.max(fromBY, toP.y + toP.height - 1) + 2;
      }
      const labelStart = midX - Math.floor(paddedLabel.length / 2);
      for (let i = 0;i < paddedLabel.length; i++) {
        const lx = labelStart + i;
        if (lx >= 0 && lx < totalW && midY >= 0 && midY < totalH) {
          canvas[lx][midY] = paddedLabel[i];
        }
      }
    }
  }
  return canvasToString(canvas);
}
function parseErDiagram(lines) {
  const diagram = {
    entities: [],
    relationships: []
  };
  const entityMap = /* @__PURE__ */ new Map;
  let currentEntity = null;
  for (let i = 1;i < lines.length; i++) {
    const line = lines[i];
    if (currentEntity) {
      if (line === "}") {
        currentEntity = null;
        continue;
      }
      const attr = parseAttribute(line);
      if (attr) {
        currentEntity.attributes.push(attr);
      }
      continue;
    }
    const entityBlockMatch = line.match(/^(\S+)\s*\{$/);
    if (entityBlockMatch) {
      const id = entityBlockMatch[1];
      const entity = ensureEntity(entityMap, id);
      currentEntity = entity;
      continue;
    }
    const rel = parseRelationshipLine(line);
    if (rel) {
      ensureEntity(entityMap, rel.entity1);
      ensureEntity(entityMap, rel.entity2);
      diagram.relationships.push(rel);
      continue;
    }
  }
  diagram.entities = [...entityMap.values()];
  return diagram;
}
function ensureEntity(entityMap, id) {
  let entity = entityMap.get(id);
  if (!entity) {
    entity = { id, label: id, attributes: [] };
    entityMap.set(id, entity);
  }
  return entity;
}
function parseAttribute(line) {
  const match = line.match(/^(\S+)\s+(\S+)(?:\s+(.+))?$/);
  if (!match)
    return null;
  const type = match[1];
  const name = match[2];
  const rest = match[3]?.trim() ?? "";
  const keys = [];
  let comment;
  const commentMatch = rest.match(/"([^"]*)"/);
  if (commentMatch) {
    comment = commentMatch[1];
  }
  const restWithoutComment = rest.replace(/"[^"]*"/, "").trim();
  for (const part of restWithoutComment.split(/\s+/)) {
    const upper = part.toUpperCase();
    if (upper === "PK" || upper === "FK" || upper === "UK") {
      keys.push(upper);
    }
  }
  return { type, name, keys, comment };
}
function parseRelationshipLine(line) {
  const match = line.match(/^(\S+)\s+([|o}{]+(?:--|\.\.)[|o}{]+)\s+(\S+)\s*:\s*(.+)$/);
  if (!match)
    return null;
  const entity1 = match[1];
  const cardinalityStr = match[2];
  const entity2 = match[3];
  const label = match[4].trim();
  const lineMatch = cardinalityStr.match(/^([|o}{]+)(--|\.\.?)([|o}{]+)$/);
  if (!lineMatch)
    return null;
  const leftStr = lineMatch[1];
  const lineStyle = lineMatch[2];
  const rightStr = lineMatch[3];
  const cardinality1 = parseCardinality(leftStr);
  const cardinality2 = parseCardinality(rightStr);
  const identifying = lineStyle === "--";
  if (!cardinality1 || !cardinality2)
    return null;
  return { entity1, entity2, cardinality1, cardinality2, label, identifying };
}
function parseCardinality(str) {
  const sorted = str.split("").sort().join("");
  if (sorted === "||")
    return "one";
  if (sorted === "o|")
    return "zero-one";
  if (sorted === "|}" || sorted === "{|")
    return "many";
  if (sorted === "{o" || sorted === "o{")
    return "zero-many";
  return null;
}
function formatAttribute(attr) {
  const keyStr = attr.keys.length > 0 ? attr.keys.join(",") + " " : "   ";
  return `${keyStr}${attr.type} ${attr.name}`;
}
function buildEntitySections(entity) {
  const header = [entity.label];
  const attrs = entity.attributes.map(formatAttribute);
  if (attrs.length === 0)
    return [header];
  return [header, attrs];
}
function getCrowsFootChars(card, useAscii) {
  if (useAscii) {
    switch (card) {
      case "one":
        return "||";
      case "zero-one":
        return "o|";
      case "many":
        return "}|";
      case "zero-many":
        return "o{";
    }
  } else {
    switch (card) {
      case "one":
        return "║";
      case "zero-one":
        return "o║";
      case "many":
        return "╟";
      case "zero-many":
        return "o╟";
    }
  }
}
function renderErAscii(text, config) {
  const lines = text.split(`
`).map((l) => l.trim()).filter((l) => l.length > 0 && !l.startsWith("%%"));
  const diagram = parseErDiagram(lines);
  if (diagram.entities.length === 0)
    return "";
  const useAscii = config.useAscii;
  const hGap = 6;
  const vGap = 4;
  const entitySections = /* @__PURE__ */ new Map;
  const entityBoxW = /* @__PURE__ */ new Map;
  const entityBoxH = /* @__PURE__ */ new Map;
  for (const ent of diagram.entities) {
    const sections = buildEntitySections(ent);
    entitySections.set(ent.id, sections);
    let maxTextW = 0;
    for (const section of sections) {
      for (const line of section)
        maxTextW = Math.max(maxTextW, line.length);
    }
    const boxW = maxTextW + 4;
    let totalLines = 0;
    for (const section of sections)
      totalLines += Math.max(section.length, 1);
    const boxH = totalLines + (sections.length - 1) + 2;
    entityBoxW.set(ent.id, boxW);
    entityBoxH.set(ent.id, boxH);
  }
  const maxPerRow = Math.max(2, Math.ceil(Math.sqrt(diagram.entities.length)));
  const placed = /* @__PURE__ */ new Map;
  let currentX = 0;
  let currentY = 0;
  let maxRowH = 0;
  let colCount = 0;
  for (const ent of diagram.entities) {
    const w = entityBoxW.get(ent.id);
    const h = entityBoxH.get(ent.id);
    if (colCount >= maxPerRow) {
      currentY += maxRowH + vGap;
      currentX = 0;
      maxRowH = 0;
      colCount = 0;
    }
    placed.set(ent.id, {
      entity: ent,
      sections: entitySections.get(ent.id),
      x: currentX,
      y: currentY,
      width: w,
      height: h
    });
    currentX += w + hGap;
    maxRowH = Math.max(maxRowH, h);
    colCount++;
  }
  let totalW = 0;
  let totalH = 0;
  for (const p of placed.values()) {
    totalW = Math.max(totalW, p.x + p.width);
    totalH = Math.max(totalH, p.y + p.height);
  }
  totalW += 4;
  totalH += 2;
  const canvas = mkCanvas(totalW - 1, totalH - 1);
  for (const p of placed.values()) {
    const boxCanvas = drawMultiBox(p.sections, useAscii);
    for (let bx = 0;bx < boxCanvas.length; bx++) {
      for (let by = 0;by < boxCanvas[0].length; by++) {
        const ch = boxCanvas[bx][by];
        if (ch !== " ") {
          const cx = p.x + bx;
          const cy = p.y + by;
          if (cx < totalW && cy < totalH) {
            canvas[cx][cy] = ch;
          }
        }
      }
    }
  }
  const H = useAscii ? "-" : "─";
  const V = useAscii ? "|" : "│";
  const dashH = useAscii ? "." : "╌";
  const dashV = useAscii ? ":" : "┊";
  for (const rel of diagram.relationships) {
    const e1 = placed.get(rel.entity1);
    const e2 = placed.get(rel.entity2);
    if (!e1 || !e2)
      continue;
    const lineH = rel.identifying ? H : dashH;
    const lineV = rel.identifying ? V : dashV;
    const e1CX = e1.x + Math.floor(e1.width / 2);
    const e1CY = e1.y + Math.floor(e1.height / 2);
    const e2CX = e2.x + Math.floor(e2.width / 2);
    const e2CY = e2.y + Math.floor(e2.height / 2);
    const sameRow = Math.abs(e1CY - e2CY) < Math.max(e1.height, e2.height);
    if (sameRow) {
      const [left, right] = e1CX < e2CX ? [e1, e2] : [e2, e1];
      const [leftCard, rightCard] = e1CX < e2CX ? [rel.cardinality1, rel.cardinality2] : [rel.cardinality2, rel.cardinality1];
      const startX = left.x + left.width;
      const endX = right.x - 1;
      const lineY = left.y + Math.floor(left.height / 2);
      for (let x = startX;x <= endX; x++) {
        if (x < totalW)
          canvas[x][lineY] = lineH;
      }
      const leftChars = getCrowsFootChars(leftCard, useAscii);
      for (let i = 0;i < leftChars.length; i++) {
        const mx = startX + i;
        if (mx < totalW)
          canvas[mx][lineY] = leftChars[i];
      }
      const rightChars = getCrowsFootChars(rightCard, useAscii);
      for (let i = 0;i < rightChars.length; i++) {
        const mx = endX - rightChars.length + 1 + i;
        if (mx >= 0 && mx < totalW)
          canvas[mx][lineY] = rightChars[i];
      }
      if (rel.label) {
        const gapMid = Math.floor((startX + endX) / 2);
        const labelStart = Math.max(startX, gapMid - Math.floor(rel.label.length / 2));
        const labelY = lineY - 1;
        if (labelY >= 0) {
          for (let i = 0;i < rel.label.length; i++) {
            const lx = labelStart + i;
            if (lx >= startX && lx <= endX && lx < totalW) {
              canvas[lx][labelY] = rel.label[i];
            }
          }
        }
      }
    } else {
      const [upper, lower] = e1CY < e2CY ? [e1, e2] : [e2, e1];
      const [upperCard, lowerCard] = e1CY < e2CY ? [rel.cardinality1, rel.cardinality2] : [rel.cardinality2, rel.cardinality1];
      const startY = upper.y + upper.height;
      const endY = lower.y - 1;
      const lineX = upper.x + Math.floor(upper.width / 2);
      for (let y = startY;y <= endY; y++) {
        if (y < totalH)
          canvas[lineX][y] = lineV;
      }
      const lowerCX = lower.x + Math.floor(lower.width / 2);
      if (lineX !== lowerCX) {
        const midY = Math.floor((startY + endY) / 2);
        const lx = Math.min(lineX, lowerCX);
        const rx = Math.max(lineX, lowerCX);
        for (let x = lx;x <= rx; x++) {
          if (x < totalW && midY < totalH)
            canvas[x][midY] = lineH;
        }
        for (let y = midY + 1;y <= endY; y++) {
          if (y < totalH)
            canvas[lowerCX][y] = lineV;
        }
      }
      const upperChars = getCrowsFootChars(upperCard, useAscii);
      if (startY < totalH) {
        for (let i = 0;i < upperChars.length; i++) {
          const mx = lineX - Math.floor(upperChars.length / 2) + i;
          if (mx >= 0 && mx < totalW)
            canvas[mx][startY] = upperChars[i];
        }
      }
      const targetX = lineX !== lowerCX ? lowerCX : lineX;
      const lowerChars = getCrowsFootChars(lowerCard, useAscii);
      if (endY >= 0 && endY < totalH) {
        for (let i = 0;i < lowerChars.length; i++) {
          const mx = targetX - Math.floor(lowerChars.length / 2) + i;
          if (mx >= 0 && mx < totalW)
            canvas[mx][endY] = lowerChars[i];
        }
      }
      if (rel.label) {
        const midY = Math.floor((startY + endY) / 2);
        const labelX = lineX + 2;
        if (midY >= 0) {
          for (let i = 0;i < rel.label.length; i++) {
            const lx = labelX + i;
            if (lx >= 0) {
              increaseSize(canvas, lx + 1, midY + 1);
              canvas[lx][midY] = rel.label[i];
            }
          }
        }
      }
    }
  }
  return canvasToString(canvas);
}
function detectDiagramType(text) {
  const firstLine = text.trim().split(`
`)[0]?.trim().toLowerCase() ?? "";
  if (/^sequencediagram\s*$/.test(firstLine))
    return "sequence";
  if (/^classdiagram\s*$/.test(firstLine))
    return "class";
  if (/^erdiagram\s*$/.test(firstLine))
    return "er";
  return "flowchart";
}
function renderMermaidAscii(text, options = {}) {
  const config = {
    useAscii: options.useAscii ?? false,
    paddingX: options.paddingX ?? 5,
    paddingY: options.paddingY ?? 5,
    boxBorderPadding: options.boxBorderPadding ?? 1,
    graphDirection: "TD"
  };
  const diagramType = detectDiagramType(text);
  switch (diagramType) {
    case "sequence":
      return renderSequenceAscii(text, config);
    case "class":
      return renderClassAscii(text, config);
    case "er":
      return renderErAscii(text, config);
    case "flowchart":
    default: {
      const parsed = parseMermaid(text);
      if (parsed.direction === "LR" || parsed.direction === "RL") {
        config.graphDirection = "LR";
      } else {
        config.graphDirection = "TD";
      }
      const graph = convertToAsciiGraph(parsed, config);
      createMapping(graph);
      drawGraph(graph);
      if (parsed.direction === "BT") {
        flipCanvasVertically(graph.canvas);
      }
      return canvasToString(graph.canvas);
    }
  }
}

// src/index.ts
import { writeFileSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
var args = process.argv.slice(2);
function getFlag(name) {
  return args.includes(`--${name}`);
}
function getOption(name) {
  const idx = args.indexOf(`--${name}`);
  if (idx !== -1 && idx + 1 < args.length) {
    return args[idx + 1];
  }
  return;
}
function getPositional() {
  for (let i = 0;i < args.length; i++) {
    if (args[i].startsWith("--")) {
      if (!["--help", "--examples"].includes(args[i])) {
        i++;
      }
      continue;
    }
    return args[i];
  }
  return;
}
var USAGE = `
mermaid-diagram-creator - Generate and render Mermaid diagrams

USAGE:
  bun scripts/index.js [options] [mermaid-source]

INPUT:
  --file <path>        Read mermaid source from a .mmd file
  <mermaid-source>     Inline mermaid string (positional argument)

OPTIONS:
  --output <path>      Output file path (default: diagram.html for html, stdout for ascii)
  --format <type>      Output format: ascii or html (default: html)
  --theme <name>       Built-in theme name (default: zinc-light)
  --debug              Print mermaid source to stderr for debugging
  --examples           Print example diagrams for all 5 types
  --help               Print this help message

EXAMPLES:
  bun scripts/index.js --file diagram.mmd --output diagram.html
  bun scripts/index.js --file diagram.mmd --format ascii
  bun scripts/index.js --file diagram.mmd --format ascii --output diagram.txt
  bun scripts/index.js --file diagram.mmd --theme dracula
  bun scripts/index.js --examples
  bun scripts/index.js "graph TD; A-->B"

AVAILABLE THEMES:
  zinc-dark, tokyo-night, tokyo-night-storm, tokyo-night-light,
  catppuccin-mocha, catppuccin-latte, nord, nord-light, dracula,
  github-light, github-dark, solarized-light, solarized-dark, one-dark
`.trim();
var EXAMPLES = `
=== Flowchart ===
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
    C --> E[End]
    D --> E

=== Sequence Diagram ===
sequenceDiagram
    participant Client
    participant Server
    participant DB
    Client->>Server: POST /api/data
    Server->>DB: INSERT query
    DB-->>Server: OK
    Server-->>Client: 201 Created

=== State Diagram ===
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing: submit
    Processing --> Success: complete
    Processing --> Error: fail
    Error --> Idle: retry
    Success --> [*]

=== Class Diagram ===
classDiagram
    class Animal {
        +String name
        +int age
        +makeSound() void
    }
    class Dog {
        +fetch() void
    }
    class Cat {
        +purr() void
    }
    Animal <|-- Dog
    Animal <|-- Cat

=== ER Diagram ===
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains
    PRODUCT ||--o{ LINE_ITEM : "is in"
    USER {
        int id PK
        string name
        string email
    }
    ORDER {
        int id PK
        date created
    }
`.trim();
function generateHtml(source, themeName) {
  const escapedSource = source.replace(/\\/g, "\\\\").replace(/`/g, "\\`").replace(/\$/g, "\\$").replace(/<\/(script)/gi, "<\\/$1");
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Mermaid Diagram</title>
<style>
  body { margin: 0; display: flex; justify-content: center; align-items: center; min-height: 100vh; background: #f5f5f5; }
  #diagram { max-width: 100%; padding: 2rem; }
  #diagram svg { max-width: 100%; height: auto; }
</style>
<script src="https://unpkg.com/beautiful-mermaid@0.1.3/dist/beautiful-mermaid.browser.global.js"></script>
</head>
<body>
<div id="diagram">Loading diagram...</div>
<script>
  const { renderMermaid, THEMES } = beautifulMermaid;
  const source = \`${escapedSource}\`;
  const theme = THEMES['${themeName.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/<\/(script)/gi, "<\\/$1")}'] || {};
  renderMermaid(source, theme).then(svg => {
    document.getElementById('diagram').innerHTML = svg;
  }).catch(err => {
    document.getElementById('diagram').innerHTML = '<pre style="color:red">' + err.message + '</pre>';
  });
</script>
</body>
</html>`;
}
async function main() {
  if (getFlag("help")) {
    console.log(USAGE);
    process.exit(0);
  }
  if (getFlag("examples")) {
    console.log(EXAMPLES);
    process.exit(0);
  }
  const filePath = getOption("file");
  const format = getOption("format") || "html";
  const theme = getOption("theme") || "zinc-light";
  const output = getOption("output");
  const positional = getPositional();
  let source;
  if (filePath) {
    source = readFileSync(resolve(filePath), "utf-8").trim();
  } else if (positional) {
    source = positional;
  } else {
    console.error("Error: No input provided. Use --file <path> or pass mermaid source as an argument.");
    console.error("Run with --help for usage information.");
    process.exit(1);
  }
  if (getFlag("debug")) {
    console.error("--- Mermaid Source ---");
    console.error(source);
    console.error("--- End Source ---");
  }
  switch (format) {
    case "ascii": {
      const ascii = renderMermaidAscii(source);
      if (output) {
        writeFileSync(resolve(output), ascii, "utf-8");
        console.log(`ASCII diagram written to ${output}`);
      } else {
        console.log(ascii);
      }
      break;
    }
    case "html": {
      const htmlOutput = output || "diagram.html";
      const html = generateHtml(source, theme);
      writeFileSync(resolve(htmlOutput), html, "utf-8");
      console.log(`HTML diagram written to ${htmlOutput}`);
      break;
    }
    default:
      console.error(`Error: Unknown format "${format}". Use ascii or html.`);
      process.exit(1);
  }
}
main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
