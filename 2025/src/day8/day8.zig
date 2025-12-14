const std = @import("std");
const LinkSet = std.HashMap(Link, void, LinkContext, load_percentage);
const BoxSet = std.HashMap(Box, void, BoxContext, load_percentage);
const AdjList = std.HashMap(Box, BoxSet, BoxContext, load_percentage);
const load_percentage = std.hash_map.default_max_load_percentage;

// MARK: Models

const Box = struct {
    id: usize,
    x: f64,
    y: f64,
    z: f64,

    fn distanceTo(self: *const Box, other: Box) f64 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return std.math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    fn equalTo(self: *const Box, other: Box) bool {
        return self.id == other.id;
    }
};

const BoxContext = struct {
    pub fn hash(_: @This(), box: Box) u64 {
        var h = std.hash.Fnv1a_64.init();
        h.update(std.mem.asBytes(&box.id));
        return h.final();
    }

    pub fn eql(_: @This(), lhs: Box, rhs: Box) bool {
        return lhs.equalTo(rhs);
    }
};

const Link = struct {
    box1: Box,
    box2: Box,

    fn distance(self: *const Link) f64 {
        return self.box1.distanceTo(self.box2);
    }

    fn equalTo(self: *const Link, other: Link) bool {
        if (self.box1.equalTo(other.box1) and self.box2.equalTo(other.box2)) {
            return true;
        }
        if (self.box1.equalTo(other.box2) and self.box2.equalTo(other.box1)) {
            return true;
        }
        return false;
    }

    fn hash(link: Link) u64 {
        var h = std.hash.Fnv1a_64.init();

        // Ensure deterministic ordering of IDs
        if (link.box1.id < link.box2.id) {
            h.update(std.mem.asBytes(&link.box1.id));
            h.update(std.mem.asBytes(&link.box2.id));
        } else {
            h.update(std.mem.asBytes(&link.box2.id));
            h.update(std.mem.asBytes(&link.box1.id));
        }

        return h.final();
    }
};

const LinkContext = struct {
    pub fn hash(_: @This(), link: Link) u64 {
        return link.hash();
    }

    pub fn eql(_: @This(), lhs: Link, rhs: Link) bool {
        return lhs.equalTo(rhs);
    }
};

// MARK: Main

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day8/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    var boxes: std.ArrayList(Box) = .empty;
    defer boxes.deinit(alloc);
    try getBoxes(alloc, input, &boxes);

    const part1_solution = try part1(alloc, &boxes);
    std.debug.print("part1: {}\n", .{part1_solution});

    const part2_solution = try part2(alloc, &boxes);
    std.debug.print("part2: {}\n", .{part2_solution});
}

fn part1(alloc: std.mem.Allocator, boxes: *std.ArrayList(Box)) !usize {
    var adjList = AdjList.init(alloc);
    defer {
        var values = adjList.valueIterator();
        while (values.next()) |value| {
            value.deinit();
        }
        adjList.deinit();
    }
    _ = try buildAdjList(alloc, boxes, 1000, &adjList);

    var components: std.ArrayList(BoxSet) = .empty;
    defer {
        for (components.items) |*component| {
            component.deinit();
        }
        components.deinit(alloc);
    }
    try getComponents(alloc, &adjList, &components);

    std.mem.sort(BoxSet, components.items, {}, orderComponentsBySize);

    var part1_solution: usize = 1;
    for (components.items[0..3]) |component| {
        part1_solution *= component.count();
    }

    return part1_solution;
}

fn part2(alloc: std.mem.Allocator, boxes: *std.ArrayList(Box)) !f64 {
    // Jank solution -- just binary search for num_times
    const min_times = try getNumTimesForSingleComponent(alloc, boxes);

    // More jank -- recreate adj list just to get the last link used
    var adjList = AdjList.init(alloc);
    defer {
        var values = adjList.valueIterator();
        while (values.next()) |value| {
            value.deinit();
        }
        adjList.deinit();
    }
    const link = try buildAdjList(alloc, boxes, min_times, &adjList);

    return link.box1.x * link.box2.x;
}

// MARK: Helpers

fn getBoxes(alloc: std.mem.Allocator, input: []const u8, array: *std.ArrayList(Box)) !void {
    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| {
        if (line.len <= 0) continue;

        var pos_iter = std.mem.splitScalar(u8, line, ',');
        var buf: [3]f64 = undefined;
        var i: u8 = 0;
        while (pos_iter.next()) |coordinate| {
            std.debug.assert(i < 3);
            buf[i] = try std.fmt.parseFloat(f64, coordinate);
            i += 1;
        }
        const box = Box{ .id = array.items.len, .x = buf[0], .y = buf[1], .z = buf[2] };

        try array.append(alloc, box);
    }
}

// zig fmt: off
// HACK: returns last-connected link (for part 2)
fn buildAdjList(
    alloc: std.mem.Allocator,
    boxes: *std.ArrayList(Box),
    num_times: usize,
    adjList: *AdjList
) !Link {
// zig fmt: on

    // Precompute all links
    var links: std.ArrayList(Link) = .empty;
    defer links.deinit(alloc);
    for (boxes.items, 0..) |box1, i| {
        for (boxes.items[i + 1 ..]) |box2| {
            const link = Link{ .box1 = box1, .box2 = box2 };
            try links.append(alloc, link);
        }
    }

    // Sort links in-place by ascending distance
    std.mem.sort(Link, links.items, {}, struct {
        pub fn lessThan(_: void, lhs: Link, rhs: Link) bool {
            return lhs.distance() < rhs.distance();
        }
    }.lessThan);

    var visited = LinkSet.init(alloc);
    defer visited.deinit();

    for (boxes.items) |box| {
        try adjList.put(box, BoxSet.init(alloc));
    }

    var num_added: usize = 0;
    for (links.items) |link| {
        if (visited.contains(link)) continue;

        var nbrs1 = adjList.get(link.box1).?;
        try nbrs1.put(link.box2, {});
        try adjList.put(link.box1, nbrs1);

        var nbrs2 = adjList.get(link.box2).?;
        try nbrs2.put(link.box1, {});
        try adjList.put(link.box2, nbrs2);

        try visited.put(link, {});
        num_added += 1;
        if (num_added >= num_times) {
            return link;
        }
    }

    return links.items[links.items.len - 1];
}

// zig fmt: off
fn getComponents(
    alloc: std.mem.Allocator,
    adjList: *AdjList,
    components: *std.ArrayList(BoxSet)
) !void {
// zig fmt: on
    var key_iter = adjList.keyIterator();
    key_loop: while (key_iter.next()) |key| {
        for (components.items) |component| {
            // We won't have thaaat many components, shouldn't be too slow hopefully
            if (component.contains(key.*)) continue :key_loop;
        }

        var component = BoxSet.init(alloc);

        // Instantiate a stack of nodes to visit
        var to_visit: std.ArrayList(Box) = .empty; // a stack
        defer to_visit.deinit(alloc);
        try to_visit.ensureTotalCapacity(alloc, 20);

        try to_visit.append(alloc, key.*);

        // Traverse, adding any discovered nbrs to `component`
        while (to_visit.pop()) |curr| {
            if (component.contains(curr)) continue;
            try component.put(curr, {});

            if (adjList.get(curr)) |nbrs| {
                var nbrs_iter = nbrs.keyIterator();
                while (nbrs_iter.next()) |nbr| {
                    try to_visit.append(alloc, nbr.*);
                }
            }
        }

        // Once we're done, we have our final `component`
        try components.append(alloc, component);
    }
}

fn getNumTimesForSingleComponent(alloc: std.mem.Allocator, boxes: *std.ArrayList(Box)) !usize {
    var upper: usize = 5000;
    var lower: usize = 1;

    while (upper > lower) {
        const mid = (upper + lower) / 2;
        const num_components = try countComponents(alloc, boxes, mid);
        if (num_components > 1) {
            lower = mid + 1;
        } else {
            upper = mid;
        }
        std.debug.print("num_components: {} {} {}\n", .{ num_components, lower, upper });
    }

    return upper;
}

fn countComponents(alloc: std.mem.Allocator, boxes: *std.ArrayList(Box), num_times: usize) !usize {
    var adjList = AdjList.init(alloc);
    defer {
        var values = adjList.valueIterator();
        while (values.next()) |value| {
            value.deinit();
        }
        adjList.deinit();
    }
    _ = try buildAdjList(alloc, boxes, num_times, &adjList);

    var components: std.ArrayList(BoxSet) = .empty;
    defer {
        for (components.items) |*component| {
            component.deinit();
        }
        components.deinit(alloc);
    }
    try getComponents(alloc, &adjList, &components);

    return components.items.len;
}

fn orderComponentsBySize(_: void, lhs: BoxSet, rhs: BoxSet) bool {
    return lhs.count() > rhs.count();
}

fn printBoxSet(boxSet: BoxSet) void {
    var iter = boxSet.keyIterator();
    while (iter.next()) |key| {
        std.debug.print("{} ", .{key.id});
    }
    std.debug.print("\n", .{});
}

fn printAdjList(adjList: AdjList) void {
    var iter = adjList.keyIterator();
    while (iter.next()) |key| {
        if (adjList.get(key.*)) |nbrs| {
            std.debug.print("{}: ", .{key.id});
            printBoxSet(nbrs);
        }
    }
}

// MARK: Tests

test "example" {
    const input =
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var boxes: std.ArrayList(Box) = .empty;
    defer boxes.deinit(alloc);
    try getBoxes(alloc, input, &boxes);

    // This will fail unless we set `num_times` to `10` inside `part1`
    const part1_solution = try part1(alloc, &boxes);
    try std.testing.expectEqual(40, part1_solution);

    const part2_solution = try part2(alloc, &boxes);
    try std.testing.expectEqual(25272, part2_solution);
}
