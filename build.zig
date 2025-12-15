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

    if (target.result.os.tag == .windows) {
        const sdl_root = "C:/vcpkg/installed/x64-windows";

        exe.addIncludePath(b.path(sdl_root ++ "/include"));
        exe.addLibraryPath(b.path(sdl_root ++ "/lib"));

        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("SDL2_ttf");
    } else {
        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("SDL2_ttf");
    }

    exe.linkLibC();

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
