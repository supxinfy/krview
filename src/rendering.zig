const kr = @import("krawtchouk.zig");
const clrs = @import("colorshemes.zig");

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 900;

pub const ORDER = "Order: {any}";
pub const MODULO = "Modulo: {any}";

const SDL_Color = sdl.struct_SDL_Color;

const FPS: i32 = 60;
const DELTA_TIME_SEC: f32 = 1.0 / @as(f32, @floatFromInt(FPS));

const OFFSET = 200;

fn make_rect(x: i32, y: i32, w: i32, h: i32) sdl.SDL_Rect {
    return sdl.SDL_Rect{
        .x = x,
        .y = y,
        .w = w,
        .h = h,
    };
}

fn tosdlcolor(color: clrs.Color) SDL_Color {
    return SDL_Color{
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a,
    };
}

const background = clrs.Color{ .r = 18, .g = 18, .b = 18, .a = 255 };
const text_color = clrs.Color{ .r = 208, .g = 208, .b = 208, .a = 255 };

const srcrect_order = make_rect(0, 0, 140, 100);
const dstrect_order = make_rect(0, 0, 140, 100);

const srcrect_modulo = make_rect(0, 0, 140, 100);
const dstrect_modulo = make_rect(0, 100, 140, 100);

pub fn render(renderer: *sdl.SDL_Renderer, font: *sdl.TTF_Font, order_str: [*c]const u8, modulo_str: [*c]const u8, matrix: [kr.number_of_matrices][kr.number_of_matrices][kr.moduli]i32, idx: usize, modulo: usize) !void {
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

    const cellSizeW = @as(i32, @intCast(WINDOW_WIDTH / (idx)));
    const cellSizeH = @as(i32, @intCast((WINDOW_HEIGHT - OFFSET) / (idx)));
    const cellSize = @min(cellSizeW, cellSizeH);

    const usedW = cellSize * @as(i32, @intCast(idx));
    const usedH = cellSize * @as(i32, @intCast(idx));

    const startX = (WINDOW_WIDTH - usedW) >> 1;
    const startY = ((WINDOW_HEIGHT - usedH) >> 1) + (OFFSET >> 1);

    for (0..idx) |i| {
        for (0..idx) |j| {
            const cellCoordX = @as(i32, @intCast(startX + @as(i32, @intCast(i)) * cellSize));
            const cellCoordY = @as(i32, @intCast(startY + @as(i32, @intCast(j)) * cellSize));
            const color = clrs.colorScheme(matrix[i][j][modulo], kr.moduli_list[modulo]);
            _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
            _ = sdl.SDL_RenderFillRect(renderer, &make_rect(cellCoordX, cellCoordY, cellSize, cellSize));
        }
    }

    sdl.SDL_RenderPresent(renderer);
}

const srcrect_loading = make_rect(0, 0, 100, 100);
const dstrect_loading = make_rect(0, 0, 100, 100);
pub fn render_loading_screen(renderer: *sdl.SDL_Renderer, font: *sdl.TTF_Font) !void {
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

    sdl.SDL_RenderPresent(renderer);
}

pub fn createWindow() ?*sdl.SDL_Window {
    return sdl.SDL_CreateWindow("Krawtchouk Matrices", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, sdl.SDL_WINDOW_RESIZABLE);
}

pub fn FPSdelay() void {
    sdl.SDL_Delay(1000 / FPS);
}
