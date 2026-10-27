import unopy

Inf = float("inf")

# 1. Define scaling parameters for physical variables
scales = [1000.0, 1.0]
offsets = [0.0, 0.0]

def unscale(x_scaled):
    return [s * xp + o for s, xp, o in zip(scales, x_scaled, offsets)]

# 2. Objective and constraint functions (acting on scaled variables)
def objective(x_scaled):
    x = unscale(x_scaled)
    return (x[0] / 1000.0 - 1.0)**2 + (x[1] - 2.0)**2

def objective_gradient(x_scaled, gradient):
    x = unscale(x_scaled)
    df_dx0 = 2.0 * (x[0] / 1000.0 - 1.0) * (1.0 / 1000.0)
    df_dx1 = 2.0 * (x[1] - 2.0)
    gradient[0] = df_dx0 * scales[0]
    gradient[1] = df_dx1 * scales[1]

def constraints(x_scaled, constraint_values):
    x = unscale(x_scaled)
    constraint_values[:] = [x[0] + x[1]]

def jacobian(x_scaled, jacobian_values):
    jacobian_values[:] = [1.0 * scales[0], 1.0 * scales[1]]

# 3. Solver callbacks (accepting *args to handle all positional arguments safely)
def iterate_callback(*args):
    primals = args[0] if len(args) > 0 else None
    print(f"Iteration update - Scaled primals: {primals}")
    return False

def termination_callback(*args):
    return False

if __name__ == "__main__":
    problem_type = unopy.PROBLEM_NONLINEAR
    base_indexing = unopy.ZERO_BASED_INDEXING
    number_variables = 2

    # Map physical bounds into the scaled coordinate space
    x_phys_lb = [0.0, 0.0]
    x_phys_ub = [5000.0, 10.0]
    variables_lower_bounds = [(lb - o) / s for lb, s, o in zip(x_phys_lb, scales, offsets)]
    variables_upper_bounds = [(ub - o) / s for ub, s, o in zip(x_phys_ub, scales, offsets)]

    # Build optimization model
    model = unopy.Model(problem_type, number_variables, variables_lower_bounds, variables_upper_bounds, base_indexing)
    model.set_name("scaled_optimization_example")
    
    # Set objective and its gradient
    optimization_sense = unopy.MINIMIZE
    model.set_objective(optimization_sense, objective, objective_gradient)
    
    # Set constraints, bounds, and sparse Jacobian structure
    number_constraints = 1
    constraints_lower_bounds = [-Inf]
    constraints_upper_bounds = [500.0]
    number_jacobian_nonzeros = 2
    jacobian_row_indices = [0, 0]
    jacobian_column_indices = [0, 1]
    
    model.set_constraints(
        number_constraints, 
        constraints, 
        constraints_lower_bounds, 
        constraints_upper_bounds, 
        number_jacobian_nonzeros, 
        jacobian_row_indices, 
        jacobian_column_indices, 
        jacobian
    )

    # Set initial guess (mapped to scaled space)
    x0_phys = [100.0, 1.0]
    x0_scaled = [(x - o) / s for x, s, o in zip(x0_phys, scales, offsets)]
    model.set_initial_primal_iterate(x0_scaled)

    # Configure solver
    uno_solver = unopy.UnoSolver()
    uno_solver.set_preset("filtersqp")
    uno_solver.set_option("print_solution", True)
    
    # Attach callbacks
    uno_solver.set_notify_acceptable_iterate_callback(iterate_callback)
    uno_solver.set_termination_callback(termination_callback)

    # Run optimization
    result = uno_solver.optimize(model)

    # Output results using correct result attributes
    print("Solution objective:", result.solution_objective)
    print("Optimal physical variables:", unscale(result.primal_solution))