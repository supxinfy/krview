const std = @import("std");
const math = @import("std").math;
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

const WINDOW_WIDTH = 400;
const WINDOW_HEIGHT = 600;
const FPS: i32 = 60;
const DELTA_TIME_SEC: f32 = 1.0 / @as(f32, @floatFromInt(FPS));

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
                                // local_matrices[s][i][j][k] /= 2;
                                local_matrices[s][i][j][k] *= (moduli_list[k] + 1) / 2;
                            }

                            local_matrices[s][i][j][k] = @mod(local_matrices[s][i][j][k], moduli_list[k]);
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

const background = Color{ .r = 18, .g = 18, .b = 18, .a = 255 };

fn render(renderer: *sdl.SDL_Renderer) void {
    _ = sdl.SDL_SetRenderDrawColor(renderer, background.r, background.g, background.b, background.a);
    _ = sdl.SDL_RenderClear(renderer);

    sdl.SDL_RenderPresent(renderer);
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

    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow("Main", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, sdl.SDL_WINDOW_RESIZABLE) orelse {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyWindow(window);

    const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyRenderer(renderer);

    var quit: bool = false;

    while (!quit) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => {
                    quit = true;
                },
                sdl.SDL_KEYDOWN => {
                    if (event.key.keysym.sym == 'q' or event.key.keysym.sym == sdl.SDLK_ESCAPE) {
                        quit = true;
                    }
                },
                else => {},
            }
        }

        render(renderer);

        sdl.SDL_Delay(1000 / FPS);
    }
}
