const kr = @import("krawtchouk.zig");
const clrs = @import("colorshemes.zig");
const colortype = @import("colors.zig");
const Color = colortype.Color;
const menu = @import("menu.zig");
const std = @import("std");

pub const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
    @cInclude("SDL2/SDL_image.h");
});

pub var WINDOW_WIDTH: c_int = 800;
pub var WINDOW_HEIGHT: c_int = 900;

const MAX_IMAGE_DIMENSION: i32 = 32767; // libpng's safe maximum (2^15 - 1)
const MAX_IMAGE_PIXELS: i64 = 500_000_000; // 500 megapixels max

pub const ORDER = "Order: {any}";
pub const MODULO = "Modulo: {any}";

const SDL_Color = sdl.struct_SDL_Color;

const FPS: i32 = 60;
const DELTA_TIME_SEC: f32 = 1.0 / @as(f32, @floatFromInt(FPS));

const OFFSET = 80;

pub var scaling: i32 = 1;
pub var globalCoordX: i32 = 0;
pub var globalCoordY: i32 = 0;

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

fn render_status_bar(
    renderer: *sdl.SDL_Renderer,
    font: *sdl.TTF_Font,
    order: usize,
    modulo: usize,
) !void {
    const status_buf = try kr.std.heap.page_allocator.alloc(u8, 256);
    defer kr.std.heap.page_allocator.free(status_buf);

    const status_text = try kr.std.fmt.bufPrint(
        status_buf,
        "Order: {d}/{d} | Modulo: {d} | {s} | Zoom: {d}x | \x00",
        .{ order, kr.number_of_calcmatrices, kr.moduli_list[modulo], clrs.current_color_scheme.name, scaling },
    );

    const status_surface = sdl.TTF_RenderText_Solid(
        font,
        @ptrCast(status_text.ptr),
        tosdlcolor(Color{ .r = 150, .g = 150, .b = 150, .a = 255 }),
    );
    defer sdl.SDL_FreeSurface(status_surface);

    if (status_surface == null) return;

    const status_texture = sdl.SDL_CreateTextureFromSurface(renderer, status_surface);
    defer sdl.SDL_DestroyTexture(status_texture);

    _ = sdl.SDL_RenderCopy(
        renderer,
        status_texture,
        null,
        &make_rect(10, 10, status_surface.*.w, status_surface.*.h),
    );
}

pub fn render(renderer: *sdl.SDL_Renderer, font: *sdl.TTF_Font, matrix: *kr.KravchukMatrix, idx: usize, modulo: usize, cell_display: *menu.CellValueDisplay, allocator: std.mem.Allocator) !void {
    _ = sdl.SDL_SetRenderDrawColor(renderer, background.r, background.g, background.b, background.a);
    _ = sdl.SDL_RenderClear(renderer);

    const real_idx = idx + 1;

    try render_status_bar(renderer, font, idx, modulo);

    const cellSizeW = @as(i32, @intCast(@as(usize, @intCast(WINDOW_WIDTH)) / (real_idx)));
    const cellSizeH = @as(i32, @intCast((@as(usize, @intCast(WINDOW_HEIGHT)) - OFFSET) / (real_idx)));
    const cellSize = @min(cellSizeW, cellSizeH);

    const usedW = cellSize * @as(i32, @intCast(real_idx));
    const usedH = cellSize * @as(i32, @intCast(real_idx));

    // globalCoordX = kr.std.math.clamp(globalCoordX, -WINDOW_WIDTH, WINDOW_WIDTH);
    // globalCoordY = kr.std.math.clamp(globalCoordY, -WINDOW_HEIGHT, WINDOW_HEIGHT);
    const startX = (WINDOW_WIDTH - usedW) >> 1;
    const startY = ((WINDOW_HEIGHT - usedH) >> 1) + (OFFSET >> 1);

    // _ = sdl.SDL_RenderSetScale(renderer, scaling, scaling);

    for (0..real_idx) |i| {
        for (0..real_idx) |j| {
            const cellCoordX = if (scaling > 0) @as(i32, @intCast(startX + @as(i32, @intCast(i)) * cellSize * scaling)) else @as(i32, @intCast(startX + @as(i32, @intCast(i)) * cellSize >> @as(u5, @intCast((1 - scaling)))));
            const cellCoordY = if (scaling > 0) @as(i32, @intCast(startY + @as(i32, @intCast(j)) * cellSize * scaling)) else @as(i32, @intCast(startY + @as(i32, @intCast(j)) * cellSize >> @as(u5, @intCast((1 - scaling)))));
            const color = clrs.colorScheme(matrix.get(i, j), kr.moduli_list[modulo]);
            _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
            _ = sdl.SDL_RenderFillRect(renderer, &make_rect(cellCoordX + globalCoordX, cellCoordY + globalCoordY, cellSize * scaling, cellSize * scaling));
        }
    }

    try cell_display.render(renderer, font, allocator);

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
    const dstrect_loading = make_rect((WINDOW_WIDTH - loading_surface.*.w) >> 1, (WINDOW_HEIGHT - loading_surface.*.h) >> 1, loading_surface.*.w, loading_surface.*.h);
    _ = sdl.SDL_RenderCopy(renderer, loading_texture, &srcrect_loading, &dstrect_loading);

    sdl.SDL_RenderPresent(renderer);
}

pub fn render_loading_matrices(renderer: *sdl.SDL_Renderer, font: *sdl.TTF_Font) !void {
    _ = sdl.SDL_RenderPresent(renderer);
    const loading_surface = sdl.TTF_RenderText_Solid(font, "Loading...", tosdlcolor(text_color));
    defer sdl.SDL_FreeSurface(loading_surface);

    if (loading_surface == null) {
        sdl.SDL_Log("Unable to initialize sdl: %s", sdl.SDL_GetError());
        return error.sdlSurfaceNotFound;
    }

    _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, background.a);

    _ = sdl.SDL_RenderFillRect(renderer, &make_rect((WINDOW_WIDTH - loading_surface.*.w) >> 1, (WINDOW_HEIGHT - loading_surface.*.h) >> 1, loading_surface.*.w, loading_surface.*.h));

    const loading_texture = sdl.SDL_CreateTextureFromSurface(renderer, loading_surface);
    defer sdl.SDL_DestroyTexture(loading_texture);

    _ = sdl.SDL_SetRenderDrawColor(renderer, text_color.r, text_color.g, text_color.b, text_color.a);

    const srcrect_loading = make_rect(0, 0, loading_surface.*.w, loading_surface.*.h);
    const dstrect_loading = make_rect((WINDOW_WIDTH - loading_surface.*.w) >> 1, (WINDOW_HEIGHT - loading_surface.*.h) >> 1, loading_surface.*.w, loading_surface.*.h);
    _ = sdl.SDL_RenderCopy(renderer, loading_texture, &srcrect_loading, &dstrect_loading);
    sdl.SDL_RenderPresent(renderer);
}

pub fn FPSdelay() void {
    sdl.SDL_Delay(1000 / FPS);
}

pub fn export_screen(title: [*c]const u8, matrix: *kr.KravchukMatrix, idx: usize, modulo: usize) !void {
    const cellSize = calculate_safe_cell_size(idx);

    const w = cellSize * @as(i32, @intCast(idx));
    const h = cellSize * @as(i32, @intCast(idx));

    // Validate dimensions BEFORE creating surface
    if (w <= 0 or h <= 0) {
        kr.std.debug.print("Error: Invalid image dimensions: {d}x{d}\n", .{ w, h });
        return error.InvalidImageDimensions;
    }

    if (w > MAX_IMAGE_DIMENSION or h > MAX_IMAGE_DIMENSION) {
        kr.std.debug.print(
            "Error: Image too large: {d}x{d} exceeds maximum of {d}x{d}\n",
            .{ w, h, MAX_IMAGE_DIMENSION, MAX_IMAGE_DIMENSION },
        );
        kr.std.debug.print(
            "Tip: For matrix order {d}, the maximum safe cell size is {d} pixels\n",
            .{ idx, @divFloor(MAX_IMAGE_DIMENSION, @as(i32, @intCast(idx))) },
        );
        return error.ImageTooLarge;
    }

    const total_pixels = @as(i64, w) * @as(i64, h);
    if (total_pixels > MAX_IMAGE_PIXELS) {
        kr.std.debug.print(
            "Error: Image has too many pixels: {d} exceeds maximum of {d}\n",
            .{ total_pixels, MAX_IMAGE_PIXELS },
        );
        return error.TooManyPixels;
    }

    _ = sdl.SDL_SetHint(sdl.SDL_HINT_RENDER_SCALE_QUALITY, "0");

    const surface = sdl.SDL_CreateRGBSurfaceWithFormat(
        0,
        w,
        h,
        32,
        sdl.SDL_PIXELFORMAT_RGBA32,
    );
    defer sdl.SDL_FreeSurface(surface);

    if (surface == null) {
        kr.std.debug.print("Failed to create surface of size {d}x{d}\n", .{ w, h });
        return error.SurfaceCreationFailed;
    }

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
                matrix.get(i, j),
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

    if (sdl.IMG_SavePNG(surface, title) != 0) {
        sdl.SDL_Log("Failed to save image: %s", sdl.SDL_GetError());
        return error.ImageSaveFailed;
    }

    kr.std.debug.print(
        "Successfully saved {d}x{d} image ({d} megapixels)\n",
        .{ w, h, @divFloor(total_pixels, 1_000_000) },
    );
}

fn calculate_safe_cell_size(idx: usize) i32 {
    const idx_i32 = @as(i32, @intCast(idx));

    const max_cell_for_dimension = @divFloor(MAX_IMAGE_DIMENSION, idx_i32);

    const max_total_for_pixels = @as(i32, @intFromFloat(@sqrt(@as(f64, @floatFromInt(MAX_IMAGE_PIXELS)))));
    const max_cell_for_pixels = @divFloor(max_total_for_pixels, idx_i32);

    const absolute_max = @min(max_cell_for_dimension, max_cell_for_pixels);

    var cell_size: i32 = undefined;

    if (idx <= 50) {
        cell_size = 20;
    } else if (idx <= 100) {
        cell_size = 15;
    } else if (idx <= 250) {
        cell_size = 10;
    } else if (idx <= 500) {
        cell_size = 5;
    } else if (idx <= 1000) {
        cell_size = 3;
    } else {
        cell_size = 2;
    }

    return @min(cell_size, absolute_max);
}
