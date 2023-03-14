const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn VecDeque(comptime Item: type) type {
    return struct {
        const This = @This();

        buff: []Item,
        start: usize,
        len: usize,

        fn init(allocator: Allocator) !This {
            const INIT_LEN = 100;
            var buff = try allocator.alloc(Item, INIT_LEN);
            return This{ .buff = buff, .start = 0, .len = 0 };
        }

        fn deinit(self: *This, allocator: Allocator) void {
            allocator.free(self.buff);
        }

        fn get(self: *This, i: usize) *Item {
            return &self.buff[wrap_sum(self.start, i, self.buff.len)];
        }

        fn len(self: *This) usize {
            return self.len;
        }

        fn push_back(self: *This, item: Item, allocator: Allocator) void {
            if (self.len == self.buff.len) {
                _ = allocator;
                @panic("memory allocation not implemented");
            }

            self.len += 1;

            self.buff[wrap_sum(self.start, self.len - 1, self.buff.len)] = item;
        }

        fn push_front(self: *This, item: Item, allocator: Allocator) void {
            if (self.len == self.buff.len) {
                _ = allocator;
                @panic("memory allocation not implemented");
            }

            self.len += 1;

            self.start = wrap_sub(self.start, 1, self.buff.len);
            self.buff[self.start] = item;
        }

        fn pop_back(self: *This) *Item {
            var item = &self.buff[wrap_sub(self.len, 1, self.buff.len)];
            self.len -= 1;

            return item;
        }

        fn pop_front(self: *This) *Item {
            var item = &self.buff[self.start];

            self.len -= 1;
            self.start = wrap_sum(self.start, 1, self.buff.len);
            return item;
        }
    };
}

inline fn wrap_sum(a: usize, b: usize, n: usize) usize {
    return (a + b) % n;
}

inline fn wrap_sub(a: usize, b: usize, n: usize) usize {
    var ia = @bitCast(isize, a);
    var ib = @bitCast(isize, b);
    var in = @bitCast(isize, n);
    var ir = @mod((ia - ib), in);
    return @bitCast(usize, ir);
}

test "alloc test" {
    const allocator = std.testing.allocator;
    var v = try VecDeque(i32).init(allocator);
    defer v.deinit(allocator);
}

test "push_back-pop_back test" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var v = try VecDeque(i32).init(allocator);
    defer v.deinit(allocator);

    v.push_back(1, allocator);
    v.push_back(2, allocator);
    v.push_back(3, allocator);
    v.push_back(4, allocator);
    try expect(v.pop_back().* == 4);
    try expect(v.pop_back().* == 3);
    try expect(v.pop_back().* == 2);
    try expect(v.pop_back().* == 1);
}

test "push_front-pop_front test" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var v = try VecDeque(i32).init(allocator);
    defer v.deinit(allocator);

    v.push_front(1, allocator);
    v.push_front(2, allocator);
    v.push_front(3, allocator);
    v.push_front(4, allocator);
    try expect(v.pop_front().* == 4);
    try expect(v.pop_front().* == 3);
    try expect(v.pop_front().* == 2);
    try expect(v.pop_front().* == 1);
}

test "get test" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var v = try VecDeque(i32).init(allocator);
    defer v.deinit(allocator);

    v.push_front(2, allocator);
    v.push_back(3, allocator);
    v.push_front(1, allocator);
    v.push_back(4, allocator);
    try expect(v.get(0).* == 1);
    try expect(v.get(1).* == 2);
    try expect(v.get(2).* == 3);
    try expect(v.get(3).* == 4);
}
