const std = @import("std");
const Vector = @import("vector.zig").Vector;

pub fn Point(comptime T: type, comptime N: usize) type {
    return struct {
        const Self = @This();
        data: [N]T,

        pub fn init(vals: [N]T) Self {
            return Self{ .data = vals };
        }

        pub fn translate(self: Self, vector: Vector(T, N)) Self {
            var out = Self{.{ .data = undefined }};
            for (0..N) |i| {
                out.data[i] = self.data[i] + vector.data[i];
            }

            return out;
        }

        pub fn substract(self: Self, point: Self) Vector(T, N) {
            var out = Vector(T, N){ .data = undefined };
            for (0..N) |i| {
                out.data[i] = self.data[i] - point.data[i];
            }

            return out;
        }
    };
}
