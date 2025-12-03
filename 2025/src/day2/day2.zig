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

    std.debug.print("part1: {}", .{try part1(ranges)});
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

fn part2(ranges: std.ArrayList(Range)) !usize {
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
        }
    }
    return solution;
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
