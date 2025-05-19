const std = @import("std");
const print = std.debug.print;
const c = @cImport({
    @cInclude("MiniFB.h");
});

const constants = @import("constants.zig");
const primitives = @import("primitives.zig");
const Tile = @import("tiles.zig").Tile;

const Point = @import("point.zig").Point;
const Vector = @import("point.zig").Vector;

var triangle_1 = primitives.Triangle{ .vertices = .{
    primitives.Vertex{
        .color = 0xFFFF0000,
        .pos = Point(i64, 2).init(.{ 0, 0 }),
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

    var buffer_1 = try allocator.alloc(u32, @intCast(constants.raster_width * constants.raster_height));
    // var buffer_2 = try std.heap.page_allocator.alloc(u32, @intCast(raster_width * raster_height));
    defer allocator.free(buffer_1);
    // defer allocator.free(buffer_2);
    const buffer = buffer_1[0..];
    @memset(buffer, 0);

    for (triangle_1.vertices) |vertex| {
        const position = vertex.pos.data[0] + vertex.pos.data[1] * constants.raster_width;
        // print("Position: {}\n", .{position});
        buffer[@intCast(position)] = vertex.color;
    }

    const window = c.mfb_open("Minifb Window", constants.window_width, constants.window_height) orelse {
        print("Failed to create window.\n", .{});
        return error.WindowInitFailed;
    };
    defer c.mfb_close(window);

    var tile = Tile{ .pos = .{ 0, 0 }, .fb = undefined };
    var j: usize = 0;
    while (j < tile.fb.len) : (j += 1) {
        tile.fb[j] = 0xFFFFFFFF;
    }

    var tile_2 = Tile{ .pos = .{ 1, 1 }, .fb = undefined };
    j = 0;
    while (j < tile.fb.len) : (j += 1) {
        tile_2.fb[j] = 0xFFFFFFFF;
    }

    var tiles: [(constants.vertical_tiles_count - 1) * constants.horizontal_tiles_count]Tile = undefined;

    var idx: usize = 0;
    for (0..constants.horizontal_tiles_count) |x| {
        for (0..constants.vertical_tiles_count - 1) |y| {
            tiles[idx] = Tile{
                .fb = undefined,
                .pos = .{ x, y },
            };

            idx += 1;
        }
    }

    var i: usize = 20;
    while (true) : (i += 1) {
        @memset(buffer, 0);

        // const bounding_box = triangle_1.get_triangle_bounding_box();
        //
        // var y = bounding_box[2];
        // while (y < bounding_box[3]) : (y += 1) {
        //     var x = bounding_box[0];
        //     while (x < bounding_box[1]) : (x += 1) {
        //         const buffer_pos = y * constants.raster_width + x;
        //         if (x >= constants.raster_width) break;
        //         if (y >= constants.raster_height) break;
        //
        //         const color = triangle_1.is_pixel_in_triangle(Point(i64, 2).init(.{ x, y }));
        //         if (color) |col| buffer[@intCast(buffer_pos)] = col;
        //     }
        // }

        for (&tiles) |*t| {
            t.clear();
            t.rasterizer_triangle(triangle_1);
            t.write_to_framebuffer(buffer);
        }

        // tile.rasterizer_triangle(triangle_1);
        // tile_2.rasterizer_triangle(triangle_1);
        // tile.write_to_framebuffer(buffer);
        // tile_2.write_to_framebuffer(buffer);

        triangle_1.vertices[2].pos.data[0] = @intCast(i % 600 + 80);
        triangle_1.vertices[1].pos.data[1] = @intCast(i % 300 + 80);

        const state = c.mfb_update_ex(window, @ptrCast(buffer.ptr), @intCast(constants.raster_width), @intCast(constants.raster_height));

        switch (state) {
            c.STATE_OK => {},
            else => break,
        }
    }

    print("RASTER WIDTH/HEIGHT: {}/{}\n", .{ constants.raster_width, constants.raster_height });
    print("Horizontal tiles: {}, vertical tiles: {}\n", .{ constants.horizontal_tiles_count, constants.vertical_tiles_count });
}
