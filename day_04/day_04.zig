const std = @import("std");

const ArrayList = std.ArrayList;

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
    var section_ranges = ArrayList(SectionRangePair).init(allocator);
    defer section_ranges.deinit();

    // Convert input to ArrayList of SectionRangePairs
    try parseInput(stdin_input, &section_ranges);

    const containing_section_count = try getContainingSectionCount(section_ranges);
    const overlapping_section_count = try getOverlappingSectionCount(section_ranges);

    try stdout.print("Part 1: {}\n", .{containing_section_count});
    try stdout.print("Part 2: {}\n", .{overlapping_section_count});
}

const SectionRange = struct {
    start: u8,
    end: u8,
};
const SectionRangePair = struct {
    first: SectionRange,
    second: SectionRange,
};
fn extractSectionRange(unparsed_section_range: []const u8) !SectionRange {
    var sections = std.mem.tokenizeScalar(u8, unparsed_section_range, '-');

    const section_range = SectionRange{
        .start = try std.fmt.parseInt(u8, sections.next().?, 10),
        .end = try std.fmt.parseInt(u8, sections.next().?, 10),
    };

    return section_range;
}

fn parseInput(unparsed_input: []const u8, section_ranges: *ArrayList(SectionRangePair)) !void {
    // Tokenize
    var tokens = std.mem.tokenizeScalar(u8, unparsed_input, '\n');
    while (tokens.next()) |line| {
        var ranges = std.mem.tokenizeScalar(u8, line, ',');
        const section_range_pair = SectionRangePair{ .first = try extractSectionRange(ranges.next().?), .second = try extractSectionRange(ranges.next().?) };

        try section_ranges.*.append(section_range_pair);
    }
}

test "parsing" {
    const test_input =
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
    ;

    var expected = ArrayList(SectionRangePair).init(test_allocator);
    defer expected.deinit();

    try expected.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 4,
    }, .second = SectionRange{
        .start = 6,
        .end = 8,
    } });
    try expected.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 3,
    }, .second = SectionRange{
        .start = 4,
        .end = 5,
    } });
    try expected.append(SectionRangePair{ .first = SectionRange{
        .start = 5,
        .end = 7,
    }, .second = SectionRange{
        .start = 7,
        .end = 9,
    } });
    try expected.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 8,
    }, .second = SectionRange{
        .start = 3,
        .end = 7,
    } });
    try expected.append(SectionRangePair{ .first = SectionRange{
        .start = 6,
        .end = 6,
    }, .second = SectionRange{
        .start = 4,
        .end = 6,
    } });
    try expected.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 6,
    }, .second = SectionRange{
        .start = 4,
        .end = 8,
    } });

    var actual = ArrayList(SectionRangePair).init(test_allocator);
    defer actual.deinit();

    try parseInput(test_input, &actual);

    for (expected.items, actual.items) |exp, act| {
        try expectEqual(exp, act);
    }
}

fn getContainingSectionCount(pairs: ArrayList(SectionRangePair)) !usize {
    var count: usize = 0;

    for (pairs.items) |pair| {
        const section_range_1 = pair.first;
        const section_range_2 = pair.second;

        if (section_range_1.start == section_range_2.start or section_range_1.end == section_range_2.end) {
            count += 1;
        } else {
            if (section_range_1.start < section_range_2.start) {
                if (section_range_1.end > section_range_2.end) {
                    count += 1;
                }
            } else {
                if (section_range_1.end < section_range_2.end) {
                    count += 1;
                }
            }
        }
    }

    return count;
}

test "part 1 toy example" {
    var section_range_pairs = ArrayList(SectionRangePair).init(test_allocator);
    defer section_range_pairs.deinit();

    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 4,
    }, .second = SectionRange{
        .start = 6,
        .end = 8,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 3,
    }, .second = SectionRange{
        .start = 4,
        .end = 5,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 5,
        .end = 7,
    }, .second = SectionRange{
        .start = 7,
        .end = 9,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 8,
    }, .second = SectionRange{
        .start = 3,
        .end = 7,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 6,
        .end = 6,
    }, .second = SectionRange{
        .start = 4,
        .end = 6,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 6,
    }, .second = SectionRange{
        .start = 4,
        .end = 8,
    } });

    const expected: usize = 2;
    const actual = try getContainingSectionCount(section_range_pairs);

    try expectEqual(expected, actual);
}

// Could be merged with getContainingSectionCount function for more effeciency
fn getOverlappingSectionCount(pairs: ArrayList(SectionRangePair)) !usize {
    var count: usize = 0;

    for (pairs.items) |pair| {
        const section_range_1 = pair.first;
        const section_range_2 = pair.second;

        if (section_range_1.start == section_range_2.start or section_range_1.end == section_range_2.end) {
            count += 1;
        } else {
            if (section_range_1.start < section_range_2.start) {
                if (section_range_1.end >= section_range_2.start) {
                    count += 1;
                }
            } else {
                if (section_range_2.end >= section_range_1.start) {
                    count += 1;
                }
            }
        }
    }

    return count;
}

test "part 2 toy example" {
    var section_range_pairs = ArrayList(SectionRangePair).init(test_allocator);
    defer section_range_pairs.deinit();

    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 4,
    }, .second = SectionRange{
        .start = 6,
        .end = 8,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 3,
    }, .second = SectionRange{
        .start = 4,
        .end = 5,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 5,
        .end = 7,
    }, .second = SectionRange{
        .start = 7,
        .end = 9,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 8,
    }, .second = SectionRange{
        .start = 3,
        .end = 7,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 6,
        .end = 6,
    }, .second = SectionRange{
        .start = 4,
        .end = 6,
    } });
    try section_range_pairs.append(SectionRangePair{ .first = SectionRange{
        .start = 2,
        .end = 6,
    }, .second = SectionRange{
        .start = 4,
        .end = 8,
    } });

    const expected: usize = 4;
    const actual = try getOverlappingSectionCount(section_range_pairs);

    try expectEqual(expected, actual);
}
