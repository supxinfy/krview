const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;
const ArrayList = std.ArrayList;

pub const KravchukMatrix = struct {
    order: usize,
    modulo: u32,
    data: []i32,

    pub fn create(allocator: std.mem.Allocator, order: usize, modulo: u32) !*KravchukMatrix {
        const self = try allocator.create(KravchukMatrix);
        const len = order * order;
        const buf = try allocator.alloc(i32, len);

        self.* = KravchukMatrix{
            .order = order,
            .modulo = modulo,
            .data = buf,
        };

        // for (0..len) |i| {
        //     self.data[i] = 0;
        // }
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
        self.data[self.idx(i, j)] = value;
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

fn calculate_row(s: usize, i: usize, modulo: usize, prev_item: *KravchukMatrix, new_item: *KravchukMatrix) !void {
    for (0..s + 1) |j| {
        var v: i32 = if (i < s and j < s) prev_item.*.get(i, j) else 0;
        if (i > 0 and j < s) v += prev_item.*.get(i - 1, j);
        if (i < s and j > 0) v += prev_item.*.get(i, j - 1);
        if (i > 0 and j > 0) v -= prev_item.*.get(i - 1, j - 1);
        if (s >= 1 and j >= 1 and j < s) {
            v *= @as(i32, @intCast((moduli_list[modulo] + 1) >> 1));
        }
        v = @mod(v, @as(i32, @intCast(moduli_list[modulo])));
        new_item.*.set(i, j, v);
    }
}

fn wrap_calculate_row(s: usize, i: usize, modulo: usize, prev_item: *KravchukMatrix, new_item: *KravchukMatrix) void {
    calculate_row(s, i, modulo, prev_item, new_item) catch {
        return;
    };
}

fn calculate_matrix(allocator: std.mem.Allocator, s: usize) !void {
    for (&moduliList, 0..) |*kr, idx| {
        const cur_modulo = @as(u32, @intCast(idx));

        if (s == 0) {
            var orderOne = try KravchukMatrix.create(allocator, 1, cur_modulo);
            orderOne.set(0, 0, 1);
            try kr.append(allocator, orderOne);
        } else {
            // const cpus = try std.Thread.getCpuCount();

            const prev_item = kr.items[kr.items.len - 1];
            const new_item = try KravchukMatrix.create(allocator, s + 1, cur_modulo);

            var pool: std.Thread.Pool = undefined;
            try pool.init(.{ .allocator = allocator });
            defer pool.deinit();

            for (0..s + 1) |i| {
                try pool.spawn(wrap_calculate_row, .{ s, i, idx, prev_item, new_item });
            }

            try kr.append(allocator, new_item);
        }
    }
    number_of_calcmatrices += 1;
}

pub fn calculate_data(allocator: std.mem.Allocator, bound: usize) !void {
    for (number_of_calcmatrices..bound + 1) |s| {
        try calculate_matrix(allocator, s);
    }
}
