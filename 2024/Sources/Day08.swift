import Foundation

struct Day08: AdventDay {
    var data: String

    private let example: String = """
        ............
        ........0...
        .....0......
        .......0....
        ....0.......
        ......A.....
        ............
        ............
        ........A...
        .........A..
        ............
        ............
        """

    init(data: String) {
        self.data = data
    }

    private struct Position: Hashable, CustomStringConvertible {
        let x: Int
        let y: Int
        var description: String { "(\(x) \(y))" }
    }

    private func parse(data: String) -> [Character: [Position]] {
        let grid =
            data
            .split(separator: "\n")
            .map { row in Array(row) }

        let W = grid[0].count
        let H = grid.count
        var map: [Character: [Position]] = [:]
        for j in 0..<H {
            for i in 0..<W {
                let char = grid[j][i]
                if char != "." {
                    if map[char] == nil {
                        map[char] = []
                    }
                    map[char]!.append(Position(x: i, y: j))
                }
            }
        }

        return map
    }

    func part1() -> Int {
        let pylons = parse(data: self.data)

        let grid =
            data
            .split(separator: "\n")
            .map { row in Array(row) }
        let W = grid[0].count
        let H = grid.count

        var antinodes: Set<Position> = []
        // brute force again
        for (_, locations) in pylons {
            for l in locations {
                var dists: [(dx: Int, dy: Int)] = []
                for ll in locations {
                    if l == ll { continue }
                    dists.append((dx: ll.x - l.x, dy: ll.y - l.y))
                }
                for (dx, dy) in dists {
                    let x = l.x - dx
                    let y = l.y - dy
                    if 0 <= x, x < W, 0 <= y, y < H {
                        let antinode = Position(x: x, y: y)
                        // if !allLocations.contains(antinode) {
                        antinodes.insert(antinode)
                        // }
                    }
                }
            }
        }
        return antinodes.count
    }

    func part2() -> Int {
        let pylons = parse(data: self.data)

        let grid =
            data
            .split(separator: "\n")
            .map { row in Array(row) }
        let W = grid[0].count
        let H = grid.count

        var antinodes: Set<Position> = []
        // brute force again
        for (_, locations) in pylons {
            for l in locations {
                var dists: [(dx: Int, dy: Int)] = []
                for ll in locations {
                    if l == ll { continue }
                    dists.append((dx: ll.x - l.x, dy: ll.y - l.y))
                }
                for (dx, dy) in dists {
                    for multiple in -200..<200 {  // lazy, should be big enough
                        let x = l.x - (dx * multiple)
                        let y = l.y - (dy * multiple)
                        if 0 <= x, x < W, 0 <= y, y < H {
                            let antinode = Position(x: x, y: y)
                            antinodes.insert(antinode)
                        } else {
                            continue
                        }
                    }
                }
            }
        }
        return antinodes.count
    }
}
