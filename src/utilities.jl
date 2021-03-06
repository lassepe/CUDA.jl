"""
    @sync ex

Run expression `ex` and synchronize the GPU afterwards. This is a CPU-friendly
synchronization, i.e. it performs a blocking synchronization without increasing CPU load. As
such, this operation is preferred over implicit synchronization (e.g. when performing a
memory copy) for high-performance applications.

It is also useful for timing code that executes asynchronously.
"""
macro sync(ex)
    quote
        local e = CuEvent(EVENT_BLOCKING_SYNC | EVENT_DISABLE_TIMING)
        local ret = $(esc(ex))
        record(e)
        synchronize(e)
        ret
    end
end

function versioninfo(io::IO=stdout)
    println(io, "CUDA toolkit $(toolkit_version()), $(toolkit_origin()) installation")
    println(io, "CUDA driver $(release())")
    println(io)

    println(io, "Libraries: ")
    for lib in (:CUBLAS, :CURAND, :CUFFT, :CUSOLVER, :CUSPARSE)
        mod = getfield(CUDA, lib)
        println(io, "- $lib: ", mod.version())
    end
    println(io, "- CUTENSOR: ", has_cutensor() ? CUTENSOR.version() : "missing")
    println(io, "- CUDNN: ", has_cudnn() ? CUDNN.version() : "missing")
    println(io, "- CUPTI: ", has_cupti() ? CUPTI.version() : "missing")
    println(io)

    println(io, "Packages:")
    for mod in (CUDA, LLVM, GPUCompiler, GPUArrays, Adapt)
        if VERSION < v"1.4"
            name = string(mod)
            version = Pkg.installed()[name]
            println(io, "- $name.jl: $version")
        else
            id = Base.PkgId(mod)
            info = Pkg.dependencies()[id.uuid]
            println(io, "- $(info.name).jl: $(info.version)")
        end
    end
    println(io)

    println(io, "Toolchain:")
    println(io, "- Julia: $VERSION")
    println(io, "- LLVM: $(LLVM.version())")
    println(io, "- PTX ISA support: $(join(map(ver->"$(ver.major).$(ver.minor)", __ptx_support[]), ", "))")
    println(io, "- Device support: $(join(map(ver->"sm_$(ver.major)$(ver.minor)", __target_support[]), ", "))")
    println(io)

    env = filter(var->startswith(var, "JULIA_CUDA"), keys(ENV))
    if !isempty(env)
        println(io, "Environment:")
        for var in env
            println(io, "- $var: $(ENV[var])")
        end
        println()
    end

    devs = devices()
    println(io, length(devs), " device(s):")
    for dev in devs
        cap = capability(dev)
        device!(dev) do
            println(io, "- $(name(dev)) ($(Base.format_bytes(available_memory())), sm_$(cap.major)$(cap.minor))")
        end
    end
end
