import Foundation

struct Day06: AdventDay {
    var data: String

    private let example: String = """
        ....#.....
        .........#
        ..........
        ..#.......
        .......#..
        ..........
        .#..^.....
        ........#.
        #.........
        ......#...
        """

    init(data: String) {
        self.data = data
    }

    private struct Dude: Hashable {
        var x: Int
        var y: Int
        var direction: Direction
    }

    private func parseData(data: String) -> [[Character]] {
        let grid =
            data
            .split(separator: "\n")
            .map { row in Array(row) }
        return grid
    }

    private func getDude(from grid: [[Character]]) -> Dude {
        let numRows = grid.count
        let numCols = grid[0].count
        var dude: Dude? = nil
        for j in 0..<numCols {
            for i in 0..<numRows {
                let char = grid[j][i]
                if let direction = Direction(rawValue: char) {
                    assert(dude == nil, "Can't have more than one dude in input")
                    dude = Dude(x: i, y: j, direction: direction)
                }
            }
        }
        guard let dude else { fatalError("Expected dude in input") }
        return dude
    }

    private enum Direction: Character {
        case up = "^"
        case down = "v"
        case left = "<"
        case right = ">"

        var movement: (dx: Int, dy: Int) {
            switch self {
            case .up: (0, -1)
            case .down: (0, 1)
            case .left: (-1, 0)
            case .right: (1, 0)
            }
        }

        var turnedCW: Direction {
            switch self {
            case .up: .right
            case .down: .left
            case .left: .up
            case .right: .down
            }
        }
    }

    private func iterate(grid: [[Character]], dude: Dude) -> Dude? {
        var dude = dude
        let numCols = grid[0].count
        let numRows = grid.count
        let nextPosition = (
            dude.x + dude.direction.movement.dx,
            dude.y + dude.direction.movement.dy
        )
        let (nextX, nextY) = nextPosition
        if nextX < 0 || nextX >= numCols || nextY < 0 || nextY >= numRows {
            return nil
        } else if grid[nextY][nextX] == "#" {
            dude.direction = dude.direction.turnedCW
        } else {
            dude.x = nextX
            dude.y = nextY
        }
        return dude
    }

    private func run(grid: [[Character]], dude: Dude) -> Set<Dude> {
        var dude = dude
        var visited: Set<Dude> = []
        visited.insert(dude)
        while true {
            guard let newDude = self.iterate(grid: grid, dude: dude) else {
                break
            }
            dude = newDude
            visited.insert(dude)
        }
        return visited
    }

    func part1() -> Int {
        let grid = self.parseData(data: self.data)
        let dude = self.getDude(from: grid)
        let visited = self.run(grid: grid, dude: dude)
        let uniques = visited.uniqued { [$0.x, $0.y] }
        return uniques.count
    }

    func part2() -> Int {
        let grid = self.parseData(data: self.data)
        let dude = self.getDude(from: grid)
        let visited = self.run(grid: grid, dude: dude)

        var result: Set<[Int]> = []
        for pos in visited {
            let (i, j) = (pos.x, pos.y)
            guard !(i == dude.x && j == dude.y) else { continue }
            guard grid[j][i] != "#" else { continue }

            var modifiedGrid = grid
            modifiedGrid[j][i] = "#"
            var currentDude = dude

            var alsoVisited: Set<Dude> = [currentDude]
            while true {
                guard let newDude = self.iterate(grid: modifiedGrid, dude: currentDude) else {
                    break
                }
                if alsoVisited.contains(newDude) {
                    result.insert([i, j])
                    break
                }
                currentDude = newDude
                alsoVisited.insert(currentDude)
            }
        }
        return result.count
    }
}
