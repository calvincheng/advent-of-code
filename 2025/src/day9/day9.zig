const std = @import("std");

const Polygon = struct {
    edges: std.ArrayList(Edge),

    fn contains(self: Polygon, point: [2]usize) bool {
        return false;
    }
};

const Edge = struct {
    start: [2]usize,
    end: [2]usize,

    fn contains(self: Edge, point: [2]usize) bool {
        return false;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day9/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    const part1_solution = try part1(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});

    const part2_solution = try part2(alloc, input);
    std.debug.print("part2: {}\n", .{part2_solution});
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

fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    // strategy: polygon `contains` check, probs with odd/even rule
 
    var locations: std.ArrayList([2]usize) = .empty;
    defer locations.deinit(alloc);

    var edges: std.ArrayList(Edge) = .empty;
    defer edges.deinit(alloc);

    const polygon = Polygon{ .edges = edges };
    const haha = polygon.contains([2]usize{ 1, 1});
    std.debug.print("{}\n", .{haha});

    var iter = std.mem.splitScalar(u8, input, '\n');
    var prevLocation: ?[2]usize = null;
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.indexOf(u8, line, ",")) |commaIndex| {
            // Add location
            const x = try std.fmt.parseInt(usize, line[0..commaIndex], 10);
            const y = try std.fmt.parseInt(usize, line[commaIndex + 1 ..], 10);
            const location = [2]usize{ x, y };
            try locations.append(alloc, location);

            // Add edge
            if (prevLocation) |prev| {
                const edge = Edge{ .start = prev, .end = location };
                try edges.append(alloc, edge);
            }

            prevLocation = location;
        }
    }
    // Don't forget to close the polygon!
    try edges.append(alloc, Edge{
        .start = locations.items[locations.items.len - 1],
        .end = locations.items[0]
    });

    for (edges.items) |edge| {
        std.debug.print("{any}\n", .{edge});
    }

    var best: usize = 0;
    for (locations.items, 0..) |a, i| {
        inner: for (locations.items[i..]) |c| {
            // Check for validity
            if (equal(a, c)) continue;
            for (getCorners(a, c)) |corner| {
                if (!polygon.contains(corner)) continue :inner;
            }

            best = @max(best, area(a, c));
        }
    }

    return best;
}

fn getCorners(a: [2]usize, c: [2]usize) [4][2]usize {
    const b = [2]usize{ c[0], a[1] };
    const d = [2]usize{ a[0], c[1] };
    return [4][2]usize{ a, b, c, d };
}

fn area(a: [2]usize, b: [2]usize) usize {
    const dx = if (a[0] > b[0]) a[0] - b[0] else b[0] - a[0];
    const dy = if (a[1] > b[1]) a[1] - b[1] else b[1] - a[1];
    return (dx + 1) * (dy + 1);
}

fn equal(a: [2]usize, b: [2]usize) bool {
    return a[0] == b[0] and a[1] == b[1];
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
    const part2_solution = try part2(alloc, input);
    std.debug.print("part1: {}\n", .{part1_solution});
    std.debug.print("part2: {}\n", .{part2_solution});

    try std.testing.expectEqual(50, part1_solution);
    try std.testing.expectEqual(24, part2_solution);
}

test "edge" {
    const edge1 = Edge{ .start = [2]usize{ 1, 1 }, .end = [2]usize{ 5, 1 } };
    const edge2 = Edge{ .start = [2]usize{ 1, 1 }, .end = [2]usize{ 5, 1 } };
    const containing = edge1.contains(edge2);
    std.debug.print("{any}\n", .{containing});
}
