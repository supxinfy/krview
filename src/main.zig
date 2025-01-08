const std = @import("std");
const math = @import("std").math;
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};
const WINDOW_WIDTH = 600;
const WINDOW_HEIGHT = 800;
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

fn colorScheme(n: i32, modulo: u32) Color {
    var v: f32 = 0.0;
    var h: f32 = 0.0;
    const nn = @as(f32, @floatFromInt(n)) / @as(f32, @floatFromInt(modulo));
    if (0 <= nn and nn < 0.5) {
        h = @mod(0.77 * (1 - nn), 1);
    } else {
        h = @mod(0.414 * (1 - nn), 1);
    }
    if (0 <= nn and nn < 0.1) {
        v = @mod(5 * h + 0.5, 1);
    } else if (0.9 < nn and nn <= 1) {
        v = @mod(-5 * nn + 5.5, 1);
    } else {
        v = 1;
    }
    var i: u8 = @as(u8, @intFromFloat(h * 6.0));
    const f = h * 6.0 - @as(f32, @floatFromInt(i));
    const q = v * (1.0 - f);
    const t = v * f;
    i = i % 6;
    switch (i) {
        0 => return Color{
            .r = @as(u8, @intFromFloat(@mod(v * 255, 255))),
            .g = @as(u8, @intFromFloat(@mod(t * 255, 255))),
            .b = @as(u8, 0),
            .a = 255,
        },
        1 => return Color{
            .r = @as(u8, @intFromFloat(@mod(q * 255, 255))),
            .g = @as(u8, @intFromFloat(@mod(v * 255, 255))),
            .b = @as(u8, 0),
            .a = 255,
        },
        2 => return Color{
            .r = @as(u8, 0),
            .g = @as(u8, @intFromFloat(@mod(v * 255, 255))),
            .b = @as(u8, @intFromFloat(@mod(t * 255, 255))),
            .a = 255,
        },
        3 => return Color{
            .r = @as(u8, 0),
            .g = @as(u8, @intFromFloat(@mod(q * 255, 255))),
            .b = @as(u8, @intFromFloat(@mod(v * 255, 255))),
            .a = 255,
        },
        4 => return Color{
            .r = @as(u8, @intFromFloat(@mod(t * 255, 255))),
            .g = @as(u8, 0),
            .b = @as(u8, @intFromFloat(@mod(v * 255, 255))),
            .a = 255,
        },
        5 => return Color{
            .r = @as(u8, @intFromFloat(@mod(v * 255, 255))),
            .g = @as(u8, 0),
            .b = @as(u8, @intFromFloat(@mod(q * 255, 255))),
            .a = 255,
        },
        else => {
            return Color{ .r = 0, .g = 0, .b = 0, .a = 0 };
        },
    }
}

const number_of_matrices = 300;
const moduli = amount_of_primes(33);
const moduli_list = prime_list(33, moduli);

var currect_matrix: usize = 1;
var current_modulo: usize = 0;

const ORDER = "Order: {any}";
const MODULO = "Modulo: {any}";

const SDL_Color = sdl.struct_SDL_Color;

fn make_rect(x: i32, y: i32, w: i32, h: i32) sdl.SDL_Rect {
    return sdl.SDL_Rect{
        .x = x,
        .y = y,
        .w = w,
        .h = h,
    };
}

fn tosdlcolor(color: Color) SDL_Color {
    return SDL_Color{
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a,
    };
}

const background = Color{ .r = 18, .g = 18, .b = 18, .a = 255 };
const text_color = Color{ .r = 208, .g = 208, .b = 208, .a = 255 };

const srcrect_order = make_rect(0, 0, 140, 100);
const dstrect_order = make_rect(0, 0, 140, 100);

const srcrect_modulo = make_rect(0, 0, 140, 100);
const dstrect_modulo = make_rect(0, 100, 140, 100);

const OFFSET = 200;

fn render(renderer: *sdl.SDL_Renderer, font: *sdl.TTF_Font, order_str: [*c]const u8, modulo_str: [*c]const u8, matrix: [number_of_matrices][number_of_matrices][moduli]i32, idx: usize, modulo: usize) !void {
    _ = sdl.SDL_SetRenderDrawColor(renderer, background.r, background.g, background.b, background.a);
    _ = sdl.SDL_RenderClear(renderer);

    const order_surface = sdl.TTF_RenderText_Solid(font, order_str, tosdlcolor(text_color));
    defer sdl.SDL_FreeSurface(order_surface);

    if (order_surface == null) {
        sdl.SDL_Log("Unable to initialize sdl: %s", sdl.SDL_GetError());
        return error.sdlSurfaceNotFound;
    }
    const order_texture = sdl.SDL_CreateTextureFromSurface(renderer, order_surface);
    defer sdl.SDL_DestroyTexture(order_texture);

    const modulo_surface = sdl.TTF_RenderText_Solid(font, modulo_str, tosdlcolor(text_color));
    defer sdl.SDL_FreeSurface(modulo_surface);

    if (modulo_surface == null) {
        sdl.SDL_Log("Unable to initialize sdl: %s", sdl.SDL_GetError());
        return error.sdlSurfaceNotFound;
    }
    const modulo_texture = sdl.SDL_CreateTextureFromSurface(renderer, modulo_surface);
    defer sdl.SDL_DestroyTexture(modulo_texture);

    _ = sdl.SDL_SetRenderDrawColor(renderer, text_color.r, text_color.g, text_color.b, text_color.a);

    _ = sdl.SDL_RenderCopy(renderer, order_texture, &srcrect_order, &dstrect_order);

    _ = sdl.SDL_RenderCopy(renderer, modulo_texture, &srcrect_modulo, &dstrect_modulo);

    for (0..idx) |i| {
        for (0..idx) |j| {
            const color = colorScheme(matrix[i][j][modulo], moduli_list[modulo]);
            _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
            _ = sdl.SDL_RenderFillRect(renderer, &make_rect(@as(i32, @intCast(WINDOW_WIDTH / (idx + 1) * j)), @as(i32, @intCast(OFFSET + i * (WINDOW_HEIGHT - OFFSET) / (idx + 1))), @as(i32, @intCast(WINDOW_WIDTH / (idx))), @as(i32, @intCast((WINDOW_HEIGHT - OFFSET) / (idx)))));
        }
    }

    sdl.SDL_RenderPresent(renderer);
}

const srcrect_loading = make_rect(0, 0, 100, 100);
const dstrect_loading = make_rect(0, 0, 100, 100);
fn render_loading_screen(renderer: *sdl.SDL_Renderer, font: *sdl.TTF_Font) !void {
    _ = sdl.SDL_SetRenderDrawColor(renderer, background.r, background.g, background.b, background.a);
    _ = sdl.SDL_RenderClear(renderer);

    const loading_surface = sdl.TTF_RenderText_Solid(font, "Loading...", tosdlcolor(text_color));
    defer sdl.SDL_FreeSurface(loading_surface);

    if (loading_surface == null) {
        sdl.SDL_Log("Unable to initialize sdl: %s", sdl.SDL_GetError());
        return error.sdlSurfaceNotFound;
    }
    const loading_texture = sdl.SDL_CreateTextureFromSurface(renderer, loading_surface);
    defer sdl.SDL_DestroyTexture(loading_texture);

    _ = sdl.SDL_SetRenderDrawColor(renderer, text_color.r, text_color.g, text_color.b, text_color.a);

    _ = sdl.SDL_RenderCopy(renderer, loading_texture, &srcrect_loading, &dstrect_loading);
}

var matrices: [number_of_matrices][number_of_matrices][number_of_matrices][moduli]i32 = undefined;

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

fn calculate_data() !void {
    for (0..number_of_matrices) |s| {
        try calculate_matrix(s);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow("Krawtchouk Matrices", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, sdl.SDL_WINDOW_RESIZABLE) orelse {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyWindow(window);

    const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyRenderer(renderer);

    if (sdl.TTF_Init() < 0) {
        sdl.SDL_Log("Unable to initialize sdl: %s", sdl.SDL_GetError());
        return error.sdlInitializationFailed;
    }
    defer sdl.TTF_Quit();

    const font = sdl.TTF_OpenFont("assets/Terminus.ttf", 24) orelse {
        sdl.SDL_Log("Unable to load font: %s", sdl.SDL_GetError());
        return error.sdlFontNotFound;
    };
    defer sdl.TTF_CloseFont(font);

    render_loading_screen(renderer, font) catch |err| {
        return err;
    };

    try calculate_data();

    var quit: bool = false;

    while (!quit) {
        const order_str: []u8 = try std.fmt.allocPrint(
            allocator,
            ORDER ++ "\x00",
            .{currect_matrix},
        );
        defer allocator.free(order_str);

        const modulo_str: []u8 = try std.fmt.allocPrint(
            allocator,
            MODULO ++ "\x00",
            .{moduli_list[current_modulo]},
        );
        defer allocator.free(modulo_str);

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
                    if (currect_matrix + 1 < number_of_matrices and (event.key.keysym.sym == 'w' or event.key.keysym.sym == sdl.SDLK_UP)) {
                        currect_matrix += 1;
                    }
                    if (currect_matrix > 1 and (event.key.keysym.sym == 's' or event.key.keysym.sym == sdl.SDLK_DOWN)) {
                        currect_matrix -= 1;
                    }
                    if (current_modulo > 0 and (event.key.keysym.sym == 'a' or event.key.keysym.sym == sdl.SDLK_LEFT)) {
                        current_modulo -= 1;
                    }
                    if (current_modulo + 1 < moduli and (event.key.keysym.sym == 'd' or event.key.keysym.sym == sdl.SDLK_RIGHT)) {
                        current_modulo += 1;
                    }
                    if (event.key.keysym.sym == sdl.SDLK_SPACE) {}
                },
                else => {},
            }
        }
        const keyboard = sdl.SDL_GetKeyboardState(null);
        if (current_modulo + 1 < moduli and (keyboard[sdl.SDL_SCANCODE_LSHIFT] != 0 and keyboard[sdl.SDL_SCANCODE_D] != 0 or keyboard[sdl.SDL_SCANCODE_LEFT] != 0)) {
            current_modulo += 1;
        }
        if (current_modulo > 0 and (keyboard[sdl.SDL_SCANCODE_LSHIFT] != 0 and keyboard[sdl.SDL_SCANCODE_A] != 0 or keyboard[sdl.SDL_SCANCODE_RIGHT] != 0)) {
            current_modulo -= 1;
        }
        if (currect_matrix > 1 and (keyboard[sdl.SDL_SCANCODE_LSHIFT] != 0 and keyboard[sdl.SDL_SCANCODE_S] != 0 or keyboard[sdl.SDL_SCANCODE_DOWN] != 0)) {
            currect_matrix -= 1;
        }
        if (currect_matrix + 1 < number_of_matrices and (keyboard[sdl.SDL_SCANCODE_LSHIFT] != 0 and keyboard[sdl.SDL_SCANCODE_W] != 0 or keyboard[sdl.SDL_SCANCODE_UP] != 0)) {
            currect_matrix += 1;
        }

        render(renderer, font, @as([*c]const u8, @ptrCast(order_str)), @as([*c]const u8, @ptrCast(modulo_str)), matrices[currect_matrix], currect_matrix, current_modulo) catch |err| {
            return err;
        };

        sdl.SDL_Delay(1000 / FPS);
    }
}
