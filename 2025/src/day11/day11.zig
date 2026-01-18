const std = @import("std");
const Id = [3]u8;
const AdjList = std.AutoHashMap(Id, []Id);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day11/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    var adj_list = try buildAdjList(alloc, input);
    defer {
        var values = adj_list.valueIterator();
        while (values.next()) |v| alloc.free(v.*);
        adj_list.deinit();
    }

    const part1 = try countPaths(alloc, adj_list, "you".*, "out".*, false);
    std.debug.print("part1: {}\n", .{part1});
    const part2 = try countPathsRecursive(alloc, adj_list, "svr".*, "out".*, true);
    std.debug.print("part2: {}\n", .{part2});
}

fn buildAdjList(
    alloc: std.mem.Allocator,
    input: []const u8,
) !AdjList {
    var adj_list = std.AutoHashMap(Id, []Id).init(alloc);
    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const result = try parseLine(alloc, line);
        try adj_list.put(result.source, result.dests);
    }

    return adj_list;
}

fn parseLine(
    alloc: std.mem.Allocator,
    line: []const u8,
) !struct { source: Id, dests: []Id } {
    std.debug.assert(line.len > 3);

    var source: Id = undefined;
    @memcpy(source[0..], line[0..3]);

    var dests: std.ArrayList(Id) = .empty;
    defer dests.deinit(alloc);

    var dest_iter = std.mem.splitScalar(u8, line[5..], ' ');
    while (dest_iter.next()) |dest| {
        var id: Id = undefined;
        std.debug.assert(dest.len == 3);
        @memcpy(id[0..], dest);
        try dests.append(alloc, id);
    }

    return .{ .source = source, .dests = try dests.toOwnedSlice(alloc) };
}

const RState = struct { id: Id, visited_dac: bool, visited_fft: bool };

fn countPathsRecursive(
    alloc: std.mem.Allocator,
    adj: AdjList,
    start_id: Id,
    end_id: Id,
    enforce_visits: bool,
) !usize {
    const start_state: RState = .{
        .id = start_id,
        .visited_fft = false,
        .visited_dac = false,
    };

    var memo = std.AutoHashMap(RState, usize).init(alloc);
    defer memo.deinit();

    return try helper(adj, start_state, end_id, enforce_visits, &memo);
}

fn helper(
    // alloc: std.mem.Allocator,
    adj: AdjList,
    curr: RState,
    end_id: Id,
    enforce_visits: bool,
    memo: *std.AutoHashMap(RState, usize),
) !usize {
    const curr_id = curr.id;

    if (memo.get(curr)) |cached_paths| {
        return cached_paths;
    }

    // If we've hit the `end`, we've found one valid path
    if (std.mem.eql(u8, &curr_id, &end_id)) {
        if (enforce_visits and (!curr.visited_dac or !curr.visited_fft)) {
            return 0;
        }
        return 1;
    }

    const is_dac = std.mem.eql(u8, &curr_id, "dac");
    const is_fft = std.mem.eql(u8, &curr_id, "fft");

    // Find neighbours of `curr`, and append to stack
    var num_paths: usize = 0;
    if (adj.get(curr.id)) |nbrs| {
        for (nbrs) |nbr| {
            const nbr_and_meta: RState = .{
                .id = nbr,
                .visited_dac = curr.visited_dac or is_dac,
                .visited_fft = curr.visited_fft or is_fft,
            };
            num_paths += try helper(adj, nbr_and_meta, end_id, enforce_visits, memo);
        }
    }

    try memo.put(curr, num_paths);

    return num_paths;
}

fn countPaths(
    alloc: std.mem.Allocator,
    adj: AdjList,
    start_id: Id,
    end_id: Id,
    enforce_visits: bool,
) !usize {
    const State = struct { id: Id, visited_dac: bool, visited_fft: bool };

    var stack: std.ArrayList(State) = .empty;
    defer stack.deinit(alloc);

    try stack.append(alloc, .{
        .id = start_id,
        .visited_dac = false,
        .visited_fft = false,
    });

    var num_paths: usize = 0;
    while (stack.pop()) |curr| {
        const curr_id = curr.id;

        // If we've hit the `end`, we've found one valid path
        if (std.mem.eql(u8, &curr_id, &end_id)) {
            if (enforce_visits and (!curr.visited_dac or !curr.visited_fft)) {
                continue;
            }
            num_paths += 1;
            continue;
        }

        const is_dac = std.mem.eql(u8, &curr_id, "dac");
        const is_fft = std.mem.eql(u8, &curr_id, "fft");

        // Find neighbours of `curr`, and append to stack
        if (adj.get(curr.id)) |nbrs| {
            for (nbrs) |nbr| {
                const nbr_and_meta: State = .{
                    .id = nbr,
                    .visited_dac = curr.visited_dac or is_dac,
                    .visited_fft = curr.visited_fft or is_fft,
                };
                try stack.append(alloc, nbr_and_meta);
            }
        }
    }

    return num_paths;
}

test "example" {
    const alloc = std.testing.allocator;
    const input =
        \\aaa: you hhh
        \\you: bbb ccc
        \\bbb: ddd eee
        \\ccc: ddd eee fff
        \\ddd: ggg
        \\eee: out
        \\fff: out
        \\ggg: out
        \\hhh: ccc fff iii
        \\iii: out
    ;

    var adj_list = try buildAdjList(alloc, input);
    defer {
        var values = adj_list.valueIterator();
        while (values.next()) |v| alloc.free(v.*);
        adj_list.deinit();
    }

    const part1_solution = try countPaths(alloc, adj_list, "you".*, "out".*, false);
    std.debug.print("part1: {}\n", .{part1_solution});
}

test "example (part2)" {
    const alloc = std.testing.allocator;
    const input =
        \\svr: aaa bbb
        \\aaa: fft
        \\fft: ccc
        \\bbb: tty
        \\tty: ccc
        \\ccc: ddd eee
        \\ddd: hub
        \\hub: fff
        \\eee: dac
        \\dac: fff
        \\fff: ggg hhh
        \\ggg: out
        \\hhh: out
    ;

    var adj_list = try buildAdjList(alloc, input);
    defer {
        var values = adj_list.valueIterator();
        while (values.next()) |v| alloc.free(v.*);
        adj_list.deinit();
    }

    const part2_solution = try countPathsRecursive(alloc, adj_list, "svr".*, "out".*, true);
    std.debug.print("part2: {}\n", .{part2_solution});
}
