"""
Task class
"""

class Task:

    def __init__(self, number, processing_time, machines, previous_tasks, release_date, due_date) -> None:
        self.number = number
        self.previous_tasks = previous_tasks
        self.processing_time = processing_time
        self.machines = machines
        self.finished = False
        self.current_machine = -1
        self.current_operator = -1
        self.release_date = release_date
        self.due_date = due_date
        self.start_date = -1

    def is_available(self, finished_tasks, date):
        if self.finished or self.current_machine >= 0:
            return False
        if self.release_date > date or not set(self.previous_tasks).issubset(set(finished_tasks)):
            return False
        return True

    def start(self, date, machines, operators):
        self.current_machine = 1
        self.current_operator = 1
        self.start_date = date
        machines[self.current_machine].available = False
        operators[self.current_operator].available = False
        return machines, operators

    def update(self, machines, operators):
        if self.current_machine > 0:
            self.processing_time -= 1
            if self.processing_time == 0:
                self.finished = True
                machines[self.current_machine].available = True
                operators[self.current_operator].available = True
        return machines, operators
    
    def __lt__(self, other):
        return self.number < other.number
