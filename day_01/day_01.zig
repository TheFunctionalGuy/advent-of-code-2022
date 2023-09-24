const std = @import("std");

const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

const ArrayList = std.ArrayList;

pub fn main() !void {
    // Use arena allocator for now
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Try to get stdin input. Don't restrict memory.
    const stdin_input = try stdin.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdin_input);

    // Allocate list
    var calories_list = ArrayList(usize).init(allocator);
    defer calories_list.deinit();

    try fillCalorieList(&calories_list, stdin_input);
    std.mem.sort(usize, calories_list.items, {}, comptime std.sort.desc(usize));

    try stdout.writer().print("Part 1: {}\n", .{calories_list.items[0]});
    try stdout.writer().print("Part 2: {}\n", .{calories_list.items[0] + calories_list.items[1] + calories_list.items[2]});
}

fn fillCalorieList(calories_list: *ArrayList(usize), stdin_input: []const u8) !void {
    // Iterate over all chunks in the input
    var chunks = std.mem.tokenizeSequence(u8, stdin_input, "\n\n");
    while (chunks.next()) |chunk| {
        var chunk_sum: usize = 0;

        // Iterate over all items in each chunk
        var items = std.mem.tokenizeScalar(u8, chunk, '\n');
        while (items.next()) |item| {
            // Try to parse the int
            const parsed_number = try std.fmt.parseInt(u32, item, 10);
            chunk_sum += parsed_number;
        }

        try calories_list.append(chunk_sum);
    }
}
