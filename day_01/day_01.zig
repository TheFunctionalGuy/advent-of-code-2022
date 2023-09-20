const std = @import("std");
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

pub fn main() !void {
    // Use general purpose allocator for now
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // Try to get stdin input. Don't restrict memory.
    const stdin_input = try stdin.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdin_input);

    var largest_chunk: u64 = 0;

    // Iterate over all chunks in the input
    var chunks = std.mem.tokenizeSequence(u8, stdin_input, "\n\n");
    while (chunks.next()) |chunk| {
        var chunk_sum: u64 = 0;

        // Iterate over all items in each chunk
        var items = std.mem.tokenize(u8, chunk, "\n");
        while (items.next()) |item| {
            // Try to parse the int
            const parsed_number = try std.fmt.parseInt(u32, item, 10);
            chunk_sum += parsed_number;
        }

        if (chunk_sum > largest_chunk) {
            largest_chunk = chunk_sum;
        }
    }

    try stdout.writer().print("Largest chunk sum: {d}\n", .{largest_chunk});
}
