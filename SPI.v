// Fundamental SPI with verilog
module spi_controller(
    input wire clk,            // Sistem saat sinyali
    input wire reset,          // Sistem sıfırlama sinyali
    output wire sclk,          // Seri saat sinyali
    output wire cs_n,          // Chip Select sinyali (Aktif düşük)
    output wire mosi,          // Master Out Slave In veri hattı
    input wire miso            // Master In Slave Out veri hattı
);

    // SPI durum makinemizin durumları
    reg [2:0] state;
    parameter IDLE = 3'b000;   // Bekleme durumu
    parameter TRANSMIT = 3'b001; // Veri gönderme durumu
    parameter RECEIVE = 3'b010;  // Veri alma durumu

    // SPI ile iletişim için kullanılan sayaçlar ve veri depolama
    reg [7:0] data_out;         // Veri gönderme verisi
    reg [7:0] data_in;          // Veri alma verisi
    reg [2:0] bit_counter;      // Bit sayacı
    reg clk_divider;            // SCLK bölücü

    // SPI saat hızını ayarlamak için parametre
    parameter SCLK_PERIOD = 10; // SPI saat döngü süresi (örneğin, 10 birim)

    // SPI kontrol sinyalleri
    wire sclk_pulse;            // SCLK darbesi
    wire shift_data;            // Veri kaydırma işareti

    // SPI saat sinyalini oluşturun (SCLK)
    always @(posedge clk) begin
        if (reset) begin
            sclk <= 0;
            clk_divider <= 0;
        end else begin
            clk_divider <= clk_divider + 1'b1;
            if (clk_divider == SCLK_PERIOD / 2) begin
                sclk <= 1;
            end else if (clk_divider == SCLK_PERIOD) begin
                sclk <= 0;
                clk_divider <= 0;
            end
        end
    end

    // SPI durum makinesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_counter <= 0;
            data_out <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    cs_n <= 1; // CS yüksek (devre pasif)
                    if (shift_data) begin
                        state <= TRANSMIT;
                        bit_counter <= 7; // İlk bit'ten başla
                    end else if (miso == 0) begin
                        state <= RECEIVE;
                        bit_counter <= 7;
                    end
                end
                TRANSMIT: begin
                    if (bit_counter == 0) begin
                        state <= IDLE; // Tüm bitleri gönderdik
                    end
                end
                RECEIVE: begin
                    if (bit_counter == 0) begin
                        state <= IDLE; // Tüm bitleri aldık
                    end
                end
            endcase
        end
    end

    // MOSI (Master Out Slave In) veri hattı kontrolü
    assign mosi = (state == TRANSMIT) ? data_out[bit_counter] : 1'bZ;

    // SCLK darbelerini oluşturun
    assign sclk_pulse = (state == TRANSMIT || state == RECEIVE) && (bit_counter == 0);

    // MISO (Master In Slave Out) veri hattı kontrolü
    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            data_in <= 8'h00;
        end else begin
            if (sclk_pulse) begin
                data_in[bit_counter] <= miso;
                bit_counter <= bit_counter - 1'b1;
            end
        end
    end

    // Veri kaydırma işareti kontrolü
    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            shift_data <= 0;
        end else begin
            if (state == TRANSMIT && bit_counter == 0) begin
                shift_data <= 1;
            end else if (state == RECEIVE && bit_counter == 0) begin
                shift_data <= 1;
            end else begin
                shift_data <= 0;
            end
        end
    end

endmodule
