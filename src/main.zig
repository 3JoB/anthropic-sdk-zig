const std = @import("std");
const gc = @import("gc/gc.zig");
const http = std.http;

const _ = gc.GC.init().run();

const string = []const u8;

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
    metadata: MetaData,

    pub fn setUserID(s: *sender, user_id: string) void {
        s.metadata.user_id = user_id;
    }
};

pub const MetaData = struct {
    user_id: ?string = null,
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
pub fn new(client: Client) Client {
    return client;
}

pub fn main() void {
    var cn = Client{
        .key = "12354",
    };
    cn.send();
    std.debug.print("{s}\n", .{cn.key});
}