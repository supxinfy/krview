const std = @import("std");
const math = @import("std").math;
const r = @import("rendering.zig");
const kr = @import("krawtchouk.zig");
const clrs = @import("colorshemes.zig");
const log = @import("logging.zig");

var current_matrix: usize = 1;
var current_modulo: usize = 0;

const MIN_W = 400;
const MIN_H = 400;

const loading_constant = 2;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var args = try std.process.argsWithAllocator(arena_allocator);
    defer args.deinit();

    _ = args.next(); // skip program name

    try log.start_logging();

    const is_handled: bool = log.args_parser(&args) catch |err| switch (err) {
        error.MatrixOrderOverflow, error.ModuloOverflow => {
            std.debug.print("Overflow... Abort. \n", .{});
            return;
        },
        else => {
            std.debug.print("Args are incorrect... See --help for reference {}\n", .{err});
            return;
        },
    };
    if (is_handled) {
        return;
    }

    _ = r.sdl.SDL_SetHint(r.sdl.SDL_HINT_RENDER_SCALE_QUALITY, "0");
    try log.log("SDL_HINT_RENDER_SCALE_QUALITY set to 0 (nearest pixel sampling).");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    if (r.sdl.SDL_Init(r.sdl.SDL_INIT_VIDEO) < 0) {
        r.sdl.SDL_Log("Unable to initialize SDL: %s", r.sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer r.sdl.SDL_Quit();

    try log.log("SDL initialized successfully.");

    const window: *r.sdl.SDL_Window = r.sdl.SDL_CreateWindow("Krawtchouk Matrices", 0, 0, @as(c_int, @intCast(r.WINDOW_WIDTH)), @as(c_int, @intCast(r.WINDOW_HEIGHT)), r.sdl.SDL_WINDOW_RESIZABLE) orelse {
        r.sdl.SDL_Log("Unable to initialize SDL: %s", r.sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    try log.log("SDL window created successfully.");

    _ = r.sdl.SDL_SetWindowMinimumSize(window, MIN_W, MIN_H);
    defer r.sdl.SDL_DestroyWindow(window);
    try log.log("SDL window minimum size set.");

    const renderer = r.sdl.SDL_CreateRenderer(window, -1, r.sdl.SDL_RENDERER_ACCELERATED) orelse {
        r.sdl.SDL_Log("Unable to initialize SDL: %s", r.sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer r.sdl.SDL_DestroyRenderer(renderer);
    try log.log("SDL renderer created successfully.");

    if (r.sdl.TTF_Init() < 0) {
        r.sdl.SDL_Log("Unable to initialize sdl: %s", r.sdl.SDL_GetError());
        return error.sdlInitializationFailed;
    }
    defer r.sdl.TTF_Quit();
    try log.log("SDL TTF initialized successfully.");

    const font = r.sdl.TTF_OpenFont("assets/fonts/Terminus.ttf", 24) orelse {
        r.sdl.SDL_Log("Unable to load font: %s", r.sdl.SDL_GetError());
        return error.sdlFontNotFound;
    };
    defer r.sdl.TTF_CloseFont(font);
    try log.log("Font loaded successfully.");

    r.render_loading_screen(renderer, font) catch |err| {
        return err;
    };
    try log.log("Loading screen rendered successfully.");
    r.sdl.SDL_Delay(16);
    try kr.calculate_data(allocator, kr.number_of_matrices);
    try log.log("Krawtchouk matrices calculated successfully.");

    std.fs.cwd().makeDir("assets/screenshots") catch |err| {
        if (err != error.PathAlreadyExists) {
            try log.log("assets/screenshots can not be found.");
            return err;
        } else {
            try log.log("assets/screenshots exists...");
        }
    };

    var quit: bool = false;
    var update: bool = true;
    var helping_screen: bool = true;

    var last_mouse_state_x: i32 = 0;
    var last_mouse_state_y: i32 = 0;
    var curr_mouse_state_x: i32 = 0;
    var curr_mouse_state_y: i32 = 0;
    var dragging: bool = false;

    while (!quit) {
        const order_str: []u8 = try std.fmt.allocPrint(
            allocator,
            r.ORDER ++ "\x00",
            .{current_matrix},
        );

        defer allocator.free(order_str);

        const modulo_str: []u8 = try std.fmt.allocPrint(
            allocator,
            r.MODULO ++ "\x00",
            .{kr.moduli_list[current_modulo]},
        );
        defer allocator.free(modulo_str);

        var event: r.sdl.SDL_Event = undefined;
        while (r.sdl.SDL_PollEvent(&event) != 0) {
            var sc: r.sdl.SDL_Scancode = 0;
            var window_event: r.sdl.SDL_WindowEvent = r.sdl.SDL_WindowEvent{
                .type = 0,
            };
            update = true;
            event_state: switch (event.type) {
                r.sdl.SDL_QUIT => {
                    quit = true;
                },
                r.sdl.SDL_KEYDOWN => {
                    sc = event.key.keysym.scancode;
                    switch (sc) {
                        r.sdl.SDL_SCANCODE_LSHIFT, r.sdl.SDL_SCANCODE_RSHIFT => {
                            break :event_state;
                        },
                        r.sdl.SDL_SCANCODE_Q, r.sdl.SDL_SCANCODE_ESCAPE => {
                            quit = true;
                            break :event_state;
                        },
                        r.sdl.SDL_SCANCODE_H, r.sdl.SDL_SCANCODE_SPACE => {
                            helping_screen = !helping_screen;
                        },
                        r.sdl.SDL_SCANCODE_C => {
                            clrs.current_color_scheme.name = clrs.nextColorScheme(clrs.current_color_scheme.name);
                        },
                        r.sdl.SDL_SCANCODE_W, r.sdl.SDL_SCANCODE_UP => {
                            if (current_matrix + 1 < kr.number_of_calcmatrices) {
                                current_matrix += 1;
                            }
                        },
                        r.sdl.SDL_SCANCODE_S, r.sdl.SDL_SCANCODE_DOWN => {
                            if (current_matrix > 1) {
                                current_matrix -= 1;
                            }
                        },
                        r.sdl.SDL_SCANCODE_A, r.sdl.SDL_SCANCODE_LEFT => {
                            if (current_modulo > 0) {
                                current_modulo -= 1;
                            }
                        },
                        r.sdl.SDL_SCANCODE_D, r.sdl.SDL_SCANCODE_RIGHT => {
                            if (current_modulo + 1 < kr.moduli) {
                                current_modulo += 1;
                            }
                        },
                        r.sdl.SDL_SCANCODE_E => {
                            const export_title_buf = try allocator.allocSentinel(u8, 256, 0);
                            defer allocator.free(export_title_buf);

                            const export_title = try std.fmt.bufPrint(
                                export_title_buf,
                                "assets/screenshots/km-o{}m{}{s}.png",
                                .{
                                    current_matrix,
                                    kr.moduli_list[current_modulo],
                                    clrs.current_color_scheme.name,
                                },
                            );
                            export_title_buf[export_title.len] = 0;

                            const export_title_z: [:0]const u8 = export_title_buf[0..export_title.len :0];

                            try r.export_screen(export_title_z, kr.moduliList[current_modulo].items[current_matrix], current_matrix, current_modulo);
                        },
                        r.sdl.SDL_SCANCODE_I => {
                            r.globalCoordY += 1 + @as(i32, @intCast(current_matrix / 50));
                        },
                        r.sdl.SDL_SCANCODE_K => {
                            r.globalCoordY -= 1 + @as(i32, @intCast(current_matrix / 50));
                        },
                        r.sdl.SDL_SCANCODE_J => {
                            r.globalCoordX += 1 + @as(i32, @intCast(current_matrix / 50));
                        },
                        r.sdl.SDL_SCANCODE_L => {
                            r.globalCoordX -= 1 + @as(i32, @intCast(current_matrix / 50));
                        },
                        r.sdl.SDL_SCANCODE_Z => {
                            r.scaling += 1;
                        },
                        r.sdl.SDL_SCANCODE_X => {
                            r.scaling -= 1;
                            if (r.scaling <= 0) r.scaling = 1;
                        },
                        r.sdl.SDL_SCANCODE_R => {
                            r.scaling = 1;
                            r.globalCoordX = 0;
                            r.globalCoordY = 0;
                        },
                        else => {},
                    }
                },
                r.sdl.SDL_WINDOWEVENT => {
                    window_event = event.window;
                    switch (window_event.event) {
                        r.sdl.SDL_WINDOWEVENT_CLOSE => {
                            quit = true;
                            break :event_state;
                        },
                        r.sdl.SDL_WINDOWEVENT_SIZE_CHANGED => {
                            r.WINDOW_WIDTH = @as(c_int, @intCast(window_event.data1));
                            r.WINDOW_HEIGHT = @as(c_int, @intCast(window_event.data2));
                            update = true;
                            break :event_state;
                        },
                        else => {},
                    }
                },
                r.sdl.SDL_MOUSEBUTTONDOWN => {
                    if (event.button.button == r.sdl.SDL_BUTTON_LEFT and !helping_screen) {
                        dragging = true;

                        last_mouse_state_x = event.button.x;
                        last_mouse_state_y = event.button.y;

                        curr_mouse_state_x = last_mouse_state_x;
                        curr_mouse_state_y = last_mouse_state_y;
                    }
                },
                r.sdl.SDL_MOUSEBUTTONUP => {
                    if (event.button.button == r.sdl.SDL_BUTTON_LEFT) {
                        dragging = false;
                    }
                },
                r.sdl.SDL_MOUSEMOTION => {
                    curr_mouse_state_x = event.motion.x;
                    curr_mouse_state_y = event.motion.y;
                },
                else => {},
            }
        }
        const keyboard = r.sdl.SDL_GetKeyboardState(null);
        if (current_modulo + 1 < kr.moduli and (keyboard[r.sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[r.sdl.SDL_SCANCODE_D] != 0 or keyboard[r.sdl.SDL_SCANCODE_RIGHT] != 0))) {
            current_modulo += 1;
            update = true;
        }
        if (current_modulo > 0 and (keyboard[r.sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[r.sdl.SDL_SCANCODE_A] != 0 or keyboard[r.sdl.SDL_SCANCODE_LEFT] != 0))) {
            current_modulo -= 1;
            update = true;
        }
        if (current_matrix > 1 and (keyboard[r.sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[r.sdl.SDL_SCANCODE_S] != 0 or keyboard[r.sdl.SDL_SCANCODE_DOWN] != 0))) {
            current_matrix -= 1;
            update = true;
        }
        if (current_matrix + 1 < kr.number_of_calcmatrices and (keyboard[r.sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[r.sdl.SDL_SCANCODE_W] != 0 or keyboard[r.sdl.SDL_SCANCODE_UP] != 0))) {
            current_matrix += 1;
            update = true;
        }
        if ((keyboard[r.sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[r.sdl.SDL_SCANCODE_J] != 0))) {
            r.globalCoordX += 1 + @as(i32, @intCast(current_matrix / 50));
            update = true;
        }
        if ((keyboard[r.sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[r.sdl.SDL_SCANCODE_L] != 0))) {
            r.globalCoordX -= 1 + @as(i32, @intCast(current_matrix / 50));
            update = true;
        }
        if ((keyboard[r.sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[r.sdl.SDL_SCANCODE_I] != 0))) {
            r.globalCoordY += 1 + @as(i32, @intCast(current_matrix / 50));
            update = true;
        }
        if ((keyboard[r.sdl.SDL_SCANCODE_LSHIFT] != 0 and (keyboard[r.sdl.SDL_SCANCODE_K] != 0))) {
            r.globalCoordY -= 1 + @as(i32, @intCast(current_matrix / 50));
            update = true;
        }
        if (helping_screen) {
            r.render_helping_screen(renderer, font) catch |err| {
                return err;
            };
            r.sdl.SDL_Delay(500);
            continue;
        }

        if (dragging) {
            const dx = curr_mouse_state_x - last_mouse_state_x;
            const dy = curr_mouse_state_y - last_mouse_state_y;

            r.globalCoordX += dx;
            r.globalCoordY += dy;

            last_mouse_state_x = curr_mouse_state_x;
            last_mouse_state_y = curr_mouse_state_y;

            update = true;
        }

        if (!update) {
            r.FPSdelay();
            continue;
        } else {
            r.render(renderer, font, @as([*c]const u8, @ptrCast(order_str)), @as([*c]const u8, @ptrCast(modulo_str)), kr.moduliList[current_modulo].items[current_matrix], current_matrix, current_modulo) catch |err| {
                return err;
            };
            if (kr.number_of_calcmatrices < current_matrix + loading_constant) {
                try r.render_loading_matrices(renderer, font);
                try kr.calculate_data(allocator, kr.number_of_calcmatrices + loading_constant * 2);
            }
        }
        update = false;

        r.FPSdelay();
    }

    try log.stop_logging();
}
