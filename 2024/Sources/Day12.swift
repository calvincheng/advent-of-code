import Foundation

struct Day12: AdventDay {
    var data: String

    private let example: String = """
        OOOOO
        OXOXO
        OOOOO
        OXOXO
        OOOOO
        """

    private let example2: String = """
        AAAA
        BBCD
        BBCC
        EEEC
        """

    init(data: String) {
        self.data = example2  // data
    }

    private func parse(_ data: String) -> [[Character]] {
        data
            .split(separator: "\n")
            .map { row in Array(row) }
    }

    private let directions: [(dx: Int, dy: Int)] = [
        (0, -1),
        (1, 0),
        (0, 1),
        (-1, 0),
    ]

    private func dfs(grid: [[Character]], i: Int, j: Int) -> (
        area: Int, fences: Set<[Int]>, visited: Set<[Int]>
    ) {
        let W = grid[0].count
        let H = grid.count
        let type: Character = grid[j][i]

        var stack: [[Int]] = []  // [i, j]
        var visited: Set<[Int]> = []
        var area: Int = 0
        var fences: Set<[Int]> = []  // [i, j, direction]

        stack.append([i, j])

        while !stack.isEmpty {
            let curr = stack.popLast()!

            if visited.contains(curr) { continue }
            visited.insert(curr)

            let (i, j) = (curr[0], curr[1])

            if grid[j][i] == type {
                area += 1
            }

            // Get neighbors
            let nbrs = directions.enumerated().compactMap { di, d in
                // too lazy to turn direction into an enum, just use its index
                return (i + d.dx, j + d.dy, di)
            }
            // Count fences
            for nbr in nbrs {
                let (x, y, di) = nbr
                let inBounds = 0 <= x && x < W && 0 <= y && y < H
                if !inBounds || grid[y][x] != type {
                    fences.insert([x, y, di])
                }
            }
            // Add neighbours
            for nbr in nbrs {
                let (x, y, _) = nbr
                let inBounds = 0 <= x && x < W && 0 <= y && y < H
                if inBounds, grid[y][x] == type {
                    stack.append([x, y])
                }
            }
        }

        return (area, fences, visited)

    }

    func part1() -> Int {
        let grid = parse(self.data)
        let W = grid[0].count
        let H = grid.count
        var price: Int = 0
        var visited: Set<[Int]> = []
        for j in 0..<H {
            for i in 0..<W {
                if visited.contains([i, j]) { continue }
                let (a, fs, v) = self.dfs(grid: grid, i: i, j: j)
                price += (a * fs.count)
                visited = visited.union(v)
            }
        }
        return price
    }

    func part2() -> Int {
        let grid = parse(self.data)
        let W = grid[0].count
        let H = grid.count
        var price: Int = 0
        var visited: Set<[Int]> = []
        for j in 0..<H {
            for i in 0..<W {
                if visited.contains([i, j]) { continue }

                let (a, fs, v) = self.dfs(grid: grid, i: i, j: j)
                visited = visited.union(v)

                // scan rows and cols and count sides -- can probably use a smart
                // sorting algo but i'm lazy
                var numSides: Int = 0

                // check for horizontal fences along each row
                for dir in [0, 2] {
                    for j in -1..<H + 1 {
                        var last: [Int]? = nil
                        for i in -1..<W + 1 {
                            let fence = fs.first { $0 == [i, j, dir] }
                            if last == nil, fence != nil {
                                numSides += 1
                            }
                            last = fence
                        }
                        last = nil
                    }
                }
                // check for vertical fences along each column
                for dir in [1, 3] {
                    for i in -1..<W + 1 {
                        var last: [Int]? = nil
                        for j in -1..<H + 1 {
                            let fence = fs.first { $0 == [i, j, dir] }
                            if last == nil, fence != nil {
                                numSides += 1
                            }
                            last = fence
                        }
                        last = nil
                    }
                }

                // add em up
                price += (a * numSides)
            }
        }
        // bob's ur uncle
        return price
    }
}
