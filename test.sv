module test #(
  parameter real Tstart = 10e-6,
  parameter real Tstop = 60e-6
);
  timeunit 1ns;
  timeprecision 1ps;

  real xout;
  xtal_osc dut (.xout);

  integer fh;
  initial begin
    #(Tstart*1s);
    fh = $fopen("xout.csv", "w");
    $fdisplay(fh, "time,xout");
    while ($realtime() < (Tstop*1s)) begin
      #10ns;
      $fdisplay(fh, "%.4e, %.4e", $realtime()/1s, xout);
    end
    $finish();
  end
  
endmodule


module xtal_osc #(
  parameter real CL1 = 36e-12,
  parameter real R1 = 10,
  parameter real C1 = 15e-15,
  parameter real L1 = 15e-3,
  parameter real C0 = 5e-12,
  parameter real Gain = 20,
  parameter real Vdd = 3.3,
  parameter real InitialVC1 = 0,
  parameter real InitialVCL = Vdd/2,
  parameter real InitialIL1 = -10e-9,
  parameter real Tstep = 100e-12
)(
  output var real xout
);
  timeunit 1ns;
  timeprecision 1ps;

  real vi = InitialVCL;
  real vo = InitialVCL;
  real il1 = InitialIL1;
  real vc1 = InitialVC1;

  function automatic real f (
    input real vi
  );
    return (Vdd/2) * (1 - $tanh(Gain*(vi - (Vdd/2))));
  endfunction

  function automatic real f_prime (
    input real vi
  );
    real x = Gain * (vi - Vdd/2);
    real sech = 2 / ($exp(x) + $exp(-x));
    return -(Gain * Vdd / 2) * (sech**2);
  endfunction

  function automatic real dvi_dt (
    input real vi,
    input real vo,
    input real il1
  );
    return -il1 / (CL1 + C0*(1 - f_prime(vi)));
  endfunction

  function automatic real dil1_dt (
    input real vi,
    input real vo,
    input real il1,
    input real vc1
  );
    return (1/L1) * (vi - f(vi) - R1*il1 - vc1);
  endfunction

  function automatic real dvc1_dt (
    input real il1
  );
    return il1/C1;
  endfunction

  real k_vi;
  real k_il1;
  real k_vc1;

  initial begin
    forever begin
      #(Tstep * 1s);

      k_vi = dvi_dt(vi, vo, il1);
      k_il1 = dil1_dt(vi, vo, il1, vc1);
      k_vc1 = dvc1_dt(il1);
      
      vi += k_vi * Tstep;
      il1 += k_il1 * Tstep;
      vc1 += k_vc1 * Tstep;
    end
  end

  always_comb begin
    vo = f(vi);
  end

  always_comb begin
    xout = vo;
  end

endmodule