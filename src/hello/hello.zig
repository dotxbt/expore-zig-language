const std = @import("std");

fn getWord(name: []const u8) ![]const u8 {
    const allocator = std.heap.page_allocator;
    return try std.fmt.allocPrint(
        allocator,
        "Hello Orang ganteng {s} 😍\n",
        .{name},
    );
}

pub fn displayMessage(your_name: []const u8) !void {
    const allocator = std.heap.page_allocator;
    const msg = try getWord(your_name);
    defer allocator.free(msg);
    std.debug.print("{s}", .{msg});
}

fn getWordsArray(name: []const u8, count: usize) ![][]const u8 {
    const allocator = std.heap.page_allocator;
    var result = try allocator.alloc([]const u8, count);
    for (0..count) |index| {
        const item = try getWord(name);
        result[index] = item;
    }
    return result;
}

// [ UNIT TEST ]
test "Display Orang Ganteng" {
    const expected = "Hello Orang ganteng Sabituddin Bigbang 😍\n";
    const allocator = std.heap.page_allocator;
    const actual = try getWord("Sabituddin Bigbang");
    defer allocator.free(actual);
    try std.testing.expectEqualStrings(expected, actual);
}

test "Display Orang Ganteng Versi Array" {
    const allocator = std.heap.page_allocator;
    const expected = [_][]const u8{
        "Hello Orang ganteng Sabituddin Bigbang 😍\n",
        "Hello Orang ganteng Sabituddin Bigbang 😍\n",
        "Hello Orang ganteng Sabituddin Bigbang 😍\n",
        "Hello Orang ganteng Sabituddin Bigbang 😍\n",
        "Hello Orang ganteng Sabituddin Bigbang 😍\n",
    };
    const actual = try getWordsArray(
        "Sabituddin Bigbang",
        5,
    );
    defer for (actual) |s| allocator.free(s);
    for (0..expected.len) |index| {
        try std.testing.expectEqualStrings(
            expected[index],
            actual[index],
        );
    }
}
