extends Object

class_name TypeFormattingLogic

var all_type_names = {null:"ERR", TYPE_NIL:"nil", TYPE_BOOL:"bool", TYPE_INT:"int", TYPE_REAL:"real", TYPE_STRING:"str", TYPE_VECTOR2:"v2", TYPE_RECT2:"rect2", TYPE_VECTOR3:"v3", TYPE_TRANSFORM2D:"trans2D", TYPE_PLANE:"plane", TYPE_QUAT:"quat", TYPE_AABB:"aabb", TYPE_BASIS:"basis", TYPE_TRANSFORM:"transform", TYPE_COLOR:"color", TYPE_NODE_PATH:"nodepath", TYPE_RID:"rid", TYPE_OBJECT:"obj", TYPE_DICTIONARY:"dict", TYPE_ARRAY:"arr", TYPE_RAW_ARRAY:"rawarr", TYPE_INT_ARRAY:"intarr", TYPE_REAL_ARRAY:"realarr", TYPE_STRING_ARRAY:"strarr", TYPE_VECTOR2_ARRAY:"v2arr", TYPE_VECTOR3_ARRAY:"v3ar", TYPE_COLOR_ARRAY:"colorarr", TYPE_MAX:"max"}
var supported_type_names = {TYPE_NIL:"nil", TYPE_BOOL:"bool", TYPE_INT:"int", TYPE_REAL:"real", TYPE_STRING:"str", TYPE_VECTOR2:"v2", TYPE_RECT2:"rect2", TYPE_VECTOR3:"v3", TYPE_COLOR:"color", TYPE_DICTIONARY:"dict", TYPE_ARRAY:"arr"}


# different colors for UI type labels
func get_typehint(tval):
	var typename
	if tval is Array and tval == ["ERR"]:
		return ["ERR", Color(1,0.5,0.5,0.25)]
	elif(typeof(tval) == TYPE_OBJECT):
		typename = tval.get_class()
	else:
		typename = all_type_names[typeof(tval)]

	var sum = 0
	for x in range(0,typename.length()):
		sum += typename.ord_at(x)-100
		
	var color = Color(0,0,0,0.33)
	color.r = 0.25 + 0.015*((sum*11)%50)
	color.g = 0.25 + 0.015*((sum*17)%50)
	color.b = 0.25 + 0.015*((sum*3)%50)
	
	return [typename, color]


func guess_my_type(tval):
	if is_hex_color(tval):
		return TYPE_COLOR
	elif is_number(tval):
		if "." in tval:
			return TYPE_REAL
		else:
			return TYPE_INT
	elif tval.to_upper().replace(" ", "") in ["FALSE","TRUE"]:
		return TYPE_BOOL
	elif is_number_tuple(tval):
		if count(tval, ",") == 1:
			return TYPE_VECTOR2
		elif count(tval, ",") == 2:
			return TYPE_VECTOR3
		elif count(tval, ",") == 3:
			return TYPE_COLOR		# or TYPE_RECT2
	else:
		return typeof(tval)

func custom_val2str(val):
	var typ = typeof(val)
	if typ == TYPE_COLOR:
		return "#"+val.to_html(true).to_upper()
	elif typ in [TYPE_VECTOR2, TYPE_VECTOR3, TYPE_RECT2]:
		return str(val).replace("(", "").replace(")", "")
		
	return str(val)

func custom_convert(val, typ):
	if typeof(val) == typ:		# this should be unused
		return [val]
	else:
		val = str(val)
		if typ != TYPE_STRING:
			val = val.replace(" ", "")

		if typ == TYPE_DICTIONARY:
			return [{}]
		elif typ == TYPE_ARRAY:
			return [[]]
		elif typ == TYPE_REAL:
			return [float(val)]
		elif typ == TYPE_INT:
			return [int(val)]
		elif typ == TYPE_STRING:
			return [str(val)]
		elif typ == TYPE_BOOL:
			if val.to_upper() in ["0", "0.0", "0.", "F", "N", "FALSE","SAGE"]:
				return [false]
			else:
				return [true]
		elif typ == TYPE_NIL:
				return [null]
		elif typ == TYPE_VECTOR2:
			if val.length() == 0:
				val  = "0,0"
			var v = val.split(",")
			if v.size() == 2:
				return [Vector2(float(v[0]), float(v[1]))]
			else:
				return [null, "Can't convert \""+str(val)+"\" to Vector2(x,y)."]
		elif typ == TYPE_VECTOR3:
			if val.length() == 0:
				val  = "0,0,0"
			var v = val.split(",")
			if v.size() == 3:
				return [Vector3(float(v[0]), float(v[1]), float(v[2]))]
			else:
				return [null, "Can't convert \""+str(val)+"\" to Vector3(x,y,z)."]
		elif typ == TYPE_RECT2:
			if val.length() == 0:
				val  = "0,0,0,0"
			var v = val.split(",")
			if v.size() == 4:
				return [Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))]
			else:
				return [null, "Can't convert \""+str(val)+"\" to Rect2(x,y,w,h)."]
		elif typ == TYPE_COLOR:
			if val.length() == 0:
				val  = "0,0,0"
			var v = val.split(",")
			if v.size() == 3:
				return [Color(float(v[0]), float(v[1]), float(v[2]))]
			elif v.size() == 4:
				return [Color(float(v[0]), float(v[1]), float(v[2]), float(v[3]))]
			elif is_hex_color(val):
				return [Color(val)]
			else:
				return [null, "Can't convert \""+str(val)+"\" to Color(r,g,b[,a]) | Color(#XXXXXXX[XX])"]

	return [null, "Unsupported type: "+all_type_names[typ]+" , for \""+str(val)+"\" "]


func is_hex_color(val):
	if (val.length() == 7 or val.length() == 9) and val[0] == "#":
		for i in val.substr(1,-1):
			if not i.capitalize() in ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]:
				return false
		return true
	return false


func is_number(val):
	if count(val, ".") > 1:
		return false

	var stripped = val.replace(".", "").replace(" ", "")
	if stripped.length() == 0:
		return false

	for i in stripped:
		if not i in ["0","1","2","3","4","5","6","7","8","9"]:
			return false

	return true


func is_number_tuple(val):
	for num in val.split(","):
		if not is_number(num):
			return false
	return true

func count(s, w):
	var i = 0
	for c in s:
		if c == w:
			i += 1
	return i
