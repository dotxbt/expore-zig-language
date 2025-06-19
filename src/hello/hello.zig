const print = @import("std").debug.print;

pub fn display_message(your_name: []const u8) void {
    print("Hello Orang ganteng {s} 😍\n", .{your_name});
}
