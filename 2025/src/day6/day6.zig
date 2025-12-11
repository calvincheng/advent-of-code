const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day6/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    const part1_solution = try part1(alloc, input);
    const part2_solution = try part2(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});
    std.debug.print("part2: {}\n", .{part2_solution});
}

fn part1(alloc: std.mem.Allocator, input: []const u8) !usize {
    var operands: std.ArrayList(std.ArrayList(usize)) = .empty;
    defer {
        for (operands.items) |*inner| {
            inner.deinit(alloc);
        }
        operands.deinit(alloc);
    }

    var total: usize = 0;
    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;

        var token_iter = std.mem.tokenizeSequence(u8, line, " ");
        if (line[0] == '*' or line[0] == '+') {
            // Operators
            var i: usize = 0;
            while (token_iter.next()) |operator| {
                std.debug.assert(operator.len == 1);

                var value: usize = 0;
                for (operands.items[i].items) |operand| {
                    // check is safe since '0' doesn't exist in input
                    if (value == 0) {
                        value += operand;
                    } else {
                        switch (operator[0]) {
                            '*' => value *= operand,
                            '+' => value += operand,
                            else => unreachable,
                        }
                    }
                }

                total += value;
                i += 1;
            }
        } else {
            // Operands
            const should_init_operands = operands.items.len == 0;
            var i: usize = 0;
            while (token_iter.next()) |operand| {
                const value = try std.fmt.parseInt(usize, operand, 10);
                if (should_init_operands) {
                    var inner: std.ArrayList(usize) = .empty;
                    try inner.append(alloc, value);
                    try operands.append(alloc, inner);
                } else {
                    try operands.items[i].append(alloc, value);
                }
                i += 1;
            }
        }
    }

    return total;
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    var grid: std.ArrayList([]const u8) = .empty;
    defer grid.deinit(alloc);

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try grid.append(alloc, line);
    }

    const num_rows = grid.items.len;
    const last_index = num_rows - 1;

    var solution: usize = 0;

    for (grid.items[last_index], 0..) |char, i| {
        if (char == '*' or char == '+') {
            const nums = gatherNumbers(&grid, i);
            if (char == '*') {
                var value: usize = 1;
                for (nums) |num| {
                    if (num) |n| {
                        value *= n;
                    }
                }
                solution += value;
            } else if (char == '+') {
                var value: usize = 0;
                for (nums) |num| {
                    if (num) |n| {
                        value += n;
                    }
                }
                solution += value;
            } else {
                unreachable;
            }
        }
    }

    return solution;
}

fn gatherNumbers(
    grid: *std.ArrayList([]const u8),
    col: usize,
) [4]?usize {
    const num_rows = grid.items.len;
    const num_cols = grid.items[0].len;

    // Get start and end cols to scan through column-by-column
    const start = col;
    var end = col + 1;
    while (end < num_cols) {
        const char = grid.items[num_rows - 1][end];
        if (char == '+' or char == '*') break;
        end += 1;
    }

    // example
    // start: 10
    // end: 15
    std.debug.assert(end - start - 1 <= 4);

    var buf = [4]?usize{ null, null, null, null };

    for (start..end) |i| {
        var n: usize = 0;
        for (0..num_rows - 1) |j| {
            const char = grid.items[j][i];
            if (char == ' ') continue;
            const value = char - '0';
            n *= 10;
            n += value;
        }
        if (n != 0) {
            const index = i - start;
            buf[index] = n;
        }
    }

    return buf;
}

test "example" {
    const input =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const part1_solution = try part1(alloc, input);
    const part2_solution = try part2(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});
    std.debug.print("part2: {}\n", .{part2_solution});
    try std.testing.expectEqual(4277556, part1_solution);
    try std.testing.expectEqual(3263827, part2_solution);
}
