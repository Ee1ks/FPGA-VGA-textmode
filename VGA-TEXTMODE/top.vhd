library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;

entity top is
	port(
		-- HPS
		clk_clk                     : in    std_logic                     := 'X';             -- clk
		reset_reset_n               : in    std_logic                     := 'X';             -- reset_n
		hps_io_hps_io_usb1_inst_D0  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D0
		hps_io_hps_io_usb1_inst_D1  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D1
		hps_io_hps_io_usb1_inst_D2  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D2
		hps_io_hps_io_usb1_inst_D3  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D3
		hps_io_hps_io_usb1_inst_D4  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D4
		hps_io_hps_io_usb1_inst_D5  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D5
		hps_io_hps_io_usb1_inst_D6  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D6
		hps_io_hps_io_usb1_inst_D7  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D7
		hps_io_hps_io_usb1_inst_CLK : in    std_logic                     := 'X';             -- hps_io_usb1_inst_CLK
		hps_io_hps_io_usb1_inst_STP : out   std_logic;                                        -- hps_io_usb1_inst_STP
		hps_io_hps_io_usb1_inst_DIR : in    std_logic                     := 'X';             -- hps_io_usb1_inst_DIR
		hps_io_hps_io_usb1_inst_NXT : in    std_logic                     := 'X';             -- hps_io_usb1_inst_NXT
		hps_io_hps_io_uart0_inst_RX : in    std_logic                     := 'X';             -- hps_io_uart0_inst_RX
		hps_io_hps_io_uart0_inst_TX : out   std_logic;                                        -- hps_io_uart0_inst_TX
		memory_mem_a                : out   std_logic_vector(14 downto 0);                    -- mem_a
		memory_mem_ba               : out   std_logic_vector(2 downto 0);                     -- mem_ba
		memory_mem_ck               : out   std_logic;                                        -- mem_ck
		memory_mem_ck_n             : out   std_logic;                                        -- mem_ck_n
		memory_mem_cke              : out   std_logic;                                        -- mem_cke
		memory_mem_cs_n             : out   std_logic;                                        -- mem_cs_n
		memory_mem_ras_n            : out   std_logic;                                        -- mem_ras_n
		memory_mem_cas_n            : out   std_logic;                                        -- mem_cas_n
		memory_mem_we_n             : out   std_logic;                                        -- mem_we_n
		memory_mem_reset_n          : out   std_logic;                                        -- mem_reset_n
		memory_mem_dq               : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
		memory_mem_dqs              : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
		memory_mem_dqs_n            : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
		memory_mem_odt              : out   std_logic;                                        -- mem_odt
		memory_mem_dm               : out   std_logic_vector(3 downto 0);                     -- mem_dm
		memory_oct_rzqin            : in    std_logic                     := 'X';             -- oct_rzqin
		-- VGA
		h_sync		:	OUT	STD_LOGIC;	--horiztonal sync pulse
		v_sync		:	OUT	STD_LOGIC;	--vertical sync pulse
		n_blank		:	OUT	STD_LOGIC;	--direct blacking output to DAC
		n_sync		:	OUT	STD_LOGIC; 	--sync-on-green output to DAC
		vga_clk		: 	out	std_logic;	--CLK output
	    r,g,b   		: out std_logic_vector(7 downto 0) := (others => '0')
	);
end entity;

architecture RTL of top is

-- vga signals
signal clk_25Mhz 			: std_LOGIC;
signal column 				: integer 	:= 0;
signal row 					: integer 	:= 0;
signal disp_ena 			: std_logic := '0';
signal reset_n 			: std_logic := '1';

-- font rom signals
signal charBitInRow 		: std_logic_vector(8-1 downto 0):= (others => '0');
signal fontAddress 		: integer := 0;

-- ram signals
signal onchip_mem_address        : std_logic_vector(11 downto 0) := (others => '0');   -- onchip_mem.address
signal onchip_mem_write          : std_logic;            										--           .write
signal onchip_mem_readdata       : std_logic_vector(7 downto 0);         					--           .readdata
signal onchip_mem_writedata		: std_logic_vector(7 downto 0);								--           .writedata

--position variables
signal char_bit_x_pos 	: integer 	:= 0;
signal char_bit_y_pos 	: integer 	:= 0;
signal char_x_pos 		: integer 	:= 0;
signal char_y_pos 		: integer 	:= 0;
signal pixOn			: std_LOGIC := '0';

signal next_data_ena 	: std_logic := '0';
signal current_data		: std_logic_vector(7 downto 0);
signal next_data		: std_logic_vector(7 downto 0);
signal addr_now 		: integer := char_x_pos;
signal addr_next 		: integer := addr_now;


-- components
component soc_system is
	port (
		clk_clk                     : in    std_logic                     := 'X';             -- clk
		clk_25mhz_clk               : out   std_logic;                                        -- clk
		reset_reset_n               : in    std_logic                     := 'X';             -- reset_n
		hps_io_hps_io_usb1_inst_D0  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D0
		hps_io_hps_io_usb1_inst_D1  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D1
		hps_io_hps_io_usb1_inst_D2  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D2
		hps_io_hps_io_usb1_inst_D3  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D3
		hps_io_hps_io_usb1_inst_D4  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D4
		hps_io_hps_io_usb1_inst_D5  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D5
		hps_io_hps_io_usb1_inst_D6  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D6
		hps_io_hps_io_usb1_inst_D7  : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D7
		hps_io_hps_io_usb1_inst_CLK : in    std_logic                     := 'X';             -- hps_io_usb1_inst_CLK
		hps_io_hps_io_usb1_inst_STP : out   std_logic;                                        -- hps_io_usb1_inst_STP
		hps_io_hps_io_usb1_inst_DIR : in    std_logic                     := 'X';             -- hps_io_usb1_inst_DIR
		hps_io_hps_io_usb1_inst_NXT : in    std_logic                     := 'X';             -- hps_io_usb1_inst_NXT
		hps_io_hps_io_uart0_inst_RX : in    std_logic                     := 'X';             -- hps_io_uart0_inst_RX
		hps_io_hps_io_uart0_inst_TX : out   std_logic;                                        -- hps_io_uart0_inst_TX
		memory_mem_a                : out   std_logic_vector(14 downto 0);                    -- mem_a
		memory_mem_ba               : out   std_logic_vector(2 downto 0);                     -- mem_ba
		memory_mem_ck               : out   std_logic;                                        -- mem_ck
		memory_mem_ck_n             : out   std_logic;                                        -- mem_ck_n
		memory_mem_cke              : out   std_logic;                                        -- mem_cke
		memory_mem_cs_n             : out   std_logic;                                        -- mem_cs_n
		memory_mem_ras_n            : out   std_logic;                                        -- mem_ras_n
		memory_mem_cas_n            : out   std_logic;                                        -- mem_cas_n
		memory_mem_we_n             : out   std_logic;                                        -- mem_we_n
		memory_mem_reset_n          : out   std_logic;                                        -- mem_reset_n
		memory_mem_dq               : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
		memory_mem_dqs              : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
		memory_mem_dqs_n            : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
		memory_mem_odt              : out   std_logic;                                        -- mem_odt
		memory_mem_dm               : out   std_logic_vector(3 downto 0);                     -- mem_dm
		memory_oct_rzqin            : in    std_logic                     := 'X';             -- oct_rzqin
		onchip_mem_address          : in    std_logic_vector(11 downto 0) := (others => 'X'); -- address
		onchip_mem_chipselect       : in    std_logic                     := 'X';             -- chipselect
		onchip_mem_clken            : in    std_logic                     := 'X';             -- clken
		onchip_mem_write            : in    std_logic                     := 'X';             -- write
		onchip_mem_readdata         : out   std_logic_vector(7 downto 0);                     -- readdata
		onchip_mem_writedata        : in    std_logic_vector(7 downto 0)  := (others => 'X')  -- writedata
	);
end component soc_system;

begin

u0 : component soc_system
	port map (
		clk_clk                     => clk_clk,                     --        clk.clk
		clk_25mhz_clk               => clk_25Mhz,               --  clk_25mhz.clk
		reset_reset_n               => reset_reset_n,               --      reset.reset_n
		hps_io_hps_io_usb1_inst_D0  => hps_io_hps_io_usb1_inst_D0,  --     hps_io.hps_io_usb1_inst_D0
		hps_io_hps_io_usb1_inst_D1  => hps_io_hps_io_usb1_inst_D1,  --           .hps_io_usb1_inst_D1
		hps_io_hps_io_usb1_inst_D2  => hps_io_hps_io_usb1_inst_D2,  --           .hps_io_usb1_inst_D2
		hps_io_hps_io_usb1_inst_D3  => hps_io_hps_io_usb1_inst_D3,  --           .hps_io_usb1_inst_D3
		hps_io_hps_io_usb1_inst_D4  => hps_io_hps_io_usb1_inst_D4,  --           .hps_io_usb1_inst_D4
		hps_io_hps_io_usb1_inst_D5  => hps_io_hps_io_usb1_inst_D5,  --           .hps_io_usb1_inst_D5
		hps_io_hps_io_usb1_inst_D6  => hps_io_hps_io_usb1_inst_D6,  --           .hps_io_usb1_inst_D6
		hps_io_hps_io_usb1_inst_D7  => hps_io_hps_io_usb1_inst_D7,  --           .hps_io_usb1_inst_D7
		hps_io_hps_io_usb1_inst_CLK => hps_io_hps_io_usb1_inst_CLK, --           .hps_io_usb1_inst_CLK
		hps_io_hps_io_usb1_inst_STP => hps_io_hps_io_usb1_inst_STP, --           .hps_io_usb1_inst_STP
		hps_io_hps_io_usb1_inst_DIR => hps_io_hps_io_usb1_inst_DIR, --           .hps_io_usb1_inst_DIR
		hps_io_hps_io_usb1_inst_NXT => hps_io_hps_io_usb1_inst_NXT, --           .hps_io_usb1_inst_NXT
		hps_io_hps_io_uart0_inst_RX => hps_io_hps_io_uart0_inst_RX, --     hps_io.hps_io_uart0_inst_RX
		hps_io_hps_io_uart0_inst_TX => hps_io_hps_io_uart0_inst_TX, --           .hps_io_uart0_inst_TX
		memory_mem_a                => memory_mem_a,                --     memory.mem_a
		memory_mem_ba               => memory_mem_ba,               --           .mem_ba
		memory_mem_ck               => memory_mem_ck,               --           .mem_ck
		memory_mem_ck_n             => memory_mem_ck_n,             --           .mem_ck_n
		memory_mem_cke              => memory_mem_cke,              --           .mem_cke
		memory_mem_cs_n             => memory_mem_cs_n,             --           .mem_cs_n
		memory_mem_ras_n            => memory_mem_ras_n,            --           .mem_ras_n
		memory_mem_cas_n            => memory_mem_cas_n,            --           .mem_cas_n
		memory_mem_we_n             => memory_mem_we_n,             --           .mem_we_n
		memory_mem_reset_n          => memory_mem_reset_n,          --           .mem_reset_n
		memory_mem_dq               => memory_mem_dq,               --           .mem_dq
		memory_mem_dqs              => memory_mem_dqs,              --           .mem_dqs
		memory_mem_dqs_n            => memory_mem_dqs_n,            --           .mem_dqs_n
		memory_mem_odt              => memory_mem_odt,              --           .mem_odt
		memory_mem_dm               => memory_mem_dm,               --           .mem_dm
		memory_oct_rzqin            => memory_oct_rzqin,            --           .oct_rzqin
		onchip_mem_address          => onchip_mem_address,          -- onchip_mem.address
		onchip_mem_chipselect       => '1',       						--           .chipselect
		onchip_mem_clken            => '1',           					--           .clken
		onchip_mem_write            => onchip_mem_write,            --           .write
		onchip_mem_readdata         => onchip_mem_readdata,         --           .readdata
		onchip_mem_writedata        => onchip_mem_writedata         --           .writedata
	);

fontRom: entity work.Font_Rom
port map(
    clk => clk_clk,
    addr => fontAddress,
    fontRow => charBitInRow
);


COMP_SYNC: ENTITY work.vga_controller
--vertical sync pulse polarity (1 = positive, 0 = negative)
	PORT map(
		pixel_clk	=> clk_25Mhz,	--pixel clock at frequency of VGA mode being used
		reset_n		=> reset_n,		--active low asycnchronous reset
		h_sync		=> h_sync,		--horiztonal sync pulse
		v_sync		=> v_sync,		--vertical sync pulse
		disp_ena		=> disp_ena,	--display enable ('1' = display time, '0' = blanking time)
		column		=> column,		--horizontal pixel coordinate
		row			=> row,			--vertical pixel coordinate
		n_blank		=> n_blank,		--direct blacking output to DAC
		n_sync		=> n_sync
		);
		
	vga_clk <= clk_25Mhz;
	char_bit_x_pos <= to_integer(to_unsigned(column,3));
	char_bit_y_pos <= to_integer(to_unsigned(row,4));
	char_x_pos <= to_integer(to_unsigned(column,30) srl 3);
	char_y_pos <= to_integer(to_unsigned(row,30) srl 4);

	-- read data from ram
	onchip_mem_address 	<= std_logic_vector(to_unsigned((char_x_pos + char_y_pos*80),12));
	
	--fontAddress = (16 rows for char) * (read data ASCII value) + (current char y position)
	fontAddress <= 16*to_integer(unsigned(onchip_mem_readdata))+char_bit_y_pos;
	
	--set pixel and output it as green
	pixOn <= 	'1' when (charBitInRow(8-char_bit_x_pos-1) = '1') and disp_ena = '1' else '0';
	g<= (others => pixOn);

end architecture;
