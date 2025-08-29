const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("acl", .{});
    const attr_upstream = b.dependency("attr", .{});

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    translate_c.defineCMacro("EXPORT", "extern");
    translate_c.addIncludePath(upstream.path("include"));

    const config_h = b.addConfigHeader(.{
        .style = .{
            .autoconf_undef = upstream.path("include/config.h.in"),
        },
        .include_path = "config.h",
    }, .{
        .AC_APPLE_UNIVERSAL_BUILD = null,
        .ENABLE_NLS = 1,
        .EXPORT = .@"__attribute__ ((visibility (\"default\"))) extern",
        .HAVE_ATTR_ERROR_CONTEXT_H = null,
        .HAVE_CFLOCALECOPYPREFERREDLANGUAGES = null,
        .HAVE_CFPREFERENCESCOPYAPPVALUE = null,
        .HAVE_DCGETTEXT = 1,
        .HAVE_DLFCN_H = 1,
        .HAVE_GETTEXT = 1,
        .HAVE_ICONV = null,
        .HAVE_INTTYPES_H = 1,
        .HAVE_LIBATTR = 1,
        .HAVE_MINIX_CONFIG_H = null,
        .HAVE_STDINT_H = 1,
        .HAVE_STDIO_H = 1,
        .HAVE_STDLIB_H = 1,
        .HAVE_STRINGS_H = 1,
        .HAVE_STRING_H = 1,
        .HAVE_SYS_STAT_H = 1,
        .HAVE_SYS_TYPES_H = 1,
        .HAVE_UNISTD_H = 1,
        .HAVE_VISIBILITY_ATTRIBUTE = {},
        .HAVE_WCHAR_H = 1,
        .LT_OBJDIR = ".libs/",
        .PACKAGE = "acl",
        .PACKAGE_BUGREPORT = "acl-devel@nongnu.org",
        .PACKAGE_NAME = "acl",
        .PACKAGE_STRING = "acl 2.3.2",
        .PACKAGE_TARNAME = "acl",
        .PACKAGE_URL = "",
        .PACKAGE_VERSION = "2.3.2",
        .STDC_HEADERS = 1,
        ._ALL_SOURCE = 1,
        ._DARWIN_C_SOURCE = 1,
        .__EXTENSIONS__ = 1,
        ._GNU_SOURCE = 1,
        ._HPUX_ALT_XOPEN_SOCKET_API = 1,
        ._MINIX = null,
        ._NETBSD_SOURCE = 1,
        ._OPENBSD_SOURCE = 1,
        ._POSIX_SOURCE = null,
        ._POSIX_1_SOURCE = null,
        ._POSIX_PTHREAD_SEMANTICS = 1,
        .__STDC_WANT_IEC_60559_ATTRIBS_EXT__ = 1,
        .__STDC_WANT_IEC_60559_BFP_EXT__ = 1,
        .__STDC_WANT_IEC_60559_DFP_EXT__ = 1,
        .__STDC_WANT_IEC_60559_EXT__ = 1,
        .__STDC_WANT_IEC_60559_FUNCS_EXT__ = 1,
        .__STDC_WANT_IEC_60559_TYPES_EXT__ = 1,
        .__STDC_WANT_LIB_EXT2__ = 1,
        .__STDC_WANT_MATH_SPEC_FUNCS__ = 1,
        ._TANDEM_SOURCE = 1,
        ._XOPEN_SOURCE = null,
        .VERSION = "2.3.2",
        .WORDS_BIGENDIAN = null,
        ._FILE_OFFSET_BITS = null,
        ._LARGE_FILES = null,
        ._TIME_BITS = null,
        .__MINGW_USE_VC2005_COMPAT = null,
    });

    const misc = b.addLibrary(.{
        .name = "misc",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    misc.installHeader(
        upstream.path("include/acl.h"),
        "sys/acl.h",
    );
    misc.installHeader(
        upstream.path("include/libacl.h"),
        "acl/libacl.h",
    );

    const lib = b.addLibrary(.{
        .name = "acl",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "c", .module = translate_c.createModule() },
            },
        }),
    });
    lib.root_module.addCMacro("HAVE_CONFIG_H", "1");
    lib.addConfigHeader(config_h);
    lib.addIncludePath(upstream.path("."));
    lib.addIncludePath(upstream.path("libacl"));
    lib.addIncludePath(upstream.path("include"));
    lib.addIncludePath(attr_upstream.path("include"));
    lib.addCSourceFiles(.{
        .root = upstream.path("libacl"),
        .files = &acl_src,
        .flags = &.{"-includelibacl/perm_copy.h"},
    });
    lib.addCSourceFiles(.{
        .root = upstream.path("libmisc"),
        .files = &misc_src,
        .flags = &.{},
    });
    lib.linkLibrary(misc);
    lib.installHeader(
        upstream.path("include/acl.h"),
        "sys/acl.h",
    );
    lib.installHeader(
        upstream.path("include/libacl.h"),
        "acl/libacl.h",
    );
    b.installArtifact(lib);

    const mod_tests = b.addTest(.{
        .root_module = lib.root_module,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}

const acl_src = [_][]const u8{
    "perm_copy_fd.c",
    "perm_copy_file.c",
    "acl_add_perm.c",
    "acl_calc_mask.c",
    "acl_clear_perms.c",
    "acl_copy_entry.c",
    "acl_copy_ext.c",
    "acl_copy_int.c",
    "acl_create_entry.c",
    "acl_delete_def_file.c",
    "acl_delete_entry.c",
    "acl_delete_perm.c",
    "acl_dup.c",
    "acl_free.c",
    "acl_from_text.c",
    "acl_get_entry.c",
    "acl_get_fd.c",
    "acl_get_file.c",
    "acl_get_perm.c",
    "acl_get_permset.c",
    "acl_get_qualifier.c",
    "acl_get_tag_type.c",
    "acl_init.c",
    "acl_set_fd.c",
    "acl_set_file.c",
    "acl_set_permset.c",
    "acl_set_qualifier.c",
    "acl_set_tag_type.c",
    "acl_size.c",
    "acl_to_text.c",
    "acl_valid.c",
    "acl_check.c",
    "acl_cmp.c",
    "acl_entries.c",
    "acl_equiv_mode.c",
    "acl_error.c",
    "acl_extended_fd.c",
    "acl_extended_file.c",
    "acl_extended_file_nofollow.c",
    "acl_from_mode.c",
    "acl_to_any_text.c",
    "__acl_extended_file.c",
    "__acl_from_xattr.c",
    "__acl_reorder_obj_p.c",
    "__acl_to_any_text.c",
    "__acl_to_xattr.c",
    "__apply_mask_to_mode.c",
    "__libobj.c",
};

const misc_src = [_][]const u8{
    "uid_gid_lookup.c",
    "high_water_alloc.c",
    "next_line.c",
    "quote.c",
    "unquote.c",
    "walk_tree.c",
};
