const std = @import("std");

const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

const ArrayList = std.ArrayList;

// Enum for easier debugging. Values are used for calculations.
const Move = enum(i8) {
    rock = 1,
    paper = 2,
    scissor = 3,
};

const Game = struct {
    opponent: Move,
    player: Move,
};

const Score = struct {
    part_1_score: u8,
    part_2_score: u8,
};

pub fn main() !void {
    // Use arena allocator for now
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Try to get stdin input. Don't restrict memory.
    const stdin_input = try stdin.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdin_input);

    // Allocate list
    var game_scores = ArrayList(Score).init(allocator);
    defer game_scores.deinit();

    try fillGameScoreList(&game_scores, stdin_input);

    var part_1_sum: usize = 0;
    var part_2_sum: usize = 0;

    for (game_scores.items) |game_score| {
        part_1_sum += game_score.part_1_score;
        part_2_sum += game_score.part_2_score;
    }

    try stdout.writer().print("Part 1: {}\n", .{part_1_sum});
    try stdout.writer().print("Part 2: {}\n", .{part_2_sum});
}

fn fillGameScoreList(game_scores: *ArrayList(Score), stdin_input: []const u8) !void {
    // Iterate over all games in the input
    var games = std.mem.tokenizeScalar(u8, stdin_input, '\n');
    while (games.next()) |game| {
        const move_game = Game{
            .opponent = @enumFromInt(game[0] - 64),
            .player = @enumFromInt(game[2] - 87),
        };

        const game_score = calculateGameScore(move_game);
        const move_score = calculateMoveScore(move_game);

        try game_scores.append(Score{ .part_1_score = game_score, .part_2_score = move_score });
    }
}

inline fn calculateGameScore(game: Game) u8 {
    // Opponent - Player  => Result => Score
    // Rock     - Rock    => Draw   => 3
    // 1        - 1       => 0      => 3
    // Rock     - Paper   => Win    => 6
    // 1        - 2       => -1 = 2 => 6
    // Rock     - Scissor => Lose   => 0
    // 1        - 3       => -2 = 1 => 0
    // 3, 0, 6

    // Opponent - Player  => Result => Score
    // Paper    - Rock    => Lose   => 0
    // 2        - 1       => 1      => 0
    // Paper    - Paper   => Draw   => 3
    // 2        - 2       => 0      => 3
    // Paper    - Scissor => Win    => 6
    // 2        - 3       => -1 = 2 => 6
    // 3, 0, 6

    // Opponent - Player  => Result => Score
    // Scissor  - Rock    => Win    => 6
    // 3        - 1       => 2      => 6
    // Scissor  - Paper   => Lose   => 0
    // 3        - 2       => 1      => 0
    // Scissor  - Scissor => Draw   => 3
    // 3        - 3       => 0      => 3
    // 3, 0, 6

    // Look-up table determined by rules above
    const game_score_LUT = [_]u8{ 3, 0, 6 };

    // Score obtained by player move
    var score: u8 = @bitCast(@intFromEnum(game.player));

    // Score obtained by result
    const index: u8 = @bitCast(@mod(@intFromEnum(game.opponent) - @intFromEnum(game.player), 3));
    score += game_score_LUT[index];

    return score;
}

inline fn calculateMoveScore(game: Game) u8 {
    // Opponent - Result => Player  => Score
    // Rock     - Lose   => Scissor => 3
    // 1        + 1      => 2       => 3
    // Rock     - Draw   => Rock    => 1
    // 1        + 2      => 3 = 0   => 1
    // Rock     - Win    => Paper   => 2
    // 1        + 3      => 4 = 1   => 2
    // 1, 2, 3

    // Opponent - Result => Player  => Score
    // Paper    - Lose   => Rock    => 1
    // 2        + 1      => 3 = 0   => 1
    // Paper    - Draw   => Paper   => 2
    // 2        + 2      => 4 = 1   => 2
    // Paper    - Win    => Scissor => 3
    // 2        + 3      => 5 = 2   => 3
    // 1, 2, 3

    // Opponent - Result => Player  => Score
    // Scissor  - Lose   => Paper   => 2
    // 3        - 1      => 4 = 1   => 2
    // Scissor  - Draw   => Scissor => 3
    // 3        - 2      => 5 = 2   => 3
    // Scissor  - Win    => Rock    => 1
    // 3        - 3      => 6 = 0   => 1
    // 1, 2, 3

    // Look-up table determined by rules above
    const game_score_LUT = [_]u8{ 1, 2, 3 };

    // Score obtained by result
    var score: u8 = @bitCast((@intFromEnum(game.player) - 1) * 3);

    // Score obtained by player move
    const index: u8 = @bitCast(@mod(@intFromEnum(game.opponent) + @intFromEnum(game.player), 3));
    score += game_score_LUT[index];

    return score;
}
