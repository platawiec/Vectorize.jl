module VML

## Detect architecture - currently only OS X
AVX1 = false
AVX2 = false
AVX512 = false

# Check for AVX1.0
try
    result = readall(pipeline(`sysctl -a`, `grep machdep.cpu.features`, `grep AVX`))
    if match(r"AVX1.0", result) == Void
        error("No compatible VML architecture found - Vectorize supports AVX1.0, AVX2.0 and AVX512")
    else
        AVX1 = true
    end
catch
    # Unable to find AVX1
end

# Check for AVX2.0
try
    result = readall(pipeline(`sysctl -a`, `grep machdep.cpu.leaf7_features`, `grep AVX2`))
    if match(r"AVX2", result) == Void
        error("No compatible VML architecture found - Vectorize supports AVX1.0, AVX2.0 and AVX512")
    else
        AVX2 = true
    end
catch
    # Unable to find AVX2
end

# Check for AVX512
try
    result = readall(pipeline(`sysctl -a`, `grep machdep.cpu.leaf7_features`, `grep AVX512`))
    if match(r"AVX512", result) == Void
        error("No compatible VML architecture found - Vectorize supports AVX1.0, AVX2.0 and AVX512")
    else
        AVX512 = true
    end
catch
    #Unable to find AVX512
end

# Use the newest version of VML available
if AVX1
    const global libvml = Libdl.find_library(["libmkl_vml_avx"], ["/opt/intel/mkl/lib"])
elseif AVX2
    const global libvml = Libdl.find_library(["libmkl_vml_avx2"], ["/opt/intel/mkl/lib"])
elseif AVX512
    const global libvml = Libdl.find_library(["libmkl_vml_avx512"], ["/opt/intel/mkl/lib"])
end

# Library dependency for VML
const global librt = Libdl.find_library(["libmkl_rt"], ["/opt/intel/mkl/lib"])
Libdl.dlopen(librt)

# ======= VML FUNCTION ACCURACY CONTROL ======= #
const VML_LA               =  0x00000001     # Low Accuracy
const VML_HA               =  0x00000002     # High Accuracy
const VML_EP               =  0x00000003     # Enhanced Performance

# ======= VML ERROR HANDLING CONTROL ======= #
const VML_ERRMODE_IGNORE   =  0x00000100     # ignore errors
const VML_ERRMODE_ERRNO    =  0x00000200     # errno variable is set on error
const VML_ERRMODE_STDERR   =  0x00000400     # error description text is written to stderr
const VML_ERRMODE_EXCEPT   =  0x00000800     # exception is raised on error
const VML_ERRMODE_CALLBACK =  0x00001000     # user's error handler is called
# errno variable is set, exceptions are raised, and user's error handler is called on error
const VML_ERRMODE_DEFAULT  = VML_ERRMODE_ERRNO | VML_ERRMODE_CALLBACK | VML_ERRMODE_EXCEPT

# ======= FTZ & DAZ MODE CONTROL ======= #
const VML_FTZDAZ_ON        =  0x00280000     # faster denormal value processing
const VML_FTZDAZ_OFF       =  0x00140000     # accurate denormal value processing

"""
This function sets the default values for the VME library on import, 
allowing for the precompilation of the rest of the package. 
"""
function __init__()
    # VML default values
    VML.setmode(VML.VML_HA | VML.VML_ERRMODE_DEFAULT | VML.VML_FTZDAZ_ON)
end
"""
Sets accuracy, error, and FTZDAZ modes for all VML functions". This is automatically
called in init() but can also be called to change the modes during runtime". 
"""
function setmode(mode)
    ccall(("_vmlSetMode", libvml),  Cuint,
          (Cuint,),
          mode)
end

"""
Returns the accuracy, error, and FTZDAZ modes for all VML functions". This is automatically
called in init() but can also be called to change the modes during runtime". 
"""
function setmode(mode)
    status = ccall(("_vmlSetMode", libvml),  Cuint,
                   (Cuint,),
                   mode)
    return status
end

end # End Module
