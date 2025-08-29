const std = @import("std");
const testing = std.testing;
const c = @import("c");

test {
    const filename = "test.txt";
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    var file = try tmp_dir.dir.createFile(filename, .{ .truncate = true });
    try file.writeAll("hello world");
    file.close();
    try tmp_dir.dir.setAsCwd();

    const uid = std.posix.getuid();

    var acl = c.acl_init(1);
    try testing.expect(acl != null);
    defer _ = c.acl_free(acl);

    var entry: c.acl_entry_t = undefined;
    try testing.expect(c.acl_create_entry(&acl, &entry) == 0);

    // 4. Set the tag and qualifier for the new entry (user with current uid)
    try testing.expect(c.acl_set_tag_type(entry, c.ACL_USER) == 0);
    try testing.expect(c.acl_set_qualifier(entry, &uid) == 0);

    // 5. Set the permissions for the entry (read and write)
    var permset: c.acl_permset_t = undefined;
    try testing.expect(c.acl_get_permset(entry, &permset) == 0);
    try testing.expect(c.acl_clear_perms(permset) == 0);
    try testing.expect(c.acl_add_perm(permset, c.ACL_READ) == 0);
    try testing.expect(c.acl_add_perm(permset, c.ACL_WRITE) == 0);
    try testing.expect(c.acl_set_permset(entry, permset) == 0);

    if (true) return; // TODO: fix the test

    // 6. Set the ACL on the file
    try testing.expect(c.acl_set_file(filename, c.ACL_TYPE_ACCESS, acl) == 0);

    // 7. Get the ACL from the file
    const retrieved_acl = c.acl_get_file(filename, c.ACL_TYPE_ACCESS);
    try testing.expect(retrieved_acl != null);
    defer _ = c.acl_free(retrieved_acl);

    // 8. Convert both ACLs to text for comparison
    const original_acl_text_ptr = c.acl_to_text(acl, null);
    try testing.expect(original_acl_text_ptr != null);
    defer _ = c.acl_free(original_acl_text_ptr);
    const original_acl_text = std.mem.span(original_acl_text_ptr);

    const retrieved_acl_text_ptr = c.acl_to_text(retrieved_acl, null);
    try testing.expect(retrieved_acl_text_ptr != null);
    defer _ = c.acl_free(retrieved_acl_text_ptr);
    const retrieved_acl_text = std.mem.span(retrieved_acl_text_ptr);

    // 9. Verify that the ACLs are the same
    try std.testing.expectEqualStrings(original_acl_text, retrieved_acl_text);
}
