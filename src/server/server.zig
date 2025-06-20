const std = @import("std");
const http = std.http;

var active_threads: usize = 0;
const ordering = .seq_cst;

pub fn run() !void {
    const allocator = std.heap.page_allocator;
    const address = try std.net.Address.parseIp4("127.0.0.1", 8080);
    var listener = try address.listen(std.net.Address.ListenOptions{});
    defer listener.deinit();

    std.debug.print("\n\n::: 1 ::: HTTP SERVER EXAMPLE :::\n", .{});
    std.debug.print("---> Server running on http://127.0.0.1:8080 <---\n\n", .{});

    // Di main thread:

    var thread_count: usize = 0;

    while (true) {
        const conn = try listener.accept();
        _ = try std.Thread.spawn(
            .{},
            handleConnection,
            .{
                conn,
                allocator,
            },
        );
        thread_count += 1;
        std.debug.print("\n\nThread Count : {d}\n", .{thread_count});
        std.debug.print("Active Count : {d}\n\n", .{active_threads});
    }
}
fn handleConnection(conn: std.net.Server.Connection, allocator: std.mem.Allocator) !void {
    defer conn.stream.close();
    _ = @atomicRmw(usize, &active_threads, .Add, 1, ordering);
    defer _ = @atomicRmw(usize, &active_threads, .Sub, 1, ordering);
    var buffer: [4096]u8 = undefined;
    var server = std.http.Server.init(conn, &buffer);
    var request = try server.receiveHead();
    const method = request.head.method;
    switch (method) {
        .GET => try handleGet(&request, allocator),
        .POST => try handlePost(&request, allocator),
        else => try handleError(&request, allocator, "Internal Server Error", .internal_server_error),
    }
}

fn handleError(req: *http.Server.Request, allocator: std.mem.Allocator, message: []const u8, status: std.http.Status) !void {
    const error_data = try std.json.stringifyAlloc(allocator, .{
        .message = message,
        .success = false,
    }, .{});
    defer allocator.free(error_data);
    try req.respond(
        error_data,
        .{
            .status = status,
            .extra_headers = &[_]std.http.Header{.{ .name = "Content-Type", .value = "application/json" }},
        },
    );
}

fn handleGet(
    req: *http.Server.Request,
    allocator: std.mem.Allocator,
) !void {
    const target = req.head.target;
    if (std.mem.eql(u8, target, "/")) {
        const data = try std.json.stringifyAlloc(allocator, .{
            .message = "Welcome to the homepage",
            .success = true,
        }, .{});
        defer allocator.free(data);
        try req.respond(
            data,
            .{
                .status = .ok,
                .extra_headers = &[_]std.http.Header{.{ .name = "Content-Type", .value = "application/json" }},
            },
        );
    } else {
        try handleError(
            req,
            allocator,
            "404 : Not Found!\n",
            .not_found,
        );
    }
}

fn handlePost(req: *std.http.Server.Request, allocator: std.mem.Allocator) !void {
    if (!std.mem.eql(u8, req.head.target, "/echo")) {
        try handleError(
            req,
            allocator,
            "404 : Not Found!\n",
            .not_found,
        );
    }

    const body_len = req.head.content_length orelse 0;
    const body_buf = try allocator.alloc(u8, body_len);
    defer allocator.free(body_buf);

    const reader = try req.reader();
    _ = try reader.readAll(body_buf);

    std.debug.print("{s}", .{body_buf});

    // const body_str = body_buf[0..body_len];
    // const dataBody: std.json = undefined;
    // std.json.encodeJsonString(body_str, .{}, dataBody);

    const json_data = try std.json.stringifyAlloc(allocator, .{
        .message = "Halo dari Zig!",
        .success = true,
    }, .{});
    defer allocator.free(json_data);

    try req.respond(
        json_data,
        .{
            .status = .ok,
            .extra_headers = &[_]std.http.Header{.{ .name = "Content-Type", .value = "application/json" }},
        },
    );
}
