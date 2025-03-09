"""
    Question from Meta interview with a rideshare application as the subject

    Given a carpool ride, as a set or stream of rides (num_passengers, start_time, stop_time, id)
    Is the carpool possible given a vehicle with num_seats?

    A couple solutions:
    1. 2 loops.  recalcalulate num passengers at each state change with an inner loop..
    2. 2 loops with a reduce.  (Is basically the same as above)
    3. Use a while loop and a dictionary to maintain the passenger set
    4. Keep the current set of passengers with a filter type assignment
"""
from dataclasses import dataclass

stream = [
  {
    "id":1,
    "num_passengers":2,
    "start_time":100,
    "end_time":180
  },
  {
    "id":2,
    "num_passengers":4,
    "start_time":120,
    "end_time":160
  },
  {
    "id":3,
    "num_passengers":1,
    "start_time":180,
    "end_time":240
  },
  {
    "id":4,
    "num_passengers":2,
    "start_time":200,
    "end_time":280
  },
  {
    "id":5,
    "num_passengers":1,
    "start_time":240,
    "end_time":380
  },
  {
    "id":6,
    "num_passengers":1,
    "start_time":250,
    "end_time":300
  }
]

"""
  Could make this a little nicer by mapping to a simple container class
"""
@dataclass
class Carpool:
  id: int
  num_passengers: int
  satrt_time: int
  end_time: int

def eval_carpool(num_seats, instream):
  # Solution 1 - find the max number of passengers in the car at any time..
  max_pass = 0
  satisfiable = True
  for i in range(len(instream)):
    
    start_time=instream[i]["start_time"]
    # just count all the passengers that could be in, note need to add one to range (0th element, need to do range(1))
    passengers=0
    for j in range(0,i+1):
      if instream[j]["end_time"]>start_time:
        passengers+=instream[j]["num_passengers"]
    print(f"At stop {i} passengers is {passengers}")
    if passengers>max_pass:
      max_pass=passengers
      satisfiable = satisfiable and (max_pass <= num_seats)
  return satisfiable

print("Evaluate Carpool - full check of state")
print(f"Satisfiable? {eval_carpool(4, stream)}")
print(f"Satisfiable? {eval_carpool(7, stream)}")


def eval_carpool_filter(num_seats, instream):
  # Solution 2 - keep track of the carpools, but every time we add a new carpool
  # filter out any elements that have been dropped off
  car_pool = []
  satisfiable = True
  for i in range(len(instream)):
    
    start_time=instream[i]["start_time"]
    car_pool.append(instream[i])  # Add in the next current element, then filter to get the current state
    car_pool = [ c for c in car_pool if c["end_time"]>start_time]
    passengers = sum(map(lambda x: x["num_passengers"], car_pool))
    satisfiable = satisfiable and (passengers <= num_seats)
    print(f"Passengers now: {passengers}")
  return satisfiable

print("\n\nEvaluate Carpool Filter - full check of state")
print("Case, max=4")
print(f"Satisfiable? {eval_carpool_filter(4, stream)}")
print("Case, max=7")
print(f"Satisfiable? {eval_carpool_filter(7, stream)}")
