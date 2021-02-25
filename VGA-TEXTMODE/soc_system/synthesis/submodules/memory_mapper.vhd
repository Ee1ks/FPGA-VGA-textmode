library ieee;
use ieee.std_logic_1164.all;

entity memory_mapper is
    generic(
        ADDR_WIDTH : natural := 8;
        DATA_WIDTH : natural := 8
    );
	port(
		clk           : in std_logic;
		reset	      : in std_logic;
		-- avalon MM interface input
        writereq_in   : in std_logic;
		readreq_in    : in std_logic;
		address_in    : in std_logic_vector(ADDR_WIDTH-1 downto 0);
		writedata_in  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		readdata_in   : out std_logic_vector(DATA_WIDTH-1 downto 0);
		-- avalon MM interface output
		writereq_out  : out std_logic;
		readreq_out   : out std_logic;
		address_out   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		writedata_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
		readdata_out  : in  std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity;

architecture RTL of memory_mapper is
begin
	-- mapping
	writereq_out  <= writereq_in;
	readreq_out   <= readreq_in;
	address_out   <= address_in;
	writedata_out <= writedata_in;
	readdata_in   <= readdata_out;

end architecture;
