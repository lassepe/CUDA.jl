# texture handling


#
# Texture format
#

function Base.convert(::Type{CUarray_format}, T::Type)
    if T === UInt8
        return CU_AD_FORMAT_UNSIGNED_INT8
    elseif T === UInt16
        return CU_AD_FORMAT_UNSIGNED_INT16
    elseif T === UInt32
        return CU_AD_FORMAT_UNSIGNED_INT32
    elseif T === Int8
        return CU_AD_FORMAT_SIGNED_INT8
    elseif T === Int16
        return CU_AD_FORMAT_SIGNED_INT16
    elseif T === Int32
        return CU_AD_FORMAT_SIGNED_INT32
    elseif T === Float16
        return CU_AD_FORMAT_HALF
    elseif T === Float32
        return CU_AD_FORMAT_FLOAT
    else
        throw(ArgumentError("CUDA does not support texture arrays for element type $T."))
    end
end

nchans(::Type{<:NTuple{C}}) where {C} = C
nchans(::Type) = 1



#
# Texture buffer
#

export CuTextureBuffer

"""
    CuTextureBuffer{T,N}(undef, dims)

`N`-dimensional dense texture array with elements of type `T`. These arrays are optimized
for texture fetching, and are only meant to be used as a source for [`CuTexture`](@ref)
objects.
"""
mutable struct CuTextureBuffer{T,N}
    handle::CUarray
    dims::Dims{N}

    ctx::CuContext

   @doc """
        CuTextureBuffer{T,N}(undef, dims)

    Construct an uninitialized texture array of `N` dimensions specified in the `dims`
    tuple, with elements of type `T`. Use `Base.copyto!` to initialize this texture array,
    or use constructors that take a non-texture array to do so automatically.
    """
    function CuTextureBuffer{T,N}(::UndefInitializer, dims::Dims{N}) where {T,N}
        format = convert(CUarray_format, eltype(T))

        if N == 2
            width, height = dims
            depth = 0
            @assert 1 <= width "CUDA 2D array (texture) width must be >= 1"
            # @assert witdh <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_WIDTH
            @assert 1 <= height "CUDA 2D array (texture) height must be >= 1"
            # @assert height <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_HEIGHT
        elseif N == 3
            width, height, depth = dims
            @assert 1 <= width "CUDA 3D array (texture) width must be >= 1"
            # @assert witdh <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_WIDTH
            @assert 1 <= height "CUDA 3D array (texture) height must be >= 1"
            # @assert height <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_HEIGHT
            @assert 1 <= depth "CUDA 3D array (texture) depth must be >= 1"
            # @assert depth <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_DEPTH
        elseif N == 1
            width = dims[1]
            height = depth = 0
            @assert 1 <= width "CUDA 1D array (texture) width must be >= 1"
            # @assert witdh <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_WIDTH
        else
            "CUDA arrays (texture memory) can only have 1, 2 or 3 dimensions"
        end

        allocateArray_ref = Ref(CUDA_ARRAY3D_DESCRIPTOR(
            width, # Width::Csize_t
            height, # Height::Csize_t
            depth, # Depth::Csize_t
            format, # Format::CUarray_format
            UInt32(nchans(T)), # NumChannels::UInt32
            0))

        handle_ref = Ref{CUarray}()
        cuArray3DCreate(handle_ref, allocateArray_ref)

        t = new{T,N}(handle_ref[], dims, context())
        finalizer(unsafe_destroy!, t)
        return t
    end
end

function unsafe_destroy!(t::CuTextureBuffer)
    if isvalid(t.ctx)
        cuArrayDestroy(t)
    end
end

Base.unsafe_convert(::Type{CUarray}, t::CuTextureBuffer) = t.handle


## array interface

Base.size(tm::CuTextureBuffer) = tm.dims
Base.length(tm::CuTextureBuffer) = prod(size(tm))

Base.eltype(tm::CuTextureBuffer{T,N}) where {T,N} = T

Base.sizeof(tm::CuTextureBuffer) = sizeof(eltype(tm)) * length(tm)


## interop with other arrays

"""
    CuTextureBuffer(A::AbstractArray)

Allocate and initialize a texture buffer from host memory in `A`.
"""
@inline function CuTextureBuffer{T,N}(xs::AbstractArray{<:Any,N}) where {T,N}
  A = CuTextureBuffer{T,N}(undef, size(xs))
  copyto!(A, convert(Array{T}, xs))
  return A
end

"""
    CuTextureBuffer(A::CuArray)

Allocate and initialize a texture buffer from device memory in `A`.
"""
@inline function CuTextureBuffer{T,N}(xs::CuArray{<:Any,N}) where {T,N}
  A = CuTextureBuffer{T,N}(undef, size(xs))
  copyto!(A, convert(CuArray{T}, xs))
  return A
end

# idempotency
CuTextureBuffer{T,N}(xs::CuTextureBuffer{T,N}) where {T,N} = xs

CuTextureBuffer(A::AbstractArray{T,N}) where {T,N} = CuTextureBuffer{T,N}(A)


## memory operations

function Base.copyto!(dst::CuTextureBuffer{T,1}, src::Array{T,1}) where {T}
    size(dst) == size(src) || throw(DimensionMismatch("source and destination sizes must match"))
    cuMemcpyHtoA(dst, 0, src, sizeof(dst))
    return dst
end

function Base.copyto!(dst::CuTextureBuffer{T,1}, src::CuArray{T,1}) where {T}
    size(dst) == size(src) || throw(DimensionMismatch("source and destination sizes must match"))
    cuMemcpyDtoA(dst, 0, src, sizeof(dst))
    return dst
end

function Base.copyto!(dst::CuTextureBuffer{T,2}, src::Union{Array{T,2}, CuArray{T,2}}) where {T}
    size(dst) == size(src) || throw(DimensionMismatch("source and destination sizes must match"))
    isdevmem = isa(src, CuArray)
    copy_ref = Ref(CUDA_MEMCPY2D(
        0, # srcXInBytes::Csize_t
        0, # srcY::Csize_t
        isdevmem ? CU_MEMORYTYPE_DEVICE : CU_MEMORYTYPE_HOST, # srcMemoryType::CUmemorytype
        isdevmem ? 0 : pointer(src), # srcHost::Ptr{Cvoid}
        isdevmem ? pointer(src) : 0, # srcDevice::CUdeviceptr
        0, # srcArray::CUarray
        0, # srcPitch::Csize_t ### TODO: check why this cannot be `size(src.dims, 1) * sizeof(T)` as it should
        0, # dstXInBytes::Csize_t
        0, # dstY::Csize_t
        CU_MEMORYTYPE_ARRAY, # dstMemoryType::CUmemorytype
        0, # dstHost::Ptr{Cvoid}
        0, # dstDevice::CUdeviceptr
        dst.handle, # dstArray::CUarray
        0, # dstPitch::Csize_t
        dst.dims[1] * sizeof(eltype(dst)), # WidthInBytes::Csize_t
        dst.dims[2], # Height::Csize_t
    ))
    cuMemcpy2D(copy_ref)
    return dst
end

function Base.copyto!(dst::CuTextureBuffer{T,3}, src::Union{Array{T,3}, CuArray{T,3}}) where {T}
    size(dst) == size(src) || throw(DimensionMismatch("source and destination sizes must match"))
    isdevmem = isa(src, CuArray)
    copy_ref = Ref(CUDA_MEMCPY3D(0, # srcXInBytes::Csize_t
        0, # srcY::Csize_t
        0, # srcZ::Csize_t
        0, # srcLOD::Csize_t
        isdevmem ? CU_MEMORYTYPE_DEVICE : CU_MEMORYTYPE_HOST, # srcMemoryType::CUmemorytype
        isdevmem ? 0 : pointer(src), # srcHost::Ptr{Cvoid}
        isdevmem ? pointer(src) : 0, # srcDevice::CUdeviceptr
        0, # srcArray::CUarray
        0, # reserved0::Ptr{Cvoid}
        size(src, 1) * sizeof(eltype(dst)), # srcPitch::Csize_t
        size(src, 2), # srcHeight::Csize_t
        0, # dstXInBytes::Csize_t
        0, # dstY::Csize_t
        0, # dstZ::Csize_t
        0, # dstLOD::Csize_t
        CU_MEMORYTYPE_ARRAY, # dstMemoryType::CUmemorytype
        0, # dstHost::Ptr{Cvoid}
        0, # dstDevice::CUdeviceptr
        dst.handle, # dstArray::CUarray
        0, # reserved1::Ptr{Cvoid}
        0, # dstPitch::Csize_t
        0, # dstHeight::Csize_t
        dst.dims[1] * sizeof(eltype(dst)), # WidthInBytes::Csize_t
        dst.dims[2], # Height::Csize_t
        dst.dims[3], # Depth::Csize_t
    ))
    cuMemcpy3D(copy_ref)
    return dst
end



#
# Texture objects
#

export CuTexture

@enum_without_prefix CUaddress_mode CU_TR_

@enum_without_prefix CUfilter_mode CU_TR_

"""
    CuTexture{T,N,P}

`N`-dimensional texture object with elements of type `T`. These objects do not store data
themselves, but are bounds to another source of device memory. Texture objects can be passed
to CUDA kernels, where they will be accessible through the [`CuDeviceTexture`](@ref) type.
"""
mutable struct CuTexture{T,N,P} <: AbstractArray{T,N}
    parent::P
    handle::CUtexObject

    normalized_coordinates::Bool

    ctx::CuContext

    @doc """
        CuTexture{T,N,P}(parent::P; address_mode, filter_mode, normalized_coordinates)

    Construct a `N`-dimensional texture object with elements of type `T` as stored in
    `parent`.

    Several keyword arguments alter the behavior of texture objects:
    - `address_mode` (wrap, *clamp*, mirror): how out-of-bounds values are accessed. Can be
      specified as a value for all dimensions, or as a tuple of `N` entries.
    - `filter_mode` (*point*, linear): how non-integral indices are fetched. Point mode
      fetches a single value, linear results in linear interpolation between values.
    - `normalized_coordinates` (true, *false*): whether indices are expected to fall in the
      normalized `[0:1)` range.
    """
    function CuTexture{T,N,P}(parent::P;
                              address_mode::Union{CUaddress_mode,NTuple{N,CUaddress_mode}}=ntuple(_->ADDRESS_MODE_CLAMP,N),
                              filter_mode::CUfilter_mode=FILTER_MODE_POINT,
                              normalized_coordinates::Bool=false) where {T,N,P}
        resDesc_ref = CUDA_RESOURCE_DESC(parent)

        flags = 0x0
        if normalized_coordinates
            flags |= CU_TRSF_NORMALIZED_COORDINATES
        end
        if eltype(T) <: Integer
            flags |= CU_TRSF_READ_AS_INTEGER
        end

        # we always need 3 address modes
        address_mode = tuple(address_mode..., ntuple(_->ADDRESS_MODE_CLAMP, 3 - N)...)

        texDesc_ref = Ref(CUDA_TEXTURE_DESC(
            address_mode, # addressMode::NTuple{3, CUaddress_mode}
            filter_mode, # filterMode::CUfilter_mode
            flags, # flags::UInt32
            1, # maxAnisotropy::UInt32
            filter_mode, # mipmapFilterMode::CUfilter_mode
            0, # mipmapLevelBias::Cfloat
            0, # minMipmapLevelClamp::Cfloat
            0, # maxMipmapLevelClamp::Cfloat
            ntuple(_->Cfloat(zero(eltype(T))), 4), # borderColor::NTuple{4, Cfloat}
            ntuple(_->Cint(0), 12)))

        texObject_ref = Ref{CUtexObject}(0)
        cuTexObjectCreate(texObject_ref, resDesc_ref, texDesc_ref, C_NULL)

        t = new{T,N,P}(parent, texObject_ref[], normalized_coordinates, context())
        finalizer(unsafe_destroy!, t)
        return t
    end
end

function CUDA_RESOURCE_DESC(texarr::CuTextureBuffer)
    # FIXME: manual construction due to invalid padding (JuliaInterop/Clang.jl#238)
    # res = Ref{ANONYMOUS1_res}()
    # unsafe_store!(Ptr{CUarray}(pointer_from_objref(res)), texarr.handle)
    # resDesc_ref = Ref(CUDA_RESOURCE_DESC(
    #     CU_RESOURCE_TYPE_ARRAY, # resType::CUresourcetype
    #     res[], # res::ANONYMOUS1_res
    #     0 # flags::UInt32
    # ))
    resDesc_ref = Ref((CU_RESOURCE_TYPE_ARRAY, # resType::CUresourcetype
                       texarr.handle, # 1 x UInt64
                       ntuple(_->Int64(0), 15), # 15 x UInt64
                       UInt32(0)))
    return resDesc_ref
end

# allow passing mismatching refs where we're expecting a CUDA_RESOURCE_DESC
Base.unsafe_convert(::Type{Ptr{CUDA_RESOURCE_DESC}}, ref::Base.RefValue{T}) where {T} =
    convert(Ptr{CUDA_RESOURCE_DESC}, Base.unsafe_convert(Ptr{T}, ref))

function CUDA_RESOURCE_DESC(arr::CuArray{T,N}) where {T,N}
    # TODO: take care of allowed pitches
    1 <= N <= 2 || throw(ArgumentError("Only 1 or 2D CuArray objects can be wrapped in a texture"))

    format = convert(CUarray_format, eltype(T))
    channels = nchans(T)

    # FIXME: manual construction due to invalid padding (JuliaInterop/Clang.jl#238)
    resDesc_ref = Ref(((N == 1 ? CU_RESOURCE_TYPE_LINEAR : CU_RESOURCE_TYPE_PITCH2D), # resType::CUresourcetype
                       pointer(arr), # 1 x UInt64 (CUdeviceptr)
                       format, # 1/2 x UInt64 (CUarray_format)
                       UInt32(channels), # 1/2 x UInt64
                       (N == 2 ? size(arr, 1) : size(arr, 1) * sizeof(T)), # 1 x UInt64 nx
                       (N == 2 ? size(arr, 2) : 0), # 1 x UInt64 ny
                       (N == 2 ? size(arr, 1) * sizeof(T) : 0), # 1 x UInt64 pitch
                       ntuple(_->Int64(0), 11), # 11 x UInt64
                       UInt32(0)))
    return resDesc_ref
end

function unsafe_destroy!(t::CuTexture)
    if isvalid(t.ctx)
        cuTexObjectDestroy(t)
    end
end

Base.convert(::Type{CUtexObject}, t::CuTexture) = t.handle

Base.parent(tm::CuTexture) = tm.parent


## array interface

Base.size(tm::CuTexture) = size(tm.parent)
Base.sizeof(tm::CuTexture) = Base.elsize(x) * length(x)

Base.show(io::IO, t::CuTexture{T,1} where {T}) =
    print(io, "$(length(a))-element $(nchans(T))-channel CuTexture(::$(typeof(parent(t)).name)) with eltype $T")
Base.show(io::IO, t::CuTexture{T}) where {T} =
    print(io, "$(join(size(t), '×')) $(nchans(T))-channel CuTexture(::$(typeof(parent(t)).name)) with eltype $T")

Base.show(io::IO, mime::MIME"text/plain", a::CuTexture) = show(io, a)


## interop with other arrays

CuTexture{T,N}(A::Union{CuTextureBuffer{T,N},CuArray{T,N}}; kwargs...) where {T,N} =
    CuTexture{T,N,typeof(A)}(A; kwargs...)

"""
    CuTexture(x::CuTextureBuffer{T,N})

Create a `N`-dimensional texture object withelements of type `T` that will be read from `x`.
"""
CuTexture(x::CuTextureBuffer{T,N}; kwargs...) where {T,N} =
    CuTexture{T,N}(x; kwargs...)

"""
    CuTexture(x::CuArray{T,N})

Create a `N`-dimensional texture object that reads from a `CuArray`.

Note that it is necessary the their memory is well aligned and strided (good pitch).
Currently, that is not being enforced.
"""
CuTexture(x::CuArray{T,N}; kwargs...) where {T,N} =
    CuTexture{T,N}(x; kwargs...)

Adapt.adapt_storage(::Adaptor, t::CuTexture{T,N}) where {T,N} =
    CuDeviceTexture{T,N,t.normalized_coordinates}(size(t), t.handle)
