const std = @import("std");

const Machine = struct {
    state: u8,
    buttons: std.ArrayList(u8),
    joltage: std.ArrayList(u8),

    fn init() Machine {
        return Machine{
            .state = 0,
            .buttons = .empty,
            .joltage = .empty,
        };
    }

    fn deinit(self: *Machine, alloc: std.mem.Allocator) void {
        self.buttons.deinit(alloc);
        self.joltage.deinit(alloc);
    }
};

fn parseLine(alloc: std.mem.Allocator, line: []const u8) !Machine {
    var machine = Machine.init();

    var it = std.mem.tokenizeAny(u8, line, " \t\n");
    while (it.next()) |tok| {
        if (tok.len == 0) continue;

        switch (tok[0]) {
            '[' => { // parse initial state
                for (1..tok.len - 1) |i| {
                    const c = tok[i];
                    if (c == '#') {
                        machine.state |= @as(u8, 1) << @intCast(i);
                    }
                }
            },
            '(' => { // parse mask
                var mask: u8 = 0;
                var subtok = std.mem.tokenizeAny(u8, tok[1 .. tok.len - 1], ",");
                while (subtok.next()) |numtok| {
                    const pos = try std.fmt.parseInt(u8, numtok, 10);
                    mask |= @as(u8, 1) << @intCast(pos);
                }
                try machine.buttons.append(alloc, mask);
            },
            '{' => { // parse numbers
                var subtok = std.mem.tokenizeAny(u8, tok[1 .. tok.len - 1], ",");
                while (subtok.next()) |numtok| {
                    const val = try std.fmt.parseInt(u8, numtok, 10);
                    try machine.joltage.append(alloc, val);
                }
            },
            else => {},
        }
    }

    // Debug print
    std.debug.print("Desired state: {b:0>8}\n", .{machine.state});
    for (machine.buttons.items) |m| {
        std.debug.print("Button: {b:0>8}\n", .{m});
    }
    for (machine.joltage.items) |n| {
        std.debug.print("Joltage: {}\n", .{n});
    }

    return machine;
}

test "example" {
    const input =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var machines: std.ArrayList(Machine) = .empty;
    defer {
        for (machines.items) |*m| {
            m.deinit(alloc);
        }
        machines.deinit(alloc);
    }

    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        const machine = try parseLine(alloc, line);
        try machines.append(alloc, machine);
    }
}
