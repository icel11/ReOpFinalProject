"""
Task class
"""
import random as r

class Task:

    def __init__(self, number, processing_time, machines, previous_tasks, release_date, due_date) -> None:
        self.number = number
        self.previous_tasks = previous_tasks
        self.processing_time = processing_time
        self.useful_machines = machines
        self.finished = False
        self.current_machine = -1
        self.current_operator = -1
        self.release_date = release_date
        self.due_date = due_date
        self.start_date = -1

    def is_available(self, finished_tasks, date, available_machines, available_operators):
        if self.finished or self.current_machine > 0:
            return False
        if self.release_date > date or not set(self.previous_tasks).issubset(set(finished_tasks)):
            return False
        available_operator_and_machine = False
        useful_machines =  [m["machine"] for m in self.useful_machines]
        for machine in (m for m in useful_machines if m in available_machines):
            useful_operators = []
            for m in self.useful_machines:
                if m["machine"] == machine:
                    useful_operators = [o for o in m["operators"]]
            if len([o for o in useful_operators if o in available_operators]) > 0:
                available_operator_and_machine = True
        if not available_operator_and_machine:
            return False
        return True

    def start(self, date, machines, operators):
        available_machines = [m.number for m in machines if m.available]
        available_operators = [o.number for o in operators if o.available]
        useful_machines =  [m["machine"] for m in self.useful_machines]
        for machine in (m for m in useful_machines if m in available_machines):
            useful_operators = []
            for m in self.useful_machines:
                if m["machine"] == machine:
                    useful_operators = [o for o in m["operators"]]
            useful_operators = [o for o in useful_operators if o in available_operators]
            #print("Task", self.number, "useful machines:", useful_machines, "C machine", machine, "useful operators", useful_operators)
            if len(useful_operators) > 0:
                #print(machine, useful_operators[0])
                self.current_machine = machine
                self.current_operator = useful_operators[0]
                self.start_date = date
                machines[self.current_machine-1].available = False
                operators[self.current_operator-1].available = False
                print('Starts:', self.number)
                return machines, operators
        
        print("ERROR!!!")
        return machines, operators

    def update(self, machines, operators):
        if self.current_machine > 0:
            self.processing_time -= 1
            if self.processing_time == 0:
                self.finished = True
                machines[self.current_machine-1].available = True
                operators[self.current_operator-1].available = True
                print('Finishes:', self.number)
        return machines, operators
    
    def __lt__(self, other):
        return self.number < other.number
