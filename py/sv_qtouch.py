import struct
from enum import IntEnum
from typing import Callable, Dict
from functools import partial
from typing import Optional
import struct
from dataclasses import dataclass
import sv

class PacketType(IntEnum):
	"""Must match C++ enum PacketType, obviously"""
	TreeData = 0
	TreeDataWithVarNames = 1
	PresetsExport = 2
	LoadGlslFiles = 3
	
PacketTypeInt = int
HEADER_SIZE = 8

ByteOffset = int
Vec4 = tuple[float, float, float, float]
PacketHandler = Callable[[bytes], None]

@dataclass
class TreeDataWithVarNamesPacketContent:
	preset_name: str
	var_names: Optional[list[str]]
	total_entries: int
	first_index: int
	last_index: int
	vec4_values: list[Vec4]

class UsedOpNames:
	DatWithVarNames = "varnames"
	DatWithQtouchVec4Vars = "qtouch_vardata"
	DatWithQtouchVec4Vars_Temp = "qtouch_vardata_tmp"
	TcpIpDat = "qtouch_tcpip_connection"
	DatWithConnectionState = "qtouch_connection_state"
	DatWithGLSLFilesToParse = "sup_glsl_files"

class QTouchTcpConnection:
	def __init__(self):
		self.buffer = bytearray()
		self.packetHandlers : Dict[PacketTypeInt, PacketHandler] = {}

		self.packetHandlers[PacketType.TreeData] = partial(self.processTreeDataPacket, with_var_names = False)
		self.packetHandlers[PacketType.TreeDataWithVarNames] = partial(self.processTreeDataPacket, with_var_names = True)
		self.packetHandlers[PacketType.PresetsExport] = self.processExample
		
		self.clientsConnected = 0

	######################################
	# MIRRORING METHODS FROM TD TCP DAT: #
	######################################

	def onConnect(self, dat, peer):
		self.clientsConnected += 1
		self.update_dat_with_connection_state()
		
		print(f"QTouchTcpConnection: connected, clientsConnected={self.clientsConnected}")
		self.buffer.clear()
		return

	# Ignore everything except 'bytes'. This argument is arbitrary
	# fragment of TCP stream data, it may contain half of packet, it may
	# contain 1 byte, anything. The fragments are guaranteed to be in correct
	# order though. So we accumulate this data, then see if we have enough
	# bytes to process a packet.
	def onReceive(self, dat, rowIndex, message, bytes, peer):
		self.buffer.extend(bytes)
		self.extractAndProcessAllAvailablePackets()
		return

	def onClose(self, dat, peer):
		self.clientsConnected = max(0, self.clientsConnected-1)
		self.update_dat_with_connection_state()
		
		print(f"QTouchTcpConnection: disconnected, clientsConnected={self.clientsConnected}")
		self.buffer.clear()
		return


	########################
	# HIGH-LEVEL USER API: #
	########################

	def send_load_glsl_packet(self):
		glsl_files_op = sv.proj_op(UsedOpNames.DatWithGLSLFilesToParse)
		assert glsl_files_op
		
		glsl_filepaths = []
		for row in glsl_files_op.rows():
			glsl_op = sv.proj_op(row[0])
			assert glsl_op
			
			glsl_filepath = glsl_op.par.file.eval()
			assert glsl_filepath, "glsl node mentioned must have file linked !"
			
			glsl_filepaths.append(glsl_filepath)
		
		packet = self.make_load_glsl_files_packet(glsl_filepaths)
		self.send_bytes(packet)
		
		print(f"send_load_glsl_packet: sent for: {glsl_filepaths}\n{packet}")


	def connection_status_string(self):
		tcp_op = sv.proj_op(UsedOpNames.TcpIpDat)
		assert(tcp_op)
		
		is_active = tcp_op.par.active
		is_server = tcp_op.par.mode == "server"
		port = tcp_op.par.port
		numClients = self.clientsConnected
		
		if not is_active:
			return f"Connection not active!"
		
		if not is_server:
			return f"Mode is not 'server', its '{tcp_op.par.mode}'!"
		
		if numClients == 0:
			return f"Waiting for connection on port {port}"
		elif numClients == 1:
			return f"Client connected on port {port}"
		else:
			return f"Client (actually {numClients} clients) connected on port {port}"
				

	##############
	# INTERNALS: #
	##############

	def update_dat_with_connection_state(self):
		connstate_op = sv.proj_op(UsedOpNames.DatWithConnectionState)
		assert(connstate_op)
		connstate_op['clientCount', 1] = self.clientsConnected
		connstate_op['stateInfo', 1] = self.connection_status_string()

	def send_bytes(self, the_bytes):
		tcp_op = sv.proj_op(UsedOpNames.TcpIpDat)
		assert(tcp_op)
		tcp_op.sendBytes(the_bytes)

	# -Returns false, if wasnt enough data to process data
	# -Returns true, if data for packet was extracted from buffer
	#  and processed (successfully or not)
	def tryExtractAndProcessPacket(self):
		if len(self.buffer) < HEADER_SIZE:
			return False
			
		packetSize, packetType = struct.unpack('<II', self.buffer[:HEADER_SIZE])
		
		# im not sure how to handle this case gracefully, if something corrupted we cant
		# tell wheres actual packet begin and end in the stream... so far
		# we assume there just will not be errors like that
		assert packetSize >= HEADER_SIZE, "packetSize must be >= HEADER_SIZE"
		
		if len(self.buffer) < packetSize:
			return False
			
		print(f"Handling packet of type {packetType} and size {packetSize}")
			
		contentSize = packetSize - HEADER_SIZE
		
		# extract only content block bytes, without header
		contentBlock = self.buffer[HEADER_SIZE : HEADER_SIZE + contentSize]
		
		# delete entire packet from beginning
		del self.buffer[:packetSize]
		
		# TODO: process contentBlock based on packetType
		packetHandler = self.packetHandlers.get(packetType)
		if packetHandler is not None:
			packetHandler(contentBlock)
		else:
			print(f"QTouchTcpConnection: dropping packet with unknown type: {packetType}")
		
		return True
		
	def extractAndProcessAllAvailablePackets(self):
		while self.tryExtractAndProcessPacket():
			continue
		
		
	##############################
	# BASIC READ/MAKE FUNCTIONS: #
	##############################
	
	def make_u32(self, value: int) -> bytes:
		return value.to_bytes(4, byteorder='little', signed=False)

	def read_u32(self, buf: bytes, offset: ByteOffset) -> tuple[int, ByteOffset]:
		U32_FMT = "<I"
		U32_SIZE = 4
		if offset + U32_SIZE > len(buf):
			raise ValueError("unexpected end of packet while reading uint32")
		return struct.unpack_from(U32_FMT, buf, offset)[0], offset + U32_SIZE

	def read_vec4(self, buf: bytes, offset: ByteOffset) -> tuple[Vec4, ByteOffset]:
		VEC4_FMT = "<4f"
		VEC4_SIZE = 16
		if offset + VEC4_SIZE > len(buf):
			raise ValueError("unexpected end of packet while reading vec4")
		return struct.unpack_from(VEC4_FMT, buf, offset), offset + VEC4_SIZE

	def read_bytes(self, buf: bytes, offset: ByteOffset, size: int) -> tuple[bytes, ByteOffset]:
		if size < 0 or offset + size > len(buf):
			raise ValueError("unexpected end of packet while reading bytes")
		return buf[offset:offset + size], offset + size


	def make_string_section(self, string: str) -> bytes:
		encoded = string.encode('utf-8')
		return self.make_u32(len(encoded)) + encoded

	def read_string_section(self, buf: bytes, offset: ByteOffset) -> tuple[str, ByteOffset]:
		size, offset = self.read_u32(buf, offset)
		raw, offset = self.read_bytes(buf, offset, size)
		return raw.decode("utf-8"), offset
		
	def make_header(self, packet_type : PacketTypeInt, content_size : int) -> bytes:
		total_packet_size = HEADER_SIZE + content_size
		return self.make_u32(total_packet_size) + self.make_u32(packet_type)
		
		
	###############################################
	# HIGH-LEVEL, PACKET-SPECIFIC READ FUNCTIONS: #
	###############################################
	
	def parse_var_names_section(self, buf: bytes, offset: ByteOffset) -> tuple[list[str], ByteOffset]:
		names = []
		
		namesCount, offset = self.read_u32(buf, offset)
		for i in range(namesCount):
			name, offset = self.read_string_section(buf, offset)
			names.append(name)
		return names, offset
	
	def parseTreeDataPacket(self, contentBlock: bytes, with_var_names : bool) -> TreeDataWithVarNamesPacketContent:
		print(f"parseTreeDataPacket: processing contentBlock size = {len(contentBlock)} with_var_names = {with_var_names}")
		offset = 0
		
		preset_name, offset = self.read_string_section(contentBlock, offset)
		total_entries, offset = self.read_u32(contentBlock, offset)
		first_index, offset = self.read_u32(contentBlock, offset)
		last_index, offset = self.read_u32(contentBlock, offset)

		#Next piece of data: N x vec4 vars
		values_count = last_index - first_index + 1
		assert values_count >= 0
		vec4_values = []
		for i in range(values_count):
			vec4_value, offset = self.read_vec4(contentBlock, offset)
			#print(f"Individual vec4 value: {vec4_value}");
			vec4_values.append(vec4_value)
			
		
		#Next piece of data: optional M x var names 
		var_names = None
		if with_var_names:
			var_names, offset = self.parse_var_names_section(contentBlock, offset)
			assert len(var_names) == total_entries
		
		assert offset == len(contentBlock), f"Finished parsing, but 'offset' [{offset}] is not at the end of contentBlock, expected [{len(contentBlock)}]"
			
		result = TreeDataWithVarNamesPacketContent(
			preset_name=preset_name,
			var_names=var_names,
			total_entries=total_entries,
			first_index=first_index,
			last_index=last_index,
			vec4_values=vec4_values
		)
		
		return result
	
	
	##############################
	# PACKETS HANDLER FUNCTIONS: #
	##############################
	
	def processExample(self, contentBlock: bytes) -> None:
		print(f"processExample: received contentBlock size = {len(contentBlock)}")
		
	def processTreeDataPacket(self, contentBlock: bytes, with_var_names : bool) -> TreeDataWithVarNamesPacketContent:
		packet: TreeDataWithVarNamesPacketContent = self.parseTreeDataPacket(contentBlock, with_var_names)
		
		#print(f"parseTreeDataPacket result is: {packet}")
		
		op_varnames = sv.proj_op(UsedOpNames.DatWithVarNames)
		assert op_varnames
		
		op_vardata = sv.proj_op(UsedOpNames.DatWithQtouchVec4Vars)
		assert op_vardata
		
		op_vardata_TEMP = sv.proj_op(UsedOpNames.DatWithQtouchVec4Vars_Temp)
		assert op_vardata_TEMP
		
		
		####################
		# <SAVE VAR NAMES> #
		####################
		if with_var_names:
			op_varnames.clear()
			for var_name in packet.var_names:
				op_varnames.appendRow(var_name)
		#####################
		# </SAVE VAR NAMES> #
		#####################
		
		
		########################################
		# <SAVE VAR DATA AND FORM FINAL TABLE> #
		########################################
		
		assert op_varnames.numRows == packet.total_entries, f" existing varnames {op_varnames.numRows} != packet entries count {packet.total_entries}"
		
		new_vardata_rows = []
		for i in range(len(packet.vec4_values)):
			var_index = packet.first_index + i
			var_name = op_varnames[var_index, 0].val
			x,y,z,w = packet.vec4_values[i]
			new_vardata_rows.append([var_name,x,y,z,w])
		
		# this whole thing is supposed to be efficient, cause its one copy operation on final node.
		# we dont want to jerk final node more than once
		op_vardata_TEMP.copy(op_vardata)
		
		if op_vardata_TEMP.numRows != packet.total_entries:
			op_vardata_TEMP.setSize(packet.total_entries, op_vardata_TEMP.numCols)
		
		for i in range(len(new_vardata_rows)):
			index = packet.first_index + i
			op_vardata_TEMP.replaceRow(index, new_vardata_rows[i])
		op_vardata.copy(op_vardata_TEMP)
		
		#########################################
		# </SAVE VAR DATA AND FORM FINAL TABLE> #
		#########################################
		
		
		print("processTreeDataPacket finished.") 
	
	
	############################
	# PACKETS MAKER FUNCTIONS: #
	############################
		
	def make_load_glsl_files_packet(self, filePaths: list[str]) -> bytes:
		content_block = bytearray()
	
		for path in filePaths:
			content_block += self.make_string_section(path)
			
		packet = self.make_header(PacketType.LoadGlslFiles, len(content_block)) + content_block
		return packet
	
# Global instance shared across all importing modules
qtouchInstance = QTouchTcpConnection()