class_name Benchmark

## Runs a function and returns its execution time in milliseconds.
static func time_execution(func_ref: Callable) -> float:
	var start_time := Time.get_ticks_usec()
	func_ref.call()
	var end_time := Time.get_ticks_usec()
	
	return float(end_time - start_time) / 1000.0

## Executes a function and returns the change in memory usage in megabytes.
static func track_memory(func_ref: Callable) -> float:
	var start_mem := Performance.get_monitor(Performance.MEMORY_STATIC)
	func_ref.call()
	var end_mem := Performance.get_monitor(Performance.MEMORY_STATIC)
	
	return (end_mem - start_mem) / 1024.0 / 1024.0

## Runs a function for a specified number of [param iterations] and returns the total time in milliseconds.
static func stress_test(func_ref: Callable, iterations: int) -> float:
	var start_time := Time.get_ticks_usec()
	
	for i in range(iterations):
		func_ref.call()
		
	var end_time := Time.get_ticks_usec()
	return float(end_time - start_time) / 1000.0
