import struct
from enum import IntEnum
from typing import Callable, Dict
from functools import partial
from typing import Optional
import struct
from dataclasses import dataclass
# hello 2022.33910

class PacketType(IntEnum):
    """Must match C++ enum PacketType, obviously"""
    TreeData = 0
    TreeDataWithVarNames = 1
	VarNames = 2
	PresetsExport = 3
	
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

class QTouchTcpConnection:
	def __init__(self):
		self.buffer = bytearray()
		self.packetHandlers : Dict[PacketTypeInt, PacketHandler] = {}

		self.packetHandlers[PacketType.TreeData] = partial(self.processTreeDataPacket, with_var_names = False)
		self.packetHandlers[PacketType.TreeDataWithVarNames] = partial(self.processTreeDataPacket, with_var_names = True)
		self.packetHandlers[PacketType.PresetsExport] = self.processExample

	# This mirrors method with same name from TD TCP Dat.
	def onConnect(self, dat, peer):
		print("QTouchTcpConnection: connected")
		self.buffer.clear()
		return

	# This mirrors method with same name from TD TCP Dat.
	#
	# Ignore everything except 'bytes'. This argument is arbitrary
	# fragment of TCP stream data, it may contain half of packet, it may
	# contain 1 byte, anything. The fragments are guaranteed to be in correct
	# order though. So we accumulate this data, then see if we have enough
	# bytes to process a packet.
	def onReceive(self, dat, rowIndex, message, bytes, peer):
		self.buffer.extend(bytes)
		self.extractAndProcessAllAvailablePackets()
		return

	# This mirrors method with same name from TD TCP Dat.
	def onClose(self, dat, peer):
		print("QTouchTcpConnection: closed")
		self.buffer.clear()
		return

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
		
	#########################
	# READ UTILS FUNCTIONS: #
	#########################
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
		return struct.unpack_from(VEC4_FMT, buf, offset)[0], offset + VEC4_SIZE

	def read_bytes(self, buf: bytes, offset: ByteOffset, size: int) -> tuple[bytes, ByteOffset]:
		if size < 0 or offset + size > len(buf):
			raise ValueError("unexpected end of packet while reading bytes")
		return buf[offset:offset + size], offset + size

	def read_string_section(self, buf: bytes, offset: ByteOffset) -> tuple[str, ByteOffset]:
		size, offset = read_u32(buf, offset)
		raw, offset = read_bytes(buf, offset, size)
		return raw.decode("utf-8"), offset
		
	def parse_var_names_section(self, buf: bytes, offset: ByteOffset) -> tuple[list[str], ByteOffset]:
		namesCount, offset = read_u32(buf, offset)
		names = []
		for i in range(namesCount):
			name, offset = read_string_section(buf, offset)
			names.append(name)
		return names, offset
	
	##############################
	# PACKETS HANDLER FUNCTIONS: #
	##############################	
	def processExample(self, contentBlock: bytes) -> None:
		print(f"processExample: received contentBlock size = {len(contentBlock)}")
		
	def processTreeDataPacket(self, contentBlock: bytes, with_var_names : bool) -> TreeDataWithVarNamesPacketContent:
		print(f"processTreeDataPacket: processing contentBlock size = {len(contentBlock)}")
		offset = 0
		
		preset_name, offset = read_string_section(buf, offset)
		
		var_names = None
		if with_var_names:
			var_names, offset = parse_var_names_section(contentBlock, offset)
			
		total_entries, offset = read_u32(buf, offset)
		first_index, offset = read_u32(buf, offset)
		last_index, offset = read_u32(buf, offset)

		values_count = last_index - first_index + 1
		assert values_count >= 0
		
		vec4_values = []
		for i in range(valuesCount):
			vec4_value : Vec4, offset = self.read_vec4(buf, offset)
			vec4_values.append(vec4_value)
			
		return TreeDataWithVarNamesPacketContent(
			preset_name=preset_name,
			var_names=var_names,
			total_entries=total_entries,
			first_index=first_index,
			last_index=last_index,
			vec4_values=vec4_values,
		)
		
		
		
# Global instance shared across all importing modules
qtouchInstance = QTouchTcpConnection()