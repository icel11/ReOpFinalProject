"""
Task class
"""
import random as r

class Task:

    def __init__(self, number, processing_time, next_tasks_time, machines, previous_tasks, release_date, due_date, weight) -> None:
        self.number = number
        self.previous_tasks = previous_tasks
        self.next_tasks_time = next_tasks_time
        self.processing_time = processing_time
        self.useful_machines = machines
        self.finished = False
        self.current_machine = -1
        self.current_operator = -1
        self.release_date = release_date
        self.due_date = due_date
        self.start_date = -1
        self.weight = weight

    def is_available(self, finished_tasks, date, available_machines, available_operators):
        if self.finished or self.current_machine > 0:
            return False
        if self.release_date > date or not set(self.previous_tasks).issubset(set(finished_tasks)):
            return False
        useful_machines =  [m["machine"] for m in self.useful_machines]
        #useful_machines_with_operators = []
        for machine in (m for m in useful_machines if m in available_machines):
            useful_operators = []
            for m in self.useful_machines:
                if m["machine"] == machine:
                    useful_operators = [o for o in m["operators"]]
            useful_operators = [o for o in useful_operators if o in available_operators]
            #print("Task", self.number, "useful machines:", useful_machines, "C machine", machine, "useful operators", useful_operators)
            if len(useful_operators) > 0:
                #useful_machines_with_operators.append([machine, useful_operators])
                return True
                #print(machine, useful_operators[0])
        return False
        #return useful_machines_with_operators

    def start(self, date, machines, operators):
        available_machines = [m.number for m in machines if m.available]
        available_operators = [o.number for o in operators if o.available]
        useful_machines =  [m["machine"] for m in self.useful_machines]
        useful_machines_with_operators = []
        for machine in (m for m in useful_machines if m in available_machines):
            useful_operators = []
            for m in self.useful_machines:
                if m["machine"] == machine:
                    useful_operators = [o for o in m["operators"]]
            useful_operators = [o for o in useful_operators if o in available_operators]
            #print("Task", self.number, "useful machines:", useful_machines, "C machine", machine, "useful operators", useful_operators)
            if len(useful_operators) > 0:
                useful_machines_with_operators.append([machine, useful_operators])
                #print(machine, useful_operators[0])
        
        #useful_machines_with_operators.sort(key = lambda m: machines[m[0] - 1].tasks)
        #self.current_machine = useful_machines_with_operators[0][0]
        #operators_for_machine = useful_machines_with_operators[0][1]
        #operators_for_machine.sort(key=lambda o: operators[o - 1].tasks)
        #self.current_operator = operators_for_machine[0]
        chosen_pair = r.choice(useful_machines_with_operators)
        self.current_machine = chosen_pair[0]
        self.current_operator = r.choice(chosen_pair[1])
        self.start_date = date
        machines[self.current_machine-1].available = False
        operators[self.current_operator-1].available = False

        return machines, operators

    def update(self, machines, operators):
        if self.current_machine > 0:
            self.processing_time -= 1
            if self.processing_time == 0:
                self.finished = True
                machines[self.current_machine-1].available = True
                operators[self.current_operator-1].available = True
        return machines, operators

    def lost(self, date):
        return self.weight*(max(self.due_date - date, 0))

    def __lt__(self, other):
        #return r.choice([True, False])
        return self.due_date+self.next_tasks_time < (other.due_date+other.next_tasks_time)
        #if self.due_date-next_time_date == other.due_date:
        #    return self.weight < other.weight
        #return self.due_date < other.due_date
