const lib = @import("explore_zig_language_lib");

pub fn main() !void {
    try lib.hello.displayMessage("Sabituddin Bigbang");
    try lib.server.run();
}
