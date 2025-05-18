const std = @import("std");
const Vector = @import("vector.zig").Vector;
const Point = @import("point.zig").Point;

pub const Vertex = struct {
    color: u32,
    pos: Point(i64, 2),
};

pub const Triangle = struct {
    vertices: [3]Vertex,

    /// min_x, max_x, min_y, max_y
    pub fn get_triangle_bounding_box(self: Triangle) [4]i64 {
        const A = &self.vertices[0];
        const B = &self.vertices[1];
        const C = &self.vertices[2];

        const min_x = @min(A.pos.data[0], B.pos.data[0], C.pos.data[0]);
        const max_x = @max(A.pos.data[0], B.pos.data[0], C.pos.data[0]);
        const min_y = @min(A.pos.data[1], B.pos.data[1], C.pos.data[1]);
        const max_y = @max(A.pos.data[1], B.pos.data[1], C.pos.data[1]);

        return [4]i64{ min_x, max_x, min_y, max_y };
    }

    pub fn compute_signed_area(self: Triangle) f64 {
        const A = &self.vertices[0];
        const B = &self.vertices[1];
        const C = &self.vertices[2];

        const vector_AB = B.pos.substract(A.pos);
        const vector_AC = C.pos.substract(A.pos);

        const cross = vector_AB.cross_2d(vector_AC);
        const signed_area: f64 = @as(f64, @floatFromInt(cross)) / 2.0;

        // std.debug.print("Area: {}\n", .{signed_area});

        return signed_area;
    }

    // pub fn is_pixel_in_triangle(self: Triangle, pixel: Point(i64, 2)) ?u32 {
    //     const vertex_P = Vertex{ .pos = pixel, .color = undefined };
    //
    //     const A = &self.vertices[0];
    //     const B = &self.vertices[1];
    //     const C = &self.vertices[2];
    //
    //     const triangle_PBC = Triangle{ .vertices = .{ B.*, C.*, vertex_P } };
    //     const triangle_PCA = Triangle{ .vertices = .{ C.*, A.*, vertex_P } };
    //     const triangle_PAB = Triangle{ .vertices = .{ A.*, B.*, vertex_P } };
    //
    //     const main_signed_area = self.compute_signed_area();
    //     const main_area = @abs(main_signed_area);
    //
    //     if (main_area < 0.0001) {
    //         return null; // Degenerate triangle
    //     }
    //
    //     const u = triangle_PBC.compute_signed_area() / main_signed_area;
    //     const v = triangle_PCA.compute_signed_area() / main_signed_area;
    //     const w = triangle_PAB.compute_signed_area() / main_signed_area;
    //
    //
    //
    //     const epsilon = 0.001;
    //     if (!((u >= -epsilon) and (v >= -epsilon) and (w >= -epsilon) and
    //         (u + v + w >= 1.0 - epsilon) and (u + v + w <= 1.0 + epsilon))) return null;
    //
    //     const new_color: 32 = u * A.color + v * B.color + w * C.color;
    //     return new_color;
    // }

    pub fn is_pixel_in_triangle(self: Triangle, pixel: Point(i64, 2)) ?u32 {
        const vertex_P = Vertex{ .pos = pixel, .color = undefined };

        const A = &self.vertices[0];
        const B = &self.vertices[1];
        const C = &self.vertices[2];

        const triangle_PBC = Triangle{ .vertices = .{ B.*, C.*, vertex_P } };
        const triangle_PCA = Triangle{ .vertices = .{ C.*, A.*, vertex_P } };
        const triangle_PAB = Triangle{ .vertices = .{ A.*, B.*, vertex_P } };

        const main_signed_area = self.compute_signed_area();
        const main_area = @abs(main_signed_area);

        if (main_area < 0.0001) {
            return null; // Degenerate triangle
        }

        const u = triangle_PBC.compute_signed_area() / main_signed_area;
        const v = triangle_PCA.compute_signed_area() / main_signed_area;
        const w = triangle_PAB.compute_signed_area() / main_signed_area;

        const epsilon = 0.001;
        if (!(u >= -epsilon and v >= -epsilon and w >= -epsilon and
            (u + v + w >= 1.0 - epsilon) and (u + v + w <= 1.0 + epsilon)))
            return null;

        // Extract color components (assuming 0xAARRGGBB format)
        const a_color = A.color;
        const b_color = B.color;
        const c_color = C.color;

        const a_a = @as(f32, @floatFromInt((a_color >> 24) & 0xFF));
        const a_r = @as(f32, @floatFromInt((a_color >> 16) & 0xFF));
        const a_g = @as(f32, @floatFromInt((a_color >> 8) & 0xFF));
        const a_b = @as(f32, @floatFromInt(a_color & 0xFF));

        const b_a = @as(f32, @floatFromInt((b_color >> 24) & 0xFF));
        const b_r = @as(f32, @floatFromInt((b_color >> 16) & 0xFF));
        const b_g = @as(f32, @floatFromInt((b_color >> 8) & 0xFF));
        const b_b = @as(f32, @floatFromInt(b_color & 0xFF));

        const c_a = @as(f32, @floatFromInt((c_color >> 24) & 0xFF));
        const c_r = @as(f32, @floatFromInt((c_color >> 16) & 0xFF));
        const c_g = @as(f32, @floatFromInt((c_color >> 8) & 0xFF));
        const c_b = @as(f32, @floatFromInt(c_color & 0xFF));

        // Interpolate each component
        const interp_a = u * a_a + v * b_a + w * c_a;
        const interp_r = u * a_r + v * b_r + w * c_r;
        const interp_g = u * a_g + v * b_g + w * c_g;
        const interp_b = u * a_b + v * b_b + w * c_b;

        // Clamp to 0-255 and convert to u8
        const new_a = @as(u8, @intFromFloat(std.math.clamp(interp_a, 0, 255))); // Fixed parentheses
        const new_r = @as(u8, @intFromFloat(std.math.clamp(interp_r, 0, 255))); // Fixed parentheses
        const new_g = @as(u8, @intFromFloat(std.math.clamp(interp_g, 0, 255))); // Fixed parentheses
        const new_b = @as(u8, @intFromFloat(std.math.clamp(interp_b, 0, 255))); // Fixed parentheses

        // Pack into u32 (0xAARRGGBB)
        const new_color = (@as(u32, new_a) << 24) |
            (@as(u32, new_r) << 16) |
            (@as(u32, new_g) << 8) |
            new_b;

        return new_color;
    }
};

pub fn main() void {}
