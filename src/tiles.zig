const std = @import("std");

const constants = @import("constants.zig");
const Triangle = @import("primitives.zig").Triangle;
const Point = @import("point.zig").Point;

pub const Tile = struct {
    fb: [constants.tile_size * constants.tile_size]u32,
    pos: [2]usize,

    pub fn write_to_framebuffer(self: *Tile, main_fb: []u32) void {
        for (0..constants.tile_size) |y| {
            const source_start = y * constants.tile_size;
            const source = self.fb[source_start .. source_start + constants.tile_size];

            const dest_start = (self.pos[1] * constants.tile_size + y) * constants.raster_width + self.pos[0] * constants.tile_size;
            const dest = main_fb[dest_start .. dest_start + constants.tile_size];

            @memcpy(dest, source);
        }
    }

    pub fn rasterizer_triangle(self: *Tile, triangle: Triangle) void {
        // const box = triangle.get_triangle_bounding_box();
        // min/max x min/max y

        // var triangle_overlap_tile: bool = false;
        // const edges: [4]i64 = .{ box[2] + box[0], box[2] + box[1], box[3] + box[0], box[3] + box[1] };

        for (0..constants.tile_size) |y| {
            for (0..constants.tile_size) |x| {
                const x_pos = x + self.pos[0] * constants.tile_size;
                const y_pos = y + self.pos[1] * constants.tile_size;

                if (x_pos + y_pos * constants.raster_width > constants.raster_width * constants.raster_height) continue;

                const color = triangle.is_pixel_in_triangle(Point(i64, 2).init(.{ @intCast(x_pos), @intCast(y_pos) }));
                self.fb[y * constants.tile_size + x] = color orelse 0x00000000;
            }
        }
    }

    pub fn clear(self: *Tile) void {
        @memset(&self.fb, 0);
    }
};
