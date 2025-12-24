const std = @import("std");

const Dir = struct {
    di: isize,
    dj: isize,
};

const Pos = struct { i: usize, j: usize };

const Solution = struct {
    part1: usize,
    part2: usize,
};

const NBR_DIRS: [8]Dir = .{
    Dir{ .di = -1, .dj = -1 },
    Dir{ .di = 0, .dj = -1 },
    Dir{ .di = 1, .dj = -1 },
    Dir{ .di = -1, .dj = 0 },
    Dir{ .di = 1, .dj = 0 },
    Dir{ .di = -1, .dj = 1 },
    Dir{ .di = 0, .dj = 1 },
    Dir{ .di = 1, .dj = 1 },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day4/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    const solution = try solve(alloc, input);
    std.debug.print("part1: {}\n", .{solution.part1});
    std.debug.print("part2: {}\n", .{solution.part2});
}

fn solve(alloc: std.mem.Allocator, input: []const u8) !Solution {
    var grid: std.ArrayList([]u8) = .empty;
    defer {
        // Free each individual `duped` line
        for (grid.items) |line| {
            alloc.free(line);
        }
        grid.deinit(alloc);
    }

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        const mutable_line = try alloc.dupe(u8, line);
        try grid.append(alloc, mutable_line);
    }

    return try helper(alloc, &grid);
}

fn helper(
    alloc: std.mem.Allocator,
    grid: *std.ArrayList([]u8),
) !Solution {
    const MAX_ITERS: usize = 500;

    const num_rows = grid.items.len;
    const num_cols = grid.items[0].len;

    var part1: usize = 0;
    var part2: usize = 0;

    var num_removed: usize = 0;
    var removed: std.ArrayList(Pos) = .empty;
    defer removed.deinit(alloc);

    var iters: usize = 0;
    while (iters < MAX_ITERS) {
        for (0.., grid.items) |j, row| {
            if (row.len == 0) continue;
            for (0..num_cols, row) |i, char| {
                // Only check positions containing a roll of paper
                if (char != '@') continue;

                // Check neighbours of (i, j) and count '@'s
                var count: usize = 0;
                for (NBR_DIRS) |dir| {
                    // I have no clue why these casts work
                    const nbr_i = i +% @as(usize, @bitCast(dir.di));
                    const nbr_j = j +% @as(usize, @bitCast(dir.dj));
                    if (nbr_i < num_cols and nbr_j < num_rows) {
                        // Handle trailing newline in the input
                        if (grid.items[nbr_j].len == 0) continue;
                        if (grid.items[nbr_j][nbr_i] == '@') {
                            count += 1;
                        }
                    }
                }
                if (count < 4) {
                    if (iters == 0) part1 += 1;
                    try removed.append(alloc, .{ .i = i, .j = j });
                    num_removed += 1;
                }
            }
        }

        // We're done iterating -- no further changes can be made
        if (num_removed == 0) break;

        part2 += removed.items.len;

        for (removed.items) |pos| {
            grid.items[pos.j][pos.i] = '.';
        }

        removed.clearRetainingCapacity();
        num_removed = 0;
        iters += 1;
    }

    return .{ .part1 = part1, .part2 = part2 };
}

test "example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;
    const solution = try solve(alloc, input);
    std.debug.print("part1 (example): {}\n", .{solution.part1});
    std.debug.print("part2 (example): {}\n", .{solution.part2});
    try std.testing.expectEqual(13, solution.part1);
    try std.testing.expectEqual(43, solution.part2);
}
