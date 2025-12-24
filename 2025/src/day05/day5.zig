const std = @import("std");

const Range = struct {
    lower: usize,
    upper: usize,

    fn lessThan(_: void, lhs: Range, rhs: Range) bool {
        return lhs.lower < rhs.lower;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day5/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    std.debug.print("part1: {}\n", .{try part1(alloc, input)});
    std.debug.print("part2: {}\n", .{try part2(alloc, input)});
}

fn part1(alloc: std.mem.Allocator, input: []const u8) !usize {
    return try countFresh(alloc, input);
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    return try countFreshRange(alloc, input);
}

fn countFresh(alloc: std.mem.Allocator, input: []const u8) !usize {
    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(alloc);

    var num_fresh: usize = 0;
    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;

        if (std.mem.indexOf(u8, line, "-")) |i| {
            // Range
            const lower = try std.fmt.parseInt(usize, line[0..i], 10);
            const upper = try std.fmt.parseInt(usize, line[i + 1 ..], 10);
            const range = Range{ .lower = lower, .upper = upper };
            try ranges.append(alloc, range);
        } else {
            // Ingredient
            // (at this point all the ranges have been parsed)
            const num = try std.fmt.parseInt(usize, line, 10);
            for (ranges.items) |range| {
                if (num >= range.lower and num <= range.upper) {
                    num_fresh += 1;
                    break;
                }
            }
        }
    }

    return num_fresh;
}

fn countFreshRange(alloc: std.mem.Allocator, input: []const u8) !usize {
    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(alloc);

    // Populate ranges
    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.indexOf(u8, line, "-")) |i| {
            const lower = try std.fmt.parseInt(usize, line[0..i], 10);
            const upper = try std.fmt.parseInt(usize, line[i + 1 ..], 10);
            const range = Range{ .lower = lower, .upper = upper };
            try ranges.append(alloc, range);
        }
    }

    // Sort in order of ascending `.lower`
    std.mem.sort(Range, ranges.items, {}, Range.lessThan);

    // Merge ranges together
    var merged: std.ArrayList(Range) = .empty;
    defer merged.deinit(alloc);
    for (ranges.items) |curr| {
        if (merged.items.len > 0) {
            const prev_index = merged.items.len - 1;
            const prev = merged.items[prev_index];
            if (curr.lower <= prev.upper) {
                merged.items[prev_index].upper = @max(curr.upper, prev.upper);
            } else {
                try merged.append(alloc, curr);
            }
        } else {
            try merged.append(alloc, curr);
        }
    }

    // Tally up total fresh ingredients from merged ranges
    var num_fresh: usize = 0;
    for (merged.items) |range| {
        num_fresh += (range.upper - range.lower + 1);
    }

    return num_fresh;
}

test "example" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const num_fresh = try countFresh(alloc, input);
    const fresh_total = try countFreshRange(alloc, input);
    std.debug.print("part1: {}\n", .{num_fresh});
    std.debug.print("part2: {}\n", .{fresh_total});
    try std.testing.expectEqual(3, num_fresh);
    try std.testing.expectEqual(14, fresh_total);
}
