"""
This code is used to parse an KIRO instance and find a solution in an heuristic way
"""
from solver import Solver

PATH = './instances/KIRO-tiny.json'

if __name__ == "__main__":
    solver = Solver(PATH)
    solver.solve()
