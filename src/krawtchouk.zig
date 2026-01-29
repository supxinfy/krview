pub const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;
const ArrayList = std.ArrayList;
const matrix_type = @import("menu.zig").matrix_type;

pub const KravchukMatrix = struct {
    order: usize,
    modulo: u8,
    data: []u8,

    pub fn create(allocator: std.mem.Allocator, order: usize, modulo: u32) !*KravchukMatrix {
        const self = try allocator.create(KravchukMatrix);
        const len = order * order;
        const buf = try allocator.alloc(u8, len);

        self.* = KravchukMatrix{
            .order = order,
            .modulo = @intCast(modulo),
            .data = buf,
        };

        return self;
    }

    pub fn destroy(allocator: std.mem.Allocator, self: *KravchukMatrix) void {
        allocator.free(self.data);
        allocator.destroy(self);
    }

    fn idx(self: *KravchukMatrix, i: usize, j: usize) usize {
        return i * (self.order) + j;
    }

    pub fn set(self: *KravchukMatrix, i: usize, j: usize, value: i32) void {
        self.data[self.idx(i, j)] = @intCast(value);
    }

    pub fn get(self: *KravchukMatrix, i: usize, j: usize) i32 {
        return self.data[self.idx(i, j)];
    }
};

fn is_prime(comptime n: usize) bool {
    var idx: usize = 2;
    while (idx * idx <= n) : (idx += 1)
        if (n % idx == 0) return false;
    return true;
}

fn amount_of_primes(comptime n: u32) u32 {
    var count: u32 = 0;
    @setEvalBranchQuota(1000000);
    inline for (2..n) |m| {
        if (is_prime(m))
            count += 1;
    }
    return count;
}

fn prime_list(comptime n: u32, comptime len: u32) [len]u32 {
    var result = comptime [_]u32{0} ** len;
    var idx: u32 = 0;
    @setEvalBranchQuota(10000000);
    inline for (2..n) |m| {
        if (is_prime(m)) {
            result[idx] = m;
            idx += 1;
        }
    }
    return result;
}

pub const number_of_matrices = 50;
pub var number_of_calcmatrices: u32 = 0;
pub const moduli = amount_of_primes(33);
pub const moduli_list = prime_list(33, moduli);

pub var moduliList: [moduli]ArrayList(*KravchukMatrix) = undefined;

pub fn clearArrays(allocator: std.mem.Allocator) void {
    for (&moduliList) |*al| {
        for (al.items) |m| {
            KravchukMatrix.destroy(allocator, m);
        }
        _ = al.deinit(allocator);
    }
}

pub fn destroyArrays(allocator: std.mem.Allocator) void {
    for (&moduliList) |*al| {
        for (al.items) |m| {
            KravchukMatrix.destroy(allocator, m);
        }
        al.shrinkAndFree(allocator, 0);
    }
}

fn calculate_row(s: usize, i: usize, modulo: usize, prev_item: *KravchukMatrix, new_item: *KravchukMatrix, mt: matrix_type) !void {
    const p: i32 = @intCast(moduli_list[modulo]);
    const half_p: i32 = @intCast((p + 1) >> 1);
    switch (mt) {
        .krawtchouk => {
            for (0..s + 1) |j| {
                var v: i32 = 0;
                if (i == 0 or j == 0 or i == s or j == s) {
                    v = if (i < s and j < s) prev_item.*.get(i, j) else 0;
                    if (i > 0 and j < s) v += prev_item.*.get(i - 1, j);
                    if (i < s and j > 0) v += prev_item.*.get(i, j - 1);
                    if (i > 0 and j > 0) v -= prev_item.*.get(i - 1, j - 1);
                } else {
                    v = prev_item.*.get(i, j) + prev_item.*.get(i - 1, j) + prev_item.*.get(i, j - 1) - prev_item.*.get(i - 1, j - 1);
                }

                if (s >= 1 and j >= 1 and j < s) {
                    v *= half_p;
                }

                v = @mod(v, p);
                new_item.*.set(i, j, v);
            }
        },
        .chebyshev => {
            if (s == 1) {
                new_item.*.set(0, 0, 1);
                new_item.*.set(0, 1, 1);
                new_item.*.set(1, 0, 1);
                new_item.*.set(1, 1, p - 1);
            } else {
                for (0..s + 1) |j| {
                    var v: i32 = 0;
                    if (i < s) {
                        if (j < s) {
                            v += prev_item.*.get(i, j) * @as(i32, @intCast(s - j));
                        }
                        if (j > 0) {
                            v += prev_item.*.get(i, j - 1) * @as(i32, @intCast(j));
                        }
                        const denum = @mod(@as(i32, @intCast(s - i)), p);
                        if (denum != 0) {
                            v *= @divFloor((p + 1), @mod(@as(i32, @intCast(s - i)), p));
                        } else {
                            v = @intCast(i * j + 1);
                        }
                    }

                    if (i == s) {
                        if (j == 0) {
                            v = prev_item.*.get(i - 1, j);
                        } else if (j == s) {
                            v = -prev_item.*.get(i - 1, j - 1);
                        } else {
                            v += prev_item.*.get(i - 1, j) - prev_item.*.get(i - 1, j - 1);
                        }
                    }
                    v = @mod(v, p);
                    new_item.*.set(i, j, v);
                }
            }
            // for (0..s + 1) |j| {
            //     var v: i32 = 0;
            //     var w: i32 = 0;

            //     // First term: pad(cm, [(0,1), (1,0)]) - pad(cm, [(1,0), (1,0)])
            //     // = cm[i, j-1] - cm[i-1, j-1]
            //     if (j > 0) {
            //         if (i < s) { // Within bounds of prev matrix
            //             v += prev_item.*.get(i, j - 1);
            //         }
            //         if (i > 0) { // Within bounds of prev matrix
            //             v -= prev_item.*.get(i - 1, j - 1);
            //             w += prev_item.*.get(i - 1, j - 1);
            //         }
            //     }

            //     // Second term: diag × (pad(cm, [(1,0), (1,0)]) - pad(cm, [(1,0), (0,1)])) × diag
            //     // = diag[i] × (cm[i-1, j-1] - cm[i-1, j]) × diag[j]
            //     if (i == 0 or j == s) {
            //         w = 0; // Diagonal is 0 at these positions
            //     } else {
            //         if (i > 0) {
            //             // w already has cm[i-1, j-1] from above
            //             if (j < s) {
            //                 w -= prev_item.*.get(i - 1, j);
            //             }
            //         }
            //         // Multiply by diag[i] = 1/i and diag[j] = (s - j)
            //         w = @mod(w * @as(i32, @intCast(s - j)), p);
            //         w = @mod(w * modInverse(@as(i32, @intCast(i)), p), p);
            //     }

            //     // Third term: + e (identity at [0,0])
            //     if (i == 0 and j == 0) {
            //         v += 1;
            //     }

            //     new_item.*.set(i, j, @mod(v - w, p));
            // }
        },
        .pascal => {
            for (0..s + 1) |j| {
                var v: i32 = 0;

                if (i == 0 or j == 0) {
                    // First row and first column are all 1s
                    v = 1;
                } else if (i < s and j < s) {
                    // Interior: sum of top and left from previous matrix
                    v = prev_item.*.get(i - 1, j) + prev_item.*.get(i, j - 1);
                } else if (i == s and j < s) {
                    // New row: sum from previous matrix
                    v = prev_item.*.get(i - 1, j) + prev_item.*.get(i - 1, j - 1);
                } else if (j == s and i < s) {
                    // New column: sum from previous matrix
                    v = prev_item.*.get(i, j - 1) + prev_item.*.get(i - 1, j - 1);
                } else {
                    // Corner (i == s and j == s)
                    v = prev_item.*.get(i - 1, j - 1) + prev_item.*.get(i - 1, j - 1);
                    // OR more simply: v = 2 * prev_item.*.get(i - 1, j - 1);
                }

                v = @mod(v, p);
                new_item.*.set(i, j, v);
            }
        },
    }
}

fn calculate_single_modulo(allocator: std.mem.Allocator, s: usize, modulo_idx: usize, mt: matrix_type) !void {
    const cur_modulo = @as(u32, @intCast(modulo_idx));

    if (s == 0) {
        var orderOne = try KravchukMatrix.create(allocator, 1, cur_modulo);
        orderOne.set(0, 0, 1);
        try moduliList[modulo_idx].append(allocator, orderOne);
    } else if (s == 1 and mt == .krawtchouk) {
        var orderTwo = try KravchukMatrix.create(allocator, 2, cur_modulo);
        orderTwo.set(0, 0, 1);
        orderTwo.set(0, 1, 1);
        orderTwo.set(1, 0, 1);
        orderTwo.set(1, 1, @intCast(moduli_list[modulo_idx] - 1));
        try moduliList[modulo_idx].append(allocator, orderTwo);
    } else {
        const prev_item = moduliList[modulo_idx].items[moduliList[modulo_idx].items.len - 1];
        const new_item = try KravchukMatrix.create(allocator, s + 1, cur_modulo);

        // Calculate all rows sequentially (simpler, still fast)
        for (0..s + 1) |i| {
            try calculate_row(s, i, modulo_idx, prev_item, new_item, mt);
        }

        try moduliList[modulo_idx].append(allocator, new_item);
    }
}

fn calculate_matrix(allocator: std.mem.Allocator, s: usize, mt: matrix_type) !void {
    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator });
    defer pool.deinit();

    var wait_group = std.Thread.WaitGroup{};

    for (0..moduli) |mod_idx| {
        wait_group.start();
        try pool.spawn(struct {
            fn work(alloc: std.mem.Allocator, wg: *std.Thread.WaitGroup, ss: usize, idx: usize, wmt: matrix_type) void {
                defer wg.finish();
                calculate_single_modulo(alloc, ss, idx, wmt) catch return;
            }
        }.work, .{ allocator, &wait_group, s, mod_idx, mt });
    }

    pool.waitAndWork(&wait_group);
    number_of_calcmatrices += 1;
}

pub fn calculate_data(allocator: std.mem.Allocator, bound: usize, mt: matrix_type) !void {
    for (number_of_calcmatrices..bound + 1) |s| {
        try calculate_matrix(allocator, s, mt);
    }
}

pub fn calculate_matrix_for_render_single(allocator: std.mem.Allocator, s: usize, modulo_idx: usize) !void {
    if (s == 0) {
        // Initialize first matrix
        const cur_modulo = @as(u32, @intCast(modulo_idx));
        var orderOne = try KravchukMatrix.create(allocator, 1, cur_modulo);
        orderOne.set(0, 0, 1);
        try moduliList[modulo_idx].append(allocator, orderOne);
    } else {
        // Get the previous matrix
        const prev_idx = moduliList[modulo_idx].items.len - 1;
        const prev_item = moduliList[modulo_idx].items[prev_idx];

        // Create new matrix
        const cur_modulo = @as(u32, @intCast(modulo_idx));
        const new_item = try KravchukMatrix.create(allocator, s + 1, cur_modulo);

        // Calculate all rows (no threading needed - single modulo is fast)
        for (0..s + 1) |i| {
            try calculate_row(s, i, modulo_idx, prev_item, new_item, matrix_type.krawtchouk);
        }

        // Destroy the old matrix
        KravchukMatrix.destroy(allocator, prev_item);

        // Replace with new matrix (not append - keeps memory constant!)
        moduliList[modulo_idx].items[prev_idx] = new_item;
    }

    number_of_calcmatrices += 1;
}

pub fn calculate_data_for_render(allocator: std.mem.Allocator, bound: usize, modulo_idx: usize) !void {
    for (number_of_calcmatrices..bound + 1) |s| {
        try calculate_matrix_for_render_single(allocator, s, modulo_idx);
    }
}
