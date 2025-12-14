const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day9/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    const part1_solution = try part1(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});
}

fn part1(alloc: std.mem.Allocator, input: []const u8) !usize {
    var locations: std.ArrayList([2]usize) = .empty;
    defer locations.deinit(alloc);

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.indexOf(u8, line, ",")) |commaIndex| {
            const x = try std.fmt.parseInt(usize, line[0..commaIndex], 10);
            const y = try std.fmt.parseInt(usize, line[commaIndex + 1 ..], 10);
            const location = [2]usize{ x, y };
            try locations.append(alloc, location);
        }
    }

    var best: usize = 0;
    for (locations.items, 0..) |locationA, i| {
        for (locations.items[i..]) |locationB| {
            best = @max(best, area(locationA, locationB));
        }
    }

    return best;
}

fn area(a: [2]usize, b: [2]usize) usize {
    const dx = if (a[0] > b[0]) a[0] - b[0] else b[0] - a[0];
    const dy = if (a[1] > b[1]) a[1] - b[1] else b[1] - a[1];
    return (dx + 1) * (dy + 1);
}

test "example" {
    const input =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const part1_solution = try part1(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});

    try std.testing.expectEqual(50, part1_solution);
}
