"""
Solver class
"""
import json
from task import Task
from machine import Machine
from machine_operator import MachineOperator

def get_tasks(instance):
    tasks = []
    for job in instance["jobs"]:
        for task_job_index, task in enumerate(job["sequence"]):
            previous_tasks = job["sequence"][0:task_job_index]
            task_json = instance["tasks"][task-1]
            processing_time = task_json["processing_time"]
            next_tasks = job["sequence"][task_job_index:len(job["sequence"])]
            next_tasks_time = processing_time
            for next_task in next_tasks:
                next_tasks_time += instance["tasks"][next_task-1]["processing_time"]
            machines = task_json["machines"]
            release_date = job["release_date"]
            due_date = job["due_date"]
            weight = job["weight"]
            task = Task(task, processing_time, next_tasks_time, machines, previous_tasks, release_date, due_date, weight)
            tasks.append(task)
    return tasks

def get_machines(instance):
    machines = []
    for i in range(instance["parameters"]["size"]["nb_machines"]):
        tasks = 0
        for task in instance["tasks"]:
            for machine in task["machines"]:
                if machine["machine"] == i+1:
                    tasks += 1
        machines.append(Machine(i+1, tasks))
    return machines

def get_operators(instance):
    operators = []
    for i in range(instance["parameters"]["size"]["nb_operators"]):
        tasks = 0
        for task in instance["tasks"]:
            for machine in task["machines"]:
                for operator in machine["operators"]:
                    if operator == i+1:
                        tasks += 1
        operators.append(MachineOperator(i+1, tasks))
    return operators

def exists_unfinished_task(tasks):
    for task in tasks:
        if not task.finished:
            return True
    return False

class Solver():

    def __init__(self, path):
        self.instance = {}
        with open(path, encoding="UTF-8") as json_file:
            self.instance = json.load(json_file)
        self.tasks = get_tasks(self.instance)
        self.machines = get_machines(self.instance)
        self.operators = get_operators(self.instance)
        self.date = 0

    def get_finished_tasks(self):
        finished_tasks = []
        for task in self.tasks:
            if task.finished:
                finished_tasks.append(task.number)
        return finished_tasks
    
    def get_available_tasks(self):
        finished_tasks = self.get_finished_tasks()
        available_tasks = []
        available_machines = [m.number for m in self.machines if m.available]
        available_operators = [o.number for o in self.operators if o.available]
        for task in self.tasks:
            if task.is_available(finished_tasks, self.date, available_machines, available_operators):
                available_tasks.append(task)
       # print("Available:", available_tasks)
        return available_tasks

    def solve(self):
        while exists_unfinished_task(self.tasks) and self.date < 2000:
            available_tasks = self.get_available_tasks()
            while len(available_tasks) > 0:
                available_tasks.sort()
                self.machines, self.operators = available_tasks[0].start(self.date, self.machines, self.operators)
                available_tasks = self.get_available_tasks()
            self.date += 1
            for task in self.tasks:
                if not task.finished:
                    self.machines, self.operators = task.update(self.machines, self.operators)        
        results = []
        for task in self.tasks:
            #print("Task:", task.number+1, "b:", task.start_date, "m:", task.current_machine, "o:", task.current_operator)
            result = {}
            result["task"] = task.number
            result["start"] = task.start_date
            result["operator"] = task.current_operator
            result["machine"] = task.current_machine
            results.append(result)
        
        return results

    def cost(self, results):
        cost = 0
        alfa = self.instance["parameters"]["costs"]["unit_penalty"]
        beta = self.instance["parameters"]["costs"]["tardiness"]
        for job in self.instance["jobs"]:
            last_task_index = job["sequence"][-1]
            last_task = self.instance["tasks"][last_task_index-1]
            completion_time = 0
            for result in results:
                if result["task"] == last_task_index:
                    completion_time = result["start"] + last_task["processing_time"]

            is_late = completion_time > job["due_date"]
            tardiness = completion_time - job["due_date"] if is_late else 0

            cost += job["weight"] * (completion_time + alfa * is_late + beta * tardiness)
        return cost

        

