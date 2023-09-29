const std = @import("std");

const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const name = "day_04";

    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .path = name ++ ".zig" },
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const benchmark_cmd = b.addSystemCommand(&.{ "hyperfine", "--shell=none", "--warmup=10", "--input=./input" });
    benchmark_cmd.addArg("./zig-out/bin/" ++ name);
    benchmark_cmd.step.dependOn(b.getInstallStep());

    const benchmark_step = b.step("benchmark", "Benchmark the app with hyperfine");
    benchmark_step.dependOn(&benchmark_cmd.step);
}
