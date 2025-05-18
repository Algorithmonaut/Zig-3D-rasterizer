const std = @import("std");
const print = std.debug.print;
const c = @cImport({
    @cInclude("MiniFB.h");
});

const primitives = @import("primitives.zig");

const Point = @import("point.zig").Point;
const Vector = @import("point.zig").Vector;

// P: Constants

const window_width = 1920;
const window_height = 1080;

const downscale_factor = 4; // Preferably to be 2^x or 1

const raster_width = @divFloor(window_width, downscale_factor);
const raster_height = @divFloor(window_height, downscale_factor);

// P:

var triangle_1 = primitives.Triangle{ .vertices = .{
    primitives.Vertex{
        .color = 0xFFFF0000,
        .pos = Point(i64, 2).init(.{ 20, 20 }),
    },
    primitives.Vertex{
        .color = 0xFF00FF00,
        .pos = Point(i64, 2).init(.{ 100, 20 }),
    },
    primitives.Vertex{
        .color = 0xFF0000FF,
        .pos = Point(i64, 2).init(.{ 140, 140 }),
    },
} };

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}){};
    const allocator = da.allocator();

    var buffer_1 = try allocator.alloc(u32, @intCast(raster_width * raster_height));
    // var buffer_2 = try std.heap.page_allocator.alloc(u32, @intCast(raster_width * raster_height));
    defer allocator.free(buffer_1);
    // defer allocator.free(buffer_2);
    const buffer = buffer_1[0..];
    @memset(buffer, 0);

    for (triangle_1.vertices) |vertex| {
        const position = vertex.pos.data[0] + vertex.pos.data[1] * raster_width;
        // print("Position: {}\n", .{position});
        buffer[@intCast(position)] = vertex.color;
    }

    const window = c.mfb_open("Minifb Window", window_width, window_height) orelse {
        print("Failed to create window.\n", .{});
        return error.WindowInitFailed;
    };
    defer c.mfb_close(window);

    var i: usize = 0;
    while (true) : (i += 1) {
        @memset(buffer, 0);

        const bounding_box = triangle_1.get_triangle_bounding_box();

        var y = bounding_box[2];
        while (y < bounding_box[3]) : (y += 1) {
            var x = bounding_box[0];
            while (x < bounding_box[1]) : (x += 1) {
                const buffer_pos = y * raster_width + x;
                if (x >= raster_width) break;
                if (y >= raster_height) break;

                const color = triangle_1.is_pixel_in_triangle(Point(i64, 2).init(.{ x, y }));
                if (color) |col| buffer[@intCast(buffer_pos)] = col;
            }
        }

        triangle_1.vertices[2].pos.data[0] = @intCast(i % 4000);
        triangle_1.vertices[1].pos.data[1] = @intCast(i % 40000);

        const state = c.mfb_update_ex(window, @ptrCast(buffer.ptr), @intCast(raster_width), @intCast(raster_height));

        switch (state) {
            c.STATE_OK => {},
            else => break,
        }
    }

    print("RASTER WIDTH/HEIGHT: {}/{}\n", .{ raster_width, raster_height });
}
