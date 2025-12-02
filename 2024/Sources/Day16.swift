import Collections
import Foundation

struct Day16: AdventDay {
    var data: String

    private let example2: String = """
        #####
        #..E#
        #.#.#
        #.#.#
        #...#
        #.#.#
        #S..#
        #####
        """

    private let example: String = """
        ###############
        #.......#....E#
        #.#.###.#.###.#
        #.....#.#...#.#
        #.###.#####.#.#
        #.#.#.......#.#
        #.#.#####.###.#
        #...........#.#
        ###.#.#####.#.#
        #...#.....#.#.#
        #.#.#.###.#.#.#
        #.....#...#.#.#
        #.###.#.#.#.#.#
        #S..#.....#...#
        ###############
        """

    private let example3: String = """
        #################
        #...#...#...#..E#
        #.#.#.#.#.#.#.#.#
        #.#.#.#...#...#.#
        #.#.#.#.###.#.#.#
        #...#.#.#.....#.#
        #.#.#.#.#.#####.#
        #.#...#.#.#.....#
        #.#.#####.#.###.#
        #.#.#.......#...#
        #.#.###.#####.###
        #.#.#...#.....#.#
        #.#.#.#####.###.#
        #.#.#.........#.#
        #.#.#.#########.#
        #S#.............#
        #################
        """

    init(data: String) {
        self.data = data
    }

    struct Pose: Hashable, CustomDebugStringConvertible {
        let x: Int
        let y: Int
        let d: Int  // N-0 E-1 S-2 W-3

        var debugDescription: String {
            "( \(x), \(y), \(d) )"
        }
    }

    private func parse(_ data: String) -> (
        grid: [[Character]],
        start: Pose,
        end: Pose
    ) {
        var grid =
            data
            .split(separator: "\n")
            .map { row in Array(row) }
        var start: Pose?
        var end: Pose?
        for j in 0..<grid.count {
            for i in 0..<grid[0].count {
                if grid[j][i] == "S" {
                    start = Pose(x: i, y: j, d: 1)
                    grid[j][i] = "."
                } else if grid[j][i] == "E" {
                    end = Pose(x: i, y: j, d: 1)
                    grid[j][i] = "."
                }
            }
        }
        guard let start, let end else {
            fatalError("Could not find S or E in grid")
        }
        return (grid, start, end)
    }

    // NOTE: BFS is a lot faster than DFS here, double check why
    func bfs(
        grid: [[Character]],
        start: Pose,
        end: Pose
    ) -> (Int, Set<Pose>)? {
        let (W, H) = (grid[0].count, grid.count)

        var costs: [Pose: Int] = [start: 0]
        var queue: [(Pose, [Pose], Int)] = [(start, [], 0)]
        var pathsAndCosts: [(path: [Pose], cost: Int)] = []

        while let poseAndPath = queue.popLast() {
            let (pose, path, currCost) = poseAndPath

            if pose.x == end.x, pose.y == end.y {
                pathsAndCosts.append((path + [pose], currCost))
            }

            let dVals = self.values(pose.d)
            let nbrs: [Pose] = [
                Pose(x: pose.x + dVals.dx, y: pose.y + dVals.dy, d: pose.d),  // forward
                Pose(x: pose.x, y: pose.y, d: ((pose.d + 1) % 4)),  // turn CW
                Pose(x: pose.x, y: pose.y, d: (pose.d - 1 + 4) % 4),  // turn CCW
            ]
            .filter { p in 0 <= p.x && p.x < W && 0 <= p.y && p.y < H }
            .filter { p in grid[p.y][p.x] != "#" }

            for nbr in nbrs {
                let dCost = self.dist(from: pose, to: nbr)
                let newCost = costs[pose]! + dCost

                if newCost <= costs[nbr, default: Int.max] {
                    costs[nbr] = newCost
                    queue.insert((nbr, path + [pose], newCost), at: 0)
                }
            }
        }

        let best = costs.keys
            .filter { $0.x == end.x && $0.y == end.y }
            .min { costs[$0, default: Int.max] < costs[$1, default: Int.max] }

        guard let best, let bestCost = costs[best] else { return nil }

        let bestPaths =
            pathsAndCosts
            .filter { _, cost in cost == bestCost }
            .map(\.path)

        // Print the result
        for path in bestPaths {
            var printGrid = grid
            for pose in path {
                printGrid[pose.y][pose.x] = str(d: pose.d)
            }
            for row in printGrid {
                print(row.map { String($0) }.joined())
            }
        }

        let uniquePoses =
            bestPaths
            .flatMap { path in
                path.flatMap { $0 }
            }
            .uniqued { [$0.x, $0.y] }

        return (costs[best]!, Set(uniquePoses))
    }

    func part1() -> Int {
        let (grid, start, end) = self.parse(self.data)
        let result = self.bfs(grid: grid, start: start, end: end)
        guard let result else { return -1 }
        let (bestScore, _) = result
        return bestScore
    }

    func part2() -> Int {
        let (grid, start, end) = self.parse(self.data)
        let result = self.bfs(grid: grid, start: start, end: end)
        guard let result else { return -1 }
        let (_, uniquePoses) = result
        return uniquePoses.count
    }

    private func values(_ dir: Int) -> (dx: Int, dy: Int) {
        assert(dir >= 0)
        return switch dir % 4 {
        case 0: (0, -1)
        case 1: (1, 0)
        case 2: (0, 1)
        case 3: (-1, 0)
        default: fatalError()
        }
    }

    private func dist(from a: Pose, to b: Pose) -> Int {
        var cost = abs(a.x - b.x) + abs(a.y - b.y)
        if (b.d % 4) != (a.d % 4) { cost += 1000 }
        return cost
    }

    private func str(d: Int) -> Character {
        return switch d {
        case 0: "^"
        case 1: ">"
        case 2: "v"
        case 3: "<"
        default: fatalError("unexpected d: \(d)")
        }
    }
}
