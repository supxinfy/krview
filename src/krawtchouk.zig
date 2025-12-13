const std = @import("std");

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

pub const number_of_matrices = 300;
pub const moduli = amount_of_primes(33);
pub const moduli_list = prime_list(33, moduli);

pub var matrices: [number_of_matrices][number_of_matrices][number_of_matrices][moduli]i32 = undefined;

fn matrices_modulo(s: usize, i: usize, j: usize) void {
    for (0..moduli) |k| {
        matrices[s][i][j][k] = 0;
        if (s == 0) {
            matrices[s][0][0][k] = 1;
        } else {
            if (i < s and j < s) {
                matrices[s][i][j][k] = matrices[s - 1][i][j][k];
                if (i > 0 and j < s) {
                    matrices[s][i][j][k] += matrices[s - 1][i - 1][j][k];
                }
                if (j > 0 and i < s) {
                    matrices[s][i][j][k] += matrices[s - 1][i][j - 1][k];
                }
                if (i > 0 and j > 0) {
                    matrices[s][i][j][k] -= matrices[s - 1][i - 1][j - 1][k];
                }
                if (i >= 1 and i <= s - 2 and s > 2) {
                    matrices[s][i][j][k] *= @as(i32, @intCast((moduli_list[k] + 1) >> 1));
                }

                matrices[s][i][j][k] = @mod(matrices[s][i][j][k], @as(i32, @intCast(moduli_list[k])));
            }
        }
    }
}

fn calculate_row(s: usize, i: usize) void {
    for (0..s + 1) |j| {
        matrices_modulo(s, i, j);
    }
}

fn calculate_matrix(s: usize) !void {
    const cpus = try std.Thread.getCpuCount();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator });
    defer pool.deinit();

    if (s < cpus) {
        for (0..s + 1) |i| {
            calculate_row(s, i);
        }
        return;
    }

    for (0..s + 1) |i| {
        try pool.spawn(calculate_row, .{ s, i });
    }
}

pub fn calculate_data() !void {
    for (0..number_of_matrices) |s| {
        try calculate_matrix(s);
    }
}
