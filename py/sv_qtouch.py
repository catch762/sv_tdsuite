import struct
from enum import IntEnum
from typing import Callable, Dict

class PacketType(IntEnum):
    """Must match C++ enum PacketType, obviously"""
    TreeData = 0
    Whatever = 1
	
PacketTypeInt = int

HEADER_SIZE = 8
PacketHandler = Callable[[bytes], None]

class QTouchTcpConnection:
	def __init__(self):
		self.buffer = bytearray()
		self.packetHandlers : Dict[PacketTypeInt, PacketHandler] = {}

		self.packetHandlers[PacketType.TreeData] = self.processExample

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
		
	def processExample(self, contentBlock: bytes) -> None:
		print(f"processExample: received contentBlock size = {len(contentBlock)}")
		
# Global instance shared across all importing modules
qtouchInstance = QTouchTcpConnection()