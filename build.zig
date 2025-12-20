const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add executable
    const exe = b.addExecutable(.{
        .name = "krview",
        .root_module = root_module,
    });

    // Link SDL2 libraries
    if (target.query.os_tag == .windows) {
        const sdl_root = "C:/vcpkg/installed/x64-windows";
        exe.addIncludePath(b.path(sdl_root ++ "/include"));
        exe.addLibraryPath(b.path(sdl_root ++ "/lib"));
        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("SDL2_ttf");
        exe.linkSystemLibrary("SDL2_image");
    } else {
        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("SDL2_ttf");
        exe.linkSystemLibrary("SDL2_image");
    }

    exe.linkLibC();

    // Install and add run step
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
