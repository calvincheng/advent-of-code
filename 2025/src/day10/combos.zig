const std = @import("std");

pub const ComboIterator = struct {
    indices: []usize,
    n: usize,
    k: usize,

    started: bool,
    done: bool,

    pub fn init(alloc: std.mem.Allocator, n: usize, k: usize) !@This() {
        const indices = try alloc.alloc(usize, k);
        for (indices, 0..) |*d, i| {
            // Initialise `indices` as [0, 1, ..., k-1]
            d.* = i;
        }
        return ComboIterator{
            .indices = indices,
            .n = n,
            .k = k,
            .started = false,
            .done = false,
        };
    }

    pub fn deinit(self: @This(), alloc: std.mem.Allocator) void {
        alloc.free(self.indices);
    }

    /// Returns a `boolean` indicating whether there are remaining values to emit
    // n = 6, k = 3;
    // (n - k) + i = 3, 4, 5
    //
    // [1. 2. 3]
    // [1, 2, 4]
    // [1, 2, 5]
    // [1, 3, 4]
    // [1, 3, 5]
    // [1, 4, 5]
    // [2, 3, 4]
    // [2, 3, 5]
    // [2, 4, 5]
    // [3, 4, 5]
    pub fn next(self: *ComboIterator, out: []usize) bool {
        // If we're done, we have no more values to iterate to
        if (self.done) return false;

        // If we just started, iterate the initialised combo ([0, 1, ..., k-1])
        if (!self.started) {
            @memcpy(out, self.indices);
            self.started = true;
            return true;
        }

        // Find rightmost index that we are still increment
        var i = self.indices.len - 1;
        while (i > 0) : (i -= 1) {
            const max_value = self.n - self.k + i;
            if (self.indices[i] != max_value) break;
        }

        // If we've maxed out all the values already, we're done
        if (self.indices[i] == self.n - self.k + i) {
            self.done = true;
            return false;
        }

        self.indices[i] += 1;

        var j: usize = i + 1;
        while (j < self.indices.len) : (j += 1) {
            self.indices[j] = self.indices[j - 1] + 1;
        }

        @memcpy(out, self.indices);
        return true;
    }
};

test "combos" {
    const alloc = std.testing.allocator;

    const numbers = [_]u8{ 0, 1, 2, 3, 4 };
    const k: usize = 3;

    var combos = try ComboIterator.init(alloc, numbers.len, k);
    defer combos.deinit(alloc);

    const combo = try alloc.alloc(usize, k);
    defer alloc.free(combo);

    // while (combos.next(combo)) {
    //     std.debug.print("{any}\n", .{combo});
    // }

    // std.debug.print("{any}\n", .{combos});
}
