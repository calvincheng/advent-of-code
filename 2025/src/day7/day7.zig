const std = @import("std");

const Cell = union(enum) { source, splitter, stream: u64, empty };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day7/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    const part1_solution = try part1(alloc, input);
    const part2_solution = try part2(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});
    std.debug.print("part2: {}\n", .{part2_solution});
}

fn part1(alloc: std.mem.Allocator, input: []const u8) !usize {
    var grid: std.ArrayList([]u8) = .empty;
    defer {
        for (grid.items) |row| {
            alloc.free(row);
        }
        grid.deinit(alloc);
    }

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try grid.append(alloc, try alloc.dupe(u8, line));
    }

    const num_rows = grid.items.len;
    const num_cols = grid.items[0].len;
    std.debug.print("num_rows: {}\n", .{num_rows});
    std.debug.print("num_cols: {}\n", .{num_cols});

    var num_splits: usize = 0;

    // Just iterate, nothing fancy
    for (grid.items, 0..) |row, j| {
        // defer std.debug.print("{s}\n", .{grid.items[j]});
        if (j == 0) continue;

        for (row, 0..) |_, i| {
            const current = grid.items[j][i];
            const above = grid.items[j - 1][i];
            // std.debug.print("{any}\n", .{@TypeOf(above)});
            // std.debug.print("{any}\n", .{above});
            if (above == 'S') {
                grid.items[j][i] = '|';
            } else if (current == '^' and above == '|') {
                // NOTE: don't think we need bounds check
                grid.items[j][i - 1] = '|';
                grid.items[j][i + 1] = '|';
                num_splits += 1;
            } else if (current == '.' and above == '|') {
                grid.items[j][i] = '|';
            }
        }
    }

    return num_splits;
}

fn isStream(cell: Cell) bool {
    return switch (cell) {
        .stream => true,
        .source => true, // treat source as a stream start
        else => false,
    };
}

fn streamValue(cell: Cell) u64 {
    // std.debug.assert(isStream(c));
    switch (cell) {
        .source => return 1,
        .stream => |value| return value,
        .empty => return 0,
        .splitter => return 0,
    }
    unreachable;
}

fn toCell(c: u8) Cell {
    switch (c) {
        '^' => return .splitter,
        'S' => return .source,
        '|' => return Cell{ .stream = 1 },
        '.' => return .empty,
        else => unreachable,
    }
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    var grid: std.ArrayList([]Cell) = .empty;
    defer {
        for (grid.items) |row| {
            alloc.free(row);
        }
        grid.deinit(alloc);
    }

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        const row = try alloc.alloc(Cell, line.len);
        for (line, 0..) |char, k| {
            row[k] = toCell(char);
        }
        try grid.append(alloc, row);
        // try grid.append(alloc, try alloc.dupe(u8, line));
    }

    const num_rows = grid.items.len;

    // Just iterate, nothing fancy
    for (grid.items, 0..) |row, j| {
        // defer std.debug.print("{any}\n", .{grid.items[j]});
        if (j == 0) continue;

        for (row, 0..) |_, i| {
            const current = grid.items[j][i];
            const above = grid.items[j - 1][i];
            if (above == .source) {
                grid.items[j][i] = Cell{ .stream = 1 };
            } else if (current == .splitter and isStream(above)) {
                const leftVal = streamValue(grid.items[j][i - 1]) + streamValue(above);
                grid.items[j][i - 1] = Cell{ .stream = leftVal };
                const rightVal = streamValue(grid.items[j][i + 1]) + streamValue(above);
                grid.items[j][i + 1] = Cell{ .stream = rightVal };
            } else if (current != .splitter and isStream(above)) { // tricky
                const val = streamValue(grid.items[j][i]) + streamValue(above);
                grid.items[j][i] = Cell{ .stream = val };
            }
        }
    }

    // try printEncodedGrid(grid);

    var num_paths: usize = 0;
    for (grid.items[num_rows - 1]) |c| {
        num_paths += streamValue(c);
    }

    return num_paths;
}

fn printEncodedGrid(list: std.ArrayList([]u8)) !void {
    for (list.items) |row| {
        for (row) |cell| {
            var char_to_print: u8 = undefined;
            switch (cell) {
                46 => char_to_print = '.',
                83 => char_to_print = 'S',
                94 => char_to_print = '^',
                // Handle digits 0-9
                0...9 => char_to_print = cell + '0',
                else => char_to_print = cell,
            }
            std.debug.print("{c}", .{char_to_print});
        }
        std.debug.print("\n", .{});
    }
}

test "example" {
    const input =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const part1_solution = try part1(alloc, input);
    const part2_solution = try part2(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});
    std.debug.print("part2: {}\n", .{part2_solution});

    try std.testing.expectEqual(21, part1_solution);
    try std.testing.expectEqual(40, part2_solution);
}
