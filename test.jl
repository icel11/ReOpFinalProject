import Pkg; Pkg.add("JuMP")
import Pkg; Pkg.add("JSON")
import Pkg; Pkg.add("SCIP")
#import Pkg; Pkg.add("Gurobi"); Pkg.build("Gurobi")

using JuMP, JSON, SCIP #, Gurobi

stringdata = join(readlines("./instances/KIRO-small.json"))
dict = JSON.parse(stringdata)


# Preparing an optimization model
model = Model(SCIP.Optimizer)
M = 100
nb_jobs = dict["parameters"]["size"]["nb_jobs"]
nb_tasks = dict["parameters"]["size"]["nb_tasks"]
nb_machines = dict["parameters"]["size"]["nb_machines"]
nb_operators = dict["parameters"]["size"]["nb_operators"]
jobs = 1:length(dict["jobs"])

# Declaring variables
# Starting time of task i
@variable(model, b[1:nb_tasks], Int)
# 1 if job j ends after due_date
@variable(model, U[1:nb_jobs], Bin)
# m[t,m] is the answer to "The task t uses machine m" (1 if true, 0 else)
@variable(model, m[1:nb_tasks, 1:nb_machines], Bin)
# o[t,m, o] is the answer to "The task t uses machine m and operator o" (1 if true, 0 else)
@variable(model, o[1:nb_tasks, 1:nb_machines, 1:nb_operators], Bin)
# (1) 1 if start_task_i < end_task_j
@variable(model, starts_after[1:nb_tasks, 1:nb_tasks], Bin)
# (2) 1 if end_task_i < start_task_j
@variable(model, ends_before[1:nb_tasks, 1:nb_tasks], Bin)
# Overlap in time of i and j if starts_after(i, j) and ends_before(j, i)
# https://eli.thegreenplace.net/2008/08/15/intersection-of-1d-segments


# First we create the list of processing times
processing_times = [0 for n=1:length(dict["tasks"])]
for task in 1:length(dict["tasks"])
    processing_times[task] = dict["tasks"][task]["processing_time"]
end

# Then we add the operator and machine constraints
for task in 1:length(dict["tasks"])
    available_machines = []
    for machine in dict["tasks"][task]["machines"]
        push!(available_machines, machine["machine"])
    end
    for machine in 1:nb_machines
        if !(machine in available_machines)
            # If the task cannot be made in this machine, then 
            # m[task, machine] must be 0
            @constraint(model, m[task, machine] == 0)
            for operator in 1:nb_operators
                # Also, the task cannot be made in this machine with this operator (maybe superfluous?) 
                @constraint(model, o[task, machine, operator] == 0)
            end
        else
            available_operators = []
            for machine_data in dict["tasks"][task]["machines"]
                if machine_data["machine"] == machine
                    for operator in machine_data["operators"]
                        push!(available_operators, operator)
                    end
                end
            end
            for operator in 1:nb_operators
                if !(operator in available_operators)
                    # If the task can be made in this machine, but cannot be used by this operator, then
                    # o[task, machine, operator] must be 0
                    @constraint(model, o[task, machine, operator] == 0)
                else
                    # If the task can be made by this machine and this operator, it will only be able
                    # to be done by this operator if it is done by this machine:
                    @constraint(model, o[task, machine, operator] <= m[task, machine])
                end
            end
        end
    end

    # There must be only one machine and one operator for every task
    @constraint(model, sum( m[task, machine] for machine in 1:nb_machines) == 1)
    @constraint(model, sum( sum( o[task, machine, operator] for operator in 1:nb_operators) for machine in 1:nb_machines) == 1)
end

# Setting overlapping indicators
for task_1 in 1:length(dict["tasks"])
    for task_2 in 1:length(dict["tasks"])

        # This is how we model indicator functions as A 1 if B>C 0 otherwise to set the 
        # starts_after/ends_before indicators
        # https://cs.stackexchange.com/questions/69531/greater-than-condition-in-integer-linear-program-with-a-binary-variable
        
        @constraint(model, b[task_1] + processing_times[task_1] >= b[task_2] + 1 - M*(1-starts_after[task_1, task_2]))
        @constraint(model, b[task_1] + processing_times[task_1] <= b[task_2] + M*starts_after[task_1, task_2])
        @constraint(model, b[task_2] + processing_times[task_2] >= b[task_1] + 1 - M*(1-ends_before[task_1, task_2]))
        @constraint(model, b[task_2] + processing_times[task_2] <= b[task_1] + M*ends_before[task_1, task_2])

        if task_1 != task_2
            for machine in 1:nb_machines
                # If they are using the same machine, two tasks cannot overlap in time
                @constraint(model, m[task_1, machine]*m[task_2, machine] + starts_after[task_1, task_2]*ends_before[task_1, task_2] <= 1)
                for machine_2 in 1:nb_machines
                    for operator in 1:nb_operators
                        # If they are using the same operator, two tasks cannot overlap in time
                        @constraint(model, o[task_1, machine, operator]*o[task_2, machine_2, operator] + starts_after[task_1, task_2]*ends_before[task_1, task_2] <= 1)
                    end
                end
            end
        end

        #as = 50
        #cs = 5
        #@constraint(m, M_2*d_2 + cs*bla + (cs + e)*d_1 <= as)
        #@constraint(m, as <= (cs + e)*d_2 + cs*bla + M_1*d_1)
        #@constraint(m, d_1 + d_2 + bla == 1)
        
        # Big M method to check if they use the same machine/operator
        # This one -> https://or.stackexchange.com/questions/33/in-an-integer-program-how-i-can-force-a-binary-variable-to-equal-1-if-some-cond
        #@constraint(m, 1 - M* (machine[task_1] - machine[task_2]) <= o_m[task_1, task_2])
        #@constraint(m, o_m[task_1, task_2] >= 1 + M * (machine[task_1] - machine[task_2]))

        #@constraint(m, M_2*d_2_m[task_1,task_2] + machine[task_2]*o_m[task_1,task_2] + (machine[task_2] + e)*d_1_m[task_1,task_2] <= machine[task_1]) 
        #@constraint(m, machine[task_1] <= (machine[task_2] - e)*d_2_m[task_1,task_2] + machine[task_2]*o_m[task_1,task_2] + M_1*d_1_m[task_1,task_2]) 
        #@constraint(m, d_1_m[task_1,task_2] + d_2_m[task_1,task_2] + o_m[task_1,task_2] == 1)    

        #@constraint(m, M_2*d_2_o[task_1,task_2] + o[task_2]*o_o[task_1,task_2] + (o[task_2] + e)*d_1_o[task_1,task_2] <= o[task_1]) 
        #@constraint(m, o[task_1] <= (o[task_2] - e)*d_2_o[task_1,task_2] + o[task_2]*o_o[task_1,task_2] + M_1*d_1_o[task_1,task_2]) 
        #@constraint(m, d_1_o[task_1,task_2] + d_2_o[task_1,task_2] + o_o[task_1,task_2] == 1)    

        #@constraint(m, 1 - M* (o[task_1] - o[task_2]) <= o_o[task_1, task_2])
        #@constraint(m, o_o[task_1, task_2] >= 1 + M * (o[task_1] - o[task_2]))

        #@constraint(m, o_m[task_1, task_2] => { machine[task_1] - machine[task_2] == 0 })
        #@constraint(m, o_o[task_1, task_2] => { o[task_1] - o[task_2] == 0 })
        end
end

# Adding sequencing constraints
end_jobs_tasks = [0 for n=jobs]
for job in dict["jobs"]
    # All jobs start after the release_date
    @constraint(model, b[job["sequence"][1]] >= job["release_date"])
    for tf in 2:length(job["sequence"])
        # All tasks of a job come one after the other
        @constraint(model, b[job["sequence"][tf]] >= b[job["sequence"][tf-1]] + processing_times[job["sequence"][tf-1]])
    end
    last_task = job["sequence"][length(job["sequence"])]
    d = job["due_date"]
    end_jobs_tasks[job["job"]] = last_task
    # The U delay is 1 if the job finishes after the due date (not sure if it is correct, must redo)
    #@constraint(m, b[last_task] + processing_times[last_task] - d <= M*U[last_task])
    @constraint(model, b[job["job"]] + processing_times[job["job"]] >= d + 1 - M*(1-U[job["job"]]))
    @constraint(model, b[job["job"]] + processing_times[job["job"]] <= d + M*U[job["job"]])

    
    #@constraint(model, U[job["job"]] => { b[last_task] + processing_times[last_task] - d >= 1})
end


# Setting the objective
alpha = dict["parameters"]["costs"]["unit_penalty"]
beta = dict["parameters"]["costs"]["tardiness"]

function C(job)
    return b[end_jobs_tasks[job]] + processing_times[end_jobs_tasks[job]]
end

function T(job) 
    return U[job] * (C(job) - dict["jobs"][job]["due_date"])
end

function W(job)
    return dict["jobs"][job]["weight"]
end

@objective(model, Min, sum( W(job)*(C(job) + alpha * U[job] + beta * T(job)) for job = jobs))

#print(model)
# Solving the optimization problem
JuMP.optimize!(model)

# Printing the optimal solutions obtained and creating the json file
println("Optimal Solutions:")
results = []
for task in 1:nb_tasks
    task_machine = -1
    task_operator = -1
    print("b",task,": ", JuMP.value(b[task]), " ")
    for machine in 1:nb_machines
        if JuMP.value(m[task, machine]) == 1
            print("m",task,": ", machine, " ")
            task_machine = machine
        end
        for operator in 1:nb_operators
            if JuMP.value(o[task, machine, operator]) == 1
                println("o",task,": ", operator, " ")
                task_operator = operator
            end
        end
    end
    task_result = Dict("task" => task, "start"=> JuMP.value(b[task]), "machine"=>task_machine, "operator"=>task_operator)
    push!(results, task_result)
end

# Writing it in a json file
open("KIRO-small-sol_23.json", "w") do f
    JSON.print(f, results)
end

