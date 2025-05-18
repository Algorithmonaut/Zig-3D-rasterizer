const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "rasterizer",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link against C standard library and minifb
    exe.linkLibC();
    exe.linkSystemLibrary("minifb");

    // Additional system libraries for Linux (X11)
    if (target.result.os.tag == .linux) {
        exe.linkSystemLibrary("X11");
        exe.linkSystemLibrary("Xrandr");
        exe.linkSystemLibrary("Xinerama");
        exe.linkSystemLibrary("Xxf86vm");
        exe.linkSystemLibrary("Xi");
        exe.linkSystemLibrary("dl");
        exe.linkSystemLibrary("pthread");
        exe.linkSystemLibrary("GL");
    }

    b.installArtifact(exe);

    const run_step = b.addRunArtifact(exe);
    b.step("run", "Run the game-of-life app").dependOn(&run_step.step);
}
