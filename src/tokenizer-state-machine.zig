const std = @import("std");
const print = std.debug.print;
const tokenFactory = @import("token-factory.zig");
const Allocator = std.mem.Allocator;

const State = enum { Data, TagOpen, MarkupDeclaration, EndTag, TagName, SelfClosingStartTag };

fn isLowerAlpha(ch: u8) bool {
    return ch >= 'a' and ch <= 'z';
}

fn isUpperAlpha(ch: u8) bool {
    return ch >= 'A' and ch <= 'Z';
}

pub fn toLowercase(c: u8) u8 {
    if (c >= 'A' and c <= 'Z') {
        return c + ('a' - 'A');
    }
    return c;
}

pub const TokenizerStateMachine = struct {
    const Self = @This();
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    state: State = State.Data,
    reconsume: bool = false,
    currentToken: ?tokenFactory.Token = null,
    stream: []const u8,
    allocator: Allocator = gpa,

    index: usize = 0,

    // we do a slice for 2 reasons:
    // 1. We don't know the size of the string
    // 2. We want to point to that place not get a copy of it
    pub fn init(text: []const u8) Self {
        print("Address: {*}\n", .{text});
        return Self{ .stream = text };
    }

    pub fn nextChar(self: *TokenizerStateMachine) ?u8 {
        self.index += 1;
        return currentChar(self);
    }

    fn currentChar(self: *TokenizerStateMachine) ?u8 {
        if (self.index < self.stream.len) {
            return self.stream[self.index];
        }
        return null; // or handle error or overflow based on your design decisions
    }

    pub fn consume(self: *TokenizerStateMachine) ?tokenFactory.Token {
        //... you can either return null when no token is produced or a Token when one is complete
        return switch (self.state) {
            State.Data => self.dataState(),
            State.TagOpen => self.tagOpenState(),
            // ... handle other states
            else => null,
        };
    }

    fn dataState(self: *TokenizerStateMachine) ?tokenFactory.Token {
        // read next character:
        const character = self.nextChar() orelse return null;

        switch (character) {
            '<' => {
                // Switch to the tag open state.
                self.state = State.TagOpen;
                return null;
            },
            else => return null,
        }
        return null;

        //... handle other characters
    }

    fn tagOpenState(self: *TokenizerStateMachine) ?tokenFactory.Token {
        //consume next character:
        const char = self.nextChar() orelse return null;

        switch (char) {
            '!' => {
                // switch to markup delcaration open state
                self.state = State.MarkupDeclaration;
            },
            '/' => {
                // Switch to the end tag open state
                self.state = State.EndTag;
            },
            else => {
                if (isLowerAlpha(char) or isUpperAlpha(char)) {
                    // create new start tag token & set its tag name to empty string
                    const token = tokenFactory.createStartTagToken(&self.allocator);
                    self.currentToken = token;

                    // Reconsume in the tag name state.
                    self.state = State.TagName;
                    self.reconsume = true;
                    print("token: {any}", .{self.currentToken});
                }
                return null;
            },
        }
        return null;
        // handle tag open state
    }
    fn tagNameState(self: *TokenizerStateMachine) ?tokenFactory.Token {
        // consume next character BUT reconsume may be true
        const character = (if (self.reconsume) self.currentChar() else self.nextChar()) orelse return null;
        self.reconsume = false;

        switch (character) {
            '/' => {
                self.state = State.SelfClosingStartTag;
            },
            '>' => {
                self.state = State.Data;
                //Emit the current tag token.
                // How????
            },
            isUpperAlpha(character) => {
                //Append the lowercase version of the current input character (add 0x0020 to the character's code point)
                //to the current tag token's tag name.
                const lowerCase = toLowercase(character);
                _ = lowerCase;
                print("{any}\n", .{self.currentToken});
            },
            isLowerAlpha(character) => {
                //Append the current input character to the current tag token's tag name.
                return null;
            },
            else => return null,
        }
    }
};

const expect = std.testing.expect;

test "should retrieve initial character in html string" {
    var stateMachine = TokenizerStateMachine.init("<div>Wow</div>");
    const character = stateMachine.readNextCharacter();

    expect(character == '<');
}

// Process the first character '<'
// Feed to state machine
//
//
//
//
//
//
