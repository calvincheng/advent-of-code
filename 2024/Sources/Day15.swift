import Foundation

struct Day15: AdventDay {
    var data: String

    private let example: String = """
        ########
        #..O.O.#
        ##@.O..#
        #...O..#
        #.#.O..#
        #...O..#
        #......#
        ########

        <^^>>>vv<v>>v<<
        """

    private let bigExample: String = """
        ##########
        #..O..O.O#
        #......O.#
        #.OO..O.O#
        #..O@..O.#
        #O#..O...#
        #O..O..O.#
        #.OO.O.OO#
        #....O...#
        ##########

        <vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        ><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        <<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        ^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        ^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        >^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        <><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        ^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
        """

    private enum Direction: String {
        case up = "^"
        case down = "v"
        case left = "<"
        case right = ">"

        var value: (dx: Int, dy: Int) {
            switch self {
            case .up: (0, -1)
            case .down: (0, 1)
            case .left: (-1, 0)
            case .right: (1, 0)
            }
        }
    }

    init(data: String) {
        // self.data = data
        self.data = self.bigExample
    }

    private func transform(_ grid: [[Character]]) -> [[Character]] {
        grid
            .map { row in
                row.flatMap { char in
                    switch char {
                    case "#": ["#", "#"]
                    case ".": [".", "."]
                    case "O": ["[", "]"]
                    case "@": ["@", "."]
                    default: fatalError("haha")
                    }
                }
                .map { Character($0) }
            }
    }

    private func parse(_ data: String) -> (grid: [[Character]], ds: [Direction]) {
        let splitted = data.split(separator: "\n\n")
        let gridStr = splitted[0]
        let dsStr = splitted[1]
        let grid = gridStr.split(separator: "\n").map { Array($0) }
        var ds: [Direction] = []
        for row in dsStr.split(separator: "\n") {
            for c in row {
                let d = Direction(rawValue: String(c))
                guard let d else {
                    print("reject", c)
                    fatalError()
                }
                ds.append(d)
            }
        }
        let result = (grid, ds)
        return result
    }

    private func canMove(i: Int, j: Int, dir: Direction, grid: [[Character]]) -> Bool {
        if grid[j][i] == "#" { return false }
        if grid[j][i] == "." { return false }

        let (di, dj) = dir.value
        let (I, J) = (i + di, j + dj)
        let (W, H) = (grid[0].count, grid.count)

        guard 0 <= I, I < W, 0 <= J, J < H else { return false }

        switch grid[J][I] {
        case "#": return false
        case "@": return false
        case ".": return true
        case "O":
            return self.canMove(i: I, j: J, dir: dir, grid: grid)
        case "[":
            return self.canMove(i: I, j: J, dir: dir, grid: grid)
        case "]":
            return self.canMove(i: I, j: J, dir: dir, grid: grid)

        default: fatalError("unknown")
        }
    }

    private func move(i: Int, j: Int, dir: Direction, grid: [[Character]]) -> [[Character]] {
        var newGrid = grid
        let (di, dj) = dir.value
        let (I, J) = (i + di, j + dj)
        let (W, H) = (grid[0].count, grid.count)

        guard 0 <= I, I < W, 0 <= J, J < H else { return newGrid }

        let curr = grid[j][i]
        let nbr = grid[J][I]

        switch curr {
        case "@":
            let m = { (g: inout [[Character]]) in
                g[j][i] = "."
                g[J][I] = curr
            }
            switch nbr {
            case "#": break
            case "[", "]":
                newGrid = self.move(i: I, j: J, dir: dir, grid: newGrid)
                m(&newGrid)
            case ".":
                m(&newGrid)
            default:
                fatalError("Unexpected nbr: \(nbr)")
            }
        case "[":
            let m = { (g: inout [[Character]]) in
                g[j][i] = "."
                g[j][i + 1] = "."
                g[J][I] = curr
                g[J][I + 1] = "]"
            }
            switch nbr {
            case "#": break
            case "[", "]":
                newGrid = self.move(i: I, j: J, dir: dir, grid: newGrid)
                m(&newGrid)
            case ".":
                m(&newGrid)
            default:
                fatalError("Unexpected nbr: \(nbr)")
            }
        case "]":
            let m = { (g: inout [[Character]]) in
                g[j][i] = "."
                g[j][i - 1] = "."
                g[J][I] = curr
                g[J][I - 1] = "["
            }
            switch nbr {
            case "#": break
            case "[", "]":
                newGrid = self.move(i: I, j: J, dir: dir, grid: newGrid)
                m(&newGrid)
            case ".":
                m(&newGrid)
            default:
                fatalError("Unexpected nbr: \(nbr)")
            }
        case "#": break
        case ".": break
        default:
            fatalError("B")
        }
        return newGrid
    }

    func draw(_ grid: [[Character]]) {
        grid.map { $0.map { String($0) }.joined() }.forEach { print($0) }
    }

    func find(_ grid: [[Character]]) -> (Int, Int) {
        let (W, H) = (grid[0].count, grid.count)
        for j in 0..<H {
            for i in 0..<W {
                if grid[j][i] == "@" {
                    return (i, j)
                }
            }
        }
        fatalError("A")
    }

    func part1() -> Int {
        // return 0
        let (grid, directions) = self.parse(self.data)
        var newGrid = self.transform(grid)
        self.draw(newGrid)
        for dir in directions {
            print()
            print("Move: \(dir.rawValue):")
            let (i, j) = self.find(newGrid)
            if self.canMove(i: i, j: j, dir: dir, grid: newGrid) {
                newGrid = self.move(i: i, j: j, dir: dir, grid: newGrid)
            }
            self.draw(newGrid)
        }

        var score: Int = 0
        let (W, H) = (grid[0].count, grid.count)
        for j in 0..<H {
            for i in 0..<W {
                if newGrid[j][i] == "O" {
                    score += j * 100 + i
                }
            }
        }

        return score
    }

    func part2() -> Int {
        return 0
        let (grid, directions) = self.parse(self.data)
        let thicc = self.transform(grid)

        var newGrid = thicc
        self.draw(newGrid)

        let (i, j) = self.find(newGrid)
        for d in [Direction.up, .right, .down, .left] {
            print(d.rawValue, self.canMove(i: i, j: j, dir: d, grid: newGrid))
        }

        return 0
    }
}
