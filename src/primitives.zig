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

    pub fn edge_function(self: Triangle) f64 {
        const A = self.vertices[0].pos;
        const B = self.vertices[1].pos;
        const C = self.vertices[2].pos;

        const vector_AB = B.substract(A);
        const vector_AC = C.substract(A);

        const cross = vector_AB.cross_2d(vector_AC);
        const double_signed_area: f64 = @as(f64, @floatFromInt(cross));
        return double_signed_area;
    }

    pub fn is_pixel_in_triangle(self: Triangle, pixel: Point(i64, 2)) ?u32 {
        const vertex_P = Vertex{ .pos = pixel, .color = undefined };

        const A = &self.vertices[0];
        const B = &self.vertices[1];
        const C = &self.vertices[2];

        const triangle_PBC = Triangle{ .vertices = .{ B.*, C.*, vertex_P } };
        const triangle_PCA = Triangle{ .vertices = .{ C.*, A.*, vertex_P } };

        const main_signed_area = self.edge_function();
        const inv_main_signed_area = 1 / main_signed_area;

        const u = triangle_PBC.edge_function() * inv_main_signed_area;
        const v = triangle_PCA.edge_function() * inv_main_signed_area;
        // const w = 1 - u - v;

        const epsilon = 0.001;
        if (u < -epsilon or v < -epsilon or u + v > 1.0 + epsilon) return null;

        // Extract color components (assuming 0xAARRGGBB format)
        const a_color = A.color;
        const b_color = B.color;
        const c_color = C.color;

        // NOTE: idk if I should prefer u16 or u8
        const ui = @as(u16, @intFromFloat(std.math.clamp(u * 255.0, 0.0, 255.0)));
        const vi = @as(u16, @intFromFloat(std.math.clamp(v * 255.0, 0.0, 255.0)));
        const wi = @as(u16, 255 - ui - vi);

        const mask_rb: u32 = 0x00FF00FF;
        const mask_g: u32 = 0x0000FF00;

        const ARB = a_color & mask_rb;
        const BRB = b_color & mask_rb;
        const CRB = c_color & mask_rb;

        const rb_interpolated = (@as(u32, ARB) * @as(u32, ui) +
            @as(u32, BRB) * @as(u32, vi) +
            @as(u32, CRB) * @as(u32, wi)) >> 8;

        const AG = (a_color & mask_g) >> 8;
        const BG = (b_color & mask_g) >> 8;
        const CG = (c_color & mask_g) >> 8;

        const g_interpolated = (@as(u32, AG) * @as(u32, ui) +
            @as(u32, BG) * @as(u32, vi) +
            @as(u32, CG) * @as(u32, wi)) >> 8;

        const g_shifted_back = g_interpolated << 8;

        const result_color = (rb_interpolated & mask_rb) | g_shifted_back;
        return @as(u32, @intCast(result_color));
    }
};
