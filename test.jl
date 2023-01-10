import Pkg; Pkg.add("JuMP")
import Pkg; Pkg.add("JSON")
import Pkg; Pkg.add("SCIP")
#import Pkg; Pkg.add("Gurobi"); Pkg.build("Gurobi")

using JuMP, JSON, SCIP #, Gurobi

stringdata = join(readlines("./instances/KIRO-tiny.json"))
dict = JSON.parse(stringdata)


# Preparing an optimization model
model = Model(SCIP.Optimizer)
M_1 = 100
M_2 = -100
e = 0.01
nb_jobs = dict["parameters"]["size"]["nb_jobs"]
nb_tasks = dict["parameters"]["size"]["nb_tasks"]
nb_machines = dict["parameters"]["size"]["nb_machines"]
nb_operators = dict["parameters"]["size"]["nb_operators"]
jobs = 1:length(dict["jobs"])

# Declaring variables (integers)
@variable(model, b[1:nb_tasks], Int)
@variable(model, U[1:nb_jobs], Bin)
@variable(model, m[1:nb_tasks, 1:nb_machines], Bin)
#@variable(model, o[1:nb_tasks, 1:nb_machines, 1:nb_operators], Bin)
# (1) 1 if start 1 < end 2
@variable(model, starts_after[1:nb_tasks, 1:nb_tasks], Bin)
# (2) 1 if end 1 < start 2
@variable(model, ends_before[1:nb_tasks, 1:nb_tasks], Bin)
# Overlap in time if (1) and (2)
#@variable(m, o_t[1:nb_tasks, 1:nb_tasks], Bin)
# 1 if two tasks overlap machine, 0 else
#@variable(model, o_m[1:nb_tasks, 1:nb_tasks], Bin)
@variable(model, o_o[1:nb_tasks, 1:nb_tasks], Bin)

#@variable(m, d_1_m[1:nb_tasks, 1:nb_tasks], Bin)
#@variable(m, d_2_m[1:nb_tasks, 1:nb_tasks], Bin)
#@variable(m, d_1_o[1:nb_tasks, 1:nb_tasks], Bin)
#@variable(m, d_2_o[1:nb_tasks, 1:nb_tasks], Bin)

#@variable(m, task_i_is_machine_k[1:nb_tasks, 1:nb_machines], Bin)

#@variable(m, d_1, Bin)
#@variable(m, d_2, Bin)
#@variable(m, bla, Bin)
#@variable(m, bla2, Bin)
#@variable(m, bla3, Bin)

processing_times = [0 for n=1:length(dict["tasks"])]
for task in 1:length(dict["tasks"])
    processing_times[task] = dict["tasks"][task]["processing_time"]
end

for task in 1:length(dict["tasks"])
    available_machines = []
    available_operators = []
    for machine in dict["tasks"][task]["machines"]
        push!(available_machines, machine["machine"])
    end
    not_available_machines = []
    for machine in 1:nb_machines
        #for operator in dict["tasks"][task]["machines"][]
        #    push!(available_operators, ope)
        #end
        if !(machine in available_machines)
            @constraint(model, m[task, machine] == 0)
            #for operator in 1:nb_operators
            #    @constraint(model, o[task, machine, operator] == 0)
            #end
        else
            #for operator in 1:nb_operators
            #    if !(operator in dict["tasks"][task]["machines"][machine][])
            #        @constraint(model, o[task, machine, operator] == 0)
            #    else
            #        @constraint(model, o[task, machine, operator] <= m[task, machine])
            #    end
            #end
        end
    end


    @constraint(model, sum( m[task, machine] for machine in 1:nb_machines) == 1)
    #@constraint(model, sum( sum( o[task, machine, operator] for operator in 1:nb_operators) for machine in 1:nb_machines) == 1)

end

# Setting overlapping indicators
for task_1 in 1:length(dict["tasks"])
    for task_2 in 1:length(dict["tasks"])

        for machine in 1:nb_machines
            if task_1 != task_2
                @constraint(model, m[task_1, machine]*m[task_2, machine] + starts_after[task_1, task_2]*ends_before[task_1, task_2] <= 1)
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
        
        # Time constraints to set the overlapping constraints
        # https://cs.stackexchange.com/questions/69531/greater-than-condition-in-integer-linear-program-with-a-binary-variable
        # https://eli.thegreenplace.net/2008/08/15/intersection-of-1d-segments
        # bla2 = 1 if x2 > y1
        # bla3 = 1 if y2 > x1
        #bs = 26
        #@constraint(m, bs >= cs + 1 - M*(1 - bla))
        #@constraint(m, bs <= cs + M*(bla))
        
        @constraint(model, b[task_1] + processing_times[task_1] >= b[task_2] + 1 - M_1*(1-starts_after[task_1, task_2]))
        @constraint(model, b[task_1] + processing_times[task_1] <= b[task_2] + M_1*starts_after[task_1, task_2])
        @constraint(model, b[task_2] + processing_times[task_2] >= b[task_1] + 1 - M_1*(1-ends_before[task_1, task_2]))
        @constraint(model, b[task_2] + processing_times[task_2] <= b[task_1] + M_1*ends_before[task_1, task_2])
        #@constraint(m, starts_after[task_1, task_2] * ends_before[task_1, task_2] == o_t[task_1, task_2])

        #@constraint(m, b[task_2] >= b[task_1] + processing_times[task_1] - M * (1-starts_after[task_1, task_2]))
        #@constraint(m, b[task_2] <= b[task_1] + processing_times[task_1] - 1 + M * starts_after[task_1, task_2] ) 
        #@constraint(m, b[task_2] + processing_times[task_2] >= b[task_1] - M * (1-ends_before[task_1, task_2]))
        #@constraint(m, b[task_2] + processing_times[task_2] <= b[task_1] - 1 + M * ends_before[task_1, task_2] )
        
        #@constraint(m, starts_after[task_1, task_2] => {b[task_2] >= b[task_1] + processing_times[task_1]})
        #@constraint(m, ends_before[task_1, task_2] => {b[task_2] + processing_times[task_2] >= b[task_1]})

        # Check o_t = A and B
        #@constraint(m, o_t[task_1, task_2] == starts_after[task_1, task_2] * ends_before[task_1, task_2])
        #@constraint(m, o_t[task_1, task_2] => {starts_after[task_1, task_2] + ends_before[task_1, task_2] >= 2})
    end
end

# Adding sequencing constraints
end_jobs_tasks = [0 for n=jobs]
for job in dict["jobs"]
    # All jobs start after the release_date
    @constraint(model, b[job["sequence"][1]] >= job["release_date"])
    for tf in 2:length(job["sequence"])
        # All tasks of a job come one after the other
        @constraint(model, b[job["sequence"][tf]] >= b[job["sequence"][tf-1]] + processing_times[tf-1])
    end
    last_task = job["sequence"][length(job["sequence"])]
    d = job["due_date"]
    end_jobs_tasks[job["job"]] = last_task
    # The U delay is 1 if the job finishes after the due date
    #@constraint(m, b[last_task] + processing_times[last_task] - d <= M*U[last_task])
    @constraint(model, U[job["job"]] => { b[last_task] + processing_times[last_task] - d >= 1})
end

# Adding overlapping constraints
for task_1 in 1:length(dict["tasks"])
    for task_2 in 1:length(dict["tasks"])
        if task_1 != task_2
            #@constraint(m, o_o[task_1, task_2] + starts_after[task_1, task_2] + ends_before[task_1, task_2] <= 2)
            #@constraint(m, o_m[task_1, task_2] + starts_after[task_1, task_2] + ends_before[task_1, task_2] <= 2)
        end
    end
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

# Printing the optimal solutions obtained
println("Optimal Solutions:")
for i in 1:nb_tasks
    print("b",i,": ", JuMP.value(b[i]), " ")
    for machine in 1:nb_machines
        if JuMP.value(m[i, machine]) == 1
            println("m",i,": ", machine, " ")
        end
    end
    #println("o",i,": ", JuMP.value(o[i]))
end


