const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "Specify static or dynamic linkage",
    ) orelse .static;

    const iceoryx = b.dependency("iceoryx", .{});
    const cpptoml = b.dependency("cpptoml", .{});

    const std_cxx_flags: []const []const u8 = &.{
        "--std=c++17",
        "-pthread",
        "-W",
        "-Wall",
        "-Wextra",
        "-Wuninitialized",
        "-Wpedantic",
        "-Wstrict-aliasing",
        "-Wcast-align",
        "-Wconversion",
        // Not sure why this isn't found in <climits>
        "-DSEM_VALUE_MAX=2147483647",
    };

    // =========================================================================
    // Configured Files

    const version_config = b.addConfigHeader(.{
        .style = .{ .cmake = iceoryx.path("iceoryx_platform/cmake/iceoryx_versions.h.in") },
    }, .{
        .PROJECT_VERSION_MAJOR = 2,
        .PROJECT_VERSION_MINOR = 95,
        .PROJECT_VERSION_PATCH = 4,
        .IOX_VERSION_TWEAK = 0,
        .PROJECT_VERSION = "2.95.4",
        .IOX_VERSION_SUFFIX = "",
        .ICEORYX_BUILDDATE = "REPRODUCIBLE-BUILD",
        .ICEORYX_SHA1 = "c616c3bd0f4147af6d5b33e89f66136da50d7902",
    });

    // =========================================================================
    // Libraries

    // -------------------------------------------------------------------------
    // iceoryx_platform
    const platform_config = b.addConfigHeader(.{
        .style = .{ .cmake = iceoryx.path("iceoryx_platform/linux/cmake/platform_settings.hpp.in") },
        .include_path = "iceoryx_platform/platform_settings.hpp",
    }, .{
        .IOX_CFG_FEATURE_ACL = 0, // libacl - can disable!
        .IOX_PLATFORM_LOCK_FILE_PATH_PREFIX = "/tmp/",
        .IOX_PLATFORM_TEMP_DIR = "/tmp/",
        .IOX_PLATFORM_UDS_SOCKET_PATH_PREFIX = "/tmp/",
        .IOX_PLATFORM_DEFAULT_CONFIG_LOCATION = "/etc/",
    });

    const iceoryx_platform = b.addLibrary(.{
        .name = "iceoryx_platform",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = true,
            .link_libc = true,
            .link_libcpp = true,
        }),
        .linkage = linkage,
    });
    iceoryx_platform.addConfigHeader(platform_config);
    iceoryx_platform.addConfigHeader(version_config);

    for (all_include_dirs) |dir| {
        iceoryx_platform.addIncludePath(iceoryx.path(dir));
    }

    iceoryx_platform.addCSourceFiles(.{
        .root = iceoryx.path("."),
        .files = platform_generic_files ++ platform_linux_files,
        .flags = std_cxx_flags,
    });

    b.installArtifact(iceoryx_platform);

    // -------------------------------------------------------------------------
    // iceoryx_hoofs
    const hoofs_deploy_config = b.addConfigHeader(.{
        .style = .{ .cmake = iceoryx.path("iceoryx_hoofs/cmake/iceoryx_hoofs_deployment.hpp.in") },
        .include_path = "iox/iceoryx_hoofs_deployment.hpp",
    }, .{
        .IOX_VERSION_STRING = "2.95.4",
        .IOX_MINIMAL_LOG_LEVEL = "Trace",
        .IOX_MAX_NAMED_PIPE_MESSAGE_SIZE = 4096,
        .IOX_MAX_NAMED_PIPE_NUMBER_OF_MESSAGES = 10,
    });

    const iceoryx_hoofs = b.addLibrary(.{
        .name = "iceoryx_hoofs",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = true,
            .link_libc = true,
            .link_libcpp = true,
        }),
        .linkage = linkage,
    });
    iceoryx_hoofs.addConfigHeader(hoofs_deploy_config);
    iceoryx_hoofs.addConfigHeader(version_config);
    iceoryx_hoofs.addConfigHeader(platform_config);
    iceoryx_hoofs.linkLibrary(iceoryx_platform);

    for (all_include_dirs) |dir| {
        iceoryx_hoofs.addIncludePath(iceoryx.path(dir));
    }

    iceoryx_hoofs.addCSourceFiles(.{
        .root = iceoryx.path("."),
        .files = hoofs_files,
        .flags = std_cxx_flags,
    });

    b.installArtifact(iceoryx_hoofs);

    // -------------------------------------------------------------------------
    // iceoryx_posh
    const posh_deploy_config = b.addConfigHeader(.{
        .style = .{ .cmake = iceoryx.path("iceoryx_posh/cmake/iceoryx_posh_deployment.hpp.in") },
        .include_path = "iceoryx_posh/iceoryx_posh_deployment.hpp",
    }, .{
        .IOX_COMMUNICATION_POLICY = "ManyToManyPolicy",
        .IOX_DEFAULT_RESOURCE_PREFIX = "iox1",
        .IOX_EXPERIMENTAL_POSH_FLAG = "false",
        .IOX_INTERPROCESS_LOCK = "mutex",
        .IOX_INTERPROCESS_SEMAPHORE = "UnnamedSemaphore",
        .IOX_MAX_CHUNKS_ALLOCATED_PER_PUBLISHER_SIMULTANEOUSLY = 8,
        .IOX_MAX_CHUNKS_HELD_PER_SUBSCRIBER_SIMULTANEOUSLY = 256,
        .IOX_MAX_CLIENTS = 512,
        .IOX_MAX_CLIENTS_PER_SERVER = 256,
        .IOX_MAX_ID_STRING_LENGTH = 100,
        .IOX_MAX_INTERFACE_NUMBER = 4,
        .IOX_MAX_NODE_NAME_LENGTH = 87,
        .IOX_MAX_NODE_NUMBER = 1000,
        .IOX_MAX_NODE_PER_PROCESS = 50,
        .IOX_MAX_NUMBER_OF_CONDITION_VARIABLES = 1024,
        .IOX_MAX_NUMBER_OF_MEMPOOLS = 32,
        .IOX_MAX_NUMBER_OF_NOTIFIERS = 256,
        .IOX_MAX_PROCESS_NUMBER = 300,
        .IOX_MAX_PUBLISHERS = 512,
        .IOX_MAX_PUBLISHER_HISTORY = 16,
        .IOX_MAX_REQUESTS_PROCESSED_SIMULTANEOUSLY = 4,
        .IOX_MAX_REQUEST_QUEUE_CAPACITY = 1024,
        .IOX_MAX_RESPONSES_PROCESSED_SIMULTANEOUSLY = 16,
        .IOX_MAX_RESPONSE_QUEUE_CAPACITY = 16,
        .IOX_MAX_RUNTIME_NAME_LENGTH = 87,
        .IOX_MAX_SERVERS = 128,
        .IOX_MAX_SHM_SEGMENTS = 100,
        .IOX_MAX_SUBSCRIBERS = 1024,
        .IOX_MAX_SUBSCRIBERS_PER_PUBLISHER = 256,
    });

    const iceoryx_posh = b.addLibrary(.{
        .name = "iceoryx_posh",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = true,
            .link_libc = true,
            .link_libcpp = true,
        }),
        .linkage = linkage,
    });
    iceoryx_posh.addConfigHeader(version_config);
    iceoryx_posh.addConfigHeader(platform_config);
    iceoryx_posh.addConfigHeader(hoofs_deploy_config);
    iceoryx_posh.addConfigHeader(posh_deploy_config);

    for (all_include_dirs) |dir| {
        iceoryx_posh.addIncludePath(iceoryx.path(dir));
    }
    iceoryx_posh.addIncludePath(cpptoml.path("include"));

    iceoryx_posh.addCSourceFiles(.{
        .root = iceoryx.path("."),
        .files = posh_files,
        .flags = std_cxx_flags,
    });

    b.installArtifact(iceoryx_posh);

    // -------------------------------------------------------------------------
    // iceoryx_binding_c
    const iceoryx_binding_c = b.addLibrary(.{
        .name = "iceoryx_binding_c",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .pic = true,
            .link_libc = true,
            .link_libcpp = true,
        }),
        .linkage = linkage,
    });
    iceoryx_binding_c.addConfigHeader(version_config);
    iceoryx_binding_c.addConfigHeader(platform_config);
    iceoryx_binding_c.addConfigHeader(hoofs_deploy_config);
    iceoryx_binding_c.addConfigHeader(posh_deploy_config);

    for (all_include_dirs) |dir| {
        iceoryx_binding_c.addIncludePath(iceoryx.path(dir));
    }

    iceoryx_binding_c.addCSourceFiles(.{
        .root = iceoryx.path("."),
        .files = binding_c_files,
        .flags = std_cxx_flags,
    });

    iceoryx_binding_c.linkLibrary(iceoryx_hoofs);
    iceoryx_binding_c.linkLibrary(iceoryx_posh);

    b.installArtifact(iceoryx_binding_c);

    // -------------------------------------------------------------------------
    // Install all header files
    for (all_include_dirs) |dir| {
        iceoryx_binding_c.installHeadersDirectory(iceoryx.path(dir), "", .{
            .include_extensions = &.{ ".h", ".hpp" },
        });
    }

    // -------------------------------------------------------------------------
    // Iceoryx RouDi (Routing and Discovery) Executable
    // Note that MUSL does *not* provide all necessary pthread symbols, so we MUST use GNU
    var rudi_target: std.Build.ResolvedTarget = target;
    rudi_target.query.abi = .gnu;

    const roudi = b.addExecutable(.{
        .name = "iox-roudi",
        .root_module = b.createModule(.{
            .target = rudi_target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
            .pic = true,
        }),
        .link_libc = true,
        //.linkage = linkage,
    });
    roudi.addCSourceFile(.{
        .file = iceoryx.path("iceoryx_posh/source/roudi/application/roudi_main.cpp"),
        .flags = std_cxx_flags,
    });
    roudi.linkLibrary(iceoryx_hoofs);
    roudi.linkLibrary(iceoryx_posh);

    // TODO: Need to clean up the includes everywhere
    for (all_include_dirs) |dir| {
        roudi.addIncludePath(iceoryx.path(dir));
    }
    roudi.addConfigHeader(version_config);
    roudi.addConfigHeader(platform_config);
    roudi.addConfigHeader(hoofs_deploy_config);
    roudi.addConfigHeader(posh_deploy_config);

    b.installArtifact(roudi);
}

const examples_files: []const []const u8 = &.{
    "iceoryx_examples/experimental/node/iox_cpp_node_publisher.cpp",
    "iceoryx_examples/experimental/node/iox_cpp_node_server.cpp",
    "iceoryx_examples/experimental/node/iox_cpp_node_subscriber.cpp",
    "iceoryx_examples/experimental/node/iox_cpp_node_client.cpp",
    "iceoryx_examples/icedelivery/iox_subscriber_untyped.cpp",
    "iceoryx_examples/icedelivery/iox_subscriber.cpp",
    "iceoryx_examples/icedelivery/iox_publisher_untyped.cpp",
    "iceoryx_examples/icedelivery/iox_publisher.cpp",
    "iceoryx_examples/callbacks/ice_callbacks_publisher.cpp",
    "iceoryx_examples/callbacks/ice_callbacks_listener_as_class_member.cpp",
    "iceoryx_examples/callbacks/ice_callbacks_subscriber.cpp",
    "iceoryx_examples/iceperf/roudi_main_static_config.cpp",
    "iceoryx_examples/iceperf/iceoryx.cpp",
    "iceoryx_examples/iceperf/main_follower.cpp",
    "iceoryx_examples/iceperf/uds.cpp",
    "iceoryx_examples/iceperf/iceoryx_wait.cpp",
    "iceoryx_examples/iceperf/iceperf_follower.cpp",
    "iceoryx_examples/iceperf/mq.cpp",
    "iceoryx_examples/iceperf/iceperf_leader.cpp",
    "iceoryx_examples/iceperf/main_leader.cpp",
    "iceoryx_examples/iceperf/iceoryx_c.cpp",
    "iceoryx_examples/iceperf/base.cpp",
    "iceoryx_examples/complexdata/iox_subscriber_vector.cpp",
    "iceoryx_examples/complexdata/iox_subscriber_complexdata.cpp",
    "iceoryx_examples/complexdata/iox_publisher_complexdata.cpp",
    "iceoryx_examples/complexdata/iox_publisher_vector.cpp",
    "iceoryx_examples/icehello/iox_publisher_helloworld.cpp",
    "iceoryx_examples/icehello/iox_subscriber_helloworld.cpp",
    "iceoryx_examples/user_header/publisher_cxx_api.cpp",
    "iceoryx_examples/user_header/subscriber_untyped_cxx_api.cpp",
    "iceoryx_examples/user_header/subscriber_cxx_api.cpp",
    "iceoryx_examples/user_header/publisher_untyped_cxx_api.cpp",
    "iceoryx_examples/ice_access_control/iox_radar_app.cpp",
    "iceoryx_examples/ice_access_control/iox_display_app.cpp",
    "iceoryx_examples/ice_access_control/iox_cheeky_app.cpp",
    "iceoryx_examples/ice_access_control/roudi_main_static_segments.cpp",
    "iceoryx_examples/icediscovery/src/discovery_monitor.cpp",
    "iceoryx_examples/icediscovery/src/discovery_blocking.cpp",
    "iceoryx_examples/icediscovery/iox_discovery_monitor.cpp",
    "iceoryx_examples/icediscovery/iox_offer_service.cpp",
    "iceoryx_examples/icediscovery/iox_find_service.cpp",
    "iceoryx_examples/icediscovery/iox_wait_for_service.cpp",
    "iceoryx_examples/iceoptions/iox_publisher_with_options.cpp",
    "iceoryx_examples/iceoptions/iox_subscriber_with_options.cpp",
    "iceoryx_examples/waitset/ice_waitset_individual.cpp",
    "iceoryx_examples/waitset/ice_waitset_gateway.cpp",
    "iceoryx_examples/waitset/ice_waitset_grouping.cpp",
    "iceoryx_examples/waitset/ice_waitset_timer_driven_execution.cpp",
    "iceoryx_examples/waitset/ice_waitset_publisher.cpp",
    "iceoryx_examples/waitset/ice_waitset_trigger.cpp",
    "iceoryx_examples/waitset/ice_waitset_basic.cpp",
    "iceoryx_examples/singleprocess/single_process.cpp",
    "iceoryx_examples/request_response/client_cxx_untyped.cpp",
    "iceoryx_examples/request_response/server_cxx_untyped.cpp",
    "iceoryx_examples/request_response/server_cxx_basic.cpp",
    "iceoryx_examples/request_response/client_cxx_waitset.cpp",
    "iceoryx_examples/request_response/client_cxx_basic.cpp",
    "iceoryx_examples/request_response/server_cxx_listener.cpp",
};

const tools_files: []const []const u8 = &.{
    "tools/introspection/source/iceoryx_introspection_app.cpp",
    "tools/introspection/source/introspection_app.cpp",
    "tools/introspection/source/introspection_main.cpp",
};

const docs_files: []const []const u8 = &.{
    "doc/aspice_swe3_4/example/iceoryx_component/source/example_module/example_base_class.cpp",
    "doc/aspice_swe3_4/example/iceoryx_component/test/moduletests/test_example_base_class.cpp",
    "doc/aspice_swe3_4/example/iceoryx_component/test/moduletests/test_component_modules.cpp",
};

const platform_linux_files: []const []const u8 = &.{
    "iceoryx_platform/linux/source/mman.cpp",
    "iceoryx_platform/linux/source/mqueue.cpp",
    "iceoryx_platform/linux/source/grp.cpp",
    "iceoryx_platform/linux/source/fnctl.cpp",
    "iceoryx_platform/linux/source/socket.cpp",
    "iceoryx_platform/linux/source/file.cpp",
    "iceoryx_platform/linux/source/unistd.cpp",
};

const platform_generic_files: []const []const u8 = &.{
    "iceoryx_platform/generic/source/acl_feature_on.cpp",
    "iceoryx_platform/generic/source/_string.cpp",
    "iceoryx_platform/generic/source/acl_feature_off.cpp",
    "iceoryx_platform/generic/source/logging.cpp",
    "iceoryx_platform/generic/source/stdlib.cpp",
};

const platform_test_files: []const []const u8 = &.{
    "iceoryx_platform/test/moduletests/main_test_platform_modules.cpp",
    "iceoryx_platform/test/moduletests/test_platform_string.cpp",
    "iceoryx_platform/test/moduletests/test_platform_atomic.cpp",
    "iceoryx_platform/test/moduletests/test_platform_stdlib.cpp",
    "iceoryx_platform/test/moduletests/test_platform_logging.cpp",
    "iceoryx_platform/test/integrationtests/main_test_platform_integration.cpp",
};

const binding_c_files: []const []const u8 = &.{
    "iceoryx_binding_c/source/c_wait_set.cpp",
    "iceoryx_binding_c/source/cpp2c_subscriber.cpp",
    "iceoryx_binding_c/source/c_user_trigger.cpp",
    "iceoryx_binding_c/source/c_request_header.cpp",
    "iceoryx_binding_c/source/c2cpp_enum_translation.cpp",
    "iceoryx_binding_c/source/cpp2c_publisher.cpp",
    "iceoryx_binding_c/source/cpp2c_enum_translation.cpp",
    "iceoryx_binding_c/source/c_client.cpp",
    "iceoryx_binding_c/source/c_server.cpp",
    "iceoryx_binding_c/source/c_chunk.cpp",
    "iceoryx_binding_c/source/cpp2c_service_description_translation.cpp",
    "iceoryx_binding_c/source/binding_c_error_reporting.cpp",
    "iceoryx_binding_c/source/c_log.cpp",
    "iceoryx_binding_c/source/c_response_header.cpp",
    "iceoryx_binding_c/source/c_publisher.cpp",
    "iceoryx_binding_c/source/c_notification_info.cpp",
    "iceoryx_binding_c/source/c_listener.cpp",
    "iceoryx_binding_c/source/c_subscriber.cpp",
    "iceoryx_binding_c/source/c_service_discovery.cpp",
    "iceoryx_binding_c/source/c_runtime.cpp",
    "iceoryx_binding_c/source/c_config.cpp",
};

const binding_c_test_files: []const []const u8 = &.{
    "iceoryx_binding_c/test/moduletests/test_log.cpp",
    "iceoryx_binding_c/test/moduletests/test_runtime.cpp",
    "iceoryx_binding_c/test/moduletests/test_publisher.cpp",
    "iceoryx_binding_c/test/moduletests/test_wait_set.cpp",
    "iceoryx_binding_c/test/moduletests/test_cpp2c_service_description_translation.cpp",
    "iceoryx_binding_c/test/moduletests/test_listener.cpp",
    "iceoryx_binding_c/test/moduletests/test_notification_info.cpp",
    "iceoryx_binding_c/test/moduletests/test_chunk.cpp",
    "iceoryx_binding_c/test/moduletests/test_config.cpp",
    "iceoryx_binding_c/test/moduletests/test_request_header.cpp",
    "iceoryx_binding_c/test/moduletests/test_user_trigger.cpp",
    "iceoryx_binding_c/test/moduletests/test_subscriber.cpp",
    "iceoryx_binding_c/test/moduletests/test_service_discovery.cpp",
    "iceoryx_binding_c/test/moduletests/test_server.cpp",
    "iceoryx_binding_c/test/moduletests/test_cpp2c_enum_translation.cpp",
    "iceoryx_binding_c/test/moduletests/test_service_description.cpp",
    "iceoryx_binding_c/test/moduletests/test_client.cpp",
    "iceoryx_binding_c/test/moduletests/test_c2cpp_enum_translation.cpp",
    "iceoryx_binding_c/test/moduletests/main_test_binding_c_modules.cpp",
    "iceoryx_binding_c/test/moduletests/test_response_header.cpp",
    "iceoryx_binding_c/test/integrationtests/main_test_binding_c_integration.cpp",
};

const posh_files: []const []const u8 = &.{
    "iceoryx_posh/source/posh_error_reporting.cpp",
    "iceoryx_posh/source/popo/client_options.cpp",
    "iceoryx_posh/source/popo/publisher_options.cpp",
    "iceoryx_posh/source/popo/subscriber_options.cpp",
    "iceoryx_posh/source/popo/trigger_handle.cpp",
    "iceoryx_posh/source/popo/listener.cpp",
    "iceoryx_posh/source/popo/notification_info.cpp",
    "iceoryx_posh/source/popo/building_blocks/condition_variable_data.cpp",
    "iceoryx_posh/source/popo/building_blocks/locking_policy.cpp",
    "iceoryx_posh/source/popo/building_blocks/condition_notifier.cpp",
    "iceoryx_posh/source/popo/building_blocks/condition_listener.cpp",
    "iceoryx_posh/source/popo/building_blocks/unique_port_id.cpp",
    "iceoryx_posh/source/popo/trigger.cpp",
    "iceoryx_posh/source/popo/ports/base_port_data.cpp",
    "iceoryx_posh/source/popo/ports/interface_port.cpp",
    "iceoryx_posh/source/popo/ports/client_port_user.cpp",
    "iceoryx_posh/source/popo/ports/client_port_data.cpp",
    "iceoryx_posh/source/popo/ports/server_port_user.cpp",
    "iceoryx_posh/source/popo/ports/subscriber_port_multi_producer.cpp",
    "iceoryx_posh/source/popo/ports/server_port_data.cpp",
    "iceoryx_posh/source/popo/ports/publisher_port_user.cpp",
    "iceoryx_posh/source/popo/ports/subscriber_port_user.cpp",
    "iceoryx_posh/source/popo/ports/client_port_roudi.cpp",
    "iceoryx_posh/source/popo/ports/base_port.cpp",
    "iceoryx_posh/source/popo/ports/interface_port_data.cpp",
    "iceoryx_posh/source/popo/ports/publisher_port_roudi.cpp",
    "iceoryx_posh/source/popo/ports/publisher_port_data.cpp",
    "iceoryx_posh/source/popo/ports/server_port_roudi.cpp",
    "iceoryx_posh/source/popo/ports/subscriber_port_single_producer.cpp",
    "iceoryx_posh/source/popo/ports/subscriber_port_roudi.cpp",
    "iceoryx_posh/source/popo/ports/subscriber_port_data.cpp",
    "iceoryx_posh/source/popo/server_options.cpp",
    "iceoryx_posh/source/popo/user_trigger.cpp",
    "iceoryx_posh/source/popo/rpc_header.cpp",
    "iceoryx_posh/source/roudi/service_registry.cpp",
    "iceoryx_posh/source/mepoo/mepoo_config.cpp",
    "iceoryx_posh/source/mepoo/mepoo_segment.cpp",
    "iceoryx_posh/source/mepoo/shared_chunk.cpp",
    "iceoryx_posh/source/mepoo/segment_manager.cpp",
    "iceoryx_posh/source/mepoo/segment_config.cpp",
    "iceoryx_posh/source/mepoo/memory_info.cpp",
    "iceoryx_posh/source/mepoo/chunk_settings.cpp",
    "iceoryx_posh/source/mepoo/chunk_management.cpp",
    "iceoryx_posh/source/mepoo/memory_manager.cpp",
    "iceoryx_posh/source/mepoo/chunk_header.cpp",
    "iceoryx_posh/source/mepoo/mem_pool.cpp",
    "iceoryx_posh/source/mepoo/shm_safe_unmanaged_chunk.cpp",
    "iceoryx_posh/source/runtime/ipc_runtime_interface.cpp",
    "iceoryx_posh/source/runtime/ipc_interface_creator.cpp",
    "iceoryx_posh/source/runtime/service_discovery.cpp",
    "iceoryx_posh/source/runtime/posh_runtime_single_process.cpp",
    "iceoryx_posh/source/runtime/posh_runtime.cpp",
    "iceoryx_posh/source/runtime/ipc_message.cpp",
    "iceoryx_posh/source/runtime/ipc_interface_user.cpp",
    "iceoryx_posh/source/runtime/ipc_interface_base.cpp",
    "iceoryx_posh/source/runtime/port_config_info.cpp",
    "iceoryx_posh/source/runtime/heartbeat.cpp",
    "iceoryx_posh/source/runtime/shared_memory_user.cpp",
    "iceoryx_posh/source/runtime/posh_runtime_impl.cpp",
    "iceoryx_posh/source/version/version_info.cpp",
    "iceoryx_posh/source/capro/service_description.cpp",
    "iceoryx_posh/source/capro/capro_message.cpp",
    "iceoryx_posh/source/iceoryx_posh_types.cpp",
    "iceoryx_posh/experimental/source/node.cpp",
    // iceoryx_posh_gateway
    "iceoryx_posh/source/gateway/gateway_base.cpp",
    // iceoryx_posh_roudi
    "iceoryx_posh/roudi_env/source/roudi_env.cpp",
    "iceoryx_posh/roudi_env/source/minimal_iceoryx_config.cpp",
    "iceoryx_posh/roudi_env/source/runtime_test_interface.cpp",
    "iceoryx_posh/roudi_env/source/roudi_env_node_builder.cpp",
    "iceoryx_posh/source/roudi/roudi_config.cpp",
    "iceoryx_posh/source/roudi/memory/memory_provider.cpp",
    "iceoryx_posh/source/roudi/memory/iceoryx_roudi_memory_manager.cpp",
    "iceoryx_posh/source/roudi/memory/default_roudi_memory.cpp",
    "iceoryx_posh/source/roudi/memory/mempool_collection_memory_block.cpp",
    "iceoryx_posh/source/roudi/memory/memory_block.cpp",
    "iceoryx_posh/source/roudi/memory/port_pool_memory_block.cpp",
    "iceoryx_posh/source/roudi/memory/mempool_segment_manager_memory_block.cpp",
    "iceoryx_posh/source/roudi/memory/roudi_memory_manager.cpp",
    "iceoryx_posh/source/roudi/memory/posix_shm_memory_provider.cpp",
    "iceoryx_posh/source/roudi/roudi_cmd_line_parser_config_file_option.cpp",
    "iceoryx_posh/source/roudi/port_pool.cpp",
    "iceoryx_posh/source/roudi/process_manager.cpp",
    "iceoryx_posh/source/roudi/iceoryx_roudi_components.cpp",
    "iceoryx_posh/source/roudi/roudi.cpp",
    "iceoryx_posh/source/roudi/port_manager.cpp",
    "iceoryx_posh/source/roudi/application/roudi_app.cpp",
    "iceoryx_posh/source/roudi/application/iceoryx_roudi_app.cpp",
    "iceoryx_posh/source/roudi/process.cpp",
    "iceoryx_posh/source/roudi/roudi_cmd_line_parser.cpp",
    // iceoryx_posh_config
    "iceoryx_posh/source/gateway/gateway_config.cpp",
    "iceoryx_posh/source/gateway/toml_gateway_config_parser.cpp",
    "iceoryx_posh/source/roudi/roudi_config_toml_file_provider.cpp",
};

const hoofs_files: []const []const u8 = &.{
    "iceoryx_hoofs/posix/time/source/deadline_timer.cpp",
    "iceoryx_hoofs/posix/time/source/adaptive_wait.cpp",
    "iceoryx_hoofs/posix/filesystem/source/posix_acl.cpp",
    "iceoryx_hoofs/posix/filesystem/source/file_lock.cpp",
    "iceoryx_hoofs/posix/filesystem/source/file.cpp",
    "iceoryx_hoofs/posix/design/source/file_management_interface.cpp",
    "iceoryx_hoofs/posix/vocabulary/source/user_name.cpp",
    "iceoryx_hoofs/posix/vocabulary/source/path.cpp",
    "iceoryx_hoofs/posix/vocabulary/source/group_name.cpp",
    "iceoryx_hoofs/posix/vocabulary/source/file_name.cpp",
    "iceoryx_hoofs/posix/vocabulary/source/file_path.cpp",
    "iceoryx_hoofs/posix/sync/source/unnamed_semaphore.cpp",
    "iceoryx_hoofs/posix/sync/source/mutex.cpp",
    "iceoryx_hoofs/posix/sync/source/signal_watcher.cpp",
    "iceoryx_hoofs/posix/sync/source/signal_handler.cpp",
    "iceoryx_hoofs/posix/sync/source/named_semaphore.cpp",
    "iceoryx_hoofs/posix/sync/source/semaphore_helper.cpp",
    "iceoryx_hoofs/posix/sync/source/thread.cpp",
    "iceoryx_hoofs/posix/ipc/source/named_pipe.cpp",
    "iceoryx_hoofs/posix/ipc/source/unix_domain_socket.cpp",
    "iceoryx_hoofs/posix/ipc/source/message_queue.cpp",
    "iceoryx_hoofs/posix/ipc/source/posix_shared_memory.cpp",
    "iceoryx_hoofs/posix/ipc/source/posix_memory_map.cpp",
    "iceoryx_hoofs/posix/ipc/source/posix_shared_memory_object.cpp",
    "iceoryx_hoofs/posix/utility/source/system_configuration.cpp",
    "iceoryx_hoofs/posix/utility/source/posix_scheduler.cpp",
    "iceoryx_hoofs/posix/auth/source/posix_user.cpp",
    "iceoryx_hoofs/posix/auth/source/posix_group.cpp",
    "iceoryx_hoofs/memory/source/bump_allocator.cpp",
    "iceoryx_hoofs/memory/source/memory.cpp",
    "iceoryx_hoofs/memory/source/relative_pointer_data.cpp",
    "iceoryx_hoofs/time/source/duration.cpp",
    "iceoryx_hoofs/filesystem/source/file_reader.cpp",
    "iceoryx_hoofs/filesystem/source/filesystem.cpp",
    "iceoryx_hoofs/reporting/source/console_logger.cpp",
    "iceoryx_hoofs/reporting/source/logger.cpp",
    "iceoryx_hoofs/reporting/source/default_error_handler.cpp",
    "iceoryx_hoofs/reporting/source/hoofs_error_reporting.cpp",
    "iceoryx_hoofs/reporting/source/logging.cpp",
    "iceoryx_hoofs/primitives/source/type_traits.cpp",
    "iceoryx_hoofs/concurrent/sync/source/spin_lock.cpp",
    "iceoryx_hoofs/concurrent/sync/source/spin_semaphore.cpp",
    "iceoryx_hoofs/concurrent/buffer/source/mpmc_loffli.cpp",
    "iceoryx_hoofs/cli/source/command_line_parser.cpp",
    "iceoryx_hoofs/cli/source/option.cpp",
    "iceoryx_hoofs/cli/source/option_manager.cpp",
    "iceoryx_hoofs/cli/source/arguments.cpp",
    "iceoryx_hoofs/cli/source/option_definition.cpp",
    "iceoryx_hoofs/utility/source/unique_id.cpp",
};

const all_include_dirs: []const []const u8 = &.{
    "tools/introspection/include",
    "iceoryx_platform/linux/include",
    "iceoryx_platform/generic/include",
    "iceoryx_binding_c/include",
    "iceoryx_posh/include",
    "iceoryx_posh/experimental/include",
    "iceoryx_posh/roudi_env/include",
    "iceoryx_posh/testing/include",
    "iceoryx_hoofs/posix/time/include",
    "iceoryx_hoofs/posix/filesystem/include",
    "iceoryx_hoofs/posix/design/include",
    "iceoryx_hoofs/posix/vocabulary/include",
    "iceoryx_hoofs/posix/sync/include",
    "iceoryx_hoofs/posix/ipc/include",
    "iceoryx_hoofs/posix/utility/include",
    "iceoryx_hoofs/posix/auth/include",
    "iceoryx_hoofs/memory/include",
    "iceoryx_hoofs/time/include",
    "iceoryx_hoofs/filesystem/include",
    "iceoryx_hoofs/design/include",
    "iceoryx_hoofs/reporting/include",
    "iceoryx_hoofs/vocabulary/include",
    "iceoryx_hoofs/primitives/include",
    "iceoryx_hoofs/concurrent/sync/include",
    "iceoryx_hoofs/concurrent/buffer/include",
    "iceoryx_hoofs/functional/include",
    "iceoryx_hoofs/buffer/include",
    "iceoryx_hoofs/container/include",
    "iceoryx_hoofs/cli/include",
    "iceoryx_hoofs/utility/include",
    "iceoryx_hoofs/testing/include",
    "iceoryx_hoofs/legacy/include",
    // "iceoryx_platform/win/include",
    // "iceoryx_platform/qnx/include",
    // "iceoryx_platform/freertos/include",
    // "iceoryx_platform/mac/include",
    // "doc/aspice_swe3_4/example/iceoryx_component/include",
    // "iceoryx_examples/icediscovery/include",
};
