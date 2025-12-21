const kr = @import("krawtchouk.zig");
const clrs = @import("colorshemes.zig");
const colortype = @import("colors.zig");
const Color = colortype.Color;

pub const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
    @cInclude("SDL2/SDL_image.h");
});

pub var WINDOW_WIDTH: c_int = 800;
pub var WINDOW_HEIGHT: c_int = 900;

pub const ORDER = "Order: {any}";
pub const MODULO = "Modulo: {any}";

const SDL_Color = sdl.struct_SDL_Color;

const FPS: i32 = 60;
const DELTA_TIME_SEC: f32 = 1.0 / @as(f32, @floatFromInt(FPS));

const OFFSET = 80;

fn make_rect(x: i32, y: i32, w: i32, h: i32) sdl.SDL_Rect {
    return sdl.SDL_Rect{
        .x = x,
        .y = y,
        .w = w,
        .h = h,
    };
}

fn tosdlcolor(color: colortype.Color) SDL_Color {
    return SDL_Color{
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a,
    };
}

const background = colortype.Color{ .r = 18, .g = 18, .b = 18, .a = 255 };
const text_color = colortype.Color{ .r = 208, .g = 208, .b = 208, .a = 255 };

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

    const srcrect_order = make_rect(0, 0, 2 * order_surface.*.w, 2 * order_surface.*.h);
    const dstrect_order = make_rect(0, 0, 2 * order_surface.*.w, 2 * order_surface.*.h);

    const srcrect_modulo = make_rect(0, 0, 2 * modulo_surface.*.w, 2 * modulo_surface.*.h);
    const dstrect_modulo = make_rect(0, order_surface.*.h + 18, 2 * modulo_surface.*.w, 2 * modulo_surface.*.h);

    _ = sdl.SDL_RenderCopy(renderer, order_texture, &srcrect_order, &dstrect_order);

    _ = sdl.SDL_RenderCopy(renderer, modulo_texture, &srcrect_modulo, &dstrect_modulo);

    const cellSizeW = @as(i32, @intCast(@as(usize, @intCast(WINDOW_WIDTH)) / (idx)));
    const cellSizeH = @as(i32, @intCast((@as(usize, @intCast(WINDOW_HEIGHT)) - OFFSET) / (idx)));
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

    const srcrect_loading = make_rect(0, 0, loading_surface.*.w, loading_surface.*.h);
    const dstrect_loading = make_rect(0, 0, loading_surface.*.w, loading_surface.*.h);
    _ = sdl.SDL_RenderCopy(renderer, loading_texture, &srcrect_loading, &dstrect_loading);

    sdl.SDL_RenderPresent(renderer);
}

var flash_press_notice: bool = true;
pub fn render_helping_screen(renderer: *sdl.SDL_Renderer, font: *sdl.TTF_Font) !void {
    _ = sdl.SDL_SetRenderDrawColor(renderer, background.r, background.g, background.b, background.a);
    _ = sdl.SDL_RenderClear(renderer);

    const desctiption_lines = [_][*c]const u8{
        "Krawtchouk Matrices Visualization Tool",
        "-------------------------------------",
        "This application visualizes Krawtchouk matrices, which are",
        "orthogonal matrices with applications in coding theory,",
        "signal processing, and combinatorial designs.",
        " ",
        "Use the controls below to explore different orders and moduli.",
        " ",
    };

    const help_lines = [_][*c]const u8{
        "Controls:",
        "- Up/Down Arrow or W/S: Increase/Decrease Matrix Order",
        "- Left/Right Arrow or A/D: Change Modulo",
        "- C: Change Color Scheme",
        "Schemes Available: Gogin, Gray-scale, Logarithmic,",
        "Viridis, Plasma, Inferno, Magma",
        "- H or SPACE: Toggle Help Screen",
        "- E: Export Current Screen as JPG",
        "- Q: Quit Application",
    };
    var line_y: i32 = 0;
    for (desctiption_lines) |line| {
        const description_surface = sdl.TTF_RenderText_Solid(font, line, tosdlcolor(text_color));
        defer sdl.SDL_FreeSurface(description_surface);

        if (description_surface == null) {
            sdl.SDL_Log("Unable to initialize sdl: %s", sdl.SDL_GetError());
            return error.sdlSurfaceNotFound;
        }
        const description_texture = sdl.SDL_CreateTextureFromSurface(renderer, description_surface);
        defer sdl.SDL_DestroyTexture(description_texture);

        _ = sdl.SDL_SetRenderDrawColor(renderer, text_color.r, text_color.g, text_color.b, text_color.a);

        const particular_point_x = (@as(c_int, @intCast(WINDOW_WIDTH)) - description_surface.*.w) >> 1;
        const dstrect_description = make_rect(particular_point_x, 50 + line_y + description_surface.*.h, description_surface.*.w, description_surface.*.h);
        _ = sdl.SDL_RenderCopy(renderer, description_texture, null, &dstrect_description);

        line_y += description_surface.*.h + 10;
    }
    line_y = 0;
    for (help_lines) |line| {
        const helping_surface = sdl.TTF_RenderText_Solid(font, line, tosdlcolor(text_color));
        defer sdl.SDL_FreeSurface(helping_surface);

        if (helping_surface == null) {
            sdl.SDL_Log("Unable to initialize sdl: %s", sdl.SDL_GetError());
            return error.sdlSurfaceNotFound;
        }
        const helping_texture = sdl.SDL_CreateTextureFromSurface(renderer, helping_surface);
        defer sdl.SDL_DestroyTexture(helping_texture);

        _ = sdl.SDL_SetRenderDrawColor(renderer, text_color.r, text_color.g, text_color.b, text_color.a);

        const particular_point_x = 108;
        const dstrect_helping = make_rect(particular_point_x, line_y + (WINDOW_HEIGHT - helping_surface.*.h) >> 1, helping_surface.*.w, helping_surface.*.h);
        _ = sdl.SDL_RenderCopy(renderer, helping_texture, null, &dstrect_helping);

        line_y += helping_surface.*.h + 10;
    }
    if (flash_press_notice) {
        const press_surface = sdl.TTF_RenderText_Solid(font, "Press H or SPACE to continue...", tosdlcolor(text_color));
        defer sdl.SDL_FreeSurface(press_surface);

        if (press_surface == null) {
            sdl.SDL_Log("Unable to initialize sdl: %s", sdl.SDL_GetError());
            return error.sdlSurfaceNotFound;
        }
        const press_texture = sdl.SDL_CreateTextureFromSurface(renderer, press_surface);
        defer sdl.SDL_DestroyTexture(press_texture);

        _ = sdl.SDL_SetRenderDrawColor(renderer, text_color.r, text_color.g, text_color.b, text_color.a);

        const dstrect_press = make_rect((WINDOW_WIDTH - press_surface.*.w) >> 1, WINDOW_HEIGHT - 100, press_surface.*.w, press_surface.*.h);
        _ = sdl.SDL_RenderCopy(renderer, press_texture, null, &dstrect_press);
    }
    flash_press_notice = !flash_press_notice;

    sdl.SDL_RenderPresent(renderer);
}

pub fn FPSdelay() void {
    sdl.SDL_Delay(1000 / FPS);
}

pub fn export_screen(title: [*c]const u8, matrix: [kr.number_of_matrices][kr.number_of_matrices][kr.moduli]i32, idx: usize, modulo: usize) !void {
    // Quality factor for better resolution. Will be possible to set by user later.
    const quality_factor = 3;

    const cellSizeW = @as(i32, @intCast(@as(usize, @intCast(WINDOW_WIDTH)) / (idx)));
    const cellSizeH = @as(i32, @intCast((@as(usize, @intCast(WINDOW_HEIGHT)) - OFFSET) / (idx)));
    const cellSize = quality_factor * @min(cellSizeW, cellSizeH);

    const w = cellSize * @as(i32, @intCast(idx));
    const h = cellSize * @as(i32, @intCast(idx));

    const surface = sdl.SDL_CreateRGBSurfaceWithFormat(
        0,
        w,
        h,
        32,
        sdl.SDL_PIXELFORMAT_RGBA32,
    );
    defer sdl.SDL_FreeSurface(surface);

    if (surface == null)
        return error.SurfaceCreationFailed;

    // Fill background (optional)
    const bg = sdl.SDL_MapRGBA(
        surface.*.format,
        background.r,
        background.g,
        background.b,
        background.a,
    );
    _ = sdl.SDL_FillRect(surface, null, bg);

    for (0..idx) |i| {
        for (0..idx) |j| {
            const color = clrs.colorScheme(
                matrix[i][j][modulo],
                kr.moduli_list[modulo],
            );

            const pixel = sdl.SDL_MapRGBA(
                surface.*.format,
                color.r,
                color.g,
                color.b,
                color.a,
            );

            const rect = make_rect(
                @as(i32, @intCast(i)) * cellSize,
                @as(i32, @intCast(j)) * cellSize,
                cellSize,
                cellSize,
            );

            _ = sdl.SDL_FillRect(surface, &rect, pixel);
        }
    }

    if (sdl.IMG_SaveJPG(surface, title, 100) != 0) {
        sdl.SDL_Log("Failed to save image: %s", sdl.SDL_GetError());
        return error.ImageSaveFailed;
    }
}
