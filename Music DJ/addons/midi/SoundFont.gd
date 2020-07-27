"""
	SoundFont reader by Yui Kinomoto @arlez80
"""

class_name SoundFont

"""
	SampleLink
"""
const sample_link_mono_sample:int = 1
const sample_link_right_sample:int = 2
const sample_link_left_sample:int = 4
const sample_link_linked_sample:int = 8
const sample_link_rom_mono_sample:int = 0x8001
const sample_link_rom_right_sample:int = 0x8002
const sample_link_rom_left_sample:int = 0x8004
const sample_link_rom_linked_sample:int = 0x8008

"""
	GenerateOperator
"""
const gen_oper_start_addrs_offset:int = 0
const gen_oper_end_addrs_offset:int = 1
const gen_oper_startloop_addrs_offset:int = 2
const gen_oper_endloop_addrs_offset:int = 3
const gen_oper_start_addrs_coarse_offset:int = 4
const gen_oper_mod_lfo_to_pitch:int = 5
const gen_oper_vib_lfo_to_pitch:int = 6
const gen_oper_mod_env_to_pitch:int = 7
const gen_oper_initial_filter_fc:int = 8
const gen_oper_initial_filter_q:int = 9
const gen_oper_mod_lfo_to_filter_fc:int = 10
const gen_oper_mod_env_to_filter_fc:int = 11
const gen_oper_end_addrs_coarse_offset:int = 12
const gen_oper_mod_lfo_to_volume:int = 13
const gen_oper_unused1:int = 14
const gen_oper_chorus_effects_send:int = 15
const gen_oper_reverb_effects_send:int = 16
const gen_oper_pan:int = 17
const gen_oper_unused2:int = 18
const gen_oper_unused3:int = 19
const gen_oper_unused4:int = 20
const gen_oper_delay_mod_lfo:int = 21
const gen_oper_freq_mod_lfo:int = 22
const gen_oper_delay_vib_lfo:int = 23
const gen_oper_freq_vib_lfo:int = 24
const gen_oper_delay_mod_env:int = 25
const gen_oper_attack_mod_env:int = 26
const gen_oper_hold_mod_env:int = 27
const gen_oper_decay_mod_env:int = 28
const gen_oper_sustain_mod_env:int = 29
const gen_oper_release_mod_env:int = 30
const gen_oper_keynum_to_mod_env_hold:int = 31
const gen_oper_keynum_to_mod_env_decay:int = 32
const gen_oper_delay_vol_env:int = 33
const gen_oper_attack_vol_env:int = 34
const gen_oper_hold_vol_env:int = 35
const gen_oper_decay_vol_env:int = 36
const gen_oper_sustain_vol_env:int = 37
const gen_oper_release_vol_env:int = 38
const gen_oper_keynum_to_vol_env_hold:int = 39
const gen_oper_keynum_to_vol_env_decay:int = 40
const gen_oper_instrument:int = 41
const gen_oper_reserved1:int = 42
const gen_oper_key_range:int = 43
const gen_oper_vel_range:int = 44
const gen_oper_startloop_addrs_coarse_offset:int = 45
const gen_oper_keynum:int = 46
const gen_oper_velocity:int = 47
const gen_oper_initial_attenuation:int = 48
const gen_oper_reserved2:int = 49
const gen_oper_endloop_addrs_coarse_offset:int = 50
const gen_oper_coarse_tune:int = 51
const gen_oper_fine_tune:int = 52
const gen_oper_sample_id:int = 53
const gen_oper_sample_modes:int = 54
const gen_oper_reserved3:int = 55
const gen_oper_scale_tuning:int = 56
const gen_oper_exclusive_class:int = 57
const gen_oper_overriding_root_key:int = 58
const gen_oper_unused5:int = 59
const gen_oper_end_oper:int = 60

"""
	SampleMode
"""
const sample_mode_no_loop:int = 0
const sample_mode_loop_continuously:int = 1
const sample_mode_unused_no_loop:int = 2	# this is unused, but it needs interpreted as no loop
const sample_mode_loop_ends_by_key_depression:int = 3

"""
	Classes
"""
class SoundFontData:
	var info:SoundFontInfo
	var sdta:SoundFontSampleData
	var pdta:SoundFontPresetData

class SoundFontChunk:
	var header:String = ""
	var size:int = 0
	var stream:StreamPeerBuffer

class SoundFontVersionTag:
	var major:int = 0
	var minor:int = 0

class SoundFontInfo:
	var ifil:SoundFontVersionTag = SoundFontVersionTag.new( )
	var isng:String = ""
	var inam:String = ""

	var irom:String = ""
	var iver:SoundFontVersionTag = SoundFontVersionTag.new( )
	var icrd:String = ""
	var ieng:String = ""
	var iprd:String = ""
	var icop:String = ""
	var icmt:String = ""
	var isft:String = ""

class SoundFontSampleData:
	var smpl:PoolByteArray
	var sm24:PoolByteArray

class SoundFontPresetData:
	var phdr:Array
	var pbag:Array
	var pmod:Array
	var pgen:Array
	var inst:Array
	var ibag:Array
	var imod:Array
	var igen:Array
	var shdr:Array

class SoundFontPresetHeader:
	var name:String = ""
	var preset:int = 0
	var bank:int = 0
	var preset_bag_index:int = 0
	var library:int = 0
	var genre:int = 0
	var morphology:int = 0

class SoundFontBag:
	var gen_ndx:int = 0
	var mod_ndx:int = 0

class SoundFontModule:
	var src_oper:SoundFontPresetDataModulator = null
	var dest_oper:int = 0
	var amount:int = 0
	var amt_src_oper:SoundFontPresetDataModulator = null
	var trans_oper:int = 0

class SoundFontGenerator:
	var gen_oper:int = 0
	var uamount:int = 0
	var amount:int = 0

class SoundFontPresetDataModulator:
	var type:int
	var direction:int
	var polarity:int
	var controller:int
	var controllerPallete:int

	func _init( u:int ):
		self.type = ( u >> 10 ) & 0x3f
		self.direction = ( u >> 8 ) & 0x01
		self.polarity = ( u >> 9 ) & 0x01
		self.controller = u & 0x7f
		self.controllerPallete = ( u >> 7 ) & 0x01

class SoundFontInstrument:
	var name:String = ""
	var inst_bag_ndx:int = 0

class SoundFontSampleHeader:
	var name:String = ""
	var start:int = 0
	var end:int = 0
	var start_loop:int = 0
	var end_loop:int = 0
	var sample_rate:int = 0
	var original_key:int = 0
	var pitch_correction:int = 0
	var sample_link:int = 0
	var sample_type:int = 0

"""
	ファイルから読み込み
	@param	path	File path
	@return	smf
"""
func read_file( path:String ) -> SoundFontData:
	var f:File = File.new( )

	if f.open( path, f.READ ) != OK:
		push_error( "error: cant read file %s" % path )
		breakpoint
	var stream:StreamPeerBuffer = StreamPeerBuffer.new( )
	stream.set_data_array( f.get_buffer( f.get_len( ) ) )
	stream.big_endian = false
	f.close( )

	return self._read( stream )

"""
	配列から読み込み
	@param	data	PoolByteArray
	@return	smf
"""
func read_data( data:PoolByteArray ) -> SoundFontData:
	var stream:StreamPeerBuffer = StreamPeerBuffer.new( )
	stream.set_data_array( data )
	stream.big_endian = false
	return self._read( stream )

"""
	読み込み
	@param	input
	@return	SoundFont
"""
func _read( input:StreamPeerBuffer ) -> SoundFontData:
	self._check_chunk( input, "RIFF" )
	self._check_header( input, "sfbk" )

	var sf = SoundFontData.new( )

	sf.info = self._read_info( input )
	sf.sdta = self._read_sdta( input )
	sf.pdta = self._read_pdta( input )

	return sf

"""
	チャンクチェック
	@param	input
	@param	hdr
"""
func _check_chunk( input:StreamPeerBuffer, hdr:String ):
	self._check_header( input, hdr )
	if input.get_32( ) != 0:
		pass

"""
	ヘッダーチェック
	@param	input
	@param	hdr
"""
func _check_header( input:StreamPeerBuffer, hdr:String ):
	var chk = input.get_string( 4 )
	if hdr != chk:
		print( "Doesn't exist " + hdr + " header" )
		breakpoint

"""
	チャンク読み込み
	@param	input
	@param	needs_header
	@param	chunk
"""
func _read_chunk( stream:StreamPeerBuffer, needs_header = null ) -> SoundFontChunk:
	var chunk:SoundFontChunk = SoundFontChunk.new( )

	chunk.header = stream.get_string( 4 )
	if needs_header != null:
		if needs_header != chunk.header:
			print( "Doesn't exist " + needs_header + " header" )
			breakpoint
	chunk.size =  stream.get_u32( )
	var new_stream:StreamPeerBuffer = StreamPeerBuffer.new( )
	new_stream.set_data_array( stream.get_partial_data( chunk.size )[1] )
	new_stream.big_endian = false
	chunk.stream = new_stream

	return chunk

"""
	INFOチャンクを読み込む
	@param	stream
	@param	chunk
"""
func _read_info( stream:StreamPeerBuffer ) -> SoundFontInfo:
	var chunk:SoundFontChunk = self._read_chunk( stream, "LIST" )
	self._check_header( chunk.stream, "INFO" )

	var info:SoundFontInfo = SoundFontInfo.new( )

	while 0 < chunk.stream.get_available_bytes( ):
		var sub_chunk:SoundFontChunk = self._read_chunk( chunk.stream )
		match sub_chunk.header.to_lower( ):
			"ifil":
				info.ifil = self._read_version_tag( sub_chunk.stream )
			"isng":
				info.isng = sub_chunk.stream.get_string( sub_chunk.size )
			"inam":
				info.inam = sub_chunk.stream.get_string( sub_chunk.size )
			"irom":
				info.irom = sub_chunk.stream.get_string( sub_chunk.size )
			"iver":
				info.iver = self._read_version_tag( sub_chunk.stream )
			"icrd":
				info.icrd = sub_chunk.stream.get_string( sub_chunk.size )
			"ieng":
				info.ieng = sub_chunk.stream.get_string( sub_chunk.size )
			"iprd":
				info.iprd = sub_chunk.stream.get_string( sub_chunk.size )
			"icop":
				info.icop = sub_chunk.stream.get_string( sub_chunk.size )
			"icmt":
				info.icmt = sub_chunk.stream.get_string( sub_chunk.size )
			"isft":
				info.isft = sub_chunk.stream.get_string( sub_chunk.size )
			_:
				print( "unknown header" )
				breakpoint

	return info

"""
	バージョンタグを読み込む
	@param	stream
	@param	chunk
"""
func _read_version_tag( stream:StreamPeerBuffer ) -> SoundFontVersionTag:
	var vtag:SoundFontVersionTag = SoundFontVersionTag.new( )
	vtag.major = stream.get_u16( )
	vtag.minor = stream.get_u16( )

	return vtag

"""
	SDTAを読み込む
	@param	stream
	@param	chunk
"""
func _read_sdta( stream:StreamPeerBuffer ) -> SoundFontSampleData:
	var chunk:SoundFontChunk = self._read_chunk( stream, "LIST" )
	self._check_header( chunk.stream, "sdta" )

	var sdta:SoundFontSampleData = SoundFontSampleData.new( )

	var smpl:SoundFontChunk = self._read_chunk( chunk.stream, "smpl" )
	sdta.smpl = smpl.stream.get_partial_data( smpl.size )[1]

	if 0 < chunk.stream.get_available_bytes( ):
		var sm24_chunk:SoundFontChunk = self._read_chunk( chunk.stream, "sm24" )
		sdta.sm24 = sm24_chunk.stream.get_partial_data( sm24_chunk.size )[1]

	return sdta

"""
	PDTAを読み込む
	@param	stream
	@param	chunk
"""
func _read_pdta( stream:StreamPeerBuffer ) -> SoundFontPresetData:
	var chunk:SoundFontChunk = self._read_chunk( stream, "LIST" )
	self._check_header( chunk.stream, "pdta" )

	var pdta:SoundFontPresetData = SoundFontPresetData.new( )

	pdta.phdr = self._read_pdta_phdr( chunk.stream )
	pdta.pbag = self._read_pdta_bag( chunk.stream )
	pdta.pmod = self._read_pdta_mod( chunk.stream )
	pdta.pgen = self._read_pdta_gen( chunk.stream )
	pdta.inst = self._read_pdta_inst( chunk.stream )
	pdta.ibag = self._read_pdta_bag( chunk.stream )
	pdta.imod = self._read_pdta_mod( chunk.stream )
	pdta.igen = self._read_pdta_gen( chunk.stream )
	pdta.shdr = self._read_pdta_shdr( chunk.stream )

	return pdta

"""
	phdr 読み込み
	@param	stream
	@param	chunk
"""
func _read_pdta_phdr( stream:StreamPeerBuffer ) -> Array:
	var chunk:SoundFontChunk = self._read_chunk( stream, "phdr" )
	var phdrs:Array = Array( )

	var chunk_stream:StreamPeerBuffer = chunk.stream

	while 0 < chunk_stream.get_available_bytes( ):
		var phdr:SoundFontPresetHeader = SoundFontPresetHeader.new( )

		phdr.name = chunk_stream.get_string( 20 )
		phdr.preset = chunk_stream.get_u16( )
		phdr.bank = chunk_stream.get_u16( )
		phdr.preset_bag_index = chunk_stream.get_u16( )
		phdr.library = chunk_stream.get_32( )
		phdr.genre = chunk_stream.get_32( )
		phdr.morphology = chunk_stream.get_32( )

		phdrs.append( phdr )

	return phdrs

"""
	*bag読み込み
	@param	stream
	@param	chunk
"""
func _read_pdta_bag( stream:StreamPeerBuffer ) -> Array:
	var chunk:SoundFontChunk = self._read_chunk( stream )
	var bags:Array = Array( )

	if chunk.header.substr( 1, 3 ) != "bag":
		print( "Doesn't exist *bag header." )
		breakpoint

	var chunk_stream:StreamPeerBuffer = chunk.stream

	while 0 < chunk_stream.get_available_bytes( ):
		var bag:SoundFontBag = SoundFontBag.new( )
	
		bag.gen_ndx = chunk_stream.get_u16( )
		bag.mod_ndx = chunk_stream.get_u16( )
		bags.append( bag )

	return bags

"""
	*mod読み込み
	@param	stream
	@param	chunk
"""
func _read_pdta_mod( stream:StreamPeerBuffer ) -> Array:
	var chunk:SoundFontChunk = self._read_chunk( stream )
	var mods:Array = Array( )

	if chunk.header.substr( 1, 3 ) != "mod":
		print( "Doesn't exist *mod header." )
		breakpoint

	var chunk_stream:StreamPeerBuffer = chunk.stream

	while 0 < chunk_stream.get_available_bytes( ):
		var mod:SoundFontModule = SoundFontModule.new( )
	
		mod.src_oper = SoundFontPresetDataModulator.new( chunk_stream.get_u16( ) )
		mod.dest_oper = chunk_stream.get_u16( )
		mod.amount = chunk_stream.get_u16( )
		mod.amt_src_oper = SoundFontPresetDataModulator.new( chunk_stream.get_u16( ) )
		mod.trans_oper = chunk_stream.get_u16( )
		mods.append( mod )

	return mods

"""
	gen 読み込み
	@param	stream
	@param	chunk
"""
func _read_pdta_gen( stream:StreamPeerBuffer ) -> Array:
	var chunk:SoundFontChunk = self._read_chunk( stream )
	var gens:Array = Array( )

	if chunk.header.substr( 1, 3 ) != "gen":
		print( "Doesn't exist *gen header." )
		breakpoint

	var chunk_stream:StreamPeerBuffer = chunk.stream

	# 4 bytes
	#while 0 < chunk_stream.get_available_bytes( ):
	for i in range( chunk_stream.get_available_bytes( ) / 4 ):
		var gen:SoundFontGenerator = SoundFontGenerator.new( )
		
		gen.gen_oper = chunk_stream.get_u16( )
		var uamount:int = chunk_stream.get_u16( )
		gen.uamount = uamount
		gen.amount = uamount if uamount <= 32767 else -( 65536 - uamount )

		gens.append( gen )

	return gens

"""
	inst読み込み
	@param	stream
	@param	chunk
"""
func _read_pdta_inst( stream:StreamPeerBuffer ) -> Array:
	var chunk:SoundFontChunk = self._read_chunk( stream, "inst" )
	var insts:Array = Array( )

	var chunk_stream:StreamPeerBuffer = chunk.stream

	while 0 < chunk_stream.get_available_bytes( ):
		var inst:SoundFontInstrument = SoundFontInstrument.new( )
	
		inst.name = chunk_stream.get_string( 20 )
		inst.inst_bag_ndx = chunk_stream.get_u16( )
		insts.append( inst )

	return insts

"""
	shdr 読み込み
	@param	stream
	@param	chunk
"""
func _read_pdta_shdr( stream:StreamPeerBuffer ) -> Array:
	var chunk:SoundFontChunk = self._read_chunk( stream, "shdr" )
	var shdrs:Array = Array( )

	var chunk_stream:StreamPeerBuffer = chunk.stream

	while 0 < chunk_stream.get_available_bytes( ):
		var shdr:SoundFontSampleHeader = SoundFontSampleHeader.new( )
	
		shdr.name = chunk_stream.get_string( 20 )
		shdr.start = chunk_stream.get_u32( )
		shdr.end = chunk_stream.get_u32( )
		shdr.start_loop = chunk_stream.get_u32( )
		shdr.end_loop = chunk_stream.get_u32( )
		shdr.sample_rate = chunk_stream.get_u32( )
		shdr.original_key = chunk_stream.get_u8( )
		shdr.pitch_correction = chunk_stream.get_8( )
		shdr.sample_link = chunk_stream.get_u16( )
		shdr.sample_type = chunk_stream.get_u16( )
		shdrs.append( shdr )

	return shdrs
