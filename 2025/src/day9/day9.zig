const std = @import("std");

const Polygon = struct {
    edges: std.ArrayList(Edge),

    fn containsRect(self: Polygon, a: [2]usize, b: [2]usize) bool {
        // All corners must be inside or on the boundary
        for (getCorners(a, b)) |corner| {
            if (!self.containsPoint(corner)) return false;
        }

        // No edges may cross
        for (getEdges(a, b)) |rectEdge| {
            for (self.edges.items) |polyEdge| {
                if (rectEdge.intersectsEdge(polyEdge)) return false;
            }
        }

        return true;
    }

    fn containsPoint(self: Polygon, p: [2]usize) bool {
        var num_intersections: usize = 0;
        for (self.edges.items) |edge| {
            // Check if point is exactly on the boundary
            if (edge.containsPoint(p)) return true;

            // Standard raycast (only vertical edges to the left)
            if (edge.isVertical() and edge.start[0] < p[0]) {
                const y = p[1];
                const y_min = @min(edge.start[1], edge.end[1]);
                const y_max = @max(edge.start[1], edge.end[1]);
                
                // Half-open interval [min, max) to handle vertices correctly
                if (y >= y_min and y < y_max) {
                    num_intersections += 1;
                }
            }
        }
        return (num_intersections % 2) != 0;
    }
};

const Edge = struct {
    start: [2]usize,
    end: [2]usize,

    /// Returns true if the edges cross each other like a '+' or 'T' junction.
    /// Returns false if they are collinear/overlapping or don't touch.
    fn intersectsEdge(self: Edge, other: Edge) bool {
        // Parallel edges (both horizontal or both vertical) cannot cross
        if (self.isVertical() == other.isVertical()) return false;

        const v = if (self.isVertical()) self else other;
        const h = if (self.isHorizontal()) self else other;

        const v_x = v.start[0];
        const v_y_min = @min(v.start[1], v.end[1]);
        const v_y_max = @max(v.start[1], v.end[1]);

        const h_y = h.start[1];
        const h_x_min = @min(h.start[0], h.end[0]);
        const h_x_max = @max(h.start[0], h.end[0]);

        // Strict crossing check
        return (h_y > v_y_min and h_y < v_y_max) and
               (v_x > h_x_min and v_x < h_x_max);
    }

    /// Returns true if point p lies exactly on the edge
    fn containsPoint(self: Edge, p: [2]usize) bool {
        if (self.isVertical()) {
            if (p[0] != self.start[0]) return false;
            const y_min = @min(self.start[1], self.end[1]);
            const y_max = @max(self.start[1], self.end[1]);
            return p[1] >= y_min and p[1] <= y_max;
        } else {
            if (p[1] != self.start[1]) return false;
            const x_min = @min(self.start[0], self.end[0]);
            const x_max = @max(self.start[0], self.end[0]);
            return p[0] >= x_min and p[0] <= x_max;
        }
    }

    fn isHorizontal(self: Edge) bool {
        return self.start[1] == self.end[1];
    }

    fn isVertical(self: Edge) bool {
        return self.start[0] == self.end[0];
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
    var locations: std.ArrayList([2]usize) = .empty;
    defer locations.deinit(alloc);

    var edges: std.ArrayList(Edge) = .empty;
    defer edges.deinit(alloc);

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

    const polygon = Polygon{ .edges = edges };

    var best: usize = 0;
    for (locations.items, 0..) |a, i| {
        for (locations.items[i..]) |c| {
            if (equal(a, c)) continue;
            if (!polygon.containsRect(a, c)) continue;
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

fn getEdges(a: [2]usize, c: [2]usize) [4]Edge {
    const corners = getCorners(a, c);
    return [4]Edge{
        Edge{ .start = corners[0], .end = corners[1] },
        Edge{ .start = corners[1], .end = corners[2] },
        Edge{ .start = corners[2], .end = corners[3] },
        Edge{ .start = corners[3], .end = corners[0] },
    };
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

test "polygon" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var edges: std.ArrayList(Edge) = .empty;
    defer edges.deinit(alloc);

    try edges.append(alloc, Edge{ .start = [2]usize{0, 0}, .end = [2]usize{10, 0} });
    try edges.append(alloc, Edge{ .start = [2]usize{10, 0}, .end = [2]usize{10, 10} });
    try edges.append(alloc, Edge{ .start = [2]usize{10, 10}, .end = [2]usize{0, 10} });
    try edges.append(alloc, Edge{ .start = [2]usize{0, 10}, .end = [2]usize{0, 0} });

    const polygon = Polygon{ .edges = edges };

    const point = [2]usize { 5, 5 };
    try std.testing.expectEqual(true, polygon.containsPoint(point));
}
