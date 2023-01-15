"""
This code is used to parse an KIRO instance and find a solution in an heuristic way
"""
from solver import Solver
import json

PATH = './instances/KIRO-tiny.json'

if __name__ == "__main__":

    min_cost = 465
    for i in range(1000000):
        solver = Solver(PATH)
        results = solver.solve()
        cost = solver.cost(results)
        print("Cost:", cost)
        if cost < min_cost:
            print("Better cost!!!:", cost)
            min_cost = cost
            with open("FAST-KIRO-tiny-sol.json", "w", encoding="UTF-8") as outfile:
                outfile.write(json.dumps(results, indent=4))
