module uart_tx 
  (
   input clk,
   input       i_Tx_DV,   //datanin geldigini belirten input  
   input [7:0] i_Tx_Byte, //aktarilmak istenilen 8 bitlik input data, amac datayi paralel olarak verip seri ?ikti almak
   output      o_Tx_Active, //datanin geldigini belirten output   
   output reg  o_Tx_Serial, //seri output 
   output      o_Tx_Done    //data paketinin aktarildigini belirten parametre
   );


///baud rate 921600 ve clock frekansi 100 MHz dolayisiyla clock_per_bit=100000000/921600=108.5 yani bir data biti toplam 109 clock s?recek

  parameter CLKS_PER_BIT   = 434; // 50MHz 115200
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
   
  reg [2:0]    r_SM_Main     = 0;
  reg [15:0]   r_Clock_Count = 0;    //[7:0] dan [15:0] a y?kseltildi.
  reg [2:0]    r_Bit_Index   = 0;
  reg [7:0]    r_Tx_Data     = 0;
  reg          r_Tx_Done     = 0;
  reg          r_Tx_Active   = 0;
     
  always @(posedge clk)
    begin
    
      case (r_SM_Main)
        s_IDLE :
          begin
            o_Tx_Serial   <= 1'b1;         // default olarak seri output hep high
            r_Tx_Done     <= 1'b0;          
            r_Clock_Count <= 0;
            r_Bit_Index   <= 0;
             
            if (i_Tx_DV == 1'b1)            //input Tx_dv data geldigini belirtiyor
              begin
                r_Tx_Active <= 1'b1;
                r_Tx_Data   <= i_Tx_Byte;
                r_SM_Main   <= s_TX_START_BIT;  //i_Tx_dv 1 ise start basliyor
              end
            else
              r_SM_Main <= s_IDLE;      //i_Tx_dv 1 degilse idle devam ediyor
          end // case: s_IDLE
         
         
        // start basladi, start biti 0
        s_TX_START_BIT :
          begin
            o_Tx_Serial <= 1'b0; 
             
            // clock per bit kadar bekliycek bu sekilde yani 109 clock
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_START_BIT;
              end
            else
              begin
                r_Clock_Count <= 0;
                r_SM_Main     <= s_TX_DATA_BITS;    //burada data bitlerine gecis basliyor
              end
          end // case: s_TX_START_BIT
         
         
        // CLKS_PER_BIT-1 clock kadar bekliyor bir data biti icin ve toplam her pakette 8 data biti var         
        s_TX_DATA_BITS :
          begin
            o_Tx_Serial <= r_Tx_Data[r_Bit_Index];
             
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count <= 0;
                 
                // Check if we have sent out all bits
                if (r_Bit_Index < 7) //0'dan 7'ye kadar toplam 8 biti sirasiyla aktariyor least'den most'a dogru
                  begin 
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_SM_Main   <= s_TX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    r_SM_Main   <= s_TX_STOP_BIT;  // en son stop bite geciyor
                  end
              end
          end // case: s_TX_DATA_BITS
         
         
        // stop biti yoluyor.  Stop bit = 1
        s_TX_STOP_BIT :
          begin
            o_Tx_Serial <= 1'b1;
             
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_STOP_BIT;
              end
            else
              begin
                r_Tx_Done     <= 1'b1;
                r_Clock_Count <= 0;
                r_SM_Main     <= s_CLEANUP;
                r_Tx_Active   <= 1'b0;
              end
          end // case: s_Tx_STOP_BIT
         
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            r_Tx_Done <= 1'b1;
            r_SM_Main <= s_IDLE;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
    end
 
  assign o_Tx_Active = r_Tx_Active;
  assign o_Tx_Done   = r_Tx_Done;
   
endmodule
