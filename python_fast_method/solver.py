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
            machines = task_json["machines"]
            processing_time = task_json["processing_time"]
            release_date = job["release_date"]
            due_date = job["due_date"]
            task = Task(task, processing_time, machines, previous_tasks, release_date, due_date)
            tasks.append(task)
    return tasks

def get_machines(instance):
    machines = []
    for i in range(instance["parameters"]["size"]["nb_machines"]):
        machines.append(Machine(i+1))
    return machines

def get_operators(instance):
    operators = []
    for i in range(instance["parameters"]["size"]["nb_operators"]):
        operators.append(MachineOperator(i+1))
    return operators

def exists_unfinished_task(tasks):
    for task in tasks:
        if not task.finished:
            return True
    return False

class Solver():

    def __init__(self, path):
        instance = {}
        with open(path, encoding="UTF-8") as json_file:
            instance = json.load(json_file)
        self.tasks = get_tasks(instance)
        self.machines = get_machines(instance)
        self.operators = get_operators(instance)
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

        print("Exist unfinished tasks?", exists_unfinished_task(self.tasks))
        
        results = []
        for task in self.tasks:
            print("Task:", task.number+1, "b:", task.start_date, "m:", task.current_machine, "o:", task.current_operator)
            result = {}
            result["task"] = task.number
            result["start"] = task.start_date
            result["operator"] = task.current_operator
            result["machine"] = task.current_machine
            results.append(result)
        with open("FASTttt-KIRO-large-sol.json", "w", encoding="UTF-8") as outfile:
            outfile.write(json.dumps(results, indent=4))

        

