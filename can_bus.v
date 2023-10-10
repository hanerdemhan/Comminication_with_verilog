// fundamental Can-BUS
module can_controller(
    input wire clk,          // Sistem saat sinyali
    input wire reset,        // Sistem sıfırlama sinyali
    input wire can_rx,       // CAN Alıcı Veri Hattı
    output wire can_tx,      // CAN Gönderici Veri Hattı
    output wire can_tx_en    // CAN Gönderme İzni
);

    // CAN denetleyici durum makinesinin durumları
    reg [2:0] state;
    parameter IDLE = 3'b000;     // Bekleme durumu
    parameter TRANSMIT = 3'b001; // Veri gönderme durumu
    parameter RECEIVE = 3'b010;  // Veri alma durumu

    // CAN ile iletişim için kullanılan sayaçlar ve veri depolama
    reg [7:0] tx_data;         // Gönderilecek veri
    reg [7:0] rx_data;         // Alınan veri
    reg [2:0] bit_counter;     // Bit sayacı

    // CAN kontrol sinyalleri
    wire tx_data_ready;        // Gönderilecek veri hazır mı?
    wire rx_data_valid;        // Alınan veri geçerli mi?

    // CAN veri hattının tri-state kontrolü
    assign can_rx_tri = (state == TRANSMIT) ? 0 : 1'bZ;
    assign can_tx_tri = (state == RECEIVE) ? 0 : tx_data_ready;

    // CAN iletişim hızını ayarlamak için parametre
    parameter CAN_BIT_TIME = 10; // CAN bit süresi (örneğin, 10 birim)

    // CAN veri gönderme izni
    assign can_tx_en = (state == TRANSMIT) ? 1 : 0;

    // CAN veri hattını oluşturun
    assign can_tx = tx_data[bit_counter];

    // CAN denetleyici durum makinesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_counter <= 0;
            tx_data <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    if (tx_data_ready) begin
                        state <= TRANSMIT;
                        bit_counter <= 7;
                    end else if (can_rx == 0) begin
                        state <= RECEIVE;
                        bit_counter <= 7;
                    end
                end
                TRANSMIT: begin
                    if (bit_counter == 0) begin
                        state <= IDLE;
                    end
                end
                RECEIVE: begin
                    if (bit_counter == 0) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // CAN veri gönderme ve alma mantığı
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_data <= 8'h00;
        end else begin
            if (state == TRANSMIT) begin
                if (bit_counter == 0) begin
                    tx_data_ready <= 0;
                end
            end else if (state == RECEIVE) begin
                if (bit_counter == 0) begin
                    rx_data <= can_rx;
                    rx_data_valid <= 1;
                end
            end
        end
    end

endmodule
