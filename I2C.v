// fundamental I2C

module i2c_controller(
    input wire clk,        // Sistem saat sinyali
    input wire reset,      // Sistem sıfırlama sinyali
    output wire scl,       // Seri Saat Hattı
    inout wire sda         // Seri Veri Hattı
);

    // I2C durum makinemizin durumları
    reg [2:0] state;
    parameter IDLE = 3'b000;   // Bekleme durumu
    parameter START = 3'b001;  // Başlatma durumu
    parameter WRITE = 3'b010;  // Yazma durumu
    parameter READ = 3'b011;   // Okuma durumu
    parameter STOP = 3'b100;   // Durdurma durumu

    // I2C ile iletişim için kullanılan sayaçlar ve veri depolama
    reg [7:0] data_out;     // Veri gönderme verisi
    reg [7:0] data_in;      // Veri alma verisi
    reg [2:0] bit_counter;  // Bit sayacı

    // I2C kontrol sinyalleri
    wire scl_pulse;        // SCL darbesi
    wire shift_data;        // Veri kaydırma işareti

    // I2C saat hızını ayarlamak için parametre
    parameter SCL_PERIOD = 10; // I2C saat döngü süresi (örneğin, 10 birim)

    // I2C kontrol sinyali ile serbest bırakma (tri-state) hattı
    assign sda_tri = (state == IDLE || state == READ) ? 1 : 0;

    // I2C saat sinyalini oluşturun (SCL)
    always @(posedge clk) begin
        if (reset) begin
            scl <= 1;
        end else begin
            if (scl_pulse) begin
                scl <= ~scl;
            end
        end
    end

    // I2C durum makinesi
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_counter <= 0;
            data_out <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    if (shift_data) begin
                        state <= START;
                    end
                end
                START: begin
                    if (!scl && sda) begin
                        state <= WRITE;
                        bit_counter <= 7;
                    end
                end
                WRITE: begin
                    if (scl_pulse) begin
                        if (bit_counter == 0) begin
                            if (shift_data) begin
                                state <= STOP;
                            end else begin
                                state <= READ;
                            end
                        end
                    end
                end
                READ: begin
                    if (scl_pulse) begin
                        if (bit_counter == 0) begin
                            state <= STOP;
                        end
                    end
                end
                STOP: begin
                    if (scl && sda) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // SCL darbelerini oluşturun
    assign scl_pulse = (state == START || state == WRITE || state == READ || state == STOP) && !reset;

    // Veri kaydırma işareti kontrolü
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_data <= 0;
        end else begin
            if (state == WRITE && bit_counter == 0) begin
                shift_data <= 1;
            end else if (state == READ && bit_counter == 0) begin
                shift_data <= 1;
            end else begin
                shift_data <= 0;
            end
        end
    end

    // Veri gönderme ve alma mantığı
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in <= 8'h00;
        end else begin
            if (state == WRITE && !scl && !sda) begin
                data_in[bit_counter] <= sda;
                bit_counter <= bit_counter - 1'b1;
            end else if (state == READ && !scl && sda) begin
                data_out[bit_counter] <= 0; // Gerçek veri buradan okunur
                bit_counter <= bit_counter - 1'b1;
            end
        end
    end

endmodule
