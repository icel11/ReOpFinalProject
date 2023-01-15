"""
Operator class
"""

class MachineOperator:
    def __init__(self, number, tasks) -> None:
        self.number = number
        self.available = True
        self.tasks = tasks