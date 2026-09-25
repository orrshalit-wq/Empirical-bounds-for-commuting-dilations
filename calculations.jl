using Statistics
using DataFrames
using CSV
using Plots
using StatsBase

default(
    fontfamily="Computer Modern",
    legendfontsize=10,
    guidefontsize=14,
    tickfontsize=12,
    lw=2,
    framestyle=:box,
    gridalpha=0.3
)

function TestRun(N,k,d=2)
    As=[random_unitary(N) for i in 1:d]
    Ns=make_test_normals(d,k)
    c=calc_commuting_dilation_const(As,Ns)
    #println(c)
    return c
end


# RunExperiment: can be called with N, d, k, m as arguments
function RunExperiment(N,k,m,d=2)

    for i in 1:m
        println("Trial $i:")
        TestRun(N, k, d)
    end
end

# --------------------------
# Run experiments, save, and analyze (all-in-one)
# --------------------------

function run_and_analyze(m_dict::Dict{Int,Int}, k; results_file="results.csv", bins=20)
    Ns = sort(collect(keys(m_dict)))
    all_results = DataFrame(N=Int[], run=Int[], C=Float64[], k=Int[])

    # Run experiments
    for N in Ns
        m_N = m_dict[N]
        println("Running N = $N, m_N = $m_N...")
        for run_id in 1:m_N
            C = TestRun(N, k)
            push!(all_results, (N=N, run=run_id, C=C, k=k))
        end
    end
    CSV.write(results_file, all_results)
    println("Saved all results to $results_file")

    # Analyze results
    means = Float64[]
    stds = Float64[]
    df = all_results

    for N in Ns
        results_N = df.C[df.N .== N]   # Fixed df.r → df.C
        μ = mean(results_N)
        σ = std(results_N)
        push!(means, μ)
        push!(stds, σ)

        # Histogram
        plt = histogram(
            results_N, bins=bins,
            xlabel="C", ylabel="Frequency",
            title="Histogram for N = $N, k = $k",
            legend=false,
            linecolor=:black, fillcolor=:dodgerblue, alpha=0.7,
            framestyle=:box, grid=false,
            size=(700,450)
        )

        # Annotation with σ (fix diff error)
        xlims = Plots.xlims(plt)
        ylims = Plots.ylims(plt)
        x_annot = xlims[2] - 0.02*(xlims[2] - xlims[1])
        y_annot = ylims[2] - 0.08*(ylims[2] - ylims[1])
        annotate!(plt, (x_annot, y_annot,
            text("σ = $(round(σ, sigdigits=2))", :black, 13, :right))
        )

        savefig(plt, "hist_N$(N)_k$(k).png")
        println("Saved histogram to hist_N$(N)_k$(k).png")
    end

    # Mean vs N plot
    plt2 = plot(
        Ns, means, marker=:circle, markersize=6, lw=2,
        xlabel="N", ylabel="Mean(C)",
        title="Mean of C vs N (k = $k)",
        legend=false, grid=true,
        xticks=(Ns, string.(Ns)),  # Tick labels are exactly the N values
        framestyle=:box, size=(700,450),
        color=:darkred
    )
    savefig(plt2, "mean_vs_N_k$(k).png")
    println("Saved mean vs N plot to mean_vs_N_k$(k).png")

    # Standard deviation vs N plot
    plt3 = plot(
        Ns, stds, marker=:circle, markersize=6, lw=2,
        xlabel="N", ylabel="Std(C)",
        title="Standard Deviation of C vs N (k = $k)",
        legend=false, grid=true,
        xticks=(Ns, string.(Ns)),
        framestyle=:box, size=(700,450),
        color=:darkgreen
    )
    savefig(plt3, "std_vs_N_k$(k).png")
    println("Saved std vs N plot to std_vs_N_k$(k).png")

    return DataFrame(N=Ns, mean=means, std=stds)
end


# --------------------------
# Example usage
# --------------------------
# run_and_analyze(Dict(10=>100, 15=>100, 20=>100, 25=>100, 30=>100), k=15; results_file="results.csv", bins=5)
# or 
# run_and_analyze(Dict(10=>100, 15=>100, 20=>100, 25=>100, 30=>100), k=15)
# --------------------------

# Analyze results from a CSV file and produce plots/summary
function analyze_results_from_csv(results_file::String; bins=20)
    df = CSV.read(results_file, DataFrame)
    Ns = sort(unique(df.N))
    means = Float64[]
    stds = Float64[]
    # Try to get k from the file, else fallback to filename
    k = try
        if :k in propertynames(df)
            unique_k = unique(df.k)
            length(unique_k) == 1 ? unique_k[1] : "?"
        else
            match = match(r"k=(\d+)", results_file)
            match === nothing ? "?" : parse(Int, match.captures[1])
        end
    catch
        "?"
    end

    for N in Ns
        results_N = df.C[df.N .== N]
        μ = mean(results_N)
        σ = std(results_N)
        push!(means, μ)
        push!(stds, σ)

        plt = histogram(
            results_N, bins=bins,
            xlabel="C", ylabel="Frequency",
            title="Histogram for N = $N, k = $k",
            legend=false,
            linecolor=:black, fillcolor=:dodgerblue, alpha=0.7,
            framestyle=:box, grid=false,
            size=(700,450)
        )
        xlims = Plots.xlims(plt)
        ylims = Plots.ylims(plt)
        x_annot = xlims[2] - 0.02*(xlims[2] - xlims[1])
        y_annot = ylims[2] - 0.08*(ylims[2] - ylims[1])
        annotate!(plt, (x_annot, y_annot,
            text("σ = $(round(σ, sigdigits=2))", :black, 13, :right))
        )
        savefig(plt, "hist_N$(N)_k$(k).png")
        println("Saved histogram to hist_N$(N)_k$(k).png")
    end

    plt2 = plot(
        Ns, means, marker=:circle, markersize=6, lw=2,
        xlabel="N", ylabel="Mean(C)",
        title="Mean of C vs N (k = $k)",
        legend=false, grid=true,
        xticks=(Ns, string.(Ns)),
        framestyle=:box, size=(700,450),
        color=:darkred
    )
    savefig(plt2, "mean_vs_N_k$(k).png")
    println("Saved mean vs N plot to mean_vs_N_k$(k).png")

    # Standard deviation vs N plot
    plt3 = plot(
        Ns, stds, marker=:circle, markersize=6, lw=2,
        xlabel="N", ylabel="Std(C)",
        title="Standard Deviation of C vs N (k = $k)",
        legend=false, grid=true,
        xticks=(Ns, string.(Ns)),
        framestyle=:box, size=(700,450),
        color=:darkgreen
    )
    savefig(plt3, "std_vs_N_k$(k).png")
    println("Saved std vs N plot to std_vs_N_k$(k).png")

    return DataFrame(N=Ns, mean=means, std=stds)
end

# Run a single experiment for each N, plot only means (no std, no histograms)
function run_single_and_plot(Ns::Vector{Int}, k; results_file="results_single.csv")
    results = DataFrame(N=Int[], C=Float64[], k=Int[])
    means = Float64[]
    
    for N in Ns
        println("Running N = $N...")
        C = TestRun(N, k)
        push!(results, (N=N, C=C, k=k))
        push!(means, C)
    end
    CSV.write(results_file, results)
    println("Saved all results to $results_file")

    # Mean vs N plot (no std)
    plt = plot(
        Ns, means, marker=:circle, markersize=6, lw=2,
        xlabel="N", ylabel="C",
        title="C vs N (k = $k)",
        legend=false, grid=true,
        xticks=(Ns, string.(Ns)),
        framestyle=:box, size=(700,450),
        color=:darkred
    )
    savefig(plt, "mean_vs_N_k$(k)_single.png")
    println("Saved mean vs N plot to mean_vs_N_k$(k)_single.png")

    return DataFrame(N=Ns, C=means)
end

function append_and_plot_single(Ns_new::Vector{Int}, k; results_file="results_single.csv")
    # Read existing results if file exists
    if isfile(results_file)
        df_old = CSV.read(results_file, DataFrame)
    else
        df_old = DataFrame(N=Int[], C=Float64[], k=Int[])
    end

    # Run new experiments
    results_new = DataFrame(N=Int[], C=Float64[], k=Int[])
    means = Float64[]
    for N in Ns_new
        println("Running N = $N...")
        C = TestRun(N, k)
        push!(results_new, (N=N, C=C, k=k))
        push!(means, C)
    end

    # Combine and save
    df_all = vcat(df_old, results_new)
    CSV.write(results_file, df_all)
    println("Saved all results to $results_file")

    # Plot all results
    Ns_all = sort(unique(df_all.N))
    means_all = [mean(df_all.C[df_all.N .== N]) for N in Ns_all]
    plt = plot(
        Ns_all, means_all, marker=:circle, markersize=6, lw=2,
        xlabel="N", ylabel="C",
        title="C vs N (k = $k)",
        legend=false, grid=true,
        xticks=(Ns_all, string.(Ns_all)),
        framestyle=:box, size=(700,450),
        color=:darkred
    )
    savefig(plt, "mean_vs_N_k$(k)_single.png")
    println("Saved mean vs N plot to mean_vs_N_k$(k)_single.png")

    return df_all
end

# --------------------------
# Plot all histograms from a results file in a single PNG grid
# --------------------------
function plot_all_histograms_grid(results_file::String; bins=20, out_file="all_histograms.png")
    df = CSV.read(results_file, DataFrame)
    Ns = sort(unique(df.N))
    k = try
        if :k in propertynames(df)
            unique_k = unique(df.k)
            length(unique_k) == 1 ? unique_k[1] : "?"
        else
            match = match(r"k=(\\d+)", results_file)
            match === nothing ? "?" : parse(Int, match.captures[1])
        end
    catch
        "?"
    end

    n_N = length(Ns)
    #Ns = Ns[1:2:end]  # Use only every second N for better visibility
    #n_N = length(Ns)
    ncols = ceil(Int, sqrt(n_N))
    nrows = ceil(Int, n_N / ncols)
    global_min = minimum(df.C)
    global_max = maximum(df.C)
    edges = range(global_min, global_max; length=bins+1)
    # Find the global max y value for consistent y-axis
    max_y = 0
    for N in Ns
        results_N = df.C[df.N .== N]
        h = fit(Histogram, results_N, collect(edges))
        max_y = max(max_y, maximum(h.weights))
    end
    plots = Plots.Plot[]
    for N in Ns
        results_N = df.C[df.N .== N]
        plt = histogram(
            results_N, bins=collect(edges),
            #xlabel="C", ylabel="Freq.",
            title="N = $N, k = $k",
            legend=false,
            linecolor=:black, fillcolor=:dodgerblue, alpha=0.7,
            framestyle=:box, grid=false,
            size=(350,250),
            xlims=(global_min, global_max),
            ylims=(0, max_y)
        )
        push!(plots, plt)
    end
    
    gridplt = plot(plots..., layout=(nrows, ncols), size=(ncols*350, nrows*250))
    savefig(gridplt, out_file)
    println("Saved all histograms grid to $(out_file)")
end

function plot_single_results(results_file::String; out_file="mean_vs_N_single.png")
    df = CSV.read(results_file, DataFrame)
    Ns = sort(unique(df.N))
    means = [mean(df.C[df.N .== N]) for N in Ns]
    plt = plot(
        Ns, means, marker=:circle, markersize=6, lw=2,
        xlabel="N", ylabel="C",
        title="C vs N",
        legend=false, grid=true,
        xticks=(Ns, string.(Ns)),
        framestyle=:box, size=(700,450),
        color=:darkred
    )
    savefig(plt, out_file)
    println("Saved mean vs N plot to $(out_file)")
end

# Run multiple single experiments and plot all results
function run_multiple_single_plots(Ns::Vector{Int}, k; results_file="results_multiple.csv", n_runs=5, out_file="const_vs_N_multiple.png")
    colors = [:red, :blue, :green, :orange, :purple, :brown, :magenta, :cyan, :black, :gray]
    all_means = []
    all_results = DataFrame(N=Int[], C=Float64[], k=Int[], run=Int[])
    for run_id in 1:n_runs
        results = DataFrame(N=Int[], C=Float64[], k=Int[], run=Int[])
        means = Float64[]
        for N in Ns
            println("Run $run_id, N = $N...")
            C = TestRun(N, k)
            push!(results, (N=N, C=C, k=k, run=run_id))
            push!(means, C)
        end
        push!(all_means, means)
        all_results = vcat(all_results, results)
        # Append after each run to avoid data loss
        if isfile(results_file)
            df_old = CSV.read(results_file, DataFrame)
            df_new = vcat(df_old, results)
        else
            df_new = results
        end
        CSV.write(results_file, df_new)
    end
    # Now do all plotting at the end
    # Compute y_min/y_max from all_results
    y_min = minimum(all_results.C)
    y_max = maximum(all_results.C)
    padding = 0.05 * (y_max - y_min)
    ylims_val = (y_min - padding, y_max + padding)
    plt = plot(legend=false, xlabel="N", ylabel="C", title="C vs N for $n_runs runs (k = $k)", grid=true, framestyle=:box, ylims=ylims_val)
    for run_id in 1:n_runs
        plot!(plt, Ns, all_means[run_id], marker=:circle, markersize=6, lw=2, color=colors[run_id])
    end
    savefig(plt, out_file)
    println("Saved multiple mean vs N plot to $(out_file)")
    return all_results
end