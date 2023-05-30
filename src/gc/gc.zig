const std = @import("std");

pub const Allocator = struct {
     pub fn create(allocator: *Allocator) !*Object {
        var self = try allocator.create(Object.sizeof);
        self.allocator = allocator;
        return self; 
    }
    fn deinit(self: *Object) void {
        self.allocator.destroy(self); 
    }
};

pub const GCAllocator = struct {
    gc: *GC,

    pub fn create(self: *GCAllocator, len: usize) !*anyopaque {
        return self.gc.alloc(len);
    }

    pub fn destroy(self: *GCAllocator, ptr: *anyopaque) void {
        _ = ptr;
        _ = self;
    }
};

pub const Object = struct {
   allocator: *Allocator,
    deinit: fn (*Object) void,

    pub fn create(allocator: *Allocator) !*Object {
        var self = try allocator.create(Object);
        self.allocator = allocator;
        self.deinit = deinit;
        return self;
    }

    fn deinit(self: *Object) void {
        self.allocator.destroy(self);
    }
};

pub const StringObject = struct {
    object: Object,
    bytes: []u8,
};

pub const VectorObject = struct {
    object: Object,
    elements: []i32,
};

// GC
const objects = std.ArrayList(Object);
const max_memory = 100 * 1024 * 1024; // Max mem 100MB
const gc_pause = 100; // GC 100ms

pub const GC = struct {
    allocator: std.mem.Allocator,
    objects: std.ArrayList(Object),
    last_gc: u64,

    pub fn init(allocator: std.mem.Allocator) GC {
        return .{
            .allocator = allocator,
            .objects = std.ArrayList(Object).init(allocator),
        };
    }

    pub fn alloc(self: *GC, size: usize) !*Object {
        var object = try self.allocator.create(Object);
        object.* = Object{
            .allocator = self.allocator,
            .size = size,
            .marked = false,
        };
        try self.objects.append(object);
        return object;
    }

    pub fn markAndSweep(self: *GC) !void {
        var i: usize = 0;
        while (i < self.objects.items.len) : (i += 1) {
            self.objects.items[i].marked = false;
        }

        for (self.objects.items) |object| {
            if (object.marked) continue;
            markObject(self, object);
        }

        i = 0;
        while (i < self.objects.items.len) {
            if (self.objects.items[i].marked) {
                i += 1;
                continue;
            } else {
                freeObject(&self.objects.items[i]);
                _ = self.objects.swapRemove(i);
            }
        }
    }

    pub fn run(self: *GC) void {
        var memory_used: usize = 0;
        while (true) {
            const now = std.time.milliTimestamp();
            if (now - self.last_gc >= gc_pause and memory_used >= max_memory / 2) {
                self.markAndSweep() catch unreachable;
                memory_used = 0;
                self.last_gc = now;
            }
            memory_used += std.mem.page_size; 
            async.sleep(10); 
        }
    }

    fn doMarkAndSweep(self: *GC) void {
        self.markAndSweep() catch unreachable;
    }
};

fn markObject(gc: *GC, object: *Object) void {
    object.marked = true;

    if (object.size == Object.ref_size) {
        const ref = object.data.ref;
        if (ref) |referenced_object| {
            markObject(gc, referenced_object);
        }
    }

    const obj_start = @ptrCast(*Object, object.data.bytes);
    const obj_end = obj_start + object.size;
    var i: usize = 0;
    while (obj_start + i < obj_end) : (i += Object.ref_size) {
        const inner_ref = obj_start[i].ref;
        if (inner_ref) |inner_object| {
            markObject(gc, inner_object);
        }
    }
}

fn freeObject(object: *Object) void {
    object.allocator.destroy(object);
}