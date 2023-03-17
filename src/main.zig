const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn VecDeque(comptime Item: type) type {
    return struct {
        const This = @This();

        buff: []Item,
        start: usize,
        len: usize,
        allocator: Allocator,

        pub fn init(allocator: Allocator) !This {
            const INIT_LEN = 1_000;
            return This.with_capacity(INIT_LEN, allocator);
        }

        pub fn with_capacity(size: usize, allocator: Allocator) !This {
            var buff = try allocator.alloc(Item, size);
            return This{ .buff = buff, .start = 0, .len = 0, .allocator = allocator };
        }

        pub fn deinit(self: *This) void {
            self.allocator.free(self.buff);
        }

        pub fn get(self: *This, i: usize) *Item {
            return &self.buff[wrap_sum(self.start, i, self.buff.len)];
        }

        pub fn len(self: *This) usize {
            return self.len;
        }

        pub fn push_back(self: *This, item: Item) Allocator.Error!void {
            try self.grow_if_needed();

            self.len += 1;

            self.buff[wrap_sum(self.start, self.len - 1, self.buff.len)] = item;
        }

        pub fn push_front(self: *This, item: Item) Allocator.Error!void {
            try self.grow_if_needed();

            self.len += 1;

            self.start = wrap_sub(self.start, 1, self.buff.len);
            self.buff[self.start] = item;
        }

        pub fn pop_back(self: *This) Item {
            var item = self.buff[wrap_sub(self.len, 1, self.buff.len)];
            self.len -= 1;

            return item;
        }

        pub fn pop_front(self: *This) Item {
            var item = self.buff[self.start];

            self.len -= 1;
            self.start = wrap_sum(self.start, 1, self.buff.len);

            return item;
        }

        fn grow_if_needed(self: *This) Allocator.Error!void {
            if (self.len == self.buff.len) {
                var new_buff = try self.allocator.alloc(Item, self.buff.len * 2);

                var end = self.buff.len - self.start;
                std.mem.copy(Item, new_buff[0..end], self.buff[self.start..self.buff.len]);

                if (self.start > 0) {
                    std.mem.copy(Item, new_buff[end..], self.buff[0..self.start]);
                }

                self.start = 0;
                self.allocator.free(self.buff);
                self.buff = new_buff;
            }
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
    defer v.deinit();
}

test "push_back-pop_back test" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var v = try VecDeque(i32).init(allocator);
    defer v.deinit();

    try v.push_back(1);
    try v.push_back(2);
    try v.push_back(3);
    try v.push_back(4);
    try expect(v.pop_back() == 4);
    try expect(v.pop_back() == 3);
    try expect(v.pop_back() == 2);
    try expect(v.pop_back() == 1);
}

test "push_front-pop_front test" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var v = try VecDeque(i32).init(allocator);
    defer v.deinit();

    try v.push_front(1);
    try v.push_front(2);
    try v.push_front(3);
    try v.push_front(4);
    try expect(v.pop_front() == 4);
    try expect(v.pop_front() == 3);
    try expect(v.pop_front() == 2);
    try expect(v.pop_front() == 1);
}

test "get test" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var v = try VecDeque(i32).init(allocator);
    defer v.deinit();

    try v.push_front(2);
    try v.push_back(3);
    try v.push_front(1);
    try v.push_back(4);
    try expect(v.get(0).* == 1);
    try expect(v.get(1).* == 2);
    try expect(v.get(2).* == 3);
    try expect(v.get(3).* == 4);
}

test "push_back with allocation test" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var v = try VecDeque(i32).with_capacity(3, allocator);
    defer v.deinit();

    try v.push_back(1);
    try v.push_back(2);
    try v.push_back(3);
    try v.push_back(4);
    try expect(v.pop_back() == 4);
    try expect(v.pop_back() == 3);
    try expect(v.pop_back() == 2);
    try expect(v.pop_back() == 1);
}

test "push_front with allocation test" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var v = try VecDeque(i32).with_capacity(3, allocator);
    defer v.deinit();

    try v.push_front(1);
    try v.push_front(2);
    try v.push_front(3);
    try v.push_front(4);
    try expect(v.pop_front() == 4);
    try expect(v.pop_front() == 3);
    try expect(v.pop_front() == 2);
    try expect(v.pop_front() == 1);
}
