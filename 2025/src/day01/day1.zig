const std = @import("std");

const input_path = "input.txt";
const num_values = 100;

const Direction = enum { left, right };

const Action = union(Direction) {
    left: u16,
    right: u16,
};

pub fn main() !void {
    std.debug.print("part1: {}\n", .{try part1()});
    std.debug.print("part2: {}\n", .{try part2()});
}

fn part1() !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var actions: std.ArrayList(Action) = .empty;
    defer actions.deinit(alloc);
    try parseActions(input_path, alloc, &actions);

    var password: u64 = 0;
    var current_position: i64 = 50;
    for (actions.items) |a| {
        switch (a) {
            .left => |amount| {
                current_position = @mod(current_position - amount, num_values);
            },
            .right => |amount| {
                current_position = @mod(current_position + amount, num_values);
            },
        }
        if (current_position == 0) {
            password += 1;
        }
    }

    return password;
}

fn part2() !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var actions: std.ArrayList(Action) = .empty;
    defer actions.deinit(alloc);
    try parseActions(input_path, alloc, &actions);

    var password: u64 = 0;
    var current_position: u64 = 50;
    for (actions.items) |a| {
        switch (a) {
            .left => |amount| {
                for (0..amount) |_| {
                    current_position = @mod(current_position + num_values - 1, num_values);
                    if (current_position == 0) {
                        password += 1;
                    }
                }
            },
            .right => |amount| {
                for (0..amount) |_| {
                    current_position = @mod(current_position + 1, num_values);
                    if (current_position == 0) {
                        password += 1;
                    }
                }
            },
        }
    }

    return password;
}

// MARK: Input parsing

fn parseActions(path: []const u8, alloc: std.mem.Allocator, result: *std.ArrayList(Action)) !void {
    const contents = try contentsOf(path, alloc);
    defer alloc.free(contents);

    // Split by newlines and grab each action
    var it = std.mem.splitScalar(u8, contents, '\n');
    while (it.next()) |part| {
        if (part.len == 0) continue;

        const direction: Direction = switch (part[0]) {
            'L' => .left,
            'R' => .right,
            else => unreachable,
        };
        const amount = try std.fmt.parseInt(u16, part[1..], 10);

        const action: Action = switch (direction) {
            .left => .{ .left = amount },
            .right => .{ .right = amount },
        };
        try result.append(alloc, action);
    }
}

fn contentsOf(path: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const cwd = std.fs.cwd();
    const maxSize: u32 = 1 * 1024 * 1024; // 1MB upper limit
    const fileContents = try cwd.readFileAlloc(alloc, path, maxSize);
    return fileContents;
}
