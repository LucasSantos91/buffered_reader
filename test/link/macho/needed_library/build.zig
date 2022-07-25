const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjectStep = std.build.LibExeObjStep;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target: std.zig.CrossTarget = .{ .os_tag = .macos };

    const test_step = b.step("test", "Test the program");
    test_step.dependOn(b.getInstallStep());

    const dylib = b.addSharedLibrary("a", null, b.version(1, 0, 0));
    dylib.setTarget(target);
    dylib.setBuildMode(mode);
    dylib.addCSourceFile("a.c", &.{});
    dylib.linkLibC();
    dylib.install();

    // -dead_strip_dylibs
    // -needed-la
    const exe = b.addExecutable("test", null);
    exe.addCSourceFile("main.c", &[0][]const u8{});
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.linkLibC();
    exe.linkSystemLibraryNeeded("a");
    exe.addLibraryPath(b.pathFromRoot("zig-out/lib"));
    exe.addRPath(b.pathFromRoot("zig-out/lib"));
    exe.dead_strip_dylibs = true;

    const check = exe.checkObject(.macho);
    check.checkStart("cmd LOAD_DYLIB");
    check.checkNext("name @rpath/liba.dylib");

    const run_cmd = check.runAndCompare();
    test_step.dependOn(&run_cmd.step);
}
