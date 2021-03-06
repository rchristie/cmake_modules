# In this file the (possibly) set compiler mnemonics are used to specify default compilers.
macro(setCMakeCompilersForToolchain TOOLCHAIN)
	if (NOT "${TOOLCHAIN}" STREQUAL "")
		message(STATUS "Attempting to use ${TOOLCHAIN} compilers.")
		STRING(TOLOWER "${TOOLCHAIN}" TOOLCHAIN)
		if (TOOLCHAIN STREQUAL "gnu" OR TOOLCHAIN STREQUAL "mingw")
			SET(CMAKE_C_COMPILER gcc)
			SET(CMAKE_CXX_COMPILER g++)
			SET(CMAKE_Fortran_COMPILER gfortran)
		
		elseif (TOOLCHAIN STREQUAL "clang")
			SET(CMAKE_C_COMPILER clang)
			SET(CMAKE_CXX_COMPILER clang++)
			SET(CMAKE_Fortran_COMPILER gfortran)
			
		elseif (TOOLCHAIN STREQUAL "intel")
			set(CMAKE_CXX_STANDARD 11)
			SET(CMAKE_C_COMPILER icc)
			SET(CMAKE_CXX_COMPILER icpc)
			SET(CMAKE_Fortran_COMPILER ifort)
		elseif (TOOLCHAIN STREQUAL "ibm")
			if (OC_MULTITHREADING)
				SET(CMAKE_C_COMPILER xlc_r)
				SET(CMAKE_CXX_COMPILER xlC_r)
				# F77=xlf77_r
				SET(CMAKE_Fortran_COMPILER xlf95_r)
			else ()
				SET(CMAKE_C_COMPILER xlc)
				SET(CMAKE_CXX_COMPILER xlC)
				# F77=xlf77
				SET(CMAKE_Fortran_COMPILER xlf95)
			endif ()
		elseif (TOOLCHAIN STREQUAL "msvc")
			SET(CMAKE_C_COMPILER cl.exe)
			SET(CMAKE_CXX_COMPILER cl.exe)
			SET(CMAKE_Fortran_COMPILER ifort.exe)
		else ()
			message(WARNING "Unknown toolchain: ${TOOLCHAIN}. Proceeding with CMake default compilers.")
		endif ()
	else ()
		message(STATUS "No toolchain specified. Proceeding with CMake default compilers.")
	endif ()
endmacro()

function(getToolchain VARNAME)

    if (MINGW)
        set(_TOOLCHAIN "mingw" )
    elseif (MSYS )
        set(_TOOLCHAIN "msys" )
    elseif (BORLAND )
        set(_TOOLCHAIN "borland" )
    elseif (WATCOM )
        set(_TOOLCHAIN "watcom" )
    elseif (MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90 )
        set(_TOOLCHAIN "msvc" )
    elseif (CMAKE_COMPILER_IS_GNUCC)
        set(_TOOLCHAIN "gnu")
    elseif (CMAKE_C_COMPILER_ID MATCHES Clang)
        set(_TOOLCHAIN "clang")
    elseif (CMAKE_C_COMPILER_ID MATCHES Intel 
       OR CMAKE_CXX_COMPILER_ID MATCHES Intel)
        set(_TOOLCHAIN "intel")
    elseif (CMAKE_C_COMPILER_ID MATCHES PGI)
        set(_TOOLCHAIN "pgi")
    elseif ( CYGWIN )
        set(_TOOLCHAIN "cygwin")
    else ()
        set(_TOOLCHAIN "unknown")       
    endif ()
     

    set(${VARNAME} ${_TOOLCHAIN} PARENT_SCOPE)
endfunction()
