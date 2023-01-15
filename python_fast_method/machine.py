"""
Machine class
"""

class Machine:
    def __init__(self, number, tasks) -> None:
        self.number = number
        self.available = True
        self.tasks = tasks
