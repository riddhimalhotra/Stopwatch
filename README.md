# Stopwatch
Design Objective :
Using the Nexys4 FPGA Development Board, design and develop a functional digital stopwatch.

❖ The stopwatch will display different units of time such as:
1 Seconds
2 Minutes
3.Hours 
❖ Stopwatch will have multiple functions such as:
 1. Start 
 2. Pause
 3. Reset


Board Layout & Controls Overview: The Nexys A7 programmable logic board has seven programmable pushbuttons and sixteen programmable switches for human-machine interfacing. 
Key Components and Their Functions:
Start (V10): Starts the stopwatch.

Stop (U11): Stops the stopwatch.

Reset (J15): Resets the stopwatch .

7-Segment Display: Dynamically displays the stopwatch time 

Auto Clock (E3): Manages automatic timing synchronization.


The Display System: The Nexys 4 board features an eight-digit seven-segment display, which dynamically updates to show the stopwatch status. The display presents elapsed hours, minutes, seconds.
Display Breakdown:
Hours – Displays elapsed hours.
Minutes – Displays elapsed minutes.
Seconds – Displays elapsed seconds.










