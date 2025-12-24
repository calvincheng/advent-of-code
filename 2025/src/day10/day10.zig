const std = @import("std");
const combos = @import("combos.zig");
const ComboIterator = combos.ComboIterator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day10/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    const part1_solution = try part1(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});
}

fn part1(alloc: std.mem.Allocator, input: []const u8) !usize {
    var solution: usize = 0;

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;

        const goal = parseState(line);

        const buttons = try parseButtons(alloc, line);
        defer alloc.free(buttons);

        const minPresses = try bruteForce(alloc, goal, buttons);
        std.debug.print("minPresses: {}\n", .{minPresses});

        solution += minPresses;
    }

    return solution;
}

fn parseState(line: []const u8) u16 {
    if (line[0] != '[') unreachable;

    var mask: u16 = 0;
    var i: usize = 1;

    while (line[i] != ']') : (i += 1) {
        switch (line[i]) {
            '#' => {
                mask |= (@as(u16, 1) << @as(u4, @intCast(i - 1)));
            },
            '.' => {},
            else => unreachable,
        }
    }

    return mask;
}

fn parseButtons(alloc: std.mem.Allocator, line: []const u8) ![]u16 {
    var buttons: std.ArrayList(u16) = .empty;

    var i: usize = 0;
    while (i < line.len) {
        if (line[i] == '(') {
            var j = i;
            while (j < line.len) : (j += 1) {
                if (line[j] == ')') break;
            }

            var button: u16 = 0;
            var tokens = std.mem.tokenizeScalar(u8, line[i + 1 .. j], ',');
            while (tokens.next()) |token| {
                const position = try std.fmt.parseInt(usize, token, 10);
                button |= (@as(u16, 1) << @as(u4, @intCast(position)));
            }

            try buttons.append(alloc, button);
            i = j;
        }
        i += 1;
    }

    return try buttons.toOwnedSlice(alloc);
}

fn bruteForce(alloc: std.mem.Allocator, goal: u16, buttons: []const u16) !usize {
    const n = buttons.len;

    for (1..buttons.len + 1) |k| {
        var iter = try ComboIterator.init(alloc, n, k);
        defer iter.deinit(alloc);

        const combo = try alloc.alloc(usize, k);
        defer alloc.free(combo);

        while (iter.next(combo)) {
            var state: u16 = 0;
            for (combo) |i| state ^= buttons[i];
            if (state == goal) {
                return k;
            }
        }
    }

    return 0;
}

test "example" {
    const input =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;

    const alloc = std.testing.allocator;

    var part1_solution: usize = 0;

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        const goal = parseState(line);
        std.debug.print("goal: {b}\n", .{goal});

        const buttons = try parseButtons(alloc, line);
        defer alloc.free(buttons);

        std.debug.print("buttons: ", .{});
        for (buttons) |button| {
            std.debug.print("{b} ", .{button});
        }
        std.debug.print("\n", .{});

        const solution = try bruteForce(alloc, goal, buttons);
        std.debug.print("solution: {}\n", .{solution});

        part1_solution += solution;
    }
    std.debug.print("part1: {}\n", .{part1_solution});
}
