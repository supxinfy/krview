const std = @import("std");

const lut = @import("colors_lut.zig");

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};
const ColorScheme = struct {
    name: []const u8,
};

pub var current_color_scheme = ColorScheme{
    .name = "Gogin",
};

fn Gogin_colorScheme(n: i32, modulo: u32) Color {
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

fn Hue_colorScheme(n: i32, modulo: u32) Color {
    const h: f32 = @as(f32, @floatFromInt(n)) / @as(f32, @floatFromInt(modulo));
    var i: u8 = @as(u8, @intFromFloat(h * 6.0));
    const f = h * 6.0 - @as(f32, @floatFromInt(i));
    const q = (1.0 - f);
    const t = f;
    i = i % 6;
    switch (i) {
        0 => return Color{
            .r = @as(u8, @intFromFloat(@mod(255, 255))),
            .g = @as(u8, @intFromFloat(@mod(t * 255, 255))),
            .b = @as(u8, 0),
            .a = 255,
        },
        1 => return Color{
            .r = @as(u8, @intFromFloat(@mod(q * 255, 255))),
            .g = @as(u8, @intFromFloat(@mod(255, 255))),
            .b = @as(u8, 0),
            .a = 255,
        },
        2 => return Color{
            .r = @as(u8, 0),
            .g = @as(u8, @intFromFloat(@mod(255, 255))),
            .b = @as(u8, @intFromFloat(@mod(t * 255, 255))),
            .a = 255,
        },
        3 => return Color{
            .r = @as(u8, 0),
            .g = @as(u8, @intFromFloat(@mod(q * 255, 255))),
            .b = @as(u8, @intFromFloat(@mod(255, 255))),
            .a = 255,
        },
        4 => return Color{
            .r = @as(u8, @intFromFloat(@mod(t * 255, 255))),
            .g = @as(u8, 0),
            .b = @as(u8, @intFromFloat(@mod(255, 255))),
            .a = 255,
        },
        5 => return Color{
            .r = @as(u8, @intFromFloat(@mod(255, 255))),
            .g = @as(u8, 0),
            .b = @as(u8, @intFromFloat(@mod(q * 255, 255))),
            .a = 255,
        },
        else => {
            return Color{ .r = 0, .g = 0, .b = 0, .a = 0 };
        },
    }
}

fn Gray_colorScheme(n: i32, modulo: u32) Color {
    const gray = @as(u8, @intFromFloat(@mod(@as(f32, @floatFromInt(n)) / @as(f32, @floatFromInt(modulo)) * 255.0, 255.0)));
    return Color{ .r = gray, .g = gray, .b = gray, .a = 255 };
}

fn Log_colorScheme(n: i32, modulo: u32) Color {
    const log = @as(u8, @intFromFloat(@mod(@log(@as(f32, @floatFromInt(n + 1))) / @log(@as(f32, @floatFromInt(modulo + 1))) * 255.0, 255.0)));
    return Color{ .r = log, .g = log, .b = log, .a = 255 };
}

fn lut_colorSchemes(n: i32, modulo: u32, lut_array: [256][3]u8) Color {
    const t = @as(f32, 255) / @as(f32, @floatFromInt(modulo));
    const len = 256;
    const x = t * @as(f32, @floatFromInt(n));
    const i = @min(@as(usize, @intFromFloat(x)), len - 2);
    const f = x - @as(f32, @floatFromInt(i));

    const c0 = lut_array[i];
    const c1 = lut_array[i + 1];

    return Color{
        .r = @intFromFloat((1 - f) * @as(f32, @floatFromInt(c0[0])) + f * @as(f32, @floatFromInt(c1[0]))),
        .g = @intFromFloat((1 - f) * @as(f32, @floatFromInt(c0[1])) + f * @as(f32, @floatFromInt(c1[1]))),
        .b = @intFromFloat((1 - f) * @as(f32, @floatFromInt(c0[2])) + f * @as(f32, @floatFromInt(c1[2]))),
        .a = 255,
    };
}

pub fn colorScheme(n: i32, modulo: u32) Color {
    if (std.mem.eql(u8, current_color_scheme.name, "Gogin")) {
        return Gogin_colorScheme(n, modulo);
    } else if (std.mem.eql(u8, current_color_scheme.name, "Gray")) {
        return Gray_colorScheme(n, modulo);
    } else if (std.mem.eql(u8, current_color_scheme.name, "Log")) {
        return Log_colorScheme(n, modulo);
    } else if (std.mem.eql(u8, current_color_scheme.name, "Hue")) {
        return Hue_colorScheme(n, modulo);
    } else if (std.mem.eql(u8, current_color_scheme.name, "Viridis")) {
        return lut_colorSchemes(n, modulo, lut.viridis_lut);
    } else if (std.mem.eql(u8, current_color_scheme.name, "Plasma")) {
        return lut_colorSchemes(n, modulo, lut.plasma_lut);
    } else if (std.mem.eql(u8, current_color_scheme.name, "Magma")) {
        return lut_colorSchemes(n, modulo, lut.magma_lut);
    } else {
        return Gogin_colorScheme(n, modulo); // Default to Gogin if unknown
    }
}

pub fn nextColorScheme(name: []const u8) []const u8 {
    if (std.mem.eql(u8, name, "Gogin")) return "Gray";
    if (std.mem.eql(u8, name, "Gray")) return "Log";
    if (std.mem.eql(u8, name, "Log")) return "Hue";
    if (std.mem.eql(u8, name, "Hue")) return "Viridis";
    if (std.mem.eql(u8, name, "Viridis")) return "Plasma";
    if (std.mem.eql(u8, name, "Plasma")) return "Magma";
    if (std.mem.eql(u8, name, "Magma")) return "Gogin";
    return "Gogin";
}
