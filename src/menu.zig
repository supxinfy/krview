const std = @import("std");
const r = @import("rendering.zig");
const colortype = @import("colors.zig");
const Color = colortype.Color;

pub const MenuState = enum {
    main_menu,
    controls_menu,
    game_running,
};

pub const Button = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    text: [*c]const u8,
    hovered: bool = false,

    pub fn is_inside(self: *const Button, mouse_x: i32, mouse_y: i32) bool {
        return mouse_x >= self.x and
            mouse_x <= self.x + self.w and
            mouse_y >= self.y and
            mouse_y <= self.y + self.h;
    }

    pub fn render(
        self: *Button,
        renderer: *r.sdl.SDL_Renderer,
        font: *r.sdl.TTF_Font,
    ) !void {
        // Button background
        const bg_color = if (self.hovered)
            Color{ .r = 80, .g = 120, .b = 180, .a = 255 }
        else
            Color{ .r = 60, .g = 60, .b = 60, .a = 255 };

        _ = r.sdl.SDL_SetRenderDrawColor(renderer, bg_color.r, bg_color.g, bg_color.b, bg_color.a);
        const rect = r.sdl.SDL_Rect{ .x = self.x, .y = self.y, .w = self.w, .h = self.h };
        _ = r.sdl.SDL_RenderFillRect(renderer, &rect);

        // Button border
        const border_color = if (self.hovered)
            Color{ .r = 120, .g = 160, .b = 220, .a = 255 }
        else
            Color{ .r = 100, .g = 100, .b = 100, .a = 255 };

        _ = r.sdl.SDL_SetRenderDrawColor(renderer, border_color.r, border_color.g, border_color.b, border_color.a);
        _ = r.sdl.SDL_RenderDrawRect(renderer, &rect);

        // Button text
        const text_color = Color{ .r = 220, .g = 220, .b = 220, .a = 255 };
        const text_surface = r.sdl.TTF_RenderText_Solid(font, self.text, r.sdl.SDL_Color{
            .r = text_color.r,
            .g = text_color.g,
            .b = text_color.b,
            .a = text_color.a,
        });

        if (text_surface == null) return error.TextRenderFailed;
        defer r.sdl.SDL_FreeSurface(text_surface);

        const text_texture = r.sdl.SDL_CreateTextureFromSurface(renderer, text_surface);
        defer r.sdl.SDL_DestroyTexture(text_texture);

        // FIXED: Added parentheses to ensure correct order of operations
        const text_x = self.x + ((self.w - text_surface.*.w) >> 1);
        const text_y = self.y + ((self.h - text_surface.*.h) >> 1);

        const text_rect = r.sdl.SDL_Rect{
            .x = text_x,
            .y = text_y,
            .w = text_surface.*.w,
            .h = text_surface.*.h,
        };

        _ = r.sdl.SDL_RenderCopy(renderer, text_texture, null, &text_rect);
    }
};

pub const Menu = struct {
    state: MenuState = .main_menu,
    start_button: Button,
    controls_button: Button,
    mode_button: Button,
    quit_button: Button,
    back_button: Button,
    matrix_type: matrix_type,

    pub fn init(window_width: i32, window_height: i32) Menu {
        const button_width: i32 = 300;
        const button_height: i32 = 60;
        const button_spacing: i32 = 20;
        const center_x = (window_width - button_width) >> 1;
        const start_y = (window_height >> 1) - 60;

        return Menu{
            .start_button = Button{
                .x = center_x,
                .y = start_y,
                .w = button_width,
                .h = button_height,
                .text = "Start",
            },
            .controls_button = Button{
                .x = center_x,
                .y = start_y + button_height + button_spacing,
                .w = button_width,
                .h = button_height,
                .text = "Controls",
            },
            .mode_button = Button{
                .x = center_x,
                .y = start_y + 2 * (button_height + button_spacing),
                .w = button_width,
                .h = button_height,
                .text = "Change Matrix Type",
            },
            .quit_button = Button{
                .x = center_x,
                .y = start_y + 3 * (button_height + button_spacing),
                .w = button_width,
                .h = button_height,
                .text = "Quit",
            },
            .back_button = Button{
                .x = 20,
                .y = window_height - 80,
                .w = 150,
                .h = 50,
                .text = "Back",
            },
            .matrix_type = .krawtchouk,
        };
    }

    pub fn update_mouse_position(self: *Menu, mouse_x: i32, mouse_y: i32) void {
        switch (self.state) {
            .main_menu => {
                self.start_button.hovered = self.start_button.is_inside(mouse_x, mouse_y);
                self.controls_button.hovered = self.controls_button.is_inside(mouse_x, mouse_y);
                self.mode_button.hovered = self.mode_button.is_inside(mouse_x, mouse_y);
                self.quit_button.hovered = self.quit_button.is_inside(mouse_x, mouse_y);
            },
            .controls_menu => {
                self.back_button.hovered = self.back_button.is_inside(mouse_x, mouse_y);
            },
            .game_running => {},
        }
    }

    pub fn handle_click(self: *Menu, mouse_x: i32, mouse_y: i32) ?MenuAction {
        switch (self.state) {
            .main_menu => {
                if (self.start_button.is_inside(mouse_x, mouse_y)) {
                    return .start_game;
                }
                if (self.controls_button.is_inside(mouse_x, mouse_y)) {
                    return .show_controls;
                }
                if (self.mode_button.is_inside(mouse_x, mouse_y)) {
                    return .mode_button;
                }
                if (self.quit_button.is_inside(mouse_x, mouse_y)) {
                    return .quit;
                }
            },
            .controls_menu => {
                if (self.back_button.is_inside(mouse_x, mouse_y)) {
                    return .back_to_main;
                }
            },
            .game_running => {},
        }
        return null;
    }

    pub fn render_main_menu(
        self: *Menu,
        renderer: *r.sdl.SDL_Renderer,
        font: *r.sdl.TTF_Font,
    ) !void {
        // Background
        _ = r.sdl.SDL_SetRenderDrawColor(renderer, 18, 18, 18, 255);
        _ = r.sdl.SDL_RenderClear(renderer);

        // Title
        const title_text = switch (self.matrix_type) {
            .krawtchouk => "Kravchuk Matrix Viewer",
            .chebyshev => "Chebyshev Matrix Viewer",
            .pascal => "Pascal Matrix Viewer",
        };
        //const title_text = "Kravchuk Matrix Viewer";
        const title_surface = r.sdl.TTF_RenderText_Solid(font, title_text, r.sdl.SDL_Color{
            .r = 220,
            .g = 220,
            .b = 220,
            .a = 255,
        });
        defer r.sdl.SDL_FreeSurface(title_surface);

        if (title_surface != null) {
            const title_texture = r.sdl.SDL_CreateTextureFromSurface(renderer, title_surface);
            defer r.sdl.SDL_DestroyTexture(title_texture);

            const title_rect = r.sdl.SDL_Rect{
                .x = (r.WINDOW_WIDTH - title_surface.*.w) >> 1,
                .y = 100,
                .w = title_surface.*.w,
                .h = title_surface.*.h,
            };
            _ = r.sdl.SDL_RenderCopy(renderer, title_texture, null, &title_rect);
        }

        // Buttons
        try self.start_button.render(renderer, font);
        try self.controls_button.render(renderer, font);
        try self.mode_button.render(renderer, font);
        try self.quit_button.render(renderer, font);

        r.sdl.SDL_RenderPresent(renderer);
    }

    pub fn render_controls_menu(
        self: *Menu,
        renderer: *r.sdl.SDL_Renderer,
        font: *r.sdl.TTF_Font,
    ) !void {
        // Background
        _ = r.sdl.SDL_SetRenderDrawColor(renderer, 18, 18, 18, 255);
        _ = r.sdl.SDL_RenderClear(renderer);

        // Title
        const title_text = "Controls";
        const title_surface = r.sdl.TTF_RenderText_Solid(font, title_text, r.sdl.SDL_Color{
            .r = 220,
            .g = 220,
            .b = 220,
            .a = 255,
        });
        defer r.sdl.SDL_FreeSurface(title_surface);

        if (title_surface != null) {
            const title_texture = r.sdl.SDL_CreateTextureFromSurface(renderer, title_surface);
            defer r.sdl.SDL_DestroyTexture(title_texture);

            const title_rect = r.sdl.SDL_Rect{
                .x = (r.WINDOW_WIDTH - title_surface.*.w) >> 1,
                .y = 50,
                .w = title_surface.*.w,
                .h = title_surface.*.h,
            };
            _ = r.sdl.SDL_RenderCopy(renderer, title_texture, null, &title_rect);
        }

        // Control list
        const controls = [_][*c]const u8{
            "Navigation:",
            "  W/S or Up/Down      - Change Matrix Order",
            "  A/D or Left/Right   - Change Modulo",
            "  Hold SHIFT          - Fast navigation",
            "",
            "View:",
            "  C                   - Cycle Color Scheme",
            "  Z/X                 - Zoom In/Out",
            "  I/J/K/L             - Pan view",
            "  R                   - Reset view",
            "  Mouse Drag          - Pan matrix",
            "  Mouse Click         - Show cell value",
            "",
            "Actions:",
            "  E                   - Export as PNG",
            "  H or SPACE          - Toggle help",
            "  ESC                 - Back to menu",
        };

        var y: i32 = 120;
        for (controls) |line| {
            const line_surface = r.sdl.TTF_RenderText_Solid(font, line, r.sdl.SDL_Color{
                .r = 200,
                .g = 200,
                .b = 200,
                .a = 255,
            });
            defer r.sdl.SDL_FreeSurface(line_surface);

            if (line_surface != null) {
                const line_texture = r.sdl.SDL_CreateTextureFromSurface(renderer, line_surface);
                defer r.sdl.SDL_DestroyTexture(line_texture);

                const line_rect = r.sdl.SDL_Rect{
                    .x = 100,
                    .y = y,
                    .w = line_surface.*.w,
                    .h = line_surface.*.h,
                };
                _ = r.sdl.SDL_RenderCopy(renderer, line_texture, null, &line_rect);
            }

            y += 30;
        }

        // Back button
        try self.back_button.render(renderer, font);

        r.sdl.SDL_RenderPresent(renderer);
    }
};

pub const MenuAction = enum {
    start_game,
    show_controls,
    back_to_main,
    mode_button,
    quit,
};

pub const matrix_type = enum {
    krawtchouk,
    chebyshev,
    pascal,
    pub fn next(self: matrix_type) matrix_type {
        return switch (self) {
            .krawtchouk => .chebyshev,
            .chebyshev => .pascal,
            .pascal => .krawtchouk,
        };
    }
};

// Cell value display overlay
pub const CellValueDisplay = struct {
    active: bool = false,
    i: usize = 0,
    j: usize = 0,
    value: i32 = 0,
    timer: i32 = 0,

    pub fn show(self: *CellValueDisplay, i: usize, j: usize, value: i32) void {
        self.active = true;
        self.i = i;
        self.j = j;
        self.value = value;
        self.timer = 60; // 3 seconds at 60fps
    }

    pub fn update(self: *CellValueDisplay) void {
        if (self.timer > 0) {
            self.timer -= 1;
        } else {
            self.active = false;
        }
    }

    pub fn render(
        self: *CellValueDisplay,
        renderer: *r.sdl.SDL_Renderer,
        font: *r.sdl.TTF_Font,
        allocator: std.mem.Allocator,
    ) !void {
        if (!self.active) return;

        const text_buf = try allocator.alloc(u8, 256);
        defer allocator.free(text_buf);

        const text = try std.fmt.bufPrint(
            text_buf,
            "Cell [{d},{d}] = {d}\x00",
            .{ self.i, self.j, self.value },
        );

        // Semi-transparent background box
        const box_padding: i32 = 20;
        const text_surface = r.sdl.TTF_RenderText_Solid(font, @ptrCast(text.ptr), r.sdl.SDL_Color{
            .r = 255,
            .g = 255,
            .b = 255,
            .a = 255,
        });

        if (text_surface == null) return;
        defer r.sdl.SDL_FreeSurface(text_surface);

        const box_w = text_surface.*.w + box_padding * 2;
        const box_h = text_surface.*.h + box_padding * 2;
        const box_x = (r.WINDOW_WIDTH - box_w) >> 1;
        const box_y = r.WINDOW_HEIGHT - 150;

        // Background with fade effect based on timer
        // const alpha: u8 = if (self.timer < 60)
        //     @intCast(@divFloor((self.timer * 255), 60))
        // else
        //     255;
        const alpha: u8 = 255;

        _ = r.sdl.SDL_SetRenderDrawBlendMode(renderer, r.sdl.SDL_BLENDMODE_BLEND);
        _ = r.sdl.SDL_SetRenderDrawColor(renderer, 40, 40, 40, alpha);
        const box_rect = r.sdl.SDL_Rect{ .x = box_x, .y = box_y, .w = box_w, .h = box_h };
        _ = r.sdl.SDL_RenderFillRect(renderer, &box_rect);

        // Border
        _ = r.sdl.SDL_SetRenderDrawColor(renderer, 100, 150, 200, alpha);
        _ = r.sdl.SDL_RenderDrawRect(renderer, &box_rect);

        // Text
        const text_texture = r.sdl.SDL_CreateTextureFromSurface(renderer, text_surface);
        defer r.sdl.SDL_DestroyTexture(text_texture);

        _ = r.sdl.SDL_SetTextureAlphaMod(text_texture, alpha);

        const text_rect = r.sdl.SDL_Rect{
            .x = box_x + box_padding,
            .y = box_y + box_padding,
            .w = text_surface.*.w,
            .h = text_surface.*.h,
        };
        _ = r.sdl.SDL_RenderCopy(renderer, text_texture, null, &text_rect);
    }
};
