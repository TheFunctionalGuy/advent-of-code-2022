const std = @import("std");

const ArrayList = std.ArrayList;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const test_allocator = std.testing.allocator;

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut().writer();

    // Use arena allocator for now
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Try to get stdin input. Don't restrict memory.
    const stdin_input = try stdin.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdin_input);

    // Allocate list
    var lines = ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    // Tokenize
    var tokens = std.mem.tokenizeScalar(u8, stdin_input, '\n');
    while (tokens.next()) |line| {
        try lines.append(line);
    }

    const sum_of_priorities = getSumOfPriorities(lines);
    const sum_of_badges = try getSumOfBadges(lines, allocator);
    try stdout.print("Part 1: {}\n", .{sum_of_priorities});
    try stdout.print("Part 2: {}\n", .{sum_of_badges});
}

fn getSumOfPriorities(lines: ArrayList([]const u8)) usize {
    var sum: usize = 0;

    for (lines.items) |line| {
        const left = line[0 .. line.len / 2];
        const right = line[line.len / 2 ..];

        const res = std.mem.indexOfAny(u8, left, right);

        if (res) |index| {
            const odd_one_out = left[index];
            sum += lookupValue(odd_one_out);
        }
    }

    return sum;
}

fn lookupValue(item: u8) u8 {
    return switch (item) {
        'a'...'z' => item - 'a' + 1,
        'A'...'Z' => item - 'A' + 27,

        else => unreachable,
    };
}

test "part 1 toy example" {
    var lines = ArrayList([]const u8).init(test_allocator);
    defer lines.deinit();

    try lines.append("vJrwpWtwJgWrhcsFMMfFFhFp");
    try lines.append("jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL");
    try lines.append("PmmdzqPrVvPwwTWBwg");
    try lines.append("wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn");
    try lines.append("ttgJtRGJQctTZtZT");
    try lines.append("CrZsJsPPZsGzwwsLwLmpwMDw");

    const expected: usize = 157;
    const sum = getSumOfPriorities(lines);

    try expectEqual(expected, sum);
}

// TODO: This is much slower than using indexOfAny again.
// Think about why this is so slow.
fn getSumOfBadges(lines: ArrayList([]const u8), allocator: std.mem.Allocator) !usize {
    // Ensure that there are no trailing lines after processing in stacks of three
    assert(lines.items.len % 3 == 0);

    var sum: usize = 0;

    // Moving the maps here and freeing them while retaining capacity speed up things a little but not enough
    var bag_1_map = std.AutoArrayHashMap(u8, usize).init(allocator);
    defer bag_1_map.deinit();
    var bag_2_map = std.AutoArrayHashMap(u8, usize).init(allocator);
    defer bag_2_map.deinit();
    var bag_3_map = std.AutoArrayHashMap(u8, usize).init(allocator);
    defer bag_3_map.deinit();

    var i: usize = 0;
    // Iterate over bags in packs of three
    while (i < lines.items.len) : (i += 3) {
        const bag_1 = lines.items[i];
        const bag_2 = lines.items[i + 1];
        const bag_3 = lines.items[i + 2];

        // Fill maps
        for (bag_1) |item| {
            const res = try bag_1_map.getOrPut(item);

            if (res.found_existing) {
                res.value_ptr.* += 1;
            } else {
                res.key_ptr.* = item;
                res.value_ptr.* = 1;
            }
        }
        for (bag_2) |item| {
            const res = try bag_2_map.getOrPut(item);

            if (res.found_existing) {
                res.value_ptr.* += 1;
            } else {
                res.key_ptr.* = item;
                res.value_ptr.* = 1;
            }
        }
        for (bag_3) |item| {
            const res = try bag_3_map.getOrPut(item);

            if (res.found_existing) {
                res.value_ptr.* += 1;
            } else {
                res.key_ptr.* = item;
                res.value_ptr.* = 1;
            }
        }

        // Look for item in all three bags
        for (bag_1_map.keys()) |key| {
            if (bag_2_map.contains(key) and bag_3_map.contains(key)) {
                sum += lookupValue(key);
                bag_1_map.clearRetainingCapacity();
                bag_2_map.clearRetainingCapacity();
                bag_3_map.clearRetainingCapacity();
                break;
            }
        }
    }

    return sum;
}

test "part 2 toy example" {
    var lines = ArrayList([]const u8).init(test_allocator);
    defer lines.deinit();

    try lines.append("vJrwpWtwJgWrhcsFMMfFFhFp");
    try lines.append("jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL");
    try lines.append("PmmdzqPrVvPwwTWBwg");
    try lines.append("wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn");
    try lines.append("ttgJtRGJQctTZtZT");
    try lines.append("CrZsJsPPZsGzwwsLwLmpwMDw");

    const expected: usize = 70;
    const sum = try getSumOfBadges(lines, test_allocator);

    try expectEqual(expected, sum);
}
