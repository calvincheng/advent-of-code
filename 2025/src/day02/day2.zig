const std = @import("std");

const Range = struct {
    lower: u64,
    upper: u64,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(alloc);
    try parseRanges("input.txt", alloc, &ranges);

    std.debug.print("part1: {}\n", .{try part1(ranges)});
    std.debug.print("part2: {}\n", .{try part2(ranges, alloc)});
}

fn part1(ranges: std.ArrayList(Range)) !usize {
    var solution: usize = 0;
    for (ranges.items) |r| {
        for (r.lower..r.upper + 1) |id| {
            const num_digits = std.math.log10_int(id) + 1;
            if (@mod(num_digits, 2) != 0) continue;

            const half = std.math.pow(usize, 10, num_digits / 2);
            const left = @divTrunc(id, half);
            const right = @mod(id, half);

            if (left == right) {
                solution += id;
            }

            // NOTE: This was the slow method that used string conversion
            //
            // const id_str = try std.fmt.allocPrint(alloc, "{}", .{id});
            // defer alloc.free(id_str);
            //
            // const mid = id_str.len / 2;
            // const is_invalid = std.mem.eql(u8, id_str[0..mid], id_str[mid..]);
            // if (is_invalid) {
            //     std.debug.print("{s}\n", .{id_str});
            //     solution += id;
            // }
        }
    }
    return solution;
}

fn part2(ranges: std.ArrayList(Range), alloc: std.mem.Allocator) !usize {
    var chunks: std.ArrayList(usize) = .empty;
    defer chunks.deinit(alloc);

    var solution: usize = 0;
    for (ranges.items) |r| {
        for (r.lower..r.upper + 1) |id| {
            const num_digits = std.math.log10_int(id) + 1;
            for (1..num_digits / 2 + 1) |chunk_size| {
                // Reuse array to avoid reallocating memory
                chunks.clearRetainingCapacity();

                try getChunks(id, chunk_size, alloc, &chunks);

                if (chunks.items.len <= 0) continue;

                var isRepeated = true;
                var lastChunk: ?usize = null;
                for (chunks.items) |chunk| {
                    if (lastChunk != null and lastChunk != chunk) {
                        isRepeated = false;
                        break;
                    }
                    lastChunk = chunk;
                }
                if (isRepeated) {
                    // std.debug.print("{} REPEATED ({}) \n", .{id, lastChunk orelse unreachable});
                    solution += id;
                    break;
                }
            }
        }
    }
    return solution;
}

fn getChunks(x: usize, chunk_size: usize, alloc: std.mem.Allocator, result: *std.ArrayList(usize)) !void {
    const num_digits = std.math.log10_int(x) + 1;
    if (chunk_size >= num_digits) return;
    if (@mod(num_digits, chunk_size) != 0) return;

    const num_chunks = num_digits / chunk_size;
    if (num_chunks <= 1) return;

    for (0..num_chunks) |n| {
        const c = num_chunks - 1 - n;
        const right_pad = c * chunk_size;
        const right_div = std.math.pow(usize, 10, right_pad);
        const left_div = std.math.pow(usize, 10, chunk_size);
        const chunk = @mod(@divTrunc(x, right_div), left_div);

        try result.append(alloc, chunk);
    }
}

fn parseRanges(path: []const u8, alloc: std.mem.Allocator, result: *std.ArrayList(Range)) !void {
    const contents = try contentsOf(path, alloc);
    defer alloc.free(contents);

    // Split by commas and grab each range
    var range_iter = std.mem.splitScalar(u8, contents, ',');
    while (range_iter.next()) |raw_str| {
        const range_str = std.mem.trim(u8, raw_str, " \r\n\t");

        if (range_str.len < 3) continue;
        const i = std.mem.indexOf(u8, range_str, "-") orelse continue;

        const lower = try std.fmt.parseInt(u64, range_str[0..i], 10);
        const upper = try std.fmt.parseInt(u64, range_str[i + 1 ..], 10);
        const range = Range{ .lower = lower, .upper = upper };
        try result.append(alloc, range);
    }
}

fn contentsOf(path: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const cwd = std.fs.cwd();
    const maxSize: u32 = 1 * 1024 * 1024; // 1MB upper limit
    const fileContents = try cwd.readFileAlloc(alloc, path, maxSize);
    return fileContents;
}

test "chunking" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var chunks: std.ArrayList(usize) = .empty;
    defer chunks.deinit(alloc);

    const x = 123456789;
    const chunk_size = 3;
    try getChunks(x, chunk_size, alloc, &chunks);

    try std.testing.expectEqualSlices(usize, chunks.items, &.{ 123, 456, 789 });
}
