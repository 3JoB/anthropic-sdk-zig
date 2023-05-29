const std = @import("std");
const http = std.http;

pub const Client = struct {
    key: []const u8,
};

// Creat a New Anthropic Client
pub fn new(key: []const u8) Client {
    return Client{
        .key = key,
    }; 
}