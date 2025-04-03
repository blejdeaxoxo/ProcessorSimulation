module assembler(
  input clk, rst_b,           
  output reg valid,
  output reg [15:0] data
);
  integer file;
  integer status;
  reg [127:0] line;
  reg [15:0] datain;

  initial begin
    file = $fopen("machine_code.txt", "r");
    if (file == 0) begin
      $display("Eroare: Nu s-a putut deschide fișierul.");
      $finish;
    end
    $display("Fișier deschis cu succes.");
    valid = 1'b1; 
  end

  always @(posedge clk, negedge rst_b) begin
    if (!rst_b) begin
      if (file != 0) $fclose(file);
      valid <= 1'b0;
      data <= 16'b0;
    end else if (valid) begin
      if (!$feof(file)) begin
        status = $fgets(line, file);
	$fgetc(file);
        if (status) begin
          status = $sscanf(line, "%b", datain);
          if (status == 1) begin
		data <= datain;
		valid <= 1'b1;
            $display("Ciclu: Linia citită: %b", datain);
          end else begin
            $display("Eroare la conversia liniei: %s", line);
            valid <= 1'b0;
	$fclose(file);
        $display("Fișier închis.");
          end
        end
      end else begin
        valid <= 1'b0;
        $fclose(file);
        $display("Fișier închis.");
      end
    end
  end
endmodule