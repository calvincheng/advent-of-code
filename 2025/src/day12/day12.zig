const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const Shape = struct {
    value: [3][3]bool,
    count: usize,
};

const Region = struct {
    width: usize,
    height: usize,
    counts: [6]usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const input = try std.fs.cwd()
        .readFileAlloc(alloc, "day12/input.txt", 1 * 1024 * 1024);
    defer alloc.free(input);

    try parseInput(alloc, input);
}

fn parseInput(alloc: Allocator, input: []const u8) !void {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var parsing_regions = false;

    var regions: std.ArrayList(Region) = .empty;
    defer regions.deinit(alloc);

    var shapes: [6]Shape = undefined;
    var num_shapes_parsed: usize = 0;

    var current_shape: Shape = Shape{
        .value = .{
            .{ false, false, false },
            .{ false, false, false },
            .{ false, false, false },
        },
        .count = 0,
    };
    var current_shape_lines_parsed: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        parsing_regions = parsing_regions or std.mem.indexOfScalar(u8, line, 'x') != null;
        if (parsing_regions) {
            const region = try parseRegion(line);
            try regions.append(alloc, region);
        } else {
            if (std.mem.indexOfScalar(u8, line, ':') != null) {
                // Start a new shape
                current_shape = Shape{
                    .value = .{
                        .{ false, false, false },
                        .{ false, false, false },
                        .{ false, false, false },
                    },
                    .count = 0,
                };
                current_shape_lines_parsed = 1;
            } else {
                // Continue parsing current shape
                const row_index = current_shape_lines_parsed - 1;
                for (0.., line) |i, c| {
                    if (c == '#') {
                        current_shape.value[row_index][i] = true;
                        current_shape.count += 1;
                    }
                }

                current_shape_lines_parsed += 1;

                // We should be done parsing after the 4th row
                if (current_shape_lines_parsed == 4) {
                    shapes[num_shapes_parsed] = current_shape;
                    num_shapes_parsed += 1;
                    current_shape_lines_parsed = 0;
                }
            }
        }
    }

    var lower_bound: usize = 0;
    var upper_bound: usize = regions.items.len;
    for (regions.items) |region| {
        const area = region.width * region.height;

        var total: usize = 0;
        var cost: usize = 0;
        for (0.., region.counts) |i, count| {
            cost += (shapes[i].count * count);
            total += count;
        }

        // Can definitely fit
        if (area >= total * 9) {
            lower_bound += 1;
        }

        // Can definitely not fit
        if (area < cost) {
            upper_bound -= 1;
        }
    }

    print("total: {}\n", .{regions.items.len});
    print("lower_bound: {}\n", .{lower_bound});
    print("upper_bound: {}\n", .{upper_bound});

    // Oh...
}

fn parseRegion(line: []const u8) !Region {
    const x_index = std.mem.indexOfScalar(u8, line, 'x') orelse unreachable;
    const colon_index = std.mem.indexOfScalar(u8, line, ':') orelse unreachable;
    const width = try std.fmt.parseInt(usize, line[0..x_index], 10);
    const height = try std.fmt.parseInt(usize, line[x_index + 1 .. colon_index], 10);

    var counts: [6]usize = undefined;
    var count_idx: usize = 0;
    var counts_iter = std.mem.splitScalar(u8, line[colon_index + 1 ..], ' ');
    while (counts_iter.next()) |c| {
        if (c.len == 0) continue;
        const count = try std.fmt.parseInt(usize, c, 10);
        counts[count_idx] = count;
        count_idx += 1;
    }

    return Region{
        .height = height,
        .width = width,
        .counts = counts,
    };
}

fn printRegions(regions: *const std.ArrayList(Region)) void {
    for (regions.items) |region| {
        print("{any}\n", .{region});
    }
}

fn printShapes(shapes: *const [6]Shape) void {
    for (shapes) |shape| {
        for (shape.value) |row| {
            for (row) |c| {
                const char: u8 = if (c) 'o' else '.';
                print("{c}", .{char});
            }
            print("\n", .{});
        }
        print("\n", .{});
    }
}

test "example" {
    const input =
        \\0:
        \\###
        \\##.
        \\##.
        \\
        \\1:
        \\###
        \\##.
        \\.##
        \\
        \\2:
        \\.##
        \\###
        \\##.
        \\
        \\3:
        \\##.
        \\###
        \\##.
        \\
        \\4:
        \\###
        \\#..
        \\###
        \\
        \\5:
        \\###
        \\.#.
        \\###
        \\
        \\4x4: 0 0 0 0 2 0
        \\12x5: 1 0 1 0 2 2
        \\12x5: 1 0 1 0 3 2
    ;

    const alloc = std.testing.allocator;
    try parseInput(alloc, input);
}
