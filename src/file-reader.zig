const std = @import("std");

const print = std.debug.print;

pub fn fileReader(fileName: []const u8, buffer: *[200]u8) ![]u8 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    try file.seekTo(0);
    const bytes_read = try file.readAll(buffer);
    const text = buffer[0..bytes_read];
    defer file.close();
    return text;
}
