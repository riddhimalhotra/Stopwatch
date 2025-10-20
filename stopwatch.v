`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// Engineer: Riddhi Malhotra , Satyam , Nikhil 


// Module Name: stop_watch

module top(
    input clk_100MHz,           // 100MHz from Nexys A7
    input reset,                // btnC
    input start,                // btnU
    input stop,                 // btnD
    output [0:6] seg,           // 7 segments
    output dp,                  // decimal point
    output [7:0] an             // 8 anodes
    );
    
    wire [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s, sec100_10s, sec100_1s;
    
    stop_watch sw(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .start(start),
        .stop(stop),
        .hr_10s(hr_10s), 
        .hr_1s(hr_1s), 
        .min_10s(min_10s), 
        .min_1s(min_1s), 
        .sec_10s(sec_10s), 
        .sec_1s(sec_1s), 
        .sec100_10s(sec100_10s), 
        .sec100_1s(sec100_1s)
        );
    
    seg_display_driver sdd(
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .hr_10s(hr_10s), 
        .hr_1s(hr_1s), 
        .min_10s(min_10s), 
        .min_1s(min_1s), 
        .sec_10s(sec_10s), 
        .sec_1s(sec_1s), 
        .sec100_10s(sec100_10s), 
        .sec100_1s(sec100_1s),
        .seg(seg),
        .dp(dp),       
        .digit(an)      
        );
    
    
endmodule

module stop_watch(
    input clk_100MHz,
    input reset,
    input start,
    input stop,
    output [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s, sec100_10s, sec100_1s
    );
    
    // Button Debouncing
    reg a, b, c, d, e, f;
    wire w_start, w_stop;
    
    always @(posedge clk_100MHz) 
    begin
        a <= start;
        b <= a;
        c <= b;                
    end
    assign w_start = c;
    
    always @(posedge clk_100MHz)
    begin
        d <= stop;
        e <= d;
        f <= e;
    end
    assign w_stop = f;
    
    // Start/Stop register
    reg ss = 0;
    wire w_ss;

    // Start/Stop register control, it is essentially an SR Latch
    always @*
        if(w_start)
            ss = 1;
        else if(w_stop)
            ss = 0;
    
    assign w_ss = ss;
    
    // Create the 100 Hz generator to drive the counters
    reg [18:0] ctr_reg = 0; // 19 bits to cover 500,000
    reg r_100Hz = 0;
    wire clk_100Hz;
    
    always @(posedge clk_100MHz or posedge reset)
        if(reset) begin
            ctr_reg <= 0;
            r_100Hz <= 0;
        end
        else
            if(ctr_reg == 499_999) begin  // 100MHz / 100Hz / 2 = 500,000
                ctr_reg <= 0;
                r_100Hz <= ~r_100Hz;
            end
            else
                ctr_reg <= ctr_reg + 1;
    
    assign clk_100Hz = r_100Hz;
    
    // Registers for each counter
    reg [6:0] sec100_ctr = 0;
    reg [5:0] sec_ctr = 0;
    reg [5:0] min_ctr = 0;
    reg [6:0] hr_ctr = 0;
    
    // 1/100s of seconds reg control
    always @(posedge clk_100Hz or posedge reset)
        if(reset)
            sec100_ctr = 0;
        else
            if(w_ss)
                if(sec100_ctr == 99)
                    sec100_ctr <= 0;
                else
                    sec100_ctr <= sec100_ctr + 1;
       
    // seconds reg control            
    always @(posedge clk_100Hz or posedge reset)
        if(reset)
            sec_ctr = 0;
        else
            if(w_ss)
                if(sec100_ctr == 99)
                    if(sec_ctr == 59)
                        sec_ctr <= 0;
                    else
                        sec_ctr <= sec_ctr + 1;    
    
    // minutes reg control            
    always @(posedge clk_100Hz or posedge reset)
        if(reset)
            min_ctr = 0;
        else
            if(w_ss)
                if(sec100_ctr == 99 && sec_ctr == 59)
                    if(min_ctr == 59)
                        min_ctr <= 0;
                    else
                        min_ctr <= min_ctr + 1;  
                    
    // hours reg control            
    always @(posedge clk_100Hz or posedge reset)
        if(reset)
            hr_ctr = 0;
        else
            if(w_ss)
                if(sec100_ctr == 99 && sec_ctr == 59 && min_ctr == 59)
                    if(hr_ctr == 99)
                        hr_ctr <= 0;
                    else
                        hr_ctr <= hr_ctr + 1;  
                    
    // Binary to BCD conversion for output signals
    assign sec100_10s = sec100_ctr / 10;
    assign sec100_1s  = sec100_ctr % 10;
    assign sec_10s    = sec_ctr / 10;
    assign sec_1s     = sec_ctr % 10;
    assign min_10s    = min_ctr / 10;
    assign min_1s     = min_ctr % 10;
    assign hr_10s     = hr_ctr / 10;
    assign hr_1s      = hr_ctr % 10;
    
    
endmodule

module seg_display_driver(
    input clk_100MHz,
    input reset,
    input [3:0] hr_10s, hr_1s, min_10s, min_1s, sec_10s, sec_1s, sec100_10s, sec100_1s,
    output reg [0:6] seg,       // segment pattern 0-9
    output reg dp,              // decimal point
    output reg [7:0] digit      // digit select signals
    );

    // Parameters for segment patterns
    parameter ZERO  = 7'b000_0001;  // 0
    parameter ONE   = 7'b100_1111;  // 1
    parameter TWO   = 7'b001_0010;  // 2 
    parameter THREE = 7'b000_0110;  // 3
    parameter FOUR  = 7'b100_1100;  // 4
    parameter FIVE  = 7'b010_0100;  // 5
    parameter SIX   = 7'b010_0000;  // 6
    parameter SEVEN = 7'b000_1111;  // 7
    parameter EIGHT = 7'b000_0000;  // 8
    parameter NINE  = 7'b000_0100;  // 9
    
    // To select each digit in turn
    reg [2:0] digit_select;     // 3 bit counter for selecting each of 8 digits
    reg [16:0] digit_timer;     // counter for digit refresh
    
    // Logic for controlling digit select and digit timer
    always @(posedge clk_100MHz or posedge reset) begin
        if(reset) begin
            digit_select <= 0;
            digit_timer <= 0; 
        end
        else                                        
            if(digit_timer == 99_999) begin       
                digit_timer <= 0;
                digit_select <=  digit_select + 1;
            end
            else
                digit_timer <=  digit_timer + 1;
    end
    
    // Logic for driving the 8 bit anode output based on digit select
    always @(digit_select) begin
        case(digit_select) 
            3'b000 : digit = 8'b11111110;   // 1/100th of second ones  
            3'b001 : digit = 8'b11111101;   // 1/100th of second tens   
            3'b010 : digit = 8'b11111011;   // second ones
            3'b011 : digit = 8'b11110111;   // second tens          
            3'b100 : digit = 8'b11101111;   // minute ones       
            3'b101 : digit = 8'b11011111;   // minute tens             
            3'b110 : digit = 8'b10111111;   // hours ones     
            3'b111 : digit = 8'b01111111;   // hours tens     
        endcase
    end
    
    // Logic for driving segments based on which digit is selected and the value of each digit
    // Added drivers for the decimal point to appear on some digits
    always @*
        case(digit_select)
            3'b000 : begin       // 1/100 of Seconds 1s DIGIT
                        dp = 1'b1;
                        case(sec100_1s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b001 : begin       // 1/100 of Seconds 10s DIGIT
                        dp = 1'b1;
                        case(sec100_10s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b010 : begin       // Seconds 1s DIGIT
                        dp = 1'b0;
                        case(sec_1s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b011 : begin       // Seconds 10s DIGIT
                        dp = 1'b1;
                        case(sec_10s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
           3'b100 : begin       // Minute 1s DIGIT
                        dp = 1'b0;
                        case(min_1s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b101 : begin       // Minute 10s DIGIT
                        dp = 1'b1;
                        case(min_10s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b110 : begin       // Hour 1s DIGIT
                        dp = 1'b0;
                        case(hr_1s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            3'b111 : begin       // Hour 10s DIGIT
                        dp = 1'b1;
                        case(hr_10s)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end 
        endcase   
  
endmodule