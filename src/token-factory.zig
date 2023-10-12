const std = @import("std");
const Allocator = std.mem.Allocator;

//https://html.spec.whatwg.org/multipage/parsing.html#tokenization:~:text=The%20output%20of%20the%20tokenization%20step%20is%20a%20series%20of%20zero%20or%20more%20of%20the%20following%20tokens%3A%20DOCTYPE%2C%20start%20tag%2C%20end%20tag%2C%20comment%2C%20character%2C%20end%2Dof%2Dfile.
const TokenType = enum { doc_type, start_tag, end_tag, comment, character, end_of_file };

const Attributes = struct { name: std.ArrayList(u8), value: std.ArrayList(u8) };

pub const DocType = struct {
    name: std.ArrayList(u8),
    public_identifier: std.ArrayList(u8),
    system_identifier: std.ArrayList(u8),
    force_quirks: bool,
};

pub const StartTag = struct {
    tag_name: std.ArrayList(u8),
    self_closing_flag: bool,
    attributes: std.ArrayList(Attributes),
};

pub const EndTag = struct {
    tag_name: std.ArrayList(u8),
    self_closing_flag: bool,
    attributes: std.ArrayList(Attributes),
};

pub const Token = union(TokenType) {
    doc_type: DocType,
    start_tag: StartTag,
    end_tag: EndTag,
    comment: std.ArrayList(u8),
    character: u8,
    end_of_file: bool,

    const self = @This();

    pub fn deinit(token: *Token, allocator: *Allocator) void {
        switch (token.*) {
            .doc_type => {
                token.doc_type.name.deinit(allocator);
                token.doc_type.public_identifier.deinit(allocator);
                token.doc_type.system_identifier.deinit(allocator);
            },
            .start_tag => {
                token.start_tag.tag_name.deinit(allocator);
                for (token.start_tag.attributes.items) |*attr| {
                    attr.name.deinit(allocator);
                    attr.value.deinit(allocator);
                }
                token.start_tag.attributes.deinit(allocator);
            },
            .end_tag => {
                token.end_tag.tag_name.deinit(allocator);
                for (token.end_tag.attributes.items) |*attr| {
                    attr.name.deinit(allocator);
                    attr.value.deinit(allocator);
                }
                token.end_tag.attributes.deinit(allocator);
            },
            .comment => {
                token.comment.deinit(allocator);
            },
            .character, // for single u8, nothing to do
            .end_of_file,
            => {}, // for boolean flag, nothing to do
        }
    }
    //const allocator = std.heap.page_allocator;
    //const token = createStartTag(allocator);
    // ... Use the token ...
    //deinit(&token, allocator);
};

pub fn createDocType(allocator: std.mem.Allocator) Token {
    return Token{ .doc_type = .{
        .force_quirks = false,
        .name = std.ArrayList(u8).init(allocator),
        .public_identifier = std.ArrayList(u8).init(allocator),
        .system_identifier = std.ArrayList(u8).init(allocator),
    } };
}

pub fn createStartTagToken(allocator: *Allocator) Token {
    var tag_name_list = std.ArrayList(u8).init(allocator.*);
    // This will ensure that tag_name is initialized as an empty string
    // In essence, it doesn't push any byte since "" is empty, but demonstrates the idea.
    _ = tag_name_list.appendSlice("") catch |err| {
        std.debug.print("err: {any}", .{err});
    };

    const startTag = StartTag{
        .tag_name = tag_name_list,
        .self_closing_flag = false,
        .attributes = std.ArrayList(Attributes).init(allocator.*),
    };

    return Token{ .start_tag = startTag };
}
