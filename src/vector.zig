const std = @import("std");

pub fn Vector(comptime T: type, comptime N: usize) type {
    return struct {
        const Self = @This();
        data: [N]T,

        pub fn init(vals: [N]T) Self {
            return Self{ .data = vals };
        }

        // NOTE: Mathematical functions

        pub fn magnitude(self: Self) T {
            return @sqrt(self.data[0] * self.data[0] +
                self.data[1] * self.data[1] +
                self.data[2] * self.data[2]);
        }

        pub fn add(self: Self, other: Self) Self {
            var out = Self{ .data = undefined };
            comptime for (0..N) |i| {
                out.data[i] = self.data[i] + other.data[i];
            };

            return out;
        }

        pub fn inverse(self: Self) Self {
            var out = Self{ .data = undefined };
            comptime for (0..N) |i| {
                out.data[i] = -self.data[i];
            };

            return out;
        }

        pub fn subtract(self: Self, other: Self) Self {
            return self.add(other.inverse());
        }

        pub fn dot(self: Self, other: Self) T {
            var sum: T = @as(T, 0);

            comptime for (0..N) |i| {
                sum += self.data[i] * other.data[i];
            };

            return sum;
        }

        pub fn cross_3d(self: Self, other: Self) Self {
            comptime if (N != 3) {
                @compileError("Cross 3D is only defined for 3-components vectors");
            };

            return Self{ .data = .{
                self.data[1] * other.data[2] - self.data[2] * other.data[1],
                self.data[2] * other.data[0] - self.data[0] * other.data[2],
                self.data[0] * other.data[1] - self.data[1] * other.data[0],
            } };
        }

        pub fn cross_2d(self: Self, other: Self) T {
            comptime if (N != 2) {
                @compileError("Cross 2D is only defined for 2-components vectors");
            };

            return self.data[0] * other.data[1] - self.data[1] * other.data[0];
        }
    };
}
