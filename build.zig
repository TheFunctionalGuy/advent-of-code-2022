const std = @import("std");
const os = std.os;

const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    {
        var directory = try b.build_root.handle.openIterableDir(".", .{});
        defer directory.close();

        var iter = directory.iterate();

        while (try iter.next()) |sub_directory| {
            if (std.mem.startsWith(u8, sub_directory.name, "day_")) {
                // Intentional memory leak
                const path = try std.mem.concat(b.allocator, u8, &.{ sub_directory.name, "/", sub_directory.name, ".zig" });

                // === zig build (install) ===
                {
                    const exe = b.addExecutable(.{
                        .name = sub_directory.name,
                        .root_source_file = .{ .path = path },
                        .target = target,
                        .optimize = optimize,
                    });

                    // Install all executables on default command
                    b.installArtifact(exe);

                    // === zig build run ===
                    {
                        const install_exe = b.addInstallArtifact(exe, .{});

                        // Intentional memory leaks
                        const input_path = try std.mem.concat(b.allocator, u8, &.{ sub_directory.name, "/input" });

                        const run_cmd = b.addRunArtifact(exe);
                        run_cmd.setStdIn(.{ .lazy_path = .{ .path = input_path } });
                        // Only install specific exe
                        run_cmd.step.dependOn(&install_exe.step);

                        // Intentional memory leaks
                        const step_name = try std.mem.concat(b.allocator, u8, &.{ "run ", sub_directory.name });
                        const step_description = try std.mem.concat(b.allocator, u8, &.{ "Run ", sub_directory.name, " executable" });

                        const run_step = b.step(step_name, step_description);
                        run_step.dependOn(&run_cmd.step);
                    }
                }

                // === zig build benchmark ===
                {
                    const release_exe = b.addExecutable(.{
                        .name = sub_directory.name,
                        .root_source_file = .{ .path = path },
                        .target = target,
                        .optimize = .ReleaseSafe,
                    });
                    const install_release_exe = b.addInstallArtifact(release_exe, .{});

                    // Intentional memory leaks
                    const input_arg = try std.mem.concat(b.allocator, u8, &.{ "--input=", sub_directory.name, "/input" });
                    const exe_arg = try std.mem.concat(b.allocator, u8, &.{ "./zig-out/bin/", sub_directory.name });

                    const benchmark_cmd = b.addSystemCommand(&.{ "hyperfine", "--shell=none", "--warmup=10", input_arg });
                    benchmark_cmd.addArg(exe_arg);
                    benchmark_cmd.step.dependOn(&install_release_exe.step);

                    // Intentional memory leaks
                    const step_name = try std.mem.concat(b.allocator, u8, &.{ "benchmark ", sub_directory.name });
                    const step_description = try std.mem.concat(b.allocator, u8, &.{ "Benchmark ", sub_directory.name, " executable with hyperfine" });

                    const benchmark_step = b.step(step_name, step_description);
                    benchmark_step.dependOn(&benchmark_cmd.step);
                }
            }
        }
    }
}
