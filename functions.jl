using Clarabel
using Convex
using LinearAlgebra
using Mosek
using SCS

function calc_commuting_dilation_const(Matrices, Normals, solver = SCS.Optimizer)
    d = length(Matrices)  # number of matrices
    s = length(Normals[1]) # number of points in the spectrum
    N = size(Matrices[1], 1)  # size of matrices

    # variable to maximize: inverse dilation scale
    r = Variable()
    objective = r

    # list of k^d hermitian psd Variables (N × N)
    C = [HermitianSemidefinite(N) for _ in 1:s]

    # unitality constraint
    constraints = [sum(C) == I(N)]

    # dilation constraint
    append!(constraints, [sum(C[j] * Normals[i][j] for j in 1:length(C)) == r * Matrices[i] for i in 1:d])

    # define and solve problem
    prob = Problem(:maximize, objective, constraints...) 
    result = solve!(prob, solver)

    return 1 / Convex.evaluate(r)
end


function make_test_normals(d, k)
    Ns = reduce(hcat, [cispi.((2/k) .* Tuple(i)) for i in CartesianIndices(ntuple(_ -> k, d))])

    return [[lambda[i] for lambda in Ns] for i in 1:d]  # Liste mit d Vektoren der Länge k^d
end


function make_random_normals(d, k)
    Ns=[[cispi(2 * rand()) for i in 1:k] for j in 1:d]
    return Ns
end


function random_unitary(n)
    # returns n-by-n random unitary
    X = randn(n, n)  # Zufallsmatrix X
    Y = randn(n, n)  # Zufallsmatrix Y
    Q, R = qr(X + 1im * Y)  # QR-Zerlegung von X + i*Y
    D = sign.(Diagonal(R))  # Diagonale von R
    U = Q * D  # Einheitsmatrix mit Vorzeichen von D
    return U
end


# Reliability test function for results with different solvers, as an indication of the reliability of the results
# This function creates two random unitaries and two normals, then runs the dilation constant calculation
# with different solvers and prints the results.
function ReliabilityTest(N, k)
    # Create two random N x N unitaries
    U = [random_unitary(N) for i in 1:2]
    # Create two normals with make_test_normals
    Normals = make_test_normals(2, k)
    # Run with different solvers
    result_SCS = calc_commuting_dilation_const(U, Normals, SCS.Optimizer)
    result_Mosek = calc_commuting_dilation_const(U, Normals, Mosek.Optimizer)

    println("Reliability Test Results:")
    println("SCS:      ", result_SCS)
    println("Mosek: ", result_Mosek)
    return (SCS=result_SCS, Mosek=result_Mosek)
end