const std = @import("std");
const zeit = @import("zeit");
const r = @import("rendering.zig");
const clrs = @import("colorshemes.zig");
const kr = @import("krawtchouk.zig");

var n_val: usize = undefined;
var m_val: usize = undefined;
var current_log_file: ?std.fs.File = null;

const allocator = std.heap.page_allocator;

pub fn args_parser(args: *std.process.ArgIterator) !bool {
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            help();
            return true;
        }
        if (std.mem.eql(u8, arg, "render")) {
            const next_arg = args.next() orelse {
                try log("(Console) Missing render arguments.");
                return error.MissingRenderArguments;
            };
            if (std.mem.eql(u8, next_arg, "-n")) {
                const n_str = args.next() orelse {
                    try log("(Console) Missing matrix order argument.");
                    return error.MissingMatrixOrderArgument;
                };
                n_val = std.fmt.parseInt(usize, n_str, 10) catch |err| switch (err) {
                    error.InvalidCharacter => {
                        try log("(Console) No matrix order value specified.");
                        return error.MatrixOrderInvalidCharacter;
                    },
                    error.Overflow => {
                        try log("(Console) Matrix order value is too large.");
                        return error.MatrixOrderOverflow;
                    },
                };

                if (n_val == 0 or n_val > kr.number_of_matrices - 1) {
                    try log("(Console) Matrix order value out of bounds.");
                    return error.MatrixOrderValue;
                }
            }
            const next_next_arg = args.next() orelse {
                try log("(Console) Missing modulo argument.");
                return error.MissingModuloArgument;
            };
            if (std.mem.eql(u8, next_next_arg, "-m")) {
                const m_str = args.next() orelse {
                    try log("(Console) Missing modulo value argument.");
                    return error.MissingModuloValueArgument;
                };
                m_val = std.fmt.parseInt(usize, m_str, 10) catch |err| switch (err) {
                    error.InvalidCharacter => {
                        try log("(Console) No modulo value specified.");
                        return error.ModuloInvalidCharacter;
                    },
                    error.Overflow => {
                        try log("(Console) Modulo value is too large.");
                        return error.ModuloOverflow;
                    },
                };
            }
            var m_idx: i32 = -1;
            for (kr.moduli_list, 0..) |mod, idx| {
                if (mod == m_val) {
                    m_idx = @as(i32, @intCast(idx));
                }
            }

            if (m_idx == -1) {
                try log("(Console) Specified modulo is not supported.");
                return error.InvalidModulo;
            }

            try kr.calculate_data();

            const export_title_buf = try allocator.allocSentinel(u8, 256, 0);
            defer allocator.free(export_title_buf);

            const export_title = try std.fmt.bufPrint(
                export_title_buf,
                "assets/screenshots/km-o{}m{}{s}.jpg",
                .{
                    n_val,
                    m_val,
                    clrs.current_color_scheme.name,
                },
            );
            export_title_buf[export_title.len] = 0;

            const export_title_z: [:0]const u8 = export_title_buf[0..export_title.len :0];

            try r.export_screen(export_title_z, kr.matrices[n_val], n_val, @as(usize, @intCast(m_idx)));
            return true;
        } else {
            try log("(Console) Ignore an unknown argument...");
            return true;
        }
    }
    return false;
}

pub fn help() void {
    std.debug.print("\n", .{});
    std.debug.print("   Usage:\n", .{});
    std.debug.print("   krview [options]\n", .{});
    std.debug.print("   Options:\n", .{});
    std.debug.print("   -h, --help     Show this help message\n", .{});
    std.debug.print("   render         Render a matrix and save it in assets/screenshots/\n", .{});
    std.debug.print("   -n             Matrix order\n", .{});
    std.debug.print("   -m             Modulo\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("   Some example usages:\n", .{});
    std.debug.print("   krview --help\n", .{});
    std.debug.print("   krview render -n 257 -m 13\n", .{});
    std.debug.print("\n", .{});
}

pub fn start_logging() !void {
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    const now = try zeit.instant(.{});

    const local = try zeit.local(allocator, &env);
    const now_local = now.in(&local);
    const dt = now_local.time();

    std.fs.cwd().makeDir("logs") catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };

    const log_title = try allocator.alloc(u8, 256);
    defer allocator.free(log_title);

    const log_title_format = try std.fmt.bufPrint(
        log_title,
        "logs/log{}-{s}-{:02}-{:02}{:02}{:02}.txt",
        .{
            dt.year,
            zeit.Month.shortName(dt.month),
            dt.day,
            dt.hour,
            dt.minute,
            dt.second,
        },
    );

    const log_file = std.fs.cwd().createFile(log_title_format, .{}) catch |err| {
        std.debug.print("Failed to create log file: {}\n", .{err});
        return err;
    };
    current_log_file = log_file;
}

pub fn log(message: []const u8) !void {
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    const now = try zeit.instant(.{});

    const local = try zeit.local(allocator, &env);
    const now_local = now.in(&local);
    const dt = now_local.time();

    const log_title = try allocator.alloc(u8, 256);
    defer allocator.free(log_title);

    const timestamp = try std.fmt.bufPrint(
        log_title,
        "{}:{}:{}",
        .{
            dt.hour,
            dt.minute,
            dt.second,
        },
    );

    const whole_message_buf = try allocator.alloc(u8, 512);
    defer allocator.free(whole_message_buf);

    const whole_message = try std.fmt.bufPrint(
        whole_message_buf,
        "[{s}] {s}\n",
        .{ timestamp, message },
    );
    if (current_log_file) |file| {
        _ = try file.write(whole_message);
    }
}

pub fn render_matrix(n: i32, modulo: i32) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const general_allocator = gpa.allocator();
    defer gpa.deinit();

    const export_title_buf = try general_allocator.allocSentinel(u8, 256, 0);
    defer general_allocator.free(export_title_buf);

    var modulo_exists = false;
    for (kr.moduli_list) |mod| {
        if (mod == modulo) {
            modulo_exists = true;
            break;
        }
    }
    if (!modulo_exists) {
        try log("(Console) Invalid modulo specified.");
        return error.InvalidModulo;
    }

    const export_title = try std.fmt.bufPrint(
        export_title_buf,
        "assets/screenshots/km-o{}m{}{s}.jpg",
        .{
            n,
            modulo,
            clrs.current_color_scheme.name,
        },
    );
    export_title_buf[export_title.len] = 0;

    const export_title_z: [:0]const u8 = export_title_buf[0..export_title.len :0];

    try r.export_screen(export_title_z, kr.matrices[n], n, modulo);
}

pub fn stop_logging() !void {
    if (current_log_file) |file| {
        file.close();
        current_log_file = null;
    }
}
