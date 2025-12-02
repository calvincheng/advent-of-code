import Foundation

struct Day10: AdventDay {
    var data: String

    private let example: String = """
        89010123
        78121874
        87430965
        96549874
        45678903
        32019012
        01329801
        10456732
        """

    init(data: String) {
        self.data = data
    }

    private func gridify(_ data: String) -> [[Int]] {
        data
            .split(separator: "\n")
            .filter { !$0.isEmpty }
            .map { row in row.map { $0.wholeNumberValue! } }
    }

    private func bfs(
        grid: [[Int]],
        i: Int,
        j: Int,
        allowRepeat: Bool = false
    ) -> Int {
        let W = grid[0].count
        let H = grid.count
        var visited: Set<[Int]> = []
        var stack: [[Int]] = []
        var result: Int = 0
        stack.append([i, j])
        let directions: [(Int, Int)] = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        while !stack.isEmpty {
            let curr = stack.popLast()!
            if !allowRepeat && visited.contains(curr) { continue }

            let i = curr[0]
            let j = curr[1]
            let currValue = grid[j][i]
            visited.insert([i, j])

            if currValue == 9 {
                result += 1
                continue
            }

            for (dx, dy) in directions {
                let x = i + dx
                let y = j + dy
                if 0 <= x, x < W, 0 <= y, y < H {
                    let nbrValue = grid[y][x]
                    if nbrValue - currValue == 1 {
                        stack.append([x, y])
                    }
                }
            }
        }
        return result
    }

    func part1() -> Int {
        // classic bfs innit
        let grid = self.gridify(self.data)
        let W = grid[0].count
        let H = grid.count
        var result: Int = 0
        for j in 0..<H {
            for i in 0..<W {
                if grid[j][i] == 0 {
                    result += self.bfs(grid: grid, i: i, j: j)
                }
            }
        }
        return result
    }

    func part2() -> Int {
        // classic bfs with revisiting allowed innit
        let grid = self.gridify(self.data)
        let W = grid[0].count
        let H = grid.count
        var result: Int = 0
        for j in 0..<H {
            for i in 0..<W {
                if grid[j][i] == 0 {
                    result += self.bfs(grid: grid, i: i, j: j, allowRepeat: true)
                }
            }
        }
        return result
    }
}
