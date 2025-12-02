import Foundation

struct Day20: AdventDay {
    var data: String

    private let example2: String = """
        #####
        #S#E#
        #.#.#
        #.#.#
        #.#.#
        #...#
        #####
        """

    private let example: String = """
        ###############
        #...#...#.....#
        #.#.#.#.#.###.#
        #S#...#.#.#...#
        #######.#.#.###
        #######.#.#...#
        #######.#.###.#
        ###..E#...#...#
        ###.#######.###
        #...###...#...#
        #.#####.#.###.#
        #.#...#.#.#...#
        #.#.#.#.#.#.###
        #...#...#...###
        ###############
        """

    init(data: String) {
        self.data = data
    }

    private func parse(_ data: String) -> (
        grid: [[Character]],
        start: (x: Int, y: Int),
        end: (x: Int, y: Int),
        walls: [(x: Int, y: Int)]
    ) {
        var grid =
            data
            .split(separator: "\n")
            .filter { !$0.isEmpty }
            .map { Array($0) }
        let (W, H) = (grid[0].count, grid.count)
        var start: (x: Int, y: Int)? = nil
        var end: (x: Int, y: Int)? = nil
        var walls: [(x: Int, y: Int)] = []
        for j in 0..<H {
            for i in 0..<W {
                switch grid[j][i] {
                case "S":
                    start = (i, j)
                    grid[j][i] = "."
                case "E":
                    end = (i, j)
                    grid[j][i] = "."
                case "#":
                    walls.append((i, j))
                default:
                    break
                }
            }
        }
        guard let start, let end else {
            fatalError("Expected S and E to be in grid")
        }
        return (grid, start, end, walls)
    }

    struct Pose: Hashable, CustomDebugStringConvertible {
        let x: Int
        let y: Int

        init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }

        init(_ tuple: (x: Int, y: Int)) {
            self.x = tuple.x
            self.y = tuple.y
        }

        var debugDescription: String {
            "{\(x), \(y)}"
        }
    }

    private func bfs(grid: [[Character]], start: Pose, end: Pose) -> [Pose] {
        let (W, H) = (grid[0].count, grid.count)

        var costs: [Pose: Int] = [start: 0]
        var path: [Pose: Pose?] = [start: nil]
        var queue: [Pose] = [start]

        while let curr = queue.popLast() {
            let nbrs: [Pose] = [(0, 1), (0, -1), (1, 0), (-1, 0)]
                .map { (dx, dy) in Pose(x: curr.x + dx, y: curr.y + dy) }
                .filter { p in 0 <= p.x && p.x < W && 0 <= p.y && p.y < H }
                .filter { p in grid[p.y][p.x] != "#" }

            for nbr in nbrs {
                let newCost = costs[curr]! + 1
                if newCost < costs[nbr, default: Int.max] {
                    costs[nbr] = newCost
                    path[nbr] = curr
                    queue.insert(nbr, at: 0)
                }
            }
        }

        // Retrace path
        var bestPath: [Pose] = [end]
        var curr: Pose = end
        while let next = path[curr, default: nil] {
            bestPath.append(next)
            curr = next
        }

        bestPath.reverse()  // Flip from start to end

        return bestPath
    }

    private func dist(from a: Pose, to b: Pose) -> Int {
        return abs(b.x - a.x) + abs(b.y - a.y)
    }

    private func solve() {
    }

    func part1() -> Int {
        return 0
        let (grid, start, end, _) = self.parse(self.data)
        let minTimeSaved: Int = 100
        let cheatDist: Int = 2

        let regularPath = self.bfs(grid: grid, start: Pose(start), end: Pose(end))
        let regularTime = regularPath.count

        var cheats: [[Pose]: Int] = [:]
        for (aIdx, a) in regularPath.enumerated() {
            // print("Checking \(aIdx)/\(regularPath.count)")
            for (bIdx, b) in regularPath.enumerated() {
                if bIdx <= aIdx { continue }  // no point shortcutting backwards
                guard bIdx - aIdx >= minTimeSaved else { continue }  // must save at least minTimeSaved steps
                let aToB = dist(from: a, to: b)
                guard aToB <= cheatDist else { continue }  // must be within cheat dist

                // let fastPath = regularPath[0...aIdx] + regularPath[bIdx..<regularPath.count]
                let fastTime = aIdx + aToB + (regularPath.count - bIdx)
                guard fastTime < regularTime else { continue }

                let timeSaved = regularTime - fastTime

                cheats[[a, b]] = min(
                    cheats[[a, b], default: Int.max],
                    timeSaved
                )
            }
        }

        let counter = cheats.values
            .filter { timeSaved in timeSaved >= minTimeSaved }
            .reduce(into: [Int: Int]()) { c, timeSaved in
                c[timeSaved] = c[timeSaved, default: 0] + 1
            }

        print(counter.sorted { $0.key < $1.key }.map { ($0.key, $0.value) })

        let result =
            counter
            .filter { $0.key >= minTimeSaved }
            .reduce(0) { $0 + $1.value }

        return result
    }

    func part2() -> Int {
        let (grid, start, end, _) = self.parse(self.data)
        let minTimeSaved: Int = 100
        let cheatDist: Int = 20

        let regularPath = self.bfs(grid: grid, start: Pose(start), end: Pose(end))
        let regularTime = regularPath.count

        var cheats: [[Pose]: Int] = [:]
        for (aIdx, a) in regularPath.enumerated() {
            print("Checking \(aIdx)/\(regularPath.count)")
            for (bIdx, b) in regularPath.enumerated() {
                if bIdx <= aIdx { continue }  // no point shortcutting backwards
                guard bIdx - aIdx >= minTimeSaved else { continue }  // must save at least minTimeSaved steps
                let aToB = dist(from: a, to: b)
                guard aToB <= cheatDist else { continue }  // must be within cheat dist

                let fastTime = aIdx + aToB + (regularPath.count - bIdx)
                guard fastTime < regularTime else { continue }

                let timeSaved = regularTime - fastTime

                cheats[[a, b]] = min(
                    cheats[[a, b], default: Int.max],
                    timeSaved
                )
            }
        }

        let counter = cheats.values
            .filter { timeSaved in timeSaved >= minTimeSaved }
            .reduce(into: [Int: Int]()) { c, timeSaved in
                c[timeSaved] = c[timeSaved, default: 0] + 1
            }

        let result =
            counter
            .filter { $0.key >= minTimeSaved }
            .reduce(0) { $0 + $1.value }

        return result
    }
}

// MARK: Archive

/// Ye old' bruteforce

// var cheats: [Set<Pose>: Int] = [:]
// for (wallIdx, wall) in walls.enumerated() {
//     print("Removing wall \(wallIdx + 1)/\(walls.count)")
//     var gridCopy = grid

//     gridCopy[wall.y][wall.x] = "."

//     let key = Set([Pose(wall)])
//     if cheats.keys.contains(key) { continue }

//     let time = self.bfs(grid: gridCopy, start: Pose(start), end: Pose(end))

//     guard time < regularTime else { continue }
//     let timeSaved = regularTime - time
//     cheats[key] = timeSaved
// }
