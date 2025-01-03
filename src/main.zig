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

const number_of_matrices = 8;
const moduli = 1;
const moduli_list = [1]u32{5};

fn generate_matrices() [number_of_matrices][500][500][moduli]i32 {
    var local_matrices: [number_of_matrices][500][500][moduli]i32 = undefined;
    for (0..number_of_matrices) |s| {
        for (0..s + 1) |i| {
            for (0..s + 1) |j| {
                for (0..moduli) |k| {
                    local_matrices[s][i][j][k] = 0;
                    if (s == 0) {
                        local_matrices[s][0][0][k] = 1;
                    } else {
                        if (i < s and j < s) {
                            local_matrices[s][i][j][k] = local_matrices[s - 1][i][j][k];
                            if (i > 0 and j < s) {
                                local_matrices[s][i][j][k] += local_matrices[s - 1][i - 1][j][k];
                            }
                            if (j > 0 and i < s) {
                                local_matrices[s][i][j][k] += local_matrices[s - 1][i][j - 1][k];
                            }
                            if (i > 0 and j > 0) {
                                local_matrices[s][i][j][k] -= local_matrices[s - 1][i - 1][j - 1][k];
                            }
                            if (i >= 1 and i <= s - 2 and s > 2) {
                                local_matrices[s][i][j][k] /= 2;
                            }
                            //local_matrices[s][i][j][k] = @mod(local_matrices[s][i][j][k], moduli_list[k]);
                        }
                    }
                }
            }
        }
    }
    return local_matrices;
}

fn print_matrix(matrix: [500][500][moduli]i32, comptime idx: usize) void {
    for (0..moduli) |k| {
        std.debug.print("Matrix {}, modulo {}\n", .{ idx, moduli_list[k] });
        for (0..idx) |i| {
            for (0..idx) |j| {
                std.debug.print("{} ", .{matrix[i][j][k]});
            }
            std.debug.print("\n", .{});
        }
    }
}

const matrices = generate_matrices();
pub fn main() !void {
    print_matrix(matrices[1], 1);
    print_matrix(matrices[2], 2);
    print_matrix(matrices[3], 3);
    print_matrix(matrices[4], 4);
    print_matrix(matrices[5], 5);
    print_matrix(matrices[6], 6);
    print_matrix(matrices[7], 7);
}
