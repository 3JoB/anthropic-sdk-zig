const std = @import("std");
const gc = @import("gc/gc.zig");

const string = []const u8;

const http = std.http;

const uri = std.Uri.parse("https://api.anthropic.com/v1/complete") catch unreachable;
const version: string = "0.0.0-20230530-a01";
const ua: string = "Mozilla/5.0 (compatible; anthropic-sdk-zig/" + version + "; +https://github.com/3JoB/anthropic-sdk-go/;) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36";

const _ = gc.GC.init().run();

pub const Client = struct {
    key: string,
    defaultModel: string = "claude-instant-v1.1",

    pub fn send(self: *Client) void {
        std.debug.print("{s}\n", .{self.defaultModel});
    }
};

pub const sender = struct {
    prompt: string,
    model: string,
    stop_sequences: []string,
    stream: bool,
    max_tokens: i32,
    top_k: i32 = -1,
    top_p: i32 = -1,
    metadata: struct {
        user_id: ?string = null,
    },

    pub fn setUserID(s: *sender, user_id: string) void {
        s.metadata.user_id = user_id;
    }
};

const Response = struct {
    cache: string = "",
    completion: string,
    stop_reason: string,
    stop: string,
    log_id: string,
    exception: ?string = null,
    model: string,
    truncated: bool,

    pub fn to_string(resp: *Response) string {
        if (resp.cache.len != 0) {
            return resp.cache; 
        }
        const buf: [100]u8 = undefined;
        const len = std.fmt.bufPrintZ(&buf, "{}", .{resp}) catch unreachable;
        resp.cache = buf[0..len];
        return resp.cache;
    }
}; 

// Creat a New Anthropic Client
pub fn new(client: Client) *Client {
    var c = http.Client;
    defer c.deinit();

    const header = http.Headers;
    header.append("User-Agent", ua);
    header.append("Accept","application/json");
    header.append("Content-Type", "application/json");
    header.append("Client", "anthropic-sdk-zig/" + version);
    header.append("x-api-key", client.key);

    var req = try c.request(.POST, uri, header, .{});
    defer req.deinit();
    try req.start();
    try req.wait();

    try std.testing.expect(req.response.status == .ok);
    return *client;
}

pub fn main() void {
    var cn = Client{
        .key = "12354",
    };
    cn.send();
    std.debug.print("{s}\n", .{cn.key});
}