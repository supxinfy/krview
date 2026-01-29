const std = @import("std");
const zeit = @import("zeit");
const r = @import("rendering.zig");
const clrs = @import("colorshemes.zig");
const kr = @import("krawtchouk.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
var current_log_file: ?std.fs.File = null;
var cached_timezone: ?zeit.TimeZone = null;

const MAX_MATRIX_ORDER = 1000;

pub fn init_logging() !void {
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();
    cached_timezone = try zeit.local(allocator, &env);

    try cleanup_old_logs();

    try start_logging();
}

fn cleanup_old_logs() !void {
    var logs_dir = std.fs.cwd().openDir("logs", .{ .iterate = true }) catch |err| {
        if (err == error.FileNotFound) return; // No logs directory yet
        return err;
    };
    defer logs_dir.close();

    var newest_log: ?[]const u8 = null;
    defer if (newest_log) |name| allocator.free(name);

    var iter = logs_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file and std.mem.startsWith(u8, entry.name, "log")) {
            if (newest_log) |current_newest| {
                // Compare filenames (lexicographically since they have timestamps)
                if (std.mem.order(u8, entry.name, current_newest) == .gt) {
                    allocator.free(current_newest);
                    newest_log = try allocator.dupe(u8, entry.name);
                }
            } else {
                newest_log = try allocator.dupe(u8, entry.name);
            }
        }
    }

    if (newest_log) |keep_file| {
        var iter2 = logs_dir.iterate();
        while (try iter2.next()) |entry| {
            if (entry.kind == .file and std.mem.startsWith(u8, entry.name, "log")) {
                if (!std.mem.eql(u8, entry.name, keep_file)) {
                    logs_dir.deleteFile(entry.name) catch |err| {
                        std.debug.print("Warning: Failed to delete old log {s}: {}\n", .{ entry.name, err });
                    };
                }
            }
        }
    }
}

fn start_logging() !void {
    const local = cached_timezone orelse return error.LoggingNotInitialized;
    const now = try zeit.instant(.{});
    const now_local = now.in(&local);
    const dt = now_local.time();

    std.fs.cwd().makeDir("logs") catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    const log_filename = try std.fmt.allocPrint(
        allocator,
        "logs/log{d}-{s}-{d:0>2}-{d:0>2}{d:0>2}{d:0>2}.txt",
        .{
            dt.year,
            zeit.Month.shortName(dt.month),
            dt.day,
            dt.hour,
            dt.minute,
            dt.second,
        },
    );
    defer allocator.free(log_filename);

    const log_file = try std.fs.cwd().createFile(log_filename, .{});
    current_log_file = log_file;
}

pub fn log(message: []const u8) !void {
    const local = cached_timezone orelse return error.LoggingNotInitialized;
    const now = try zeit.instant(.{});
    const now_local = now.in(&local);
    const dt = now_local.time();

    const log_message = try std.fmt.allocPrint(
        allocator,
        "[{d:0>2}:{d:0>2}:{d:0>2}] {s}\n",
        .{ dt.hour, dt.minute, dt.second, message },
    );
    defer allocator.free(log_message);

    if (current_log_file) |file| {
        _ = try file.write(log_message);
        try file.sync(); // Ensure write persists
    }

    std.debug.print("{s}", .{log_message});
}

pub fn stop_logging() void {
    if (current_log_file) |file| {
        file.close();
        current_log_file = null;
    }
}

pub fn deinit() void {
    stop_logging();
    if (cached_timezone) |*tz| {
        tz.deinit();
    }
    _ = gpa.deinit();
}

pub fn args_parser(args: *std.process.ArgIterator) !bool {
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            help();
            return true;
        }

        if (std.mem.eql(u8, arg, "render")) {
            try handle_render_command(args);
            return true;
        }

        const msg = try std.fmt.allocPrint(allocator, "(Console) Ignoring unknown argument: {s}", .{arg});
        defer allocator.free(msg);
        try log(msg);
    }
    return false;
}

fn handle_render_command(args: *std.process.ArgIterator) !void {
    const n_flag = args.next() orelse {
        try log("(Console) Missing -n flag after render command.");
        try log("(Console) Usage: krview render -n <order> -m <modulo>");
        return error.MissingNFlag;
    };

    if (!std.mem.eql(u8, n_flag, "-n")) {
        const msg = try std.fmt.allocPrint(
            allocator,
            "(Console) Expected -n flag, got: {s}",
            .{n_flag},
        );
        defer allocator.free(msg);
        try log(msg);
        return error.ExpectedNFlag;
    }

    const n_str = args.next() orelse {
        try log("(Console) Missing matrix order value after -n.");
        return error.MissingMatrixOrder;
    };

    const n_val = parseUsize(n_str, "Matrix order") catch |err| {
        return err;
    };

    const m_flag = args.next() orelse {
        try log("(Console) Missing -m flag.");
        try log("(Console) Usage: krview render -n <order> -m <modulo>");
        return error.MissingMFlag;
    };

    if (!std.mem.eql(u8, m_flag, "-m")) {
        const msg = try std.fmt.allocPrint(
            allocator,
            "(Console) Expected -m flag, got: {s}",
            .{m_flag},
        );
        defer allocator.free(msg);
        try log(msg);
        return error.ExpectedMFlag;
    }

    const m_str = args.next() orelse {
        try log("(Console) Missing modulo value after -m.");
        return error.MissingModuloValue;
    };

    const m_val = parseUsize(m_str, "Modulo") catch |err| {
        return err;
    };

    const m_idx = find_modulo_index(m_val) orelse {
        const msg = try std.fmt.allocPrint(
            allocator,
            "(Console) Modulo {d} is not supported. Supported moduli: {any}",
            .{ m_val, kr.moduli_list },
        );
        defer allocator.free(msg);
        try log(msg);
        return error.InvalidModulo;
    };

    if (n_val > MAX_MATRIX_ORDER) {
        const msg = try std.fmt.allocPrint(
            allocator,
            "(Console) Matrix order {d} exceeds maximum of {d}.",
            .{ n_val, kr.number_of_matrices },
        );
        defer allocator.free(msg);
        try log(msg);
        return error.MatrixOrderTooLarge;
    }

    const start_msg = try std.fmt.allocPrint(
        allocator,
        "(Console) Calculating Kravchuk matrix: order={d}, modulo={d}...",
        .{ n_val, m_val },
    );
    defer allocator.free(start_msg);
    try log(start_msg);

    try kr.calculate_data_for_render(allocator, n_val, m_idx);

    try log("(Console) Calculation complete. Rendering image...");

    std.fs.cwd().makePath("assets/screenshots") catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    const filename_buf = try std.fmt.allocPrint(
        allocator,
        "assets/screenshots/km-o{d}m{d}{s}.png",
        .{ n_val, m_val, clrs.current_color_scheme.name },
    );
    defer allocator.free(filename_buf);

    const filename = try allocator.dupeZ(u8, filename_buf);
    defer allocator.free(filename);

    r.export_screen(
        filename,
        kr.moduliList[m_idx].items[0],
        n_val,
        m_idx,
    ) catch |err| {
        const err_msg = try std.fmt.allocPrint(
            allocator,
            "(Console) Failed to export image: {s}",
            .{@errorName(err)},
        );
        defer allocator.free(err_msg);
        try log(err_msg);

        if (err == error.ImageTooLarge or err == error.TooManyPixels) {
            const hint = try std.fmt.allocPrint(
                allocator,
                "(Console) Hint: Matrix order {d} is too large to export at high quality.",
                .{n_val},
            );
            defer allocator.free(hint);
            try log(hint);
            try log("(Console) Try using a smaller matrix order (< 1000 recommended).");
        }

        return err;
    };

    const success_msg = try std.fmt.allocPrint(
        allocator,
        "(Console) Image saved to: {s}",
        .{filename},
    );
    defer allocator.free(success_msg);
    try log(success_msg);
}

fn parseUsize(str: []const u8, field_name: []const u8) !usize {
    return std.fmt.parseInt(usize, str, 10) catch |err| {
        const msg = try std.fmt.allocPrint(
            allocator,
            "(Console) Invalid {s} value '{s}': {s}",
            .{ field_name, str, @errorName(err) },
        );
        defer allocator.free(msg);
        try log(msg);
        return err;
    };
}

/// Find the index of a modulo in the moduli list
fn find_modulo_index(modulo: usize) ?usize {
    for (kr.moduli_list, 0..) |mod, idx| {
        if (mod == modulo) return idx;
    }
    return null;
}

/// Print help message
pub fn help() void {
    std.debug.print("\n", .{});
    std.debug.print("   Kravchuk Matrix Viewer\n", .{});
    std.debug.print("   =====================\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("   Usage:\n", .{});
    std.debug.print("      krview [command] [options]\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("   Commands:\n", .{});
    std.debug.print("      render              Render a Kravchuk matrix and save as PNG\n", .{});
    std.debug.print("      -h, --help          Show this help message\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("   Render Options:\n", .{});
    std.debug.print("      -n <order>          Matrix order (0-{d})\n", .{kr.number_of_matrices});
    std.debug.print("      -m <modulo>         Prime modulo (supported: {any})\n", .{kr.moduli_list});
    std.debug.print("\n", .{});
    std.debug.print("   Examples:\n", .{});
    std.debug.print("      krview --help\n", .{});
    std.debug.print("      krview render -n 257 -m 13\n", .{});
    std.debug.print("      krview render -n 50 -m 31\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("   Output:\n", .{});
    std.debug.print("      Images are saved to: assets/screenshots/km-o<order>m<modulo><colorscheme>.png\n", .{});
    std.debug.print("      Logs are saved to:   logs/log<timestamp>.txt\n", .{});
    std.debug.print("\n", .{});
}
