export
  localhamiltonian,
  demoralizedlindbladian,
  makevertexset



"""

    defaultlocalhamiltonian(size)

Returns default local hamiltonian of size `size`×`size` for demoralization
procedure. The hamiltonian is sparse and the only nonzero values are on first
upperdiagonal equal to `1im` and lowerdiagonal equal to `-1im`. This is default
argument for `localhamiltonian` function.

# Examples

```jldoctest
julia> QSWalk.defaultlocalhamiltonian(4)
4×4 sparse matrix with 6 Complex{Float64} nonzero entries:
	[2, 1]  =  0.0-1.0im
	[1, 2]  =  0.0+1.0im
	[3, 2]  =  0.0-1.0im
	[2, 3]  =  0.0+1.0im
	[4, 3]  =  0.0-1.0im
	[3, 4]  =  0.0+1.0im

julia> full(QSWalk.defaultlocalhamiltonian(4))
4×4 Array{Complex{Float64},2}:
 0.0+0.0im  0.0+1.0im  0.0+0.0im  0.0+0.0im
 0.0-1.0im  0.0+0.0im  0.0+1.0im  0.0+0.0im
 0.0+0.0im  0.0-1.0im  0.0+0.0im  0.0+1.0im
 0.0+0.0im  0.0+0.0im  0.0-1.0im  0.0+0.0im

```
"""
function defaultlocalhamiltonian(size::Int)
  if size == 1
    return spzeros(Complex128,1,1)
  else
    spdiagm((im*ones(size-1),-im*ones(size-1)),(1,-1))
  end
end


"""

    localhamiltonian(vertexset[, hamiltoniansByDegree])
    localhamiltonian(vertexset, hamiltoniansByVertex)

Creates hamiltonian which works locally on each vertex from `vertexset` linear
subspace. Depending the form given, `hamiltoniansByDegree` is a dictionary
`Dict{Int,SparseDenseMatrix}`, which
for given dimension of vertex linear subspace yields some hermitian operator.
Only matrices for existing dimensions needs to be specified.
`hamiltoniansByVertex` is a dictionary `Dict{Vertex,SparseDenseMatrix}`, which
for given vertex yield hermitian operator of the size equal to the dimension of
subspace corresponding to the vertex.

`vertexset` should be generated by `demoralizedlindbladian` in order to match
demoralization procedure. Numerical analysis [1] suggests, that hamiltonians should
be complex valued.

It is expected, that for all vertcies from `vertexset` there exists corresponding
matrix in `hamiltoniansByVertex` or `hamiltoniansByDegree`.

[1] Domino, K., Glos, A., & Ostaszewski, M. (2017). Spontaneous moralization
problem in quantum stochastic walk. arXiv preprint arXiv:1701.04624.

# Examples

```jldoctest
julia> full(localhamiltonian(VertexSet([[1,2],[3,4]])))
4×4 Array{Complex{Float64},2}:
 0.0+0.0im  0.0+1.0im  0.0+0.0im  0.0+0.0im
 0.0-1.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im
 0.0+0.0im  0.0+0.0im  0.0-1.0im  0.0+0.0im

julia> A, B = rand(2,2), rand(2,2)
(
[0.218292 0.0335109; 0.855375 0.138592],

[0.643301 0.945834; 0.879102 0.669621])

julia> localhamiltonian(VertexSet([[1,2],[3,4]]), [A, B])
4×4 sparse matrix with 8 Complex{Float64} nonzero entries:
	[1, 1]  =  0.218292+0.0im
	[2, 1]  =  0.855375+0.0im
	[1, 2]  =  0.0335109+0.0im
	[2, 2]  =  0.138592+0.0im
	[3, 3]  =  0.643301+0.0im
	[4, 3]  =  0.879102+0.0im
	[3, 4]  =  0.945834+0.0im
	[4, 4]  =  0.669621+0.0im

julia> localhamiltonian(VertexSet([[1,2],[3,4]]), Dict(2 => [0 1; 1 0]))
4×4 sparse matrix with 4 Complex{Float64} nonzero entries:
	[2, 1]  =  1.0+0.0im
	[1, 2]  =  1.0+0.0im
	[4, 3]  =  1.0+0.0im
	[3, 4]  =  1.0+0.0im

```
"""
function localhamiltonian{T<:SparseDenseMatrix}(
                                  vertexset::VertexSet,
                                  hamiltonians::Dict{Int,T}
                                      =Dict(length(v)=>defaultlocalhamiltonian(length(v)) for v=vertexset()))
  hamiltonianlist = Dict{Vertex,SparseDenseMatrix}(v=>hamiltonians[length(v)] for v=vertexset())
  localhamiltonian(vertexset, hamiltonianlist)
end

function localhamiltonian{T<:SparseDenseMatrix}(vertexset::VertexSet,
                                                hamiltonians::Dict{Vertex,T})
  @assert length(vertexset) == length(hamiltonians) "The length of vertexset and hamiltonians should match"
  result = spzeros(Complex128,vertexsetsize(vertexset),vertexsetsize(vertexset))
  for vertex=vertexset()
    result[vertex(),vertex()] = hamiltonians[vertex]
  end
  result
end

"""

    incidencelist(A[; epsilon])

For given matrix `A` the function returns list of indices. The `i`-th element of
result list is the vector of indices for which `abs(A[j,i]) >= epsilon`.

# Examples

```jldoctest
julia> A = [1 2 3; 0 3. 4.; 0 0 5.]
3×3 Array{Float64,2}:
 1.0  2.0  3.0
 0.0  3.0  4.0
 0.0  0.0  5.0

julia> QSWalk.incidencelist(A)
3-element Array{Array{Int64,1},1}:
 [1]
 [1,2]
 [1,2,3]

julia> QSWalk.incidencelist(A, epsilon=2.5)
3-element Array{Array{Int64,1},1}:
  Int64[]
  [2]
  [1,2,3]


```
"""
function incidencelist{T<:Number}(A::SparseMatrixCSC{T}; epsilon::Real=eps())
  @argument epsilon >= 0 "epsilon needs to be nonnegative"
  [filter(x -> abs(A[x,i])>=epsilon, A[:,i].nzind) for i=1:size(A,1)]
end

function incidencelist{T<:Number}(A::Matrix{T}; epsilon::Real=eps())
  @argument epsilon >= 0 "epsilon needs to be nonnegative"
  [find(x -> abs(x)>=epsilon, A[:,i]) for i=1:size(A,1)]
end

"""

    reversedincidencelist(A[; epsilon])

For given matrix `A` the function returns list of indices. The `i`-th element of
result list is the vector of indices for which `abs(A[i,j]) >= epsilon`.

# Examples

```jldoctest
julia> A = [1 2 3; 0 3. 4.; 0 0 5.]
3×3 Array{Float64,2}:
 1.0  2.0  3.0
 0.0  3.0  4.0
 0.0  0.0  5.0

julia> QSWalk.reversedincidencelist(A)
3-element Array{Array{Int64,1},1}:
 [1,2,3]
 [2,3]
 [3]

julia> QSWalk.reversedincidencelist(A, epsilon=2.5)
3-element Array{Array{Int64,1},1}:
 [3]
 [2,3]
 [3]
```
"""
function reversedincidencelist{T<:Number}(A::SparseMatrixCSC{T}; epsilon::Real=eps())
  @argument epsilon >= 0 "epsilon needs to be nonnegative"
  [filter(x -> abs(A[i,x])>=epsilon, A[i,:].nzind) for i=1:size(A,1)]
end

function reversedincidencelist{T<:Number}(A::Matrix{T}; epsilon::Real=eps())
  @argument epsilon >= 0 "epsilon needs to be nonnegative"
  [find(x -> abs(x)>=epsilon, A[i,:]) for i=1:size(A,1)]
end

"""

    makevertexset(revincidencelist)

Return `vertexset` of type `VertexSet` corresponding to given incidende list. The function map
to consecutive element list orthogonal subspaces. The dimensions of the subspaces
equal to size of each element of revincidencelist. The exception is empty list,
for which onedimensional subspace is attached.

# Examples

```jldoctest
julia> vset = [Int64[],[2],[1,2,3]]
3-element Array{Array{Int64,1},1}:
 Int64[]
 [2]
 [1,2,3]

julia> QSWalk.makevertexset(vset)()
3-element Array{QSWalk.Vertex,1}:
 QSWalk.Vertex([1])
 QSWalk.Vertex([2])
 QSWalk.Vertex([3,4,5])

```
"""
function makevertexset(revincidencelist::Vector{Vector{Int}})
  vertexset = Vector{Int}[]
  start = 1
  for i=revincidencelist
    if length(i)!=0
      push!(vertexset, collect(start:(start+length(i)-1)))
      start+=length(i)
    else
      push!(vertexset, [start])
      start += 1
    end
  end
  VertexSet(vertexset)
end

"""

    fouriermatrix(size)

Returns Fourier matrix of size `size`×`size`.

# Examples

```jldoctest


```
"""
function fouriermatrix(size::Int)
  @argument size>0 "Size of the matrix needs to be positive"
  sparse([exp(2im*π*(i-1)*(j-1)/size) for i=1:size, j=1:size])
end


"""

    demoralizedlindbladian(A[, lindbladians][, epsilon])

The function returns single Lindbladian operator and vertex set describing
how vertices are bound to subspaces. The Lindbladian operator is constructed
according to corection scheme presented in [1]. `A` is square matrix, describing
the connection between the cannonical subspaces similar as adjacency matrix.
`epsilon` with default value `eps()` determines relevant values by
`abs(A[i,j]) >= epsilon` formula. `lindbladians` describes the elementary matrices
used (see [1]). It can be `Dict{Int,SparseDenseMatrix}`, which returns the matrix
by the indegree, or `Dict{Tuple{Vertex,Vertex}, SparseDenseMatrix}` which for
different pairs of vertices may return different matrices. As default the function
uses Fourier matrices.

It is expected, that for all pair of vertices there exists matrix in `lindbladians`.


 The orthogonality of matrices in `lindbladians` is not verified.

[1] Domino, K., Glos, A., & Ostaszewski, M. (2017). Spontaneous moralization
problem in quantum stochastic walk. arXiv preprint arXiv:1701.04624.


# Examples

```jldoctest
julia> A = [0 1 0; 1 0 1; 0 1 0]
3×3 Array{Int64,2}:
 0  1  0
 1  0  1
 0  1  0

julia> demoralizedlindbladian(A)
(

	[2, 1]  =  1.0+0.0im
	[3, 1]  =  1.0+0.0im
	[1, 2]  =  1.0+0.0im
	[4, 2]  =  1.0+0.0im
	[1, 3]  =  1.0+0.0im
	[4, 3]  =  1.0+0.0im
	[2, 4]  =  1.0+0.0im
	[3, 4]  =  -1.0+1.22465e-16im,

QSWalk.VertexSet(QSWalk.Vertex[QSWalk.Vertex([1]),QSWalk.Vertex([2,3]),QSWalk.Vertex([4])]))

```
"""

function demoralizedlindbladian{T<:Number,S<:SparseDenseMatrix}(
                                A::SparseDenseMatrix{T},
                                lindbladians::Dict{Int,S};
                                epsilon::Real=eps())
  revincidencelist = reversedincidencelist(A, epsilon=epsilon)
  vset = makevertexset(revincidencelist)


  L = spzeros(Complex128,vertexsetsize(vset),vertexsetsize(vset))
  for i=1:size(A,1), (index,j)=enumerate(revincidencelist[i]), k in vset[j]()
      L[vset[i](),k] = A[i,j]*lindbladians[length(vset[i])][:,index]
  end
  L, vset
end

function demoralizedlindbladian{T<:Number}(
                                A::SparseDenseMatrix{T};
                                epsilon::Real=eps())
  vset = makevertexset(reversedincidencelist(A, epsilon=epsilon))
  degrees = [length(v) for v=vset()]

  demoralizedlindbladian(A, Dict( d=>fouriermatrix(d) for d=degrees), epsilon=epsilon)
end

function demoralizedlindbladian{T<:Number,S<:SparseDenseMatrix}(
                                A::SparseDenseMatrix{T},
                                lindbladians::Dict{Tuple{Vertex,Vertex},S};
                                epsilon::Real=eps())
  revincidencelist = reversedincidencelist(A, epsilon)
  vset = makevertexset(revincidencelist)

  L = spzeros(Complex128,vertexsetsize(vset),vertexsetsize(vset))
  for i=1:size(A,1), (index,j)=enumerate(revincidencelist[i]), k in vset[j]()
      L[vset[i](),k] = A[i,j]*lindbladians[(vset[i],vset[j])][:,index]
  end
  L, vset
end
