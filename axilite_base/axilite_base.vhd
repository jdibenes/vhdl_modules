----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/01/2020 11:52:40 AM
-- Design Name: 
-- Module Name: axilite_base - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axilite_base is
port (
    clk   : in std_logic;
    reset : in std_logic;

    -- axi-lite interface
    awvalid : in  std_logic;
    awready : out std_logic;
    awaddr  : in  std_logic_vector(7 downto 0);
    
    wvalid : in  std_logic;
    wready : out std_logic;
    wdata  : in  std_logic_vector(31 downto 0);
    wstrb  : in  std_logic_vector(3 downto 0);
    
    bvalid : out std_logic;
    bready : in  std_logic;
    bresp  : out std_logic_vector(1 downto 0);
    
    arvalid : in  std_logic;
    arready : out std_logic;
    araddr  : in  std_logic_vector(7 downto 0);
    
    rvalid : out std_logic;
    rready : in  std_logic;
    rdata  : out std_logic_vector(31 downto 0);
    rresp  : out std_logic_vector(1 downto 0);
    
    -- add your signals here
    reg0_out : out std_logic_vector(31 downto 0);
    reg1_out : out std_logic_vector(31 downto 0);
    reg1_in  : in  std_logic_vector(31 downto 0);
    
    stb0_out : out std_logic  
);
end axilite_base;

architecture behavioral of axilite_base is
-- write channel ---------------------------------------------------------------
type axiw_state is (axiw_reset, axiw_addr, axiw_data, axiw_resp);

signal wstate      : axiw_state := axiw_reset;
signal wstate_next : axiw_state := axiw_reset;

signal hs_waddr : std_logic := '0';
signal hs_wdata : std_logic := '0';

signal waddr : std_logic_vector(7 downto 0);

-- read channel ----------------------------------------------------------------
type axir_state is (axir_reset, axir_addr, axir_data);

signal rstate      : axir_state := axir_reset;
signal rstate_next : axir_state := axir_reset;

signal hs_raddr : std_logic := '0';

-- registers -------------------------------------------------------------------
-- add your registers here
signal reg0 : std_logic_vector(31 downto 0);
signal reg1 : std_logic_vector(31 downto 0);

signal stb0 : std_logic;
--------------------------------------------------------------------------------
begin
-- write channel fsm -----------------------------------------------------------
wsel : process(wstate, awvalid, wvalid, bready)
begin
    awready <= '0'; hs_waddr <= '0'; wstate_next <= wstate;
    wready  <= '0'; hs_wdata <= '0';
    bvalid  <= '0';
    
    case (wstate) is
    when axiw_addr => awready <= '1'; if (awvalid = '1') then hs_waddr <= '1'; wstate_next <= axiw_data; end if;
    when axiw_data => wready  <= '1'; if (wvalid  = '1') then hs_wdata <= '1'; wstate_next <= axiw_resp; end if;
    when axiw_resp => bvalid  <= '1'; if (bready  = '1') then                  wstate_next <= axiw_addr; end if;
    when others    =>                                                          wstate_next <= axiw_addr;
    end case;
end process;

bresp <= "00";

wfsm : process(clk)
begin
    if (rising_edge(clk)) then
        if (reset = '1') then wstate <= axiw_reset; else wstate <= wstate_next; end if;
    end if;
end process;

waddr_reg : process(clk)
begin
    if (rising_edge(clk)) then
        if (hs_waddr = '1') then waddr <= awaddr; end if;
    end if;
end process;

-- read channel fsm ------------------------------------------------------------
rsel : process(rstate, arvalid, rready)
begin
    arready <= '0'; hs_raddr <= '0'; rstate_next <= rstate;
    rvalid  <= '0';
    
    case (rstate) is
    when axir_addr => arready <= '1'; if (arvalid = '1') then hs_raddr <= '1'; rstate_next <= axir_data; end if;
    when axir_data => rvalid  <= '1'; if (rready  = '1') then                  rstate_next <= axir_addr; end if;
    when others    =>                                                          rstate_next <= axir_addr;
    end case;
end process;

rresp <= "00";

rfsm : process(clk)
begin
    if (rising_edge(clk)) then
        if (reset = '1') then rstate <= axir_reset; else rstate <= rstate_next; end if;
    end if;
end process;

-- registers -------------------------------------------------------------------
-- add your strobes and registers here  
-- registers must be 4-byte aligned (00h, 04h, 08h, 0Ch ...)

-- strobe example (e.g. start signal)
stb0 <= '1' when hs_wdata = '1' and waddr = x"00" and wdata(0) = '1' else '0';

-- register example
wdata_reg : process(clk)
begin
    if (rising_edge(clk)) then
        if (hs_wdata = '1') then
            case (waddr) is
            when x"00" => reg0 <= wdata;
            when x"04" => reg1 <= wdata;
            when others =>
            end case;
        end if;
    end if;
end process;

rdata_reg : process(clk)
begin
    if (rising_edge(clk)) then
        if (hs_raddr = '1') then
            case (araddr) is
            when x"00"  => rdata <= reg0;
            when x"04"  => rdata <= reg1_in;
            when others => rdata <= (others => '1');
            end case;
        end if;
    end if;
end process;

-- outputs
reg0_out <= reg0;
reg1_out <= reg1;
stb0_out <= stb0;

--------------------------------------------------------------------------------
end behavioral;
