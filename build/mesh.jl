"""
Overview: structures and functions associated to mesh
import and management. 
"""

"""
> mutable struct Domain
- Sen : number of supported elements
- Set : type of supported elements
- Senn : number of nodes of the supported elements
- ne : number of elements of each type in the domain
- e2n : volume element connectivity
- mat : material associated to the domain
"""
mutable struct Domain
  #
  Sen::Int64
  Set::Vector{Symbol}
  Senn::Vector{Int64}
  eskip::Vector{Int64}
  ne::Vector{Int64}
  e2n::Vector{Int64}
  mat::material
  #
  Domain() = new()
end

"""
> mutable struct Boundary
- Sen : number of supported elements
- Set : type of supported elements
- Senn : number of nodes of the supported elements
- ne : number of elements of each type in the domain
- e2n : surface element connectivity
- bcdofs : which dofs are constrained
- bcvals : value associated to the boundary condition
"""
mutable struct Boundary
  #
  Sen::Int64
  Set::Vector{Symbol}
  Senn::Vector{Int64}
  eskip::Vector{Int64}
  ne::Vector{Int64}
  e2n::Vector{Int64}
  bcdofs::Vector{Int64}
  bcvals::Vector{Float64}
  #
  Boundary() = new()
  #
end


"""
> mutable struct grid
- netype : number of supperted types of elements
- etype : array that stores the number of nodes for each element
- nn : number of nodes
- nΩ : number of domains
- nΓ : number of boundaries
- n2c : nodes coordinates
- Ω : domains
- Γ : boundaries
- tcn : total cells number
- grid() : empty initialization method
"""
mutable struct Grid
  #
  nn::Int64
  nΩ::Int64
  nΓ::Int64
  #
  n2c::Vector{Float64}
  Ω::Vector{Domain}
  Γ::Vector{Boundary}
  #
  tcn::Int64
  tnn::Int64
  #
  Grid() = new()
  #
end


"""
> read_mesh( mesh_file::String, Ω_list::Vector{Vector{Int64}}, Γ_list::Vector{Vector{Int64}}, mat::Vector{material}, bc_dof::Vector{Vector{Int64}}, bc_vals::Vector{Vector{Float64}})
It reads the mesh file and it inializes the grid data structure
- mesh_file : name of the mesh file to read
- Ω_list : list of domains in which the structures is organised
- Γ_list : list of boundaries
- mat : list of materials associated to each domain
- bc_dof : list of constrained degrees of freedom of each boundary
- bc_vals : boundary condition values
"""
function read_mesh(mesh_file::String, Ω_list,
                   Γ_list, mat::Vector{String}, 
                   bc_dof::Vector{Vector{Int64}}, bc_vals::Vector{Vector{Float64}})
  mesh = Grid()
  if contains(mesh_file,".med")
    import_mesh!(mesh,mesh_file,Ω_list,Γ_list,mat,bc_dof,bc_vals,Val{:MED})
  elseif contains(mesh_file,".mphtxt")
    import_mesh!(mesh,mesh_file,Ω_list,Γ_list,mat,bc_dof,bc_vals,Val{:MPHTXT})
  else
    println("Mesh format not supported.")
  end
  return mesh
end

"""
> get_coor!(mesh::Grid, conn::Vector{Int64}, X::Vector{Float64}, nn::Int64)
it retrieves element nodes coordinates. 
- mesh : Grid 
- conn : connectivity of the element
- X : coordinates of the nodes in {x₁, y₁, z₁, ..., xₙ, yₙ, zₙ} format
- nn : number of nodes
"""
function get_coor!(mesh::Grid, conn::Vector{Int64}, X::Vector{Float64}, nn::Int64)
  #
  @inbounds for i = 1:nn
    X[1+(i-1)*dim:i*dim] = mesh.n2c[1+(conn[i]-1)*dim:conn[i]*dim]
  end
  #
  return nothing
end





"""
> get_coor!(mesh::Grid, conn::SubArray{Int64, 1, Vector{Int64}, Tuple{UnitRange{Int64}}, true}, X::Vector{Float64}, nn::Int64)
it retrieves element nodes coordinates. 
- mesh : Grid 
- conn : connectivity of the element
- X : coordinates of the nodes in {x₁, y₁, z₁, ..., xₙ, yₙ, zₙ} format
- nn : number of nodes
"""
function get_coor!(mesh::Grid, conn::SubArray{Int64, 1, Vector{Int64}, Tuple{UnitRange{Int64}}, true},
                   X::Vector{Float64}, nn::Int64)
  #
  @inbounds for i = 1:nn
    X[1+(i-1)*dim:i*dim] = mesh.n2c[1+(conn[i]-1)*dim:conn[i]*dim]
  end
  #
  return nothing
end



function import_mesh!(mesh::Grid, mesh_file::String, 
                      Ω_list, 
                      Γ_list, 
                      mat::Vector{String}, bc_dof::Vector{Vector{Int64}}, 
                      bc_vals::Vector{Vector{Float64}}, ::Type{Val{:MPHTXT}})
  #
  # it instantiates a mesh_type structure from a COMSOL .mphtxt file
  #
  local neT6,e2nT6,e2gT6
  local neQ9,e2nQ9,e2gQ9
  local neT10,e2nT10,e2gT10
  local neP18,e2nP18,e2gP18
  local neH27,e2nH27,e2gH27
  #
  fname = "./mesh/"*mesh_file
  # extract mesh infos
  open(fname,"r") do fhand
    while !eof(fhand)
      line = readline(fhand)
      if (contains(line,"# number of mesh vertices"))
        line = split(line)
        mesh.nn = Meta.parse(line[1])
        mesh.n2c = Vector{Float64}(undef,mesh.nn*dim)
      elseif (contains(line,"# Mesh vertex coordinates"))
        for i = 1:mesh.nn
          line = split(readline(fhand))
          for j = 1:dim
            mesh.n2c[j+(i-1)*dim] = Meta.parse(line[j])
          end
        end
      elseif (contains(line,"tri2 # type name"))
        line = readline(fhand)
        line = readline(fhand)
        line = readline(fhand)
        line = split(readline(fhand))
        neT6 = Meta.parse(line[1])
        line = readline(fhand)
        e2nT6 = Vector{Int64}(undef,neT6*TR6n)
        e2gT6 = Vector{Int64}(undef,neT6)
        for i = 1:neT6
          line = split(readline(fhand))
          for j = 1:TR6n
            e2nT6[j+(i-1)*TR6n] = Meta.parse(line[j])+1
          end
        end
        while (true)
          line = readline(fhand)
          if (contains(line,"# Geometric entity indices"))
            for i = 1:neT6
              line = readline(fhand)
              e2gT6[i] = Meta.parse(line)+1
            end
            break
          end
        end
      elseif (contains(line,"quad2 # type name"))
        line = readline(fhand)
        line = readline(fhand)
        line = readline(fhand)
        line = split(readline(fhand))
        neQ9 = Meta.parse(line[1])
        line = readline(fhand)
        e2nQ9 = Vector{Int64}(undef,neQ9*QU9n)
        e2gQ9 = Vector{Int64}(undef,neQ9)
        for i = 1:neQ9
          line = split(readline(fhand))
          for j = 1:QU9n
            e2nQ9[j+(i-1)*QU9n] = Meta.parse(line[j])+1
          end
        end
        while (true)
          line = readline(fhand)
          if (contains(line,"# Geometric entity indices"))
            for i = 1:neQ9
              line = readline(fhand)
              e2gQ9[i] = Meta.parse(line)+1
            end
            break
          end
        end
      elseif (contains(line,"tet2 # type name"))
        line = readline(fhand)
        line = readline(fhand)
        line = readline(fhand)
        line = split(readline(fhand))
        neT10 = Meta.parse(line[1])
        line = readline(fhand)
        e2nT10 = Vector{Int64}(undef,neT10*T10n)
        e2gT10 = Vector{Int64}(undef,neT10)
        for i = 1:neT10
          line = split(readline(fhand))
          for j = 1:T10n
            e2nT10[j+(i-1)*T10n] = Meta.parse(line[j])+1
          end
        end
        while (true)
          line = readline(fhand)
          if (contains(line,"# Geometric entity indices"))
            for i = 1:neT10
              line = readline(fhand)
              e2gT10[i] = Meta.parse(line)
            end
            break
          end
        end
      elseif (contains(line,"prism2 # type name"))
        line = readline(fhand)
        line = readline(fhand)
        line = readline(fhand)
        line = split(readline(fhand))
        neP18 = Meta.parse(line[1])
        line = readline(fhand)
        e2nP18 = Vector{Int64}(undef,neP18*P18n)
        e2gP18 = Vector{Int64}(undef,neP18)
        for i = 1:neP18
          line = split(readline(fhand))
          for j = 1:P18n
            e2nP18[j+(i-1)*P18n] = Meta.parse(line[j])+1
          end
        end
        while (true)
          line = readline(fhand)
          if (contains(line,"# Geometric entity indices"))
            for i = 1:neP18
              line = readline(fhand)
              e2gP18[i] = Meta.parse(line)
            end
            break
          end
        end
      elseif (contains(line,"hex2 # type name"))
        line = readline(fhand)
        line = readline(fhand)
        line = readline(fhand)
        line = split(readline(fhand))
        neH27 = Meta.parse(line[1])
        line = readline(fhand)
        e2nH27 = Vector{Int64}(undef,neH27*H27n)
        e2gH27 = Vector{Int64}(undef,neH27)
        for i = 1:neH27
          line = split(readline(fhand))
          for j = 1:H27n
            e2nH27[j+(i-1)*H27n] = Meta.parse(line[j])+1
          end
        end
        while (true)
          line = readline(fhand)
          if (contains(line,"# Geometric entity indices"))
            for i = 1:neH27
              line = readline(fhand)
              e2gH27[i] = Meta.parse(line)
            end
            break
          end
        end
      end
    end
  end
  # if var is not defined and assign default value
  if (!@isdefined e2gT6)
    neT6 = 0
    e2gT6 = [0]
  end
  if (!@isdefined e2gQ9)
    neQ9 = 0
    e2gQ9 = [0]
  end
  if (!@isdefined e2gT10)
    neT10 = 0
    e2gT10 = [0]
  end
  if (!@isdefined e2gP18)
    neP18 = 0
    e2gP18 = [0]
  end
  if (!@isdefined e2gH27)
    neH27 = 0
    e2gH27 = [0]
  end

  nVol = maximum([maximum(e2gT10), maximum(e2gP18), maximum(e2gH27)])
  nSurf = maximum([maximum(e2gT6), maximum(e2gQ9)])

  surf = Array{Int64}(undef,nSurf) 
  vol  = Array{Int64}(undef,nVol) 
  fill!(surf,-1)
  fill!(vol,-1)

  mesh.nΩ = size(Ω_list)[1]
  mesh.nΓ = size(Γ_list)[1]

  for i = 1:mesh.nΩ
    for j = 1:size(Ω_list[i])[1]
      ith_b = Ω_list[i][j]
      vol[ith_b] = i
    end
  end

  for i = 1:mesh.nΓ
    for j = 1:size(Γ_list[i])[1]
      ith_b = Γ_list[i][j]
      surf[ith_b] = i
    end
  end

  neΓT6  = zeros(Int64,mesh.nΓ)
  neΓQ9  = zeros(Int64,mesh.nΓ)
  neΩT10 = zeros(Int64,mesh.nΩ)
  neΩW18 = zeros(Int64,mesh.nΩ)
  neΩH27 = zeros(Int64,mesh.nΩ)

  # number of nodes for supported surface elements
  Se_nn = [TR3n, TR6n, QU4n, QU8n, QU9n]
  #Set_Γ = [:TR3, :TR6, :QU4, :QU8, :QU9]
  # number of nodes for supported volume elements
  Ve_nn = [TE4n, T10n, HE8n, H20n, H27n, PE6n, P15n, P18n]
  #Set_Ω = [:TE4, :T10, :HE8, :H20, :H27, :PE6, :P15, :P18]
  #
  neΩ = zeros(Int64,(size(Ve_nn)[1], mesh.nΩ ))
  neΓ = zeros(Int64,(size(Se_nn)[1], mesh.nΓ ))

  for i = 1:neT6
    ith_s = e2gT6[i]
    if (surf[ith_s]>0)
      neΓ[2,surf[ith_s]] += 1
    end
  end

  for i = 1:neQ9
    ith_s = e2gQ9[i]
    if (surf[ith_s]>0)
      neΓ[5,surf[ith_s]] += 1
    end
  end

  for i = 1:neT10
    ith_s = e2gT10[i]
    if (vol[ith_s]>0)
      neΩ[2,vol[ith_s]] += 1
    end
  end

  for i = 1:neP18
    ith_s = e2gP18[i]
    if (vol[ith_s]>0)
      neΩ[7,vol[ith_s]] += 1
    end
  end

  for i = 1:neH27
    ith_s = e2gH27[i]
    if (vol[ith_s]>0)
      neΩ[5,vol[ith_s]] += 1
    end
  end
  #
  mesh.Ω = [Domain() for i in 1:mesh.nΩ]
  mesh.Γ = [Boundary() for i = 1:mesh.nΓ]
  # fill mesh data structure
  for b = 1:mesh.nΓ
    iΓ = mesh.Γ[b]
    #
    iΓ.Sen = size(Se_nn)[1] 
    iΓ.Set = [:TR3, :TR6, :QU4, :QU8, :QU9]
    iΓ.Senn = Se_nn
    iΓ.ne = neΓ[:,b]
    iΓ.bcdofs = bc_dof[b]
    iΓ.bcvals = bc_vals[b]
    iΓ.eskip = zeros(Int64,iΓ.Sen)
    nn = 0
    for j = 1:iΓ.Sen-1
      nn += neΓ[j,b]*Se_nn[j]
      iΓ.eskip[j+1] = nn
    end
    nn += neΓ[end,b]*Se_nn[end]
    iΓ.e2n = Vector{Int64}(undef,nn)
  end
  #
  for d = 1:mesh.nΩ
    iΩ = mesh.Ω[d]
    #
    iΩ.Sen = size(Ve_nn)[1] 
    iΩ.Set = [:TE4, :T10, :HE8, :H20, :H27, :PE6, :P15, :P18]
    iΩ.Senn = Ve_nn
    iΩ.ne = neΩ[:,d]
    iΩ.mat = load_material(mat[d])
    iΩ.eskip = zeros(Int64,iΩ.Sen)
    #
    nn = 0
    for j = 1:iΩ.Sen-1
      nn += neΩ[j,d]*Ve_nn[j]
      iΩ.eskip[j+1] = nn
    end
    nn += neΩ[end,d]*Ve_nn[end]
    iΩ.e2n = Vector{Int64}(undef,nn)
  end
  # fill boundaries connectivity
  for b = 1:mesh.nΓ
    iΓ = mesh.Γ[b]
    #
    skip = iΓ.eskip[2]+1
    for e = 1:neT6
      ith_s = e2gT6[e]
      ith_s = surf[ith_s]
      if (ith_s==b)
        iΓ.e2n[skip:skip+TR6n-1] = e2nT6[1+(e-1)*TR6n:e*TR6n]
        skip += TR6n
      end
    end
    #
    skip = iΓ.eskip[5]+1
    for e = 1:neQ9
      ith_s = e2gQ9[e]
      ith_s = surf[ith_s]
      if (ith_s==b)
        iΓ.e2n[skip:skip+QU9n-1] = e2nQ9[1+(e-1)*QU9n:e*QU9n]
        skip += QU9n
      end
    end
    #
  end
  #
  for d = 1:mesh.nΩ
    iΩ = mesh.Ω[d]
    #
    skip = iΩ.eskip[2]
    for e = 1:neT10
      ith_s = e2gT10[e]
      ith_s = vol[ith_s]
      #
      if (ith_s==d)
        iΩ.e2n[skip+1]  =  e2nT10[1+(e-1)*T10n]
        iΩ.e2n[skip+2]  =  e2nT10[2+(e-1)*T10n]
        iΩ.e2n[skip+3]  =  e2nT10[4+(e-1)*T10n]
        iΩ.e2n[skip+4]  =  e2nT10[3+(e-1)*T10n]
        iΩ.e2n[skip+5]  =  e2nT10[5+(e-1)*T10n]
        iΩ.e2n[skip+6]  =  e2nT10[9+(e-1)*T10n]
        iΩ.e2n[skip+7]  =  e2nT10[8+(e-1)*T10n]
        iΩ.e2n[skip+8]  =  e2nT10[7+(e-1)*T10n]
        iΩ.e2n[skip+9]  =  e2nT10[6+(e-1)*T10n]
        iΩ.e2n[skip+10] = e2nT10[10+(e-1)*T10n]
        skip += T10n
      end
      #
    end
    #
    skip = iΩ.eskip[5]+1
    for e = 1:neH27
      ith_s = e2gH27[e]
      ith_s = vol[ith_s]
      if (ith_s==d)
        iΩ.e2n[skip:skip+H27n-1] = e2nH27[1+(e-1)*H27n:e*H27n]
        skip += H27n
      end
    end
    #
    skip = iΩ.eskip[7]
    for e = 1:neP18
      ith_s = e2gP18[e]
      ith_s = vol[ith_s]
      if (ith_s==d)
        iΩ.e2n[skip+1]  =  e2nP18[1+(e-1)*P18n]
        iΩ.e2n[skip+2]  =  e2nP18[2+(e-1)*P18n]
        iΩ.e2n[skip+3]  =  e2nP18[3+(e-1)*P18n]
        iΩ.e2n[skip+4]  =  e2nP18[4+(e-1)*P18n]
        iΩ.e2n[skip+5]  =  e2nP18[5+(e-1)*P18n]
        iΩ.e2n[skip+6]  =  e2nP18[6+(e-1)*P18n]
        iΩ.e2n[skip+7]  =  e2nP18[7+(e-1)*P18n]
        iΩ.e2n[skip+8]  =  e2nP18[9+(e-1)*P18n]
        iΩ.e2n[skip+9]  =  e2nP18[8+(e-1)*P18n]
        iΩ.e2n[skip+10] = e2nP18[16+(e-1)*P18n]
        #
        iΩ.e2n[skip+11] = e2nP18[18+(e-1)*P18n]
        iΩ.e2n[skip+12] = e2nP18[17+(e-1)*P18n]
        iΩ.e2n[skip+13] = e2nP18[10+(e-1)*P18n]
        iΩ.e2n[skip+14] = e2nP18[12+(e-1)*P18n]
        iΩ.e2n[skip+15] = e2nP18[15+(e-1)*P18n]
        #iΩ.e2n[skip+16] = e2nP18[11+(e-1)*P18n]
        #iΩ.e2n[skip+17] = e2nP18[13+(e-1)*P18n]
        #iΩ.e2n[skip+18] = e2nP18[14+(e-1)*P18n]
        #
        skip += P15n
      end
    end
    #  
  end
  #
  return nothing
  #
end



"""
> import_mesh!( mesh::Grid, mesh_file::String, Ω_list::Vector{Vector{Int64}}, Γ_list::Vector{Vector{Int64}}, mat::Vector{material}, bc_dof::Vector{Vector{Int64}}, bc_vals::Vector{Vector{Float64}}, ::Type{Val{:MED}})
It reads a MED mesh format
- mesh_file : name of the mesh file
- Ω_list : list of domains in which the structures is organised
- Γ_list : list of boundaries
- mat : list of materials associated to each domain
- bc_dof : list of constrained degrees of freedom of each boundary
- bc_vals : boundary condition values
- :MED : specializes function to read MED mesh format
"""
function import_mesh!(mesh::Grid, mesh_file::String, 
                      Ω_list, 
                      Γ_list, 
                      mat::Vector{String}, bc_dof::Vector{Vector{Int64}}, 
                      bc_vals::Vector{Vector{Float64}}, ::Type{Val{:MED}})
  #
  pth = joinpath(".","mesh",mesh_file)
  #
  MeshFile = aster_read_mesh(pth)
  # mesh nodes
  nodes = MeshFile["nodes"]
  mesh.nn = length(nodes)
  mesh.n2c = Vector{Float64}(undef,mesh.nn*dim)
  for i = 1:mesh.nn
    for j = 1:dim
      mesh.n2c[j+(i-1)*dim] = nodes[i][j]
    end
  end
  # allocate domains and boundaries
  mesh.nΩ = size(Ω_list)[1]
  mesh.nΓ = size(Γ_list)[1]
  mesh.Ω = [Domain() for i ∈ 1:mesh.nΩ]
  mesh.Γ = [Boundary() for i ∈ 1:mesh.nΓ]
  #
  Elements = MeshFile["elements"]
  ElementTypes = MeshFile["element_types"]
  ElementGroups = MeshFile["element_sets"]
  #
  neΓ = zeros(Int64,(Snse,mesh.nΓ))
  neΩ = zeros(Int64,(Vnse,mesh.nΩ))
  #
  for i = 1:mesh.nΓ
    sname = Γ_list[i]
    selem = ElementGroups[sname]
    for j = 1:size(selem)[1]
      etype = ElementTypes[selem[j]]
      if (etype == :TR3)
        neΓ[1,i] += 1
      elseif (etype == :TR6)
        neΓ[2,i] += 1
      elseif (etype == :QU4)
        neΓ[3,i] += 1
      elseif (etype == :QU8)
        neΓ[4,i] += 1
      elseif (etype == :QU9)
        neΓ[5,i] += 1
      else
        println("Warning, element not supported")
      end
    end
  end
  #
  for i = 1:mesh.nΩ
    vname = Ω_list[i]
    velem = ElementGroups[vname]
    for j = 1:size(velem)[1]
      etype = ElementTypes[velem[j]]
      if (etype == :TE4)
        neΩ[1,i] += 1
      elseif (etype == :T10)
        neΩ[2,i] += 1
      elseif (etype == :HE8)
        neΩ[3,i] += 1
      elseif (etype == :H20)
        neΩ[4,i] += 1
      elseif (etype == :H27)
        neΩ[5,i] += 1
      elseif (etype == :PE6)
        neΩ[6,i] += 1
      elseif (etype == :P15)
        neΩ[7,i] += 1
      elseif (etype == :P18)
        neΩ[8,i] += 1
      else
        println("Warning, element not supported")
      end
    end
  end
  #
  # number of nodes for supported surface elements
  Se_nn = [TR3n, TR6n, QU4n, QU8n, QU9n]
  # number of nodes for supported volume elements
  Ve_nn = [TE4n, T10n, HE8n, H20n, H27n, PE6n, P15n, P18n]
  # allocate connectivity
  for i = 1:mesh.nΩ
    iΩ = mesh.Ω[i]
    #
    iΩ.Sen = size(Ve_nn)[1] 
    iΩ.Set = [:TE4, :T10, :HE8, :H20, :H27, :PE6, :P15, :P18]
    iΩ.Senn = Ve_nn
    iΩ.ne = neΩ[:,i]
    iΩ.mat = load_material(mat[i])
    iΩ.eskip = zeros(Int64,iΩ.Sen)
    #
    nn = 0
    for j = 1:iΩ.Sen-1
      nn += neΩ[j,i]*Ve_nn[j]
      iΩ.eskip[j+1] = nn
    end
    nn += neΩ[end,i]*Ve_nn[end]
    iΩ.e2n = Vector{Int64}(undef,nn)
  end
  #
  for i = 1:mesh.nΓ
    iΓ = mesh.Γ[i]
    #
    iΓ.Sen = size(Se_nn)[1] 
    iΓ.Set = [:TR3, :TR6, :QU4, :QU8, :QU9]
    iΓ.Senn = Se_nn
    iΓ.ne = neΓ[:,i]
    iΓ.bcdofs = bc_dof[i]
    iΓ.bcvals = bc_vals[i]
    iΓ.eskip = zeros(Int64,iΓ.Sen)
    #
    nn = 0
    for j = 1:iΓ.Sen-1
      nn += neΓ[j,i]*Se_nn[j]
      iΓ.eskip[j+1] = nn
    end
    nn += neΓ[end,i]*Se_nn[end]
    iΓ.e2n = Vector{Int64}(undef,nn)
  end
  # fill boundaries with mesh connectivity
  for i = 1:mesh.nΓ
    iΓ = mesh.Γ[i]
    sname = Γ_list[i]
    selem = ElementGroups[sname]
    ecount = zeros(Int64,size(Se_nn)[1] )
    for j = 1:size(selem)[1]
      etype = ElementTypes[selem[j]]
      if (etype == :TR3)
        skip = iΓ.eskip[1]+ecount[1]*Se_nn[1]
        iΓ.e2n[1+skip:skip+Se_nn[1]] = Elements[selem[j]]
        ecount[1] += 1
      elseif (etype == :TR6)
        skip = iΓ.eskip[2]+ecount[2]*Se_nn[2]
        iΓ.e2n[1+skip:skip+Se_nn[2]] = Elements[selem[j]]
        ecount[2] += 1
      elseif (etype == :QU4)
        skip = iΓ.eskip[3]+ecount[3]*Se_nn[3]
        iΓ.e2n[1+skip:skip+Se_nn[3]] = Elements[selem[j]]
        ecount[3] += 1
      elseif (etype == :QU8)
        skip = iΓ.eskip[4]+ecount[4]*Se_nn[4]
        iΓ.e2n[1+skip:skip+Se_nn[4]] = Elements[selem[j]]
        ecount[4] += 1
      elseif (etype == :QU9)
        skip = iΓ.eskip[5]+ecount[5]*Se_nn[5]
        iΓ.e2n[1+skip:skip+Se_nn[5]] = Elements[selem[j]]
        ecount[5] += 1
      else
        println("Warning, element not supported")
      end
    end
    # fill domains with mesh connectivity
    for i = 1:mesh.nΩ
      iΩ = mesh.Ω[i]
      sname = Ω_list[i]
      velem = ElementGroups[sname]
      ecount = zeros(Int64,size(Ve_nn)[1] )
      for j = 1:size(velem)[1]
        etype = ElementTypes[velem[j]]
        if (etype == :TE4)
          skip = iΩ.eskip[1]+ecount[1]*Ve_nn[1]
          iΩ.e2n[1+skip:skip+Ve_nn[1]] = Elements[velem[j]]
          ecount[1] += 1
        elseif (etype == :T10)
          skip = iΩ.eskip[2]+ecount[2]*Ve_nn[2]
          iΩ.e2n[1+skip:skip+Ve_nn[2]] = Elements[velem[j]]
          ecount[2] += 1
        elseif (etype == :HE8)
          skip = iΩ.eskip[3]+ecount[3]*Ve_nn[3]
          iΩ.e2n[1+skip:skip+Ve_nn[3]] = Elements[velem[j]]
          ecount[3] += 1
        elseif (etype == :H20)
          skip = iΩ.eskip[4]+ecount[4]*Ve_nn[4]
          iΩ.e2n[1+skip:skip+Ve_nn[4]] = Elements[velem[j]]
          ecount[4] += 1
        elseif (etype == :H27)
          skip = iΩ.eskip[5]+ecount[5]*Ve_nn[5]
          iΩ.e2n[1+skip:skip+Ve_nn[5]] = Elements[velem[j]]
          ecount[5] += 1
        elseif (etype == :PE6)
          skip = iΩ.eskip[6]+ecount[6]*Ve_nn[6]
          iΩ.e2n[1+skip:skip+Ve_nn[6]] = Elements[velem[j]]
          ecount[6] += 1
        elseif (etype == :P15)
          skip = iΩ.eskip[7]+ecount[7]*Ve_nn[7]
          iΩ.e2n[1+skip:skip+Ve_nn[7]] = Elements[velem[j]]
          ecount[7] += 1
        elseif (etype == :P18)
          skip = iΩ.eskip[8]+ecount[8]*Ve_nn[8]
          iΩ.e2n[1+skip:skip+Ve_nn[8]] = Elements[velem[j]]
          ecount[8] += 1
        else
          println("Warning, element not supported")
        end
      end
    end
  end
  #
  mesh.tcn = 0
  mesh.tnn = 0
  for i = 1:mesh.nΩ
    iΩ = mesh.Ω[i]
    for se = 1:iΩ.Sen
      mesh.tcn += iΩ.ne[se]
      mesh.tnn += iΩ.ne[se]*iΩ.Senn[se]
    end
  end
  #
  return nothing
end