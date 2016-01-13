########################################################################
# Installation stuff - create & export config files
#
# The build tree uses the folder manage/CMakeModules directly, but the
# installed OpenCMISS wont necessarily have the manage folder and needs to
# be self-contained

function(messaged MSG)
    #message(STATUS "OCInstall: ${MSG}")
endfunction()

###########################################################################################
# Helper functions

# Transforms a given list named VARNAME of paths.
# At first determines the relative path to RELATIVE_TO_DIR and then prefixes
# a variable named IMPORT_PREFIX_VARNAME to it, so that use of that list
# will have dynamically computed prefixes.
function(relativizePathList VARNAME RELATIVE_TO_DIR IMPORT_PREFIX_VARNAME)
    set(REL_LIST )
    foreach(path ${${VARNAME}})
        get_filename_component(path_abs "${path}" ABSOLUTE)
        messaged("Relativizing\n${path}\nto\n${RELATIVE_TO_DIR}")
        file(RELATIVE_PATH RELPATH "${RELATIVE_TO_DIR}" "${path_abs}")
        #getRelativePath("${path_abs}" "${RELATIVE_TO_DIR}" RELPATH)
        list(APPEND REL_LIST "\${${IMPORT_PREFIX_VARNAME}}/${RELPATH}")
    endforeach()
    set(${VARNAME} ${REL_LIST} PARENT_SCOPE)
endfunction()

function(do_export CFILE VARS)
    message(STATUS "Exporting OpenCMISS build context: ${CFILE}")
    file(WRITE ${CFILE} "#Exported OpenCMISS configuration\r\n")
    file(APPEND ${CFILE} "#DO NOT EDIT THIS FILE. ITS GENERATED BY THE OPENCMISS BUILD ENVIRONMENT\r\n")
    file(APPEND ${CFILE} "get_filename_component(_OPENCMISS_CONTEXT_IMPORT_PREFIX \"\${CMAKE_CURRENT_LIST_FILE}\" DIRECTORY)\r\n")
    foreach(VARNAME ${VARS})
        if (DEFINED ${VARNAME})
            file(APPEND ${CFILE} "set(${VARNAME} ${${VARNAME}})\r\n")
        endif()    
    endforeach()
endfunction()

###########################################################################################
# Create context.cmake in arch-path dir

# Create a copy to not destroy the original (its being used somewhere later maybe)
set(OPENCMISS_PREFIX_PATH_IMPORT ${OPENCMISS_PREFIX_PATH})
relativizePathList(OPENCMISS_PREFIX_PATH_IMPORT "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}" _OPENCMISS_CONTEXT_IMPORT_PREFIX)
set(OPENCMISS_LIBRARY_PATH_IMPORT ${OPENCMISS_LIBRARY_PATH})
relativizePathList(OPENCMISS_LIBRARY_PATH_IMPORT "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}" _OPENCMISS_CONTEXT_IMPORT_PREFIX)

# Introduce prefixed variants of the MPI variables - enables to check against them
set(OPENCMISS_MPI ${MPI})
set(OPENCMISS_MPI_HOME "${MPI_HOME}")
set(OPENCMISS_MPI_VERSION "${MPI_VERSION}")
set(EXPORT_VARS
    OPENCMISS_PREFIX_PATH_IMPORT
    OPENCMISS_LIBRARY_PATH_IMPORT
    OPENCMISS_MPI
    OPENCMISS_MPI_HOME
    MPI_VERSION
    BLA_VENDOR
    #FORTRAN_MANGLING
)

# Add the build type if on single-config platform
if (DEFINED CMAKE_BUILD_TYPE AND NOT "" STREQUAL CMAKE_BUILD_TYPE)
    set(OPENCMISS_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    list(APPEND EXPORT_VARS OPENCMISS_BUILD_TYPE)
endif()

# Export component info
foreach(COMPONENT ${OPENCMISS_COMPONENTS})
    list(APPEND EXPORT_VARS OC_USE_${COMPONENT} OC_SYSTEM_${COMPONENT})
    if (${COMPONENT}_VERSION)
        list(APPEND EXPORT_VARS ${COMPONENT}_VERSION)
    endif()
endforeach()

set(OPENCMISS_CONTEXT ${CMAKE_CURRENT_BINARY_DIR}/export/context.cmake)
do_export(${OPENCMISS_CONTEXT} "${EXPORT_VARS}")

# Install it
install(
    FILES ${OPENCMISS_CONTEXT}
    DESTINATION ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}
)
unset(EXPORT_VARS)

###########################################################################################
# Create opencmiss-config.cmake

set(OPENCMISS_MODULE_PATH_EXPORT
    ${OPENCMISS_FINDMODULE_WRAPPER_DIR}
    ${OPENCMISS_INSTALL_ROOT}/cmake/OpenCMISSExtraFindModules
    ${OPENCMISS_INSTALL_ROOT}/cmake)
relativizePathList(OPENCMISS_MODULE_PATH_EXPORT "${OPENCMISS_INSTALL_ROOT}" _OPENCMISS_IMPORT_PREFIX)

if (OC_DEVELOPER AND NOT OC_INSTALL_SUPPORT_EMAIL)
    message(WARNING "Dear developer! Please set the OC_INSTALL_SUPPORT_EMAIL variable in OpenCMISSDeveloper.cmake "
                    "to your eMail address so that people using your installation can contact you for support. Thanks!")
endif()
# Check if there are defaults - otherwise use the current build's settings
if (NOT OC_DEFAULT_MPI)
    set(OC_DEFAULT_MPI ${MPI})
endif()
if (NOT OC_DEFAULT_MPI_BUILD_TYPE)
    set(OC_DEFAULT_MPI_BUILD_TYPE ${MPI_BUILD_TYPE})
endif()

# There's litte to configure yet, but could become more
configure_file(${OPENCMISS_MANAGE_DIR}/Templates/opencmiss-config.cmake
 ${CMAKE_CURRENT_BINARY_DIR}/export/opencmiss-config.cmake @ONLY
)
# Version file
include(CMakePackageConfigHelpers)
WRITE_BASIC_PACKAGE_VERSION_FILE(
    ${CMAKE_CURRENT_BINARY_DIR}/export/opencmiss-config-version.cmake
    COMPATIBILITY AnyNewerVersion
)
install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/export/opencmiss-config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/export/opencmiss-config-version.cmake
    DESTINATION ${OPENCMISS_INSTALL_ROOT}
)

# Copy the FindModule files so that the installation folder is self-contained
install(DIRECTORY ${OPENCMISS_MANAGE_DIR}/CMakeModules/
    DESTINATION ${OPENCMISS_INSTALL_ROOT}/cmake/OpenCMISSExtraFindModules
    PATTERN "FindOpenCMISS*.cmake" EXCLUDE) 
install(FILES ${OPENCMISS_MANAGE_DIR}/CMakeScripts/OCArchitecturePath.cmake
    ${OPENCMISS_MANAGE_DIR}/CMakeScripts/OCToolchainCompilers.cmake
    DESTINATION ${OPENCMISS_INSTALL_ROOT}/cmake)
    
# Install mingw libraries if we built with mingw
if (MINGW AND WIN32)
    get_filename_component(COMPILER_BIN_DIR ${CMAKE_C_COMPILER} PATH)
    file(GLOB MINGW_DLLS "${COMPILER_BIN_DIR}/*.dll")
    install(FILES ${MINGW_DLLS}
        DESTINATION ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}/lib)
endif()
    