const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "krview",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    exe.linkSystemLibrary("SDL2");
    exe.linkLibC();

    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkLibC();

    const sdl_path = b.optionalPathFromEnv("VCPKG_ROOT") orelse .{ .path = "C:/vcpkg" };
    exe.addIncludePath(.{ .path = b.pathJoin(&.{ sdl_path, "installed", "x64-windows", "include" }) });
    exe.linkLibrary(.{
        .name = "SDL2",
        .path = b.pathJoin(&.{ sdl_path, "installed", "x64-windows", "lib", "SDL2.lib" }),
    });
    exe.linkLibrary(.{
        .name = "SDL2_ttf",
        .path = b.pathJoin(&.{ sdl_path, "installed", "x64-windows", "lib", "SDL2_ttf.lib" }),
    });

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
