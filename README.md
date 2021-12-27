# Texture Packer

Pack given bitmaps into a single one.

Note: This library uses a naive rectangle packing algorithm. It's absolutely
not the most efficient one, but implementation complexity is very low.

Example:
```
const Packer = TexturePacker(u8, 20, 50);
var packer = Packer{};

const rect = std.mem.zeroes([10 * 10]u8);

const a = try packer.pushBitmap(10, 10, &rect);
try expectEqual(a.x, 0);
try expectEqual(a.y, 0);

const b = try packer.pushBitmap(10, 10, &rect);
try expectEqual(b.x, 10);
try expectEqual(b.y, 0);

const c = try packer.pushBitmap(10, 10, &rect);
try expectEqual(c.x, 0);
try expectEqual(c.y, 10);

// All packed bitmaps are stored there. 
const result = packer.bitmap;
```

A good resource about packing algorithms: 
[Exploring rectangle packing algorithms by David Colson](https://www.david-colson.com/2020/03/10/exploring-rect-packing.html)
