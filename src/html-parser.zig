const std = @import("std");
const print = std.debug.print;
const fileReader = @import("file-reader.zig");
const state = @import("tokenizer-state-machine.zig");

pub fn main() !void {
    var textBuffer: [200]u8 = undefined;
    const text = try fileReader.fileReader("src/index.html", &textBuffer);
    var stateMachine = state.TokenizerStateMachine.init(text);
    while (stateMachine.index < stateMachine.stream.len) {
        const token = stateMachine.consume();
        if (token) |t| {
            _ = t;
            // Process the token
        }
    }
}

fn zdom(html: []u8) !bool {
    // loop over the html
    const what = try state.tokenizerStateMachine(html);
    _ = what;
    return true;
}
const expect = std.testing.expect;

test "Should take a string and identify if it's valid HTML" {}
