import Foundation

struct Day14: AdventDay {
    var data: String

    private let example: String = """
        p=0,4 v=3,-3
        p=6,3 v=-1,-3
        p=10,3 v=-1,2
        p=2,0 v=2,-1
        p=0,0 v=1,3
        p=3,0 v=-2,-2
        p=7,6 v=-1,-3
        p=3,0 v=-1,-2
        p=9,3 v=2,3
        p=7,3 v=-1,2
        p=2,4 v=2,-3
        p=9,5 v=-3,-3
        """

    init(data: String) {
        self.data = data
    }

    private typealias Robot = ((Int, Int), (Int, Int))
    private let W: Int = 101
    private let H: Int = 103

    private func parse(_ data: String) -> [Robot] {
        let lines = data.split(separator: "\n")
        return lines.map { line in
            let matches = line.matches(of: /-?\d+/)
            let nums = matches.map(\.output).map { Int($0)! }
            return ((nums[0], nums[1]), (nums[2], nums[3]))
        }
    }

    private func step(robots: [Robot], by time: Int = 1) -> [Robot] {
        let movedRobots = robots.map { robot in
            let ((x, y), (u, v)) = robot
            var newX = (x + (u * time)) % W
            if newX < 0 { newX += W }
            var newY = (y + (v * time)) % H
            if newY < 0 { newY += H }
            return ((newX, newY), (u, v))
        }
        return movedRobots
    }

    private func display(robots: [Robot]) {
        var grid: [[Int]] = Array(
            repeating: Array(repeating: 0, count: W),
            count: H
        )
        for robot in robots {
            let ((x, y), _) = robot
            grid[y][x] += 1
        }
        let toPrint =
            grid
            .map { row in
                row.map { $0 == 0 ? " " : String($0) }.joined()
            }
        toPrint.forEach { print($0) }
    }

    func part1() -> Int {
        let numSeconds: Int = 100

        let robots = self.parse(self.data)
        let movedRobots = self.step(robots: robots, by: numSeconds)

        let (q1, q2, q3, q4) =
            movedRobots
            .reduce(into: (0, 0, 0, 0)) { result, robot in
                let ((x, y), _) = robot
                switch (x, y) {
                case (0..<W / 2, 0..<H / 2):
                    result.0 += 1
                case ((W / 2 + 1)..<W, 0..<H / 2):
                    result.1 += 1
                case ((W / 2 + 1)..<W, (H / 2 + 1)..<H):
                    result.2 += 1
                case (0..<W / 2, (H / 2 + 1)..<H):
                    result.3 += 1
                case (W / 2, _), (_, H / 2):
                    break
                default:
                    fatalError("Received out-of-bounds robot: \(robot)")
                }
            }

        return q1 * q2 * q3 * q4
    }

    func part2() -> Int {
        var robots = self.parse(self.data)
        for i in 0..<10000 {
            print("TIME = \(i) ====================================================")
            self.display(robots: robots)
            print()
            robots = self.step(robots: robots, by: 1)
        }
        return 0
    }
}
