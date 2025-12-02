import Foundation

struct Day23: AdventDay {
    var data: String

    private let example2: String = """
        a-b
        b-c
        c-a
        """

    private let example: String = """
        kh-tc
        qp-kh
        de-cg
        ka-co
        yn-aq
        qp-ub
        cg-tb
        vc-aq
        tb-ka
        wh-tc
        yn-cg
        kh-ub
        ta-co
        de-co
        tc-td
        tb-wq
        wh-td
        ta-ka
        td-qp
        aq-cg
        wq-ub
        ub-vc
        de-ta
        wq-aq
        wq-vc
        wh-yn
        ka-de
        kh-ta
        co-tc
        wh-qp
        tb-vc
        td-yn
        """

    init(data: String) {
        self.data = data
    }

    /// Returns an adjacency list
    private func parse(_ data: String) -> [String: Set<String>] {
        var adjList: [String: Set<String>] = [:]
        for line in data.components(separatedBy: .whitespacesAndNewlines) {
            let computers = line.split(separator: "-").map { String($0) }
            guard !computers.isEmpty else { continue }
            let a = computers[0]
            let b = computers[1]
            adjList[a, default: []].insert(b)
            adjList[b, default: []].insert(a)
        }
        return adjList
    }

    private func countTriangles(graph: [String: Set<String>]) -> Set<Set<String>> {
        var interconnected: Set<Set<String>> = []
        func find(
            _ targetNode: String,
            from node: String,
            at depth: Int,
            path: [String]
        ) {
            if depth == 0 {
                if node == targetNode {
                    interconnected.insert(Set(path))
                }
                return
            }

            let neighbors = graph[node] ?? []
            for neighbor in neighbors {
                find(targetNode, from: neighbor, at: depth - 1, path: path + [neighbor])
            }
        }

        if graph.isEmpty { return [] }
        for currentNode in graph.keys {
            find(currentNode, from: currentNode, at: 3, path: [])
        }
        return interconnected
    }

    private func findMaximalClique(node: String, graph: [String: Set<String>]) -> Set<String> {
        var frontier: [String] = [node]
        var currentClique: Set<String> = []
        while let currentNode = frontier.popLast() {
            // The current node is part of the clique if all members
            // of the current clique has an edge pointed to it.
            let isInClique = currentClique.allSatisfy { c in
                graph[c, default: []].contains(currentNode)
            }
            if isInClique {
                currentClique.insert(currentNode)
                let neighbors = graph[currentNode] ?? []
                for neighbor in neighbors {
                    frontier.append(neighbor)
                }
            }
        }

        return currentClique
    }

    private func findMaximumClique(graph: [String: Set<String>]) -> Set<String> {
        var best: Set<String> = []
        for node in graph.keys {
            let maximalClique = self.findMaximalClique(node: node, graph: graph)
            if maximalClique.count > best.count {
                best = maximalClique
            }
        }
        return best
    }

    func part1() -> Int {
        let adjList = self.parse(self.data)
        let interconnected = self.countTriangles(graph: adjList)
        return
            interconnected
            .filter { subgraph in subgraph.contains { $0.starts(with: "t") } }
            .count
    }

    func part2() -> Int {
        // NOTE: Learn about cliques and Bron-Kerbosch algorithm for finding
        // maximal cliques
        let adjList = self.parse(self.data)
        let maximumClique = self.findMaximumClique(graph: adjList)
        let answer = maximumClique.sorted().joined(separator: ",")
        print(answer)
        return 0
    }
}
