const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try contentsOf("input.txt", alloc);
    defer alloc.free(input);

    std.debug.print("part1: {}\n", .{part1(input)});
    std.debug.print("part2: {}\n", .{part2(input)});
}

fn part1(input: []const u8) usize {
    var solution: usize = 0;

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len > 0) {
            solution += findJoltage(line, 2);
        }
    }

    return solution;
}

fn part2(input: []const u8) usize {
    var solution: usize = 0;

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len > 0) {
            solution += findJoltage(line, 12);
        }
    }

    return solution;
}

fn findJoltage(line: []const u8, num_digits: u8) usize {
    var multiplier = std.math.pow(usize, 10, num_digits - 1);
    // Leave space for the remaining digits
    var start: usize = 0;
    var end: usize = line.len - (num_digits - 1);
    var joltage: u64 = 0;
    for (0..num_digits) |_| {
        const max = largest(line, start, end);
        joltage += (max.value - '0') * multiplier;
        multiplier /= 10;
        start = max.index + 1;
        end += 1;
    }

    return joltage;
}

fn largest(line: []const u8, start: usize, end: usize) struct { index: usize, value: u8 } {
    var max_i: usize = start;
    var max = line[max_i];
    for (start..end) |i| {
        const n = line[i];
        if (n > max) {
            max = n;
            max_i = i;
        }
    }
    return .{ .index = max_i, .value = max };
}

fn contentsOf(path: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const cwd = std.fs.cwd();
    const maxSize: u32 = 1 * 1024 * 1024; // 1MB upper limit
    const fileContents = try cwd.readFileAlloc(alloc, path, maxSize);
    return fileContents;
}

test "part1 example" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const solution = part1(input);
    std.debug.print("part1 (example): {}\n", .{solution});
    try std.testing.expectEqual(357, solution);
}

test "part2 example" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const solution = part2(input);
    std.debug.print("part2 (example): {}\n", .{solution});
    try std.testing.expectEqual(3121910778619, solution);
}
