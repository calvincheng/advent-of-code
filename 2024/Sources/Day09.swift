import Foundation

struct Day09: AdventDay {
    var data: String

    private let example: String = "2333133121414131402"

    init(data: String) {
        self.data = data
    }

    private func expand(data: String) -> [Bit] {
        var result: [Bit] = []
        for (idx, char) in data.enumerated() {
            guard let count = char.wholeNumberValue else {
                print("Unexpected char: \(char.debugDescription)")
                continue
            }
            if idx % 2 == 0 {
                // file space
                let fileID: Int = idx / 2
                result += Array(repeating: Bit.taken(fileID), count: count)
            } else {
                // free space
                result += Array(repeating: Bit.free, count: count)
            }
        }
        return Array(result)
    }

    enum Bit: CustomDebugStringConvertible, Equatable {
        case free
        case taken(Int)  // ID

        var debugDescription: String {
            switch self {
            case .free: "."
            case let .taken(id): String(id)
            }
        }

        var id: Int {
            switch self {
            case .free: fatalError("No id")
            case let .taken(id): id
            }
        }
    }

    enum CompactBit: CustomDebugStringConvertible {
        case free(size: Int)
        case taken(id: Int, size: Int)

        var debugDescription: String {
            switch self {
            case .free: String(repeating: ".", count: self.size)
            case let .taken(id, _): String(repeating: String(id), count: self.size)
            }
        }

        var size: Int {
            switch self {
            case let .free(size): size
            case let .taken(_, size): size
            }
        }
    }

    private func compact(bits: [Bit]) -> [CompactBit] {
        var result: [CompactBit] = []
        var buffer: [Bit] = []
        for (idx, bit) in bits.enumerated() {
            if idx == 0 {
                buffer.append(bit)
            } else {
                let prevBit = bits[idx - 1]
                switch (prevBit, bit) {
                case (.free, .free):
                    buffer.append(bit)
                case let (.taken(id1), .taken(id2)):
                    if id1 == id2 {
                        buffer.append(bit)
                    } else {
                        result.append(CompactBit.taken(id: id1, size: buffer.count))
                        buffer = []
                        buffer.append(bit)
                    }
                case (.free, .taken):
                    result.append(CompactBit.free(size: buffer.count))
                    buffer = []
                    buffer.append(bit)
                case let (.taken(id), .free):
                    result.append(CompactBit.taken(id: id, size: buffer.count))
                    buffer = []
                    buffer.append(bit)
                }
            }
        }
        if !buffer.isEmpty {
            switch buffer.last! {
            case .free:
                result.append(CompactBit.free(size: buffer.count))
            case let .taken(id):
                result.append(CompactBit.taken(id: id, size: buffer.count))
            }
        }
        return result
    }

    func part1() -> Int {
        let expanded = self.expand(data: self.data)
        var i: Int = 0
        var j: Int = expanded.count
        var checksum: Int = 0
        while i < j {
            switch expanded[i] {
            case .free:
                j -= 1
                while expanded[j] == .free {
                    j -= 1
                }
                checksum += i * expanded[j].id
            case let .taken(id):
                checksum += i * id
            }
            i += 1
        }
        return checksum
    }

    func part2() -> Int {
        var compacted = self.compact(bits: self.expand(data: self.data))
        // print(compacted.map(\.debugDescription).joined())
        var j = compacted.count - 1
        while j > 0 {
            switch compacted[j] {
            case let .taken(_, size):
                // print("finding space for", compacted[j], "at", j)
                // find a free chunk
                var freeChunkIdx: Int? = nil
                var freeChunk: CompactBit? = nil
                for (idx, bit) in compacted.enumerated() {
                    if case let .free(freeSize) = bit, freeSize >= size {
                        freeChunkIdx = idx
                        freeChunk = bit
                        break
                    }
                }
                guard let freeChunkIdx, let freeChunk, freeChunkIdx < j else {
                    j -= 1
                    break
                }
                // print("found \(freeChunk) at \(freeChunkIdx)")
                if freeChunk.size > size {
                    compacted[freeChunkIdx] = compacted[j]
                    compacted[j] = .free(size: size)
                    compacted.insert(
                        .free(size: freeChunk.size - size),
                        at: freeChunkIdx + 1
                    )
                } else if freeChunk.size == size {
                    // Simple swap
                    compacted[freeChunkIdx] = compacted[j]
                    compacted[j] = freeChunk
                } else {
                    fatalError("wtf")
                }
            case .free:
                j -= 1
            }
            // print(j, compacted.map(\.debugDescription).joined())
        }

        var checksum: Int = 0
        var i: Int = 0
        for bit in compacted {
            switch bit {
            case let .taken(id, size):
                for _ in 0..<size {
                    checksum += (i * id)
                    i += 1
                }
            case let .free(size):
                for _ in 0..<size {
                    i += 1
                }
                continue
            }
        }

        return checksum
    }
}

/// Notes
/// =====
/// - part 2 took way longer than expected, was too dead-set on manpulating
/// pointers
/// - in hindsight i can probably also use CompactBit for part 1, but with
/// `size` set to 1 for all bits
/// - part 2 still takes a while to run, i wonder which part is slow
