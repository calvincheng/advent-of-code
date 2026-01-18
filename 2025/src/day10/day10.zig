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

    const part2_solution = try part2(alloc, input);
    std.debug.print("part2: {}\n", .{part2_solution});
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
        solution += minPresses;
    }

    return solution;
}

// Basically a system of linear equations:
//   Ax = b
//   A^-1 A x = A^-1 b
//   Ix = A^-1 b
// Can't really be bothered to write my own solver though...
fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    var solution: usize = 0;

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;

        const joltage = try parseJoltage(alloc, line);
        defer alloc.free(joltage);
        const buttons = try parseButtons(alloc, line);
        defer alloc.free(buttons);

        const presses = try solveJoltage(alloc, joltage, buttons);

        solution += presses;
    }

    return solution;
}

fn parseState(line: []const u8) u16 {
    const start: usize = std.mem.indexOfScalarPos(u8, line, 0, '[') orelse unreachable;
    const end: usize = std.mem.indexOfScalarPos(u8, line, start + 1, ']') orelse unreachable;
    const state = line[start + 1 .. end];

    var mask: u16 = 0;
    for (state, 0..) |char, i| {
        if (char == '#') {
            mask |= (@as(u16, 1) << @as(u4, @intCast(i)));
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

fn parseJoltage(alloc: std.mem.Allocator, line: []const u8) ![]u16 {
    var joltage: std.ArrayList(u16) = .empty;

    const start: usize = std.mem.indexOfScalarPos(u8, line, 0, '{') orelse unreachable;
    const end: usize = std.mem.indexOfScalarPos(u8, line, start + 1, '}') orelse unreachable;

    var tokens = std.mem.splitScalar(u8, line[start + 1 .. end], ',');
    while (tokens.next()) |token| {
        const value = try std.fmt.parseInt(u16, token, 10);
        try joltage.append(alloc, value);
    }

    return try joltage.toOwnedSlice(alloc);
}

fn bruteForce(alloc: std.mem.Allocator, goal: u16, buttons: []const u16) !usize {
    const n = buttons.len;
    for (1..n + 1) |k| {
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

const JoltageAndCombo = struct {
    joltage: []const u16,
    combo: []const usize,

    fn deinit(self: *JoltageAndCombo, alloc: std.mem.Allocator) void {
        alloc.free(self.joltage);
        // Don't free `combo` since it's owned by something else
    }
};

// Thank you @tenthmascot:
// https://old.reddit.com/r/adventofcode/comments/1pk87hl/2025_day_10_part_2_bifurcate_your_way_to_victory/
// Footgun -- need to handle cases where applying a button still yields an 'allEven' result
fn solveJoltage(alloc: std.mem.Allocator, joltage: []const u16, buttons: []const u16) !usize {
    // Step 0 -- base case
    if (allZeros(joltage)) return 0;

    // Step 1 -- map joltage to odd/even (odd = 1, even = 0)
    const goal: u16 = blk: {
        var mask: u16 = 0;
        for (joltage, 0..) |jolt, i| {
            if (@mod(jolt, 2) == 1) {
                const stamp = @as(u16, 1) << @as(u4, @intCast(i));
                mask |= stamp;
            }
        }
        break :blk mask;
    };

    // Step 2 -- brute force for combinations of buttons that achieve `goal`
    var valid_combos: std.ArrayList([]usize) = .empty;
    defer {
        for (valid_combos.items) |c| alloc.free(c);
        valid_combos.deinit(alloc);
    }

    if (goal == 0) {
        try valid_combos.append(alloc, try alloc.alloc(usize, 0));
    }

    const n = buttons.len;
    for (1..n + 1) |k| {
        var iter = try ComboIterator.init(alloc, n, k);
        defer iter.deinit(alloc);
        const combo = try alloc.alloc(usize, k);
        defer alloc.free(combo);

        while (iter.next(combo)) {
            var state: u16 = 0;
            for (combo) |i| state ^= buttons[i];
            if (state == goal) {
                const copy = try alloc.dupe(usize, combo);
                try valid_combos.append(alloc, copy);
            }
        }
    }

    if (valid_combos.items.len == 0) {
        // No valid combos
        return 1_000_000;
    }

    // Step 3 -- reduce `goal` by combo
    var joltage_and_combos: std.ArrayList(JoltageAndCombo) = .empty;
    defer {
        for (joltage_and_combos.items) |*jnc| jnc.deinit(alloc);
        joltage_and_combos.deinit(alloc);
    }

    for (valid_combos.items) |combo| {
        var current = try alloc.dupe(u16, joltage);
        var is_valid = true;
        for (combo) |i| {
            const button = buttons[i];
            for (0..16) |j| {
                const mask = @as(u16, 1) << @as(u4, @intCast(j));
                if (button & mask == 0) continue;
                if (current[j] > 0) {
                    current[j] -= 1;
                } else {
                    is_valid = false;
                    break;
                }
            }
        }

        // Step 3.5 -- divide by 2 (end result must be even at this point)
        if (is_valid) {
            for (0..current.len) |i| current[i] /= 2;
            try joltage_and_combos.append(alloc, JoltageAndCombo{ .joltage = current, .combo = combo });
        } else {
            alloc.free(current);
        }
    }

    // Step 4 -- Recurse
    var best_presses: usize = 1_000_000;
    for (joltage_and_combos.items) |jnc| {
        const result = try solveJoltage(alloc, jnc.joltage, buttons);

        const P = result;
        const C = jnc.combo.len;

        const presses = 2 * P + C;
        if (presses < best_presses) {
            best_presses = presses;
        }
    }

    return best_presses;
}

fn allZeros(joltage: []const u16) bool {
    for (joltage) |j| {
        if (j != 0) return false;
    }
    return true;
}

fn printButton(button: u16) void {
    std.debug.print("(", .{});
    var num_printed: usize = 0;
    for (0..16) |j| {
        const mask = @as(u16, 1) << @as(u4, @intCast(j));
        if (button & mask != 0) {
            if (num_printed > 0) std.debug.print(", ", .{});
            std.debug.print("{}", .{j});
            num_printed += 1;
        }
    }
    std.debug.print(")", .{});
}

test "example" {
    const input =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;

    const alloc = std.testing.allocator;

    var part1_solution: usize = 0;
    var part2_solution: usize = 0;

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        const goal = parseState(line);

        const buttons = try parseButtons(alloc, line);
        defer alloc.free(buttons);

        const joltage = try parseJoltage(alloc, line);
        defer alloc.free(joltage);

        part1_solution += try bruteForce(alloc, goal, buttons);

        const result = try solveJoltage(alloc, joltage, buttons);
        part2_solution += result;
    }

    std.debug.print("part1: {}\n", .{part1_solution});
    std.debug.print("part2: {}\n", .{part2_solution});
    try std.testing.expectEqual(7, part1_solution);
    try std.testing.expectEqual(33, part2_solution);
}

// NOTE: Things to read up on:
//   * GF(2) (i.e. Galois Fields)
//   * Branch and Bound algorithms
