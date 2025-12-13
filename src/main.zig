const std = @import("std");
const math = @import("std").math;
const r = @import("rendering.zig");
const kr = @import("krawtchouk.zig");
const clrs = @import("colorshemes.zig");

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

var currect_matrix: usize = 1;
var current_modulo: usize = 0;

pub fn main() !void {
    _ = sdl.SDL_SetHint(sdl.SDL_HINT_RENDER_SCALE_QUALITY, "0");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    const window = r.createWindow() orelse {
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

    r.render_loading_screen(renderer, font) catch |err| {
        return err;
    };
    sdl.SDL_PumpEvents(); // give OS a chance
    sdl.SDL_Delay(16); // let it breathe
    try kr.calculate_data();

    var quit: bool = false;
    var update: bool = true;

    while (!quit) {
        const order_str: []u8 = try std.fmt.allocPrint(
            allocator,
            r.ORDER ++ "\x00",
            .{currect_matrix},
        );
        defer allocator.free(order_str);

        const modulo_str: []u8 = try std.fmt.allocPrint(
            allocator,
            r.MODULO ++ "\x00",
            .{kr.moduli_list[current_modulo]},
        );
        defer allocator.free(modulo_str);

        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            update = true;
            switch (event.type) {
                sdl.SDL_QUIT => {
                    quit = true;
                },
                sdl.SDL_KEYDOWN => {
                    if (event.key.keysym.sym == 'q' or event.key.keysym.sym == sdl.SDLK_ESCAPE) {
                        quit = true;
                    }
                    if (event.key.keysym.sym == 'c') {
                        clrs.current_color_scheme.name = clrs.nextColorScheme(clrs.current_color_scheme.name);
                    }
                    if (currect_matrix + 1 < kr.number_of_matrices and (event.key.keysym.sym == 'w' or event.key.keysym.sym == sdl.SDLK_UP)) {
                        currect_matrix += 1;
                    }
                    if (currect_matrix > 1 and (event.key.keysym.sym == 's' or event.key.keysym.sym == sdl.SDLK_DOWN)) {
                        currect_matrix -= 1;
                    }
                    if (current_modulo > 0 and (event.key.keysym.sym == 'a' or event.key.keysym.sym == sdl.SDLK_LEFT)) {
                        current_modulo -= 1;
                    }
                    if (current_modulo + 1 < kr.moduli and (event.key.keysym.sym == 'd' or event.key.keysym.sym == sdl.SDLK_RIGHT)) {
                        current_modulo += 1;
                    }
                    if (event.key.keysym.sym == sdl.SDLK_SPACE) {}
                },
                else => {},
            }
        }
        const keyboard = sdl.SDL_GetKeyboardState(null);
        if (current_modulo + 1 < kr.moduli and (keyboard[sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[sdl.SDL_SCANCODE_D] != 0 or keyboard[sdl.SDL_SCANCODE_RIGHT] != 0))) {
            current_modulo += 1;
            update = true;
        }
        if (current_modulo > 0 and (keyboard[sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[sdl.SDL_SCANCODE_A] != 0 or keyboard[sdl.SDL_SCANCODE_LEFT] != 0))) {
            current_modulo -= 1;
            update = true;
        }
        if (currect_matrix > 1 and (keyboard[sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[sdl.SDL_SCANCODE_S] != 0 or keyboard[sdl.SDL_SCANCODE_DOWN] != 0))) {
            currect_matrix -= 1;
            update = true;
        }
        if (currect_matrix + 1 < kr.number_of_matrices and (keyboard[sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[sdl.SDL_SCANCODE_W] != 0 or keyboard[sdl.SDL_SCANCODE_UP] != 0))) {
            currect_matrix += 1;
            update = true;
        }
        if (!update) {
            r.FPSdelay();
            continue;
        } else {
            r.render(renderer, font, @as([*c]const u8, @ptrCast(order_str)), @as([*c]const u8, @ptrCast(modulo_str)), kr.matrices[currect_matrix], currect_matrix, current_modulo) catch |err| {
                return err;
            };
        }
        update = false;

        r.FPSdelay();
    }
}
