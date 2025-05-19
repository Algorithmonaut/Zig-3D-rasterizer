pub const window_width = 1920;
pub const window_height = 1080;

pub const downscale_factor = 2; // Preferably to be 2^x or 1

pub const raster_width = @divFloor(window_width, downscale_factor);
pub const raster_height = @divFloor(window_height, downscale_factor);

pub const tile_size = 32;

const f_raster_width: f64 = @floatFromInt(raster_width);
const f_raster_height: f64 = @floatFromInt(raster_height);
const f_tile_size: f64 = @floatFromInt(tile_size);

pub const vertical_tiles_count: usize = @intFromFloat(@ceil(f_raster_height / f_tile_size));
pub const horizontal_tiles_count: usize = @intFromFloat(@ceil(f_raster_width / f_tile_size));
