const std = @import("std");
const http = std.http;

const string = []const u8;

pub const Client = struct {
    key: string,
    defaultModel: string = "claude-instant-v1.1",
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
};

pub const MetaData = struct {
    user_id: ?string = null,
};

pub fn setUserID(s: *sender, user_id: string) void {
    s.metadata.user_id = user_id;
}  

const Response = struct {
    cache: string = "",
    completion: string,
    stop_reason: string,
    stop: string,
    log_id: string,
    exception: ?string = null,
    model: string,
    truncated: bool,
};  

fn to_string(resp: *Response) string {
    if (resp.cache.len != 0) {
        return resp.cache; 
    }
    const buf: [100]u8 = undefined;
    const len = std.fmt.bufPrintZ(&buf, "{}", .{resp}) catch unreachable;
    resp.cache = buf[0..len];      
    return resp.cache;
}

// Creat a New Anthropic Client
pub fn new(client: Client) Client {
    return client;
}

pub fn send(c: Client) void {
    std.debug.print("{s}\n", .{c.defaultModel});
}

pub fn main() void {
    var cn = Client{
        .key = "12354",
    };
    send(cn);
    std.debug.print("{s}\n", .{cn.key});
}