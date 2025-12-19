const color = @import("colors.zig");
const Color = color.Color;

fn clamp01(x: f32) f32 {
    return if (x < 0.0) 0.0 else if (x > 1.0) 1.0 else x;
}

fn smoothstep(x: f32) f32 {
    // matches Mathematica-like soft brightness rolloff
    return x * x * (3.0 - 2.0 * x);
}

pub fn HSBtoRGB(h_raw: f32, b_raw: f32) Color {
    // wrap hue once
    const h = h_raw - @floor(h_raw);
    var b = clamp01(b_raw);

    // Mathematica smooths brightness
    b = smoothstep(b);

    const x = h * 6.0;
    const i: u8 = @as(u8, @intFromFloat(@floor(x))) % 6;
    const f = x - @floor(x);

    const p = 0.0;
    const q = b * (1.0 - f);
    const t = b * f;

    var r: f32 = 0;
    var g: f32 = 0;
    var bl: f32 = 0;

    switch (i) {
        0 => {
            r = b;
            g = t;
            bl = p;
        },
        1 => {
            r = q;
            g = b;
            bl = p;
        },
        2 => {
            r = p;
            g = b;
            bl = t;
        },
        3 => {
            r = p;
            g = q;
            bl = b;
        },
        4 => {
            r = t;
            g = p;
            bl = b;
        },
        5 => {
            r = b;
            g = p;
            bl = q;
        },
        else => {},
    }

    return Color{
        .r = @intFromFloat(clamp01(r) * 255.0),
        .g = @intFromFloat(clamp01(g) * 255.0),
        .b = @intFromFloat(clamp01(bl) * 255.0),
        .a = 255,
    };
}
