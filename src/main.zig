pub fn main() !void {
    const argv = std.os.argv;
    if (argv.len != 2) {
        std.debug.print("This programe can only accept 1 argument.\n", .{});
        std.posix.exit(255);
    }
    switch (argv[1][0]) {
        '1' => try test_madvise(),
        '2' => try test_mmap_huge(),
        '3' => try test_normal(),
        else => unreachable,
    }
}

fn test_madvise() !void {
    const map_flags: posix.MAP = .{
        .TYPE = .PRIVATE,
        .ANONYMOUS = true,
    };
    const mapped_mem: []align(page_size_min) u8 = posix.mmap(null, LARGE, posix.PROT.READ | posix.PROT.WRITE, map_flags, -1, 0) catch |err| {
        std.debug.print("Failed to mmap: {}\n", .{err});
        return err;
    };
    defer posix.munmap(mapped_mem);
    posix.madvise(mapped_mem.ptr, mapped_mem.len, posix.MADV.HUGEPAGE) catch |err| {
        std.debug.print("Failed to madvise: {}\n", .{err});
    };
    try do_iter(mapped_mem);
}

fn test_mmap_huge() !void {
    const map_flags: posix.MAP = .{
        .TYPE = .PRIVATE,
        .ANONYMOUS = true,
        .HUGETLB = true,
    };
    const mapped_mem: []align(page_size_min) u8 = posix.mmap(null, LARGE, posix.PROT.READ | posix.PROT.WRITE, map_flags, -1, 0) catch |err| {
        std.debug.print("Failed to mmap: {}\n", .{err});
        return err;
    };
    defer posix.munmap(mapped_mem);
    try do_iter(mapped_mem);
}

fn test_normal() !void {
    const map_flags: posix.MAP = .{
        .TYPE = .PRIVATE,
        .ANONYMOUS = true,
    };
    const mapped_mem: []align(page_size_min) u8 = posix.mmap(null, LARGE, posix.PROT.READ | posix.PROT.WRITE, map_flags, -1, 0) catch |err| {
        std.debug.print("Failed to mmap: {}\n", .{err});
        return err;
    };
    defer posix.munmap(mapped_mem);
    try do_iter(mapped_mem);
}

fn do_iter(mapped_mem :[]u8) !void {
    const u64_map = std.mem.bytesAsSlice(u64, mapped_mem);
    var rand_bytes: [8]u8 = undefined;
    const slice = @as([]u8, rand_bytes[0..]);
    try posix.getrandom(slice);
    const rand_num = std.mem.readInt(u64, @ptrCast(slice), .little);
    for (0..ITER) |_| {
        @memset(u64_map, rand_num);
    }
}

const std = @import("std");
const posix = std.posix;
const ITER = 1024;
const LARGE = 1024 * 1024 * 512;
const page_size_min = std.heap.page_size_min;
