const std = @import("std");
const mem = std.mem;

/// Pack given bitmaps into a single bitmap. This library uses a naive 
/// rectangle packing algorithm.
///
/// Note: You should sort items by height or surface area before 
/// iterating over them.  
///
/// The final result is stored in the `bitmap` field.
pub fn TexturePacker(comptime T: anytype, comptime W: i32, comptime H: i32) type {
    return struct {
        /// Bitmap's width maximum size.
        totalWidth: i32 = W,
        /// Bitmap's height maximum size.
        totalHeight: i32 = H,
        /// Packer position of the next item stored in the bitmap.
        cursor: struct { x: i32, y: i32 } = .{ .x = 0, .y = 0 },
        /// The current row's largest `height` in order to create
        /// the next row when the current one is full.
        largestHeightInCurrentRow: i32 = 0,
        /// Result of the rect packing, so it contains all pushed bitmaps.
        bitmap: [W][H]T = mem.zeroes([W][H]T),

        /// A rectangle position in the packed texture.
        pub const RectPos = struct { x: usize, y: usize, w: usize, h: usize };
        /// Error thrown when no place can't be fill, or the pushed bitmap 
        /// is way larger than the total packer size. 
        pub const PackerError = error{ isFull, bitmapTooLarge };

        const Self = @This();

        /// Push given bitmap into the packer one.
        /// Note: The data size must be width * height.
        pub fn pushBitmap(self: *Self, width: i32, height: i32, data: []const T) !RectPos {
            if (width > self.totalWidth or height > self.totalHeight) {
                return PackerError.bitmapTooLarge;
            }

            if ((self.cursor.x + width) > self.totalWidth) {
                self.cursor.y += self.largestHeightInCurrentRow;
                self.cursor.x = 0;
                self.largestHeightInCurrentRow = 0;
            }

            if ((self.cursor.y + height) >= self.totalHeight) {
                return PackerError.isFull;
            }

            if (height > self.largestHeightInCurrentRow) {
                self.largestHeightInCurrentRow = height;
            }

            const rectPos = RectPos{
                .x = @intCast(usize, self.cursor.x),
                .y = @intCast(usize, self.cursor.y),
                .w = @intCast(usize, width),
                .h = @intCast(usize, height),
            };

            self.cursor.x += width;

            var i: usize = 0;
            while (i < width) : (i += 1) {
                var j: usize = 0;
                while (j < height) : (j += 1) {
                    self.bitmap[(rectPos.y + j)][(rectPos.x + i)] =
                        data[j * @intCast(usize, width) + i];
                }
            }

            return rectPos;
        }
    };
}

test "Texture Packer" {
    const expectEqual = std.testing.expectEqual;
    const expectError = std.testing.expectError;

    const Packer = TexturePacker(u8, 40, 100);
    var packer = Packer{};

    {
        const rect = std.mem.zeroes([200 * 200]u8);
        const pos = packer.pushBitmap(200, 200, &rect);
        try expectError(Packer.PackerError.bitmapTooLarge, pos);
    }

    {
        const rect = std.mem.zeroes([10 * 10]u8);
        const pos = try packer.pushBitmap(10, 10, &rect);
        try expectEqual(pos.x, 0);
        try expectEqual(pos.y, 0);
        try expectEqual(pos.w, 10);
        try expectEqual(pos.h, 10);
    }

    {
        const rect = std.mem.zeroes([10 * 10]u8);
        const pos = try packer.pushBitmap(10, 10, &rect);
        try expectEqual(pos.x, 10);
        try expectEqual(pos.y, 0);
        try expectEqual(pos.w, 10);
        try expectEqual(pos.h, 10);
    }

    {
        const rect = std.mem.zeroes([10 * 20]u8);
        const pos = try packer.pushBitmap(10, 20, &rect);
        try expectEqual(pos.x, 20);
        try expectEqual(pos.y, 0);
        try expectEqual(pos.w, 10);
        try expectEqual(pos.h, 20);
    }

    {
        const rect = std.mem.zeroes([40 * 20]u8);
        const pos = try packer.pushBitmap(40, 20, &rect);
        try expectEqual(pos.x, 0);
        try expectEqual(pos.y, 20);
        try expectEqual(pos.w, 40);
        try expectEqual(pos.h, 20);
    }

    {
        const rect = std.mem.zeroes([10 * 60]u8);
        const pos = packer.pushBitmap(10, 60, &rect);
        try expectError(Packer.PackerError.isFull, pos);
    }
}
